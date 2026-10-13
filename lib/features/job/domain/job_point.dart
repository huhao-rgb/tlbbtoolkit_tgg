/// 职业加点计算器 —— 领域模型与公式（与 UI 原型 `class-point` 一致）。
///
/// - 每 1 级获得 5 点潜能（10 级起），等级 10~119；
///   总潜能 = (min(lv,119)-10) × 5。
/// - 五维：力量 li / 灵气 ling / 体力 ti / 定力 ding / 身法 shen。
/// - 一键推荐按门派权重（`kJobWeights`）按比例分配，余数按权重降序逐点补齐。
/// - 面板预览按门派成长系数（`kJobGrowth`，原型 `PT_GROWTH`）换算，
///   公式与原型 `renderPts` 一致；近似系数以 `≈` 标注。
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
  'shaolin': {'li': 0.45, 'ti': 0.35, 'ding': 0.1, 'shen': 0.1},
  'mingjiao': {'li': 0.5, 'shen': 0.3, 'ti': 0.2},
  'gaibang': {'li': 0.4, 'shen': 0.3, 'ti': 0.3},
  'tianshan': {'li': 0.45, 'shen': 0.4, 'ti': 0.15},
  'xiaoyao': {'ling': 0.5, 'shen': 0.35, 'ti': 0.15},
  'emei': {'ling': 0.45, 'ti': 0.3, 'ding': 0.25},
  'wudang': {'ling': 0.5, 'ding': 0.3, 'shen': 0.2},
  'xingxiu': {'ling': 0.45, 'ding': 0.3, 'ti': 0.25},
  'murong': {'li': 0.3, 'ling': 0.3, 'ti': 0.2, 'ding': 0.2},
  'mantuo': {'ling': 0.45, 'shen': 0.25, 'ti': 0.2, 'ding': 0.1},
  'tianlong': {'ling': 0.35, 'shen': 0.3, 'li': 0.15, 'ti': 0.2},
  'erengu': {'ling': 0.45, 'shen': 0.3, 'ti': 0.15, 'ding': 0.1},
};

/// 成长系数条目（对应原型 `PT_FLD`，顺序即「门派成长系数」列表顺序）。
@immutable
class JobGrowthField {
  const JobGrowthField(this.key, this.label);

  /// 键（hp / wai / nei / mp / hit / dodge / crit / critd）。
  final String key;

  /// 换算说明（如 `体力 → 血上限`）。
  final String label;
}

/// 每点潜能的属性换算值（对应原型 `PT_GROWTH[sect][field]`）。
@immutable
class JobGrowthValue {
  const JobGrowthValue(this.value, {this.approx = false});

  /// 每 1 点潜能带来的属性增量。
  final double value;

  /// 近似值（原型 `a:1`）：界面以 `≈` 标注并弱化配色。
  final bool approx;

  /// 展示文本：近似值前缀 `≈`，整数不带小数尾巴。
  String get display => '${approx ? '≈' : ''}${trimNumber(value)}';
}

/// 八个成长系数条目（顺序同原型 `PT_FLD`）。
const List<JobGrowthField> kJobGrowthFields = [
  JobGrowthField('hp', '体力 → 血上限'),
  JobGrowthField('wai', '力量 → 外功攻击'),
  JobGrowthField('nei', '灵气 → 内功攻击'),
  JobGrowthField('mp', '定力 → 气上限'),
  JobGrowthField('hit', '身法 → 命中'),
  JobGrowthField('dodge', '身法 → 闪避'),
  JobGrowthField('crit', '身法 → 会心攻击'),
  JobGrowthField('critd', '身法 → 会心防御'),
];

