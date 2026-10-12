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
String encodeRegSyncPayload(List<RegAccount> accounts) => jsonEncode({
  'v': kRegSyncPayloadVersion,
  'accts': [for (final a in accounts) a.toJson()],
});

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

/// 合并本机账号 [local] 与外部账号 [remote]（来自导入文件或同步码）。
///
/// [local] 的顺序被保留（新账号按 [remote] 顺序追加），避免导入后本机
/// 排序被搅乱。返回列表**可能含墓碑记录**，由仓储决定如何持久化与过滤。
RegMergeResult mergeRegAccounts({
  required List<RegAccount> local,
  required List<RegAccount> remote,
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

    final next = _mergePair(merged[i], r);
    if (next == null) {
      skipped++;
      continue;
    }
    merged[i] = next;
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

/// 合并同一条账号的本地版 [a] 与外部版 [b]；无需改动 [a] 时返回 null。
RegAccount? _mergePair(RegAccount a, RegAccount b) {
  final ra = _rank(a);
  final rb = _rank(b);
  // 时间大者胜；打平则墓碑优先（宁可少复活，不可误复活）。
  final bWins = rb.t > ra.t || (rb.t == ra.t && rb.deleted && !ra.deleted);
  final winner = bWins ? b : a;
  final wRank = bWins ? rb : ra;

  if (wRank.deleted) {
    if (a.isDeleted) {
      // 双方都是墓碑：只取更新的删除时间（影响墓碑保留期）。
      return bWins ? b : null;
    }
    return winner;
  }

  // 胜者是存活记录：本机是墓碑 → 复活，直接采用胜者。
  if (a.isDeleted) return winner;

  // 双方都存活：标量字段取胜者，回归轮次取并集。
  final next = RegAccount(
    id: a.id,
    name: winner.name,
    lv: winner.lv,
    sectKey: winner.sectKey,
    curMs: winner.curMs,
    runs: _unionRuns(a.runs, b.runs),
    updatedAt: ra.t > rb.t ? ra.t : rb.t,
  );
  // 内容与本地完全一致时不写回（保持本地时间戳，保证幂等）。
  return next.sameContentAs(a) ? null : next;
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
