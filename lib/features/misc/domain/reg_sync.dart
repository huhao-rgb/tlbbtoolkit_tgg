/// 卡回归 —— 跨端数据合并（纯函数，无 IO，便于单测）。
///
/// 合并契约（幂等：`merge(merge(L, R), R) == merge(L, R)`）：
/// - **同 id**：视为同一条账号记录，按 [RegAccount.updatedAt]「新者胜」；
/// - **id 不同但「姓名 + 门派」相同**：视为同一逻辑账号（历史数据 id 由毫秒
///   时间戳生成，多端各自新增时会不同），合并为一条并保留本机 id；
/// - **回归轮次 [RegRun]**：按 `startMs` 取并集（同一轮取较大的 `endMs`），
///   因此两端各自完成的回归记录不会互相覆盖；
/// - **计时起点 [RegAccount.curMs]**：随胜者整体取值（「开始/放弃/领奖」
///   都是一次内容修改），不做「有值优先」的拼接；
/// - **删除（墓碑）**：`deletedAt` 与对方的 `updatedAt` 比较，时间大者胜，
///   打平则「已删除」优先，避免误复活。
library;

import 'dart:convert';

import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';

/// 云同步载荷版本（密文内部的结构版本；与本地存储 v 无关）。
const int kRegSyncPayloadVersion = 2;

/// 把完整记录（**含墓碑**）编码为云端载荷文本。
///
/// 必须含墓碑：否则「A 设备删掉的账号」无法传播到 B，B 下次同步会把它推回来。
/// 上传前先过 [pruneRegTombstones] 裁掉超期墓碑。
///
/// **顺序规范化（essential）**：账号按 id 排序后再编码。同步引擎是靠
/// 「载荷文本是否相等」判断要不要回传的，而 [mergeRegAccounts] 刻意保留
/// `local` 顺序（导入/合并后不搅乱本机列表）。两者相遇会产生一个隐蔽的
/// 往复：A 上传的顺序以 A 为 local，B 合并后顺序以 B 为 local，
/// 于是**内容已完全一致、载荷文本却不同**，两端每次同步都各白写一次云端
/// （rev 无限增长、状态永远到不了 `upToDate`）。
///
/// 排序让载荷成为**内容的规范形式**，与「谁先合并」无关；
/// 本机列表顺序不受影响（`saveAll` 存的是合并结果本身）。
String encodeRegSyncPayload(List<RegAccount> accounts) {
  final ordered = [...accounts]..sort((a, b) => a.id.compareTo(b.id));
  return jsonEncode({
    'v': kRegSyncPayloadVersion,
    'accts': [for (final a in ordered) a.toJson()],
  });
}

/// 解析云端载荷；结构不符抛 [FormatException]。
List<RegAccount> decodeRegSyncPayload(String source) {
  final Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException catch (e) {
    throw FormatException('云同步载荷不是合法 JSON：${e.message}');
  }
  if (root is! Map<String, dynamic> || root['accts'] is! List) {
    throw const FormatException('云同步载荷结构不符（缺少 accts）');
  }
  return [
    for (final it in root['accts'] as List)
      if (it is Map<String, dynamic>) RegAccount.fromJson(it),
  ];
}

/// 合并结果：`merged` 为合并后的完整列表（含墓碑记录），其余为计数。
typedef RegMergeResult = ({
  List<RegAccount> merged,
  int added,
  int updated,
  int skipped,
});

/// 合并本机账号 [local] 与外部账号 [remote]（来自导入文件、同步码或云端）。
///
/// [local] 的顺序被保留（新账号按 [remote] 顺序追加），避免导入后本机
/// 排序被搅乱。返回列表**可能含墓碑记录**，由仓储决定如何持久化与过滤。
///
/// [canonicalizeIds]：判重命中但两端 id 不同时，是否把 id 统一到
/// [_canonicalId] 的确定性取值。
/// - **云同步必须开启**（见 `syncRegAccounts`）：两端独立合并出的载荷必须
///   逐字节一致，否则「内容已同步」永远判不出来，两端会反复回传；
/// - **导入保持关闭**：导入是本地一次性动作，不需要跨端字节相等，
///   此时把本机 id 悄悄换成导入项生成的随机 id 只会让用户困惑（选中项丢失）。
RegMergeResult mergeRegAccounts({
  required List<RegAccount> local,
  required List<RegAccount> remote,
  bool canonicalizeIds = false,
}) {
  final merged = <RegAccount>[...local];
  final indexById = <String, int>{};
  final indexByName = <String, int>{};
  for (var i = 0; i < merged.length; i++) {
    final id = merged[i].id;
    if (id.isNotEmpty) indexById.putIfAbsent(id, () => i);
    indexByName.putIfAbsent(_nameKey(merged[i]), () => i);
  }

  var added = 0;
  var updated = 0;
  var skipped = 0;

  for (final r in remote) {
    var i = r.id.isEmpty ? null : indexById[r.id];
    i ??= indexByName[_nameKey(r)];

    if (i == null) {
      // 本机没有对应账号：墓碑无内容可落地，直接跳过。
      if (r.isDeleted) {
        skipped++;
        continue;
      }
      merged.add(r);
      final at = merged.length - 1;
      if (r.id.isNotEmpty) indexById[r.id] = at;
      indexByName.putIfAbsent(_nameKey(r), () => at);
      added++;
      continue;
    }

    final next = _mergePair(merged[i], r, canonicalizeIds: canonicalizeIds);
    if (next == null) {
      skipped++;
      continue;
    }
    merged[i] = next;
    // id 可能被判重规则改成规范 id（见 _canonicalId）：补登记，
    // 否则后面带该 id 的 remote 记录会找不到它，被当成新账号重复追加。
    if (next.id.isNotEmpty) indexById.putIfAbsent(next.id, () => i!);
    updated++;
  }

  return (merged: merged, added: added, updated: updated, skipped: skipped);
}

