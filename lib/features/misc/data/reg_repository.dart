import 'dart:async';
import 'dart:convert';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync.dart';

/// 导入/同步合并结果：`accts` 为合并后的**存活**账号列表（不含墓碑）。
typedef RegImportResult = ({
  List<RegAccount> accts,
  int added,
  int updated,
  int skipped,
});

/// 卡回归数据仓储：读写本地 JSON（原型 `localStorage[REG_KEY]`）。
///
/// 存储结构：`{v:2, accts:[RegAccount.toJson…], sel:<id|null>}`。
/// `accts` **包含墓碑记录**（`d` 字段非空），[load] 只对外暴露存活账号。
///
/// 跨端传递数据有两条通道：
/// - 导出/导入 JSON 文件（原型 `regExport` / `regImportFile`），
///   文件格式 `{app:'天工阁',type:'reg-accts',ver:2,exportedAt,accts:[…]}`；
/// - 同步码 [buildSyncCode] / [parseSyncCode]，一段可复制粘贴的文本。
///
/// 两条通道都复用 [mergeRegAccounts] 合并（按 id / 姓名+门派 判重，
/// 回归轮次取并集），并兼容 v1 导出文件与纯账号数组。
class RegRepository {
  /// [clock] 可注入的当前时间（ms），用于测试消除毫秒级时序不确定性
  /// （`updatedAt` 是毫秒粒度，两次连续写入可能落在同一毫秒）；生产环境为 null。
  const RegRepository(this._store, {this.clock});

  final int Function()? clock;

  int _now() => clock?.call() ?? DateTime.now().millisecondsSinceEpoch;

  /// 当前存储 key（v2：账号带 `updatedAt` / `deletedAt` 同步元数据）。
  static const String key = 'tgg-reg-v2';

  /// v1 存储 key，仅在首次读取时用于迁移（迁移成功后删除）。
  static const String legacyKey = 'tgg-reg-v1';

  /// 导出文件标识（对应原型 `type:'reg-accts'`）。
  static const String exportType = 'reg-accts';

  /// 同步码前缀，便于识别粘贴内容（换编码方式时只需递增该版本号）。
  static const String syncCodePrefix = 'TGG1:';

  static final RegExp _whitespace = RegExp(r'\s+');

  final LocalStorage _store;

  /// 当前存活账号列表与选中 id（损坏/缺失返回空态；墓碑记录不返回）。
  ({List<RegAccount> accts, String? sel}) load() {
    final stored = _readStored();
    if (stored == null) return (accts: const [], sel: null);
    return (
      accts: [
        for (final a in stored.accts)
          if (!a.isDeleted) a,
      ],
      sel: stored.sel,
    );
  }

  /// 保存本机存活账号 [accts] 与选中 id [sel]，返回落盘后的存活账号列表。
  ///
  /// 墓碑由仓储自行推导，调用方无需感知：
  /// - 内容相对上次落盘有变化（或本机新增）→ 刷新 [RegAccount.updatedAt]；
  /// - 上次落盘存在、本次消失的存活记录 → 转成墓碑（`deletedAt = now`）；
  /// - 过期墓碑 → 裁剪（见 [kRegTombstoneTtlMs]）。
  Future<List<RegAccount>> save(List<RegAccount> accts, String? sel) async {
    final now = _now();
    final prev = _readStored()?.accts ?? const <RegAccount>[];
    final prevById = {for (final p in prev) p.id: p};
    final keptIds = {for (final a in accts) a.id};

    final live = [
      for (final a in accts)
        a.copyWith(updatedAt: _stampOf(a, prevById[a.id], now)),
    ];
    final tombstones = [
      for (final p in prev)
        if (!keptIds.contains(p.id) && p.isDeleted) p,
      for (final p in prev)
        if (!keptIds.contains(p.id) && !p.isDeleted)
          p.copyWith(deletedAt: now, updatedAt: now),
    ];
    await _writeStored(pruneRegTombstones([...live, ...tombstones], now), sel);
    return live;
  }

  /// 读取**含墓碑**的完整本地记录（云同步的合并基准）。
  ///
  /// 这个基准里必须有墓碑，否则「本机删掉的账号」会被云端旧数据复活；
  /// 页面/UI 请用 [load]（只返回存活账号）。
  List<RegAccount> loadAll() => _readStored()?.accts ?? const [];

