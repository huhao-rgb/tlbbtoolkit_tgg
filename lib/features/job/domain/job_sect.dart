/// 职业 —— 门派领域模型与数据（与 UI 原型 `SECTS` 一致）。
///
/// 九大门派：少林/明教/丐帮/天山/逍遥/峨眉/武当/星宿/慕容；
/// 每个门派有名称、定位（如 内功 · 控制）与主题色
/// （用于门派字徽 / 定位 tag / 门派筛选 pill）。
library;

import 'package:flutter/foundation.dart';

/// 一个门派。
@immutable
class JobSect {
  const JobSect({
    required this.key,
    required this.name,
    required this.type,
    required this.colorValue,
  });

  /// 路由键（`shaolin` / `xiaoyao` …）。
  final String key;

  /// 门派名（如 少林）。
  final String name;

  /// 定位文案（如 外功 · 坦克）。
  final String type;

  /// 主题色（0xAARRGGBB，对应原型 `SECTS[].c`）。
  final int colorValue;

  /// 字徽首字（`.sect-mark`）。
  String get mark => name.substring(0, 1);
}

/// 九大门派（对应原型 `SECTS`，顺序即筛选行顺序）。
const List<JobSect> kJobSects = [
  JobSect(key: 'shaolin', name: '少林', type: '外功 · 坦克', colorValue: 0xFFF0A25A),
  JobSect(key: 'mingjiao', name: '明教', type: '外功 · 爆发', colorValue: 0xFFFF7069),
  JobSect(key: 'gaibang', name: '丐帮', type: '外功 · 持续', colorValue: 0xFFE2B872),
  JobSect(key: 'tianshan', name: '天山', type: '外功 · 刺客', colorValue: 0xFF4FD1D9),
  JobSect(key: 'xiaoyao', name: '逍遥', type: '内功 · 控制', colorValue: 0xFF5B9BFF),
  JobSect(key: 'emei', name: '峨眉', type: '内功 · 治疗', colorValue: 0xFF43D69A),
  JobSect(key: 'wudang', name: '武当', type: '内功 · 均衡', colorValue: 0xFFA292FF),
  JobSect(key: 'xingxiu', name: '星宿', type: '内功 · 毒系', colorValue: 0xFF9ACD6A),
  JobSect(key: 'murong', name: '慕容', type: '内外 · 兼修', colorValue: 0xFFC3B8FF),
];