/// 「姓名 + 门派」判重键（用 `\u0000` 分隔，避免姓名里含分隔字符时误判）。
String _nameKey(RegAccount a) => '${a.name}\u0000${a.sectKey}';

/// 一条记录的合并优先级：墓碑用 `deletedAt`，存活记录用 `updatedAt`。
({bool deleted, int t}) _rank(RegAccount a) {
  final d = a.deletedAt;
  return d == null ? (deleted: false, t: a.updatedAt) : (deleted: true, t: d);
}

/// 同一条账号在两端 id 不同时，取定的规范 id：**字典序较小者**。
///
/// 必须确定性：`_mergePair` 是「本机 vs 外部」两个方向的同一套代码，
/// 若各自保留本机 id，两端合并出的载荷永远不同 → 每次同步都各白写一次云端
/// （见 `encodeRegSyncPayload` 的注释）。取较小者**可交换**，
/// 因此「谁先合并」不影响结果，两端必然收敛到同一个 id。
String _canonicalId(String a, String b) {
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return a.compareTo(b) <= 0 ? a : b;
}

/// 复制一条记录并替换 id / runs（[RegAccount.copyWith] 刻意不允许改 id）。
RegAccount _rebuild(RegAccount base, {String? id, List<RegRun>? runs}) =>
    RegAccount(
      id: id ?? base.id,
      name: base.name,
      lv: base.lv,
      sectKey: base.sectKey,
      curMs: base.curMs,
      runs: runs ?? base.runs,
      updatedAt: base.updatedAt,
      deletedAt: base.deletedAt,
    );

/// 合并同一条账号的本地版 [a] 与外部版 [b]；无需改动 [a] 时返回 null。
///
/// 关键约束：**结果必须对调 [a]、[b] 后一致**（除 id 走 [_canonicalId]）。
/// 否则两端各自合并出的载荷不同，同步引擎会以为「云端还没同步」而反复回传。
RegAccount? _mergePair(
  RegAccount a,
  RegAccount b, {
  required bool canonicalizeIds,
}) {
  final ra = _rank(a);
  final rb = _rank(b);
  // 时间大者胜；打平则墓碑优先（宁可少复活，不可误复活）。
  final bWins = rb.t > ra.t || (rb.t == ra.t && rb.deleted && !ra.deleted);
  final winner = bWins ? b : a;
  final wRank = bWins ? rb : ra;

  final RegAccount merged;
  if (wRank.deleted) {
    // 胜者是墓碑：删除生效（或刷新墓碑时间）。
    merged = a.isDeleted && !bWins ? a : winner;
  } else if (a.isDeleted) {
    // 本机是墓碑、对方存活 → 复活。回归轮次取并集：墓碑带着删除前的记录，
    // 丢掉它会与镜像方向（走「双方都存活」分支）的结果不一致。
    merged = _rebuild(winner, runs: _unionRuns(a.runs, b.runs));
  } else {
    // 双方都存活：标量字段取胜者，回归轮次取并集。
    merged = RegAccount(
      id: a.id,
      name: winner.name,
      lv: winner.lv,
      sectKey: winner.sectKey,
      curMs: winner.curMs,
      runs: _unionRuns(a.runs, b.runs),
      updatedAt: ra.t > rb.t ? ra.t : rb.t,
    );
  }

  // 不开启规范化时沿用原行为（保留本机 id）
  final id = canonicalizeIds ? _canonicalId(a.id, b.id) : merged.id;
  final result = id == merged.id ? merged : _rebuild(merged, id: id);

  // 无需写回：id 未变、内容一致、墓碑时间也没前进（后者影响墓碑保留期）。
  if (result.id == a.id &&
      result.sameContentAs(a) &&
      result.deletedAt == a.deletedAt) {
    return null;
  }
  return result;
}

/// 回归轮次并集：同一 `startMs` 视为同一轮，保留较大的 `endMs`，按起点升序。
List<RegRun> _unionRuns(List<RegRun> a, List<RegRun> b) {
  final byStart = <int, RegRun>{};
  for (final r in a) {
    byStart[r.startMs] = r;
  }
  for (final r in b) {
    final prev = byStart[r.startMs];
    if (prev == null || r.endMs > prev.endMs) byStart[r.startMs] = r;
  }
  return byStart.values.toList()
    ..sort((x, y) => x.startMs.compareTo(y.startMs));
}