  /// 落盘一份**合并结果**（`all` 视为权威状态，可含墓碑），
  /// 返回落盘后的存活账号列表。
  ///
  /// 与 [save] 的分工：[save] 面向「本地编辑」（自行推导墓碑、刷新时间戳）；
  /// 本方法面向「同步合并结果」（时间戳已由合并逻辑定好，原样落盘）。
  Future<List<RegAccount>> saveAll(List<RegAccount> all, String? sel) async {
    final kept = pruneRegTombstones(all, _now());
    await _writeStored(kept, sel);
    return [
      for (final a in kept)
        if (!a.isDeleted) a,
    ];
  }

  /// 生成导出 JSON 文本（原型 `regExport` 的 payload 序列化）。
  String buildExportJson(List<RegAccount> accts) {
    final payload = <String, dynamic>{
      'app': '天工阁',
      'type': exportType,
      'ver': kRegSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'accts': [
        for (final a in accts)
          if (!a.isDeleted) a.toJson(),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 生成同步码：`TGG1:` + Base64Url(紧凑 JSON)，供跨设备复制/粘贴合并。
  ///
  /// 体积：单账号约 110 字节 JSON（≈ 150 字符 Base64），10 个账号约 1.5K
  /// 字符，可走剪贴板、聊天窗口传递。
  String buildSyncCode(List<RegAccount> accts) {
    final payload = <String, dynamic>{
      'v': kRegSchemaVersion,
      't': exportType,
      'e': DateTime.now().toUtc().millisecondsSinceEpoch,
      'a': [
        for (final a in accts)
          if (!a.isDeleted) a.toJson(),
      ],
    };
    return '$syncCodePrefix'
        '${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';
  }

  /// 解析同步码，返回账号原始 map 列表（损坏/结构不符抛 [FormatException]）。
  ///
  /// 宽容处理：忽略空白与换行（聊天窗口粘贴常被折行）；前缀缺失、或用户
  /// 直接粘贴 JSON 文本时同样可解析。
  List<Map<String, dynamic>> parseSyncCode(String source) {
    final compact = source.replaceAll(_whitespace, '');
    if (compact.isEmpty) throw const FormatException('empty sync code');
    final body = _stripSyncPrefix(compact);
    try {
      return _extractAccountMaps(_decodeBase64Json(body));
    } on FormatException {
      if (compact.startsWith('{') || compact.startsWith('[')) {
        return parseImportJson(source); // 容忍直接粘贴 JSON 文本
      }
      rethrow;
    }
  }

  /// 解析导入文本，返回账号列表（损坏/结构不符抛 [FormatException]）。
  ///
  /// 兼容三种结构（原型 `regImportFile`）：
  /// - 本工具导出对象 `{accts:[…]}`；
  /// - 同步码 payload `{a:[…]}`；
  /// - 纯账号数组 `[…]`。
  List<Map<String, dynamic>> parseImportJson(String source) =>
      _extractAccountMaps(_decodeJson(source));

  /// 把外部账号（导入文件 / 同步码）合并进本机并落盘。
  ///
  /// 合并规则见 [mergeRegAccounts]：按 id（或「姓名+门派」）判重，
  /// 回归轮次取并集，时间戳新者胜。
  ///
  /// **基准是含墓碑的本地记录**（而非页面持有的存活列表），因此已被本机
  /// 删除的账号不会被外部旧数据「复活」；选中 id 沿用本地已落盘的值。
  /// 返回合并后的存活账号列表与新增/更新/跳过计数。
  Future<RegImportResult> importAccounts(List<Map<String, dynamic>> raw) async {
    var skipped = 0;
    final incoming = <RegAccount>[];
    for (final x in raw) {
      final a = _accountFromRaw(x);
      if (a == null) {
        skipped++;
        continue;
      }
      incoming.add(a);
    }
    final stored = _readStored();
    final r = mergeRegAccounts(
      local: stored?.accts ?? const [],
      remote: incoming,
    );
    final live = [
      for (final a in r.merged)
        if (!a.isDeleted) a,
    ];
    // 复用 save：统一刷新时间戳、保留/推导墓碑并按保留期裁剪。
    final persisted = await save(live, stored?.sel);
    return (
      accts: persisted,
      added: r.added,
      updated: r.updated,
      skipped: skipped + r.skipped,
    );
  }

  // ---- 内部实现 ----

  /// 读取「含墓碑」的完整本地记录；v2 缺失时从 [legacyKey] 迁移。
  ({List<RegAccount> accts, String? sel})? _readStored() {
    final json = _store.getJson(key);
    if (json != null) return _parseStored(json);

    final legacy = _store.getJson(legacyKey);
    if (legacy == null) return null;
    final migrated = _parseStored(legacy);
    // 历史记录没有 updatedAt：以迁移时间为准，使本机数据在后续合并中
    // 不被「时间戳更旧」的副本覆盖。
    final now = _now();
    final accts = [for (final a in migrated.accts) a.copyWith(updatedAt: now)];
    // 迁移落盘不阻塞首帧；写成功后再删 v1，失败则下次启动重试。
    unawaited(
      _writeStored(
        accts,
        migrated.sel,
      ).then((_) => _store.remove(legacyKey)).catchError((Object _) {}),
    );
    return (accts: accts, sel: migrated.sel);
  }

  ({List<RegAccount> accts, String? sel}) _parseStored(
    Map<String, dynamic> json,
  ) {
    final list = <RegAccount>[];
    for (final it in (json['accts'] as List? ?? const [])) {
      if (it is Map<String, dynamic>) {
        final a = RegAccount.fromJson(it);
        // 过滤无效空记录
        if (a.id.isNotEmpty && a.name.isNotEmpty) list.add(a);
      }
    }
    return (accts: list, sel: json['sel'] as String?);
  }

  Future<void> _writeStored(List<RegAccount> accts, String? sel) =>
      _store.setJson(key, {
        'v': kRegSchemaVersion,
        'accts': [for (final a in accts) a.toJson()],
        'sel': sel,
      });

  /// 本次落盘应写入的 [RegAccount.updatedAt]。
  ///
  /// 内容没变就沿用旧时间戳（重复保存幂等，不做无意义的时间戳漂移）；
  /// 复活墓碑时需显式推进到 `deletedAt` 之后，否则下次合并又会被删除覆盖。
  int _stampOf(RegAccount a, RegAccount? prev, int now) {
    if (prev == null || prev.isDeleted || !prev.sameContentAs(a)) {
      final floorMs = prev?.deletedAt;
      return floorMs != null && floorMs >= now ? floorMs + 1 : now;
    }
    return prev.updatedAt;
  }

  /// 把外部原始 map 规范化为 [RegAccount]；名称缺失等无效记录返回 null。
  ///
  /// 未携带 `u` 时间戳（如 v1 导出文件）按 `0` 处理：合并时不覆盖本机同账号
  /// 的字段，只做「新增账号 + 回归记录并集」，避免误覆盖正在计时的账号。
  RegAccount? _accountFromRaw(Map<String, dynamic> x) {
    final name = (x['name'] as String? ?? '').trim();
    if (name.isEmpty) return null;
    final id = (x['id'] as String? ?? '').trim();
    return RegAccount(
      id: id.isEmpty ? newRegAccountId() : id,
      name: name.length > 24 ? name.substring(0, 24) : name,
      // 门派 key 校验：未知回退逍遥（原型 `SECTS[x.sect]?x.sect:'xiaoyao'`）
      sectKey: regSectOf(x['sect'] as String? ?? '').key,
      lv: ((x['lv'] as num?)?.toInt() ?? 89).clamp(10, 119),
      curMs: (x['cur'] as num?)?.toInt(),
      runs: [
        for (final r in (x['runs'] as List? ?? const []))
          if (r is Map<String, dynamic> && r['s'] is num && r['e'] is num)
            RegRun(
              startMs: (r['s'] as num).toInt(),
              endMs: (r['e'] as num).toInt(),
            ),
      ],
      updatedAt: (x['u'] as num?)?.toInt() ?? 0,
      deletedAt: (x['d'] as num?)?.toInt(),
    );
  }

  /// 取出根节点里的账号 map 列表（兼容 `accts` / `a` / 纯数组）。
  List<Map<String, dynamic>> _extractAccountMaps(Object? root) =>
      switch (root) {
        List<dynamic> _ => [
          for (final it in root)
            if (it is Map<String, dynamic>) it,
        ],
        Map<String, dynamic> m when m['accts'] is List<dynamic> =>
          _extractAccountMaps(m['accts']),
        Map<String, dynamic> m when m['a'] is List<dynamic> =>
          _extractAccountMaps(m['a']),
        _ => throw const FormatException('unexpected root'),
      };

  Object? _decodeJson(String source) {
    try {
      return jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('invalid json: ${e.message}');
    }
  }

  Object? _decodeBase64Json(String body) {
    try {
      return jsonDecode(utf8.decode(base64Url.decode(base64.normalize(body))));
    } on FormatException catch (e) {
      throw FormatException('invalid sync code: ${e.message}');
    }
  }

  String _stripSyncPrefix(String input) =>
      input.length >= syncCodePrefix.length &&
          input.substring(0, syncCodePrefix.length).toUpperCase() ==
              syncCodePrefix
      ? input.substring(syncCodePrefix.length)
      : input;
}
