/// 职业加点计算器 —— 领域模型与公式（与 UI 原型 `class-point` 一致）。
///
/// - 每 1 级获得 5 点潜能（10 级起），等级 10~119；
///   总潜能 = (min(lv,119)-10) × 5。
/// - 五维：力量 li / 灵气 ling / 体力 ti / 定力 ding / 身法 shen。
/// - 一键推荐按门派权重（`WEIGHTS`）按比例分配，余数按权重降序逐点补齐。
/// - 面板预览公式与原型 `renderPts` 一致。
library;

import 'package:flutter/foundation.dart';

/// 五维定义（顺序同原型 `SKEYS`）。
@immutable
class JobAttrDef {
  const JobAttrDef({required this.key, required this.label});

  /// 键（li / ling / ti / ding / shen）。
  final String key;

  /// 中文名（力量 / 灵气 / 体力 / 定力 / 身法）。
  final String label;
}

/// 五维（顺序即界面展示顺序）。
const List<JobAttrDef> kJobAttrs = [
  JobAttrDef(key: 'li', label: '力量'),
  JobAttrDef(key: 'ling', label: '灵气'),
  JobAttrDef(key: 'ti', label: '体力'),
  JobAttrDef(key: 'ding', label: '定力'),
  JobAttrDef(key: 'shen', label: '身法'),
];

/// 等级范围。
const int kPointLvMin = 10;
const int kPointLvMax = 119;

/// 门派加点权重（对应原型 `WEIGHTS`：各维度占比 0~1）。
const Map<String, Map<String, double>> kJobWeights = {
  'shaolin': {'li': .45, 'ti': .35, 'ding': .1, 'shen': .1},
  'mingjiao': {'li': .5, 'shen': .3, 'ti': .2},
  'gaibang': {'li': .4, 'shen': .3, 'ti': .3},
  'tianshan': {'li': .45, 'shen': .4, 'ti': .15},
  'xiaoyao': {'ling': .5, 'shen': .35, 'ti': .15},
  'emei': {'ling': .45, 'ti': .3, 'ding': .25},
  'wudang': {'ling': .5, 'ding': .3, 'shen': .2},
  'xingxiu': {'ling': .45, 'ding': .3, 'ti': .25},
  'murong': {'li': .3, 'ling': .3, 'ti': .2, 'ding': .2},
};

/// 总潜能：等级 10 起每级 5 点，最高按 119 计。
int totalPoints(int lv) {
  final clamped = lv.clamp(kPointLvMin, kPointLvMax);
  return (clamped - kPointLvMin) * 5;
}

/// 五维键列表。
List<String> get kAttrKeys => [for (final a in kJobAttrs) a.key];

/// 「一键推荐」：按门派权重比例分配，余数按权重降序逐点补齐（对齐原型）。
Map<String, int> recommendPoints(String sectKey, int total) {
  final w = kJobWeights[sectKey] ?? {};
  final sum = w.values.fold<double>(0, (a, b) => a + b);
  final pts = <String, int>{
    for (final k in kAttrKeys)
      k: (w[k] ?? 0) == 0 ? 0 : (total * (w[k]! / sum)).floor(),
  };
  var left = total - pts.values.fold(0, (a, b) => a + b);
  // 权重从高到低排序（含 0 权重的排后）
  final order = [for (final a in kJobAttrs) a.key]
    ..sort((a, b) => (w[b] ?? 0).compareTo(w[a] ?? 0));
  var i = 0;
  while (left > 0) {
    final k = order[i % order.length];
    if ((w[k] ?? 0) > 0) {
      pts[k] = pts[k]! + 1;
      left--;
    }
    i++;
  }
  return pts;
}

/// 面板预览项。
@immutable
class JobPreview {
  const JobPreview({
    required this.hp,
    required this.mp,
    required this.atkP,
    required this.atkW,
    required this.hit,
    required this.dodge,
  });

  final int hp; // 气血上限
  final int mp; // 气上限
  final int atkP; // 内功攻击
  final int atkW; // 外功攻击
  final int hit; // 命中
  final int dodge; // 闪避
}

/// 面板预览（对齐原型 `renderPts`：lv×基础 + 加点×系数）。
JobPreview computePreview(int lv, Map<String, int> pts) {
  int p(String k) => pts[k] ?? 0;
  return JobPreview(
    hp: lv * 28 + p('ti') * 52,
    mp: lv * 20 + p('ling') * 36,
    atkP: p('ling') * 9,
    atkW: p('li') * 9,
    hit: lv * 7 + p('shen') * 8,
    dodge: lv * 5 + p('shen') * 6,
  );
}

/// 千分位：12345 → 12,345（对应 JS `toLocaleString()`）。
String formatThousand(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  final out = buf.toString();
  return value < 0 ? '-$out' : out;
}