/// 门派成长系数（对应原型 `PT_GROWTH`）。
///
/// 玩家社区实测整理，`approx` 标注的为近似值（官方未公布完整成长表）。
/// 键与 [JobSect.key] 对齐（原型中曼陀山庄为 `manduo`，端上统一为 `mantuo`）。
const Map<String, Map<String, JobGrowthValue>> kJobGrowth = {
  'shaolin': {
    'hp': JobGrowthValue(71.5),
    'wai': JobGrowthValue(7.6, approx: true),
    'nei': JobGrowthValue(3.8, approx: true),
    'mp': JobGrowthValue(25, approx: true),
    'hit': JobGrowthValue(7, approx: true),
    'dodge': JobGrowthValue(4, approx: true),
    'crit': JobGrowthValue(0.044, approx: true),
    'critd': JobGrowthValue(0.044, approx: true),
  },
  'mingjiao': {
    'hp': JobGrowthValue(55.2),
    'wai': JobGrowthValue(8.3),
    'nei': JobGrowthValue(3.8, approx: true),
    'mp': JobGrowthValue(25, approx: true),
    'hit': JobGrowthValue(7.5, approx: true),
    'dodge': JobGrowthValue(4, approx: true),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'gaibang': {
    'hp': JobGrowthValue(60),
    'wai': JobGrowthValue(7.7, approx: true),
    'nei': JobGrowthValue(3.8),
    'mp': JobGrowthValue(25, approx: true),
    'hit': JobGrowthValue(7.5, approx: true),
    'dodge': JobGrowthValue(4, approx: true),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'tianshan': {
    'hp': JobGrowthValue(55),
    'wai': JobGrowthValue(7.6184),
    'nei': JobGrowthValue(8.9),
    'mp': JobGrowthValue(25),
    'hit': JobGrowthValue(8),
    'dodge': JobGrowthValue(3.3036),
    'crit': JobGrowthValue(0.0714),
    'critd': JobGrowthValue(0.0714),
  },
  'tianlong': {
    'hp': JobGrowthValue(58),
    'wai': JobGrowthValue(6.5),
    'nei': JobGrowthValue(6.36),
    'mp': JobGrowthValue(27),
    'hit': JobGrowthValue(9),
    'dodge': JobGrowthValue(3),
    'crit': JobGrowthValue(0.0303),
    'critd': JobGrowthValue(0.0303),
  },
  'emei': {
    'hp': JobGrowthValue(50),
    'wai': JobGrowthValue(4.4, approx: true),
    'nei': JobGrowthValue(7.6, approx: true),
    'mp': JobGrowthValue(30, approx: true),
    'hit': JobGrowthValue(7.5, approx: true),
    'dodge': JobGrowthValue(4, approx: true),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'wudang': {
    'hp': JobGrowthValue(44),
    'wai': JobGrowthValue(4.4, approx: true),
    'nei': JobGrowthValue(8.8),
    'mp': JobGrowthValue(32),
    'hit': JobGrowthValue(7.5, approx: true),
    'dodge': JobGrowthValue(4, approx: true),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'xiaoyao': {
    'hp': JobGrowthValue(50),
    'wai': JobGrowthValue(4.4),
    'nei': JobGrowthValue(7.6715),
    'mp': JobGrowthValue(36),
    'hit': JobGrowthValue(7.5),
    'dodge': JobGrowthValue(4),
    'crit': JobGrowthValue(0.05),
    'critd': JobGrowthValue(0.05),
  },
  'xingxiu': {
    'hp': JobGrowthValue(52),
    'wai': JobGrowthValue(4.4),
    'nei': JobGrowthValue(7.599),
    'mp': JobGrowthValue(36),
    'hit': JobGrowthValue(6),
    'dodge': JobGrowthValue(3),
    'crit': JobGrowthValue(0.05),
    'critd': JobGrowthValue(0.0556),
  },
  'murong': {
    'hp': JobGrowthValue(60),
    'wai': JobGrowthValue(4.4, approx: true),
    'nei': JobGrowthValue(8.8),
    'mp': JobGrowthValue(25),
    'hit': JobGrowthValue(7),
    'dodge': JobGrowthValue(4),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'mantuo': {
    'hp': JobGrowthValue(58),
    'wai': JobGrowthValue(4.4, approx: true),
    'nei': JobGrowthValue(7.1),
    'mp': JobGrowthValue(35),
    'hit': JobGrowthValue(9),
    'dodge': JobGrowthValue(3),
    'crit': JobGrowthValue(0.05, approx: true),
    'critd': JobGrowthValue(0.05, approx: true),
  },
  'erengu': {
    'hp': JobGrowthValue(50),
    'wai': JobGrowthValue(7.6, approx: true),
    'nei': JobGrowthValue(3.8, approx: true),
    'mp': JobGrowthValue(25, approx: true),
    'hit': JobGrowthValue(8.5, approx: true),
    'dodge': JobGrowthValue(4.5, approx: true),
    'crit': JobGrowthValue(0.06, approx: true),
    'critd': JobGrowthValue(0.06, approx: true),
  },
};

/// 取门派成长系数；未知门派回退逍遥（对齐原型 `PT_GROWTH[ptSect]||…xiaoyao`）。
Map<String, JobGrowthValue> jobGrowthOf(String sectKey) =>
    kJobGrowth[sectKey] ?? kJobGrowth['xiaoyao']!;

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
  // 门派权重缺失（如新门派资料整理中）：按五维均分兜底，
  // 避免除零或下方逐点分配的死循环。
  if (sum <= 0) {
    final base = total ~/ kAttrKeys.length;
    final rem = total % kAttrKeys.length;
    return {
      for (var i = 0; i < kAttrKeys.length; i++)
        kAttrKeys[i]: base + (i < rem ? 1 : 0),
    };
  }
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

/// 面板预览项（数值随门派成长系数变化，可能带小数）。
@immutable
class JobPreview {
  const JobPreview({
    required this.hp,
    required this.mp,
    required this.atkP,
    required this.atkW,
    required this.hit,
    required this.dodge,
    required this.crit,
  });

  final double hp; // 气血上限
  final double mp; // 气上限
  final double atkP; // 内功攻击
  final double atkW; // 外功攻击
  final double hit; // 命中
  final double dodge; // 闪避
  final double crit; // 会心攻击（会心 + 会心防御系数 × 身法）
}

/// 面板预览（对齐原型 `renderPts`：等级基线 + 加点 × 门派成长系数）。
JobPreview computePreview(String sectKey, int lv, Map<String, int> pts) {
  final g = jobGrowthOf(sectKey);
  double c(String k) => g[k]?.value ?? 0;
  int p(String k) => pts[k] ?? 0;
  return JobPreview(
    hp: lv * 28 + p('ti') * c('hp'),
    mp: lv * 20 + p('ding') * c('mp'),
    atkP: p('ling') * c('nei'),
    atkW: p('li') * c('wai'),
    hit: lv * 7 + p('shen') * c('hit'),
    dodge: lv * 5 + p('shen') * c('dodge'),
    crit: p('shen') * (c('crit') + c('critd')),
  );
}

/// 去掉小数末尾多余的 0 与小数点（`25.0 → 25`、`3.40 → 3.4`）。
String trimNumber(num value) => _trimTrailingZeros(value.toString());

String _trimTrailingZeros(String s) {
  if (!s.contains('.')) return s;
  final out = s.replaceFirst(RegExp(r'0+$'), '');
  return out.endsWith('.') ? out.substring(0, out.length - 1) : out;
}

/// 整数千分位：12345 → 12,345（对应 JS `toLocaleString()`）。
String formatThousand(int value) {
  final out = _groupDigits(value.abs().toString());
  return value < 0 ? '-$out' : out;
}

/// 千分位 + 最多 3 位小数（对应 JS `Number.toLocaleString()` 默认行为）。
String formatGrouped(num value) {
  final s = _trimTrailingZeros(value.abs().toStringAsFixed(3));
  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  final frac = dot < 0 ? '' : s.substring(dot);
  final out = '${_groupDigits(intPart)}$frac';
  return value < 0 ? '-$out' : out;
}

/// 保留 1 位小数、去掉多余的 `.0`（对应原型 `toFixed(1).replace(/\.0$/,'')`）。
String formatFixed1(num value) => _trimTrailingZeros(value.toStringAsFixed(1));

/// 会心：四舍五入到 2 位小数后去掉多余的 0（对应原型 `Math.round(v*100)/100`）。
String formatCrit(num value) =>
    _trimTrailingZeros(((value * 100).round() / 100).toStringAsFixed(2));

/// 数字串千分位分组。
String _groupDigits(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
