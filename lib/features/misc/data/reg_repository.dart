import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../domain/reg_account.dart';

/// 卡回归数据仓储：读写本地 JSON（原型 `localStorage[REG_KEY]`）。
///
/// 存储结构：`{accts:[RegAccount.toJson…], sel:<id|null>}`。
///
/// 另提供账号 JSON 文件导入/导出（原型 `regExport` / `regImportFile`）：
/// - 导出文件格式 `{app:'天工阁',type:'reg-accts',ver:1,exportedAt,accts:[…]}`；
/// - 导入兼容 本工具导出结构 或 纯账号数组，按「姓名+门派」判重合并。
class RegRepository {
  const RegRepository(this._store);

  static const String key = 'tgg-reg-v1';

  /// 导出文件标识（对应原型 `type:'reg-accts'`）。
  static const String exportType = 'reg-accts';

  final LocalStorage _store;

  /// 当前账号列表与选中 id（损坏/缺失返回空态）。
  ({List<RegAccount> accts, String? sel}) load() {
    final json = _store.getJson(key);
    if (json == null) return (accts: const [], sel: null);
    final sel = json['sel'] as String?;
    final list = <RegAccount>[];
    for (final it in (json['accts'] as List? ?? const [])) {
      if (it is Map<String, dynamic>) {
        final a = RegAccount.fromJson(it);
        // 过滤无效空记录
        if (a.id.isNotEmpty && a.name.isNotEmpty) list.add(a);
      }
    }
    return (accts: list, sel: sel);
  }

  Future<void> save(List<RegAccount> accts, String? sel) =>
      _store.setJson(key, {
        'accts': [for (final a in accts) a.toJson()],
        'sel': sel,
      });

  /// 生成导出 JSON 文本（原型 `regExport` 的 payload 序列化）。
  String buildExportJson(List<RegAccount> accts) {
    final payload = <String, dynamic>{
      'app': '天工阁',
      'type': exportType,
      'ver': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'accts': [for (final a in accts) a.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 解析导入文本，返回账号列表（损坏/结构不符抛 [FormatException]）。
  ///
  /// 兼容两种结构（原型 `regImportFile`）：
  /// - 本工具导出对象 `{accts:[…]}`；
  /// - 纯账号数组 `[…]`。
  List<Map<String, dynamic>> parseImportJson(String source) {
    final dynamic j = jsonDecode(source);
    final list = switch (j) {
      List<dynamic> _ => j,
      Map<String, dynamic> m when m['accts'] is List<dynamic> => m['accts'],
      _ => throw const FormatException('unexpected root'),
    };
    return [
      for (final it in list)
        if (it is Map<String, dynamic>) it,
    ];
  }

  /// 按「姓名+门派」判重合并导入账号到现有列表（原型逻辑）。
  ///
  /// 返回合并后的完整列表与新增/跳过数量；无效记录计入跳过。
  ({List<RegAccount> merged, int added, int skipped}) mergeImported(
    List<Map<String, dynamic>> raw, {
    required List<RegAccount> current,
  }) {
    final merged = [...current];
    final existing = merged.toSet();
    var added = 0;
    var skipped = 0;
    var seq = 0;
    for (final x in raw) {
      final name = (x['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      // 门派 key 校验：未知回退逍遥（原型 `SECTS[x.sect]?x.sect:'xiaoyao'`）
      final sc = regSectOf(x['sect'] as String? ?? '').key;
      // 已存在「同名+同门派」则跳过
      if (existing.any((a) => a.name == name && a.sectKey == sc)) {
        skipped++;
        continue;
      }
      final id = (x['id'] is String && (x['id'] as String).isNotEmpty &&
              !existing.any((a) => a.id == x['id']))
          ? x['id'] as String
          : 'i${DateTime.now().millisecondsSinceEpoch}${seq++}';
      final lv = ((x['lv'] as num?)?.toInt() ?? 89).clamp(10, 119);
      final a = RegAccount(
        id: id,
        name: name.length > 24 ? name.substring(0, 24) : name,
        lv: lv,
        sectKey: sc,
        curMs: (x['cur'] as num?)?.toInt(),
        runs: [
          for (final r in (x['runs'] as List? ?? const []))
            if (r is Map<String, dynamic> &&
                r['s'] is num &&
                r['e'] is num)
              RegRun(startMs: (r['s'] as num).toInt(), endMs: (r['e'] as num).toInt()),
        ],
      );
      merged.add(a);
      existing.add(a);
      added++;
    }
    return (merged: merged, added: added, skipped: skipped);
  }
}
