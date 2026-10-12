/// 卡回归 —— 领域模型与常量（与 UI 原型 `v-regression` 一致）。
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

/// 卡回归数据 schema 版本（本地存储 / 导出文件 / 同步码共用）。
///
/// v1 → v2：账号补充 [RegAccount.updatedAt] / [RegAccount.deletedAt] 同步元数据，
/// id 由毫秒时间戳改为 [newRegAccountId]（跨端不撞号）。
const int kRegSchemaVersion = 2;

/// 生成跨端安全的账号 id（16 字节随机 → 32 位十六进制）。
///
/// 不能用毫秒时间戳：多设备各自新增账号时可能落在同一毫秒产生相同 id，
/// 同步合并会把两个不同账号错误地合为一个。
String newRegAccountId() {
  final rnd = Random.secure();
  return [
    for (var i = 0; i < 16; i++)
      rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// 门派（回归账号所用，复刻原型 `SECTS`；与 job 的门派数据同源同色）。
@immutable
class RegSect {
  const RegSect({
    required this.key,
    required this.name,
    required this.type,
    required this.colorValue,
  });

  final String key;
  final String name;

  /// 定位文案（如 内功 · 控制）。
  final String type;

  /// 主题色（0xAARRGGBB）。
  final int colorValue;

  /// 字徽首字。
  String get mark => name.substring(0, 1);
}

/// 回归页门门派列表（复刻原型 `SECTS`）。
const List<RegSect> kRegSects = [
  RegSect(key: 'shaolin', name: '少林', type: '外功 · 坦克', colorValue: 0xFFF0A25A),
  RegSect(key: 'mingjiao', name: '明教', type: '外功 · 爆发', colorValue: 0xFFFF7069),
  RegSect(key: 'gaibang', name: '丐帮', type: '外功 · 持续', colorValue: 0xFFE2B872),
  RegSect(key: 'tianshan', name: '天山', type: '外功 · 刺客', colorValue: 0xFF4FD1D9),
  RegSect(key: 'xiaoyao', name: '逍遥', type: '内功 · 控制', colorValue: 0xFF5B9BFF),
  RegSect(key: 'emei', name: '峨眉', type: '内功 · 治疗', colorValue: 0xFF43D69A),
  RegSect(key: 'wudang', name: '武当', type: '内功 · 均衡', colorValue: 0xFFA292FF),
  RegSect(key: 'xingxiu', name: '星宿', type: '内功 · 毒系', colorValue: 0xFF9ACD6A),
  RegSect(key: 'murong', name: '慕容', type: '内外 · 兼修', colorValue: 0xFFC3B8FF),
  RegSect(key: 'mantuo', name: '曼陀山庄', type: '内功 · 琴音', colorValue: 0xFFE58FD1),
  RegSect(key: 'tianlong', name: '天龙', type: '内外 · 兼修', colorValue: 0xFFE8D06A),
  RegSect(key: 'erengu', name: '恶人谷', type: '内功 · 刺客', colorValue: 0xFF9B6BD4),
];

/// 按 key 取门派（未知回退逍遥）。
RegSect regSectOf(String key) => kRegSects.firstWhere(
  (s) => s.key == key,
  orElse: () => kRegSects.firstWhere((s) => s.key == 'xiaoyao'),
);

/// 账号回归状态。
enum RegState { idle, run, done }

/// 一轮已完成的回归记录（起点 → 达成）。
@immutable
class RegRun {
  const RegRun({required this.startMs, required this.endMs});

  final int startMs;
  final int endMs;

  Map<String, dynamic> toJson() => {'s': startMs, 'e': endMs};

  factory RegRun.fromJson(Map<String, dynamic> json) => RegRun(
    startMs: (json['s'] as num?)?.toInt() ?? 0,
    endMs: (json['e'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is RegRun && other.startMs == startMs && other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => 'RegRun($startMs → $endMs)';
}

/// 一个回归账号。
///
/// 除业务字段外，另带两个**同步元数据**字段（跨端合并的唯一依据）：
/// - [updatedAt]：业务内容最后一次修改时间（ms），合并时「新者胜」；
/// - [deletedAt]：墓碑标记（ms）；非 null 表示已删除，仅用于合并时
///   阻止已被别的端删掉的账号复活，**不进入 UI 列表**。
@immutable
class RegAccount {
  const RegAccount({
    required this.id,
    required this.name,
    required this.lv,
    required this.sectKey,
    this.curMs,
    this.runs = const [],
    this.updatedAt = 0,
    this.deletedAt,
  });

  final String id;
  final String name;
  final int lv;
  final String sectKey;

  /// 本轮计时起点（ms）；null = 空闲。
  final int? curMs;

  /// 已完成的回归轮次（升序）。
  final List<RegRun> runs;

  /// 内容最后修改时间（ms）；0 = 未知（历史数据）。
  final int updatedAt;

  /// 删除时间（ms）；非 null = 墓碑记录。
  final int? deletedAt;

  /// 是否为墓碑（已删除，仅供合并使用）。
  bool get isDeleted => deletedAt != null;

  RegAccount copyWith({
    String? name,
    int? lv,
    String? sectKey,
    int? curMs,
    bool clearCur = false,
    List<RegRun>? runs,
    int? updatedAt,
    int? deletedAt,
    bool clearDeleted = false,
  }) => RegAccount(
    id: id,
    name: name ?? this.name,
    lv: lv ?? this.lv,
    sectKey: sectKey ?? this.sectKey,
    curMs: clearCur ? null : (curMs ?? this.curMs),
    runs: runs ?? this.runs,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
  );

  /// 业务内容是否与 [other] 一致（忽略 [updatedAt] / [deletedAt]）。
  ///
  /// 仓储据此判断「内容没变就不刷新 [updatedAt]」，
  /// 保证重复保存 / 重复合并是幂等的、不产生无意义的时间戳漂移。
  bool sameContentAs(RegAccount other) {
    if (name != other.name ||
        lv != other.lv ||
        sectKey != other.sectKey ||
        curMs != other.curMs ||
        runs.length != other.runs.length) {
      return false;
    }
    for (var i = 0; i < runs.length; i++) {
      if (runs[i] != other.runs[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lv': lv,
    'sect': sectKey,
    'cur': curMs,
    'runs': [for (final r in runs) r.toJson()],
    'u': updatedAt,
    if (deletedAt != null) 'd': deletedAt,
  };

  factory RegAccount.fromJson(Map<String, dynamic> json) => RegAccount(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    lv: (json['lv'] as num?)?.toInt() ?? 89,
    sectKey: json['sect'] as String? ?? 'xiaoyao',
    curMs: (json['cur'] as num?)?.toInt(),
    runs: [
      for (final r in (json['runs'] as List? ?? const []))
        if (r is Map<String, dynamic>) RegRun.fromJson(r),
    ],
    updatedAt: (json['u'] as num?)?.toInt() ?? 0,
    deletedAt: (json['d'] as num?)?.toInt(),
  );

  @override
  String toString() =>
      'RegAccount($id · $name · Lv.$lv · $sectKey'
      '${isDeleted ? ' · 已删除' : ''})';
}

/// 卡回归周期：7 天 + 1 分钟（原型 `REG_DUR`）。
const int kRegDurMs = 7 * 24 * 3600 * 1000 + 60000;

/// 墓碑保留期（180 天）：超期裁剪，避免记录无限增长。
///
/// 代价是离线超过该期限的设备仍可能「复活」已删除账号，属可接受取舍。
const int kRegTombstoneTtlMs = 180 * 24 * 3600 * 1000;

/// 裁掉过期墓碑，保留全部存活记录与未过期墓碑。
///
/// 本地落盘与云同步上传前都要走一遍：云端载荷必须**携带墓碑**（否则
/// 「A 设备删掉的账号」无法传播到 B），但又不能让墓碑无限累积。
List<RegAccount> pruneRegTombstones(List<RegAccount> accounts, int nowMs) => [
  for (final a in accounts)
    if (!a.isDeleted || nowMs - a.deletedAt! < kRegTombstoneTtlMs) a,
];

/// 达成时刻 = 起点 + 周期。
int regEndOf(int curMs) => curMs + kRegDurMs;

/// 判定账号状态（原型 `acState`）。
RegState regStateOf(RegAccount a, int nowMs) {
  final cur = a.curMs;
  if (cur == null) return RegState.idle;
  return nowMs >= regEndOf(cur) ? RegState.done : RegState.run;
}

/// 「MM月dd日 HH:mm」时间文本（原型 `regFmt`）。
String regFmt(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.month}月${d.day}日 ${_pad2(d.hour)}:${_pad2(d.minute)}';
}

/// 倒计时「x天 HH:MM:SS」（原型 `cdText`）。
String regCdText(int ms) {
  final t = ms <= 0 ? 0 : ms ~/ 1000;
  final d = t ~/ 86400;
  final h = (t % 86400) ~/ 3600;
  final m = (t % 3600) ~/ 60;
  final s = t % 60;
  return '$d天 ${_pad2(h)}:${_pad2(m)}:${_pad2(s)}';
}

/// 两位补零（用于时间文本）。
String _pad2(int n) => n.toString().padLeft(2, '0');
