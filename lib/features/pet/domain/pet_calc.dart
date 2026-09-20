/// 宝宝资质计算 —— 领域模型与公式（官方「珍兽养成」口径）。
///
/// 公式来源：畅游官方「珍兽养成」页 + 17173 资料站数据表。
/// - 裸资 = 当前资质 ÷ (1+当前悟性加成) ÷ (1+当前灵性加成)
/// - 目标资质 = 裸资 × (1+目标悟性加成) × (1+目标灵性加成)
///   （灵性加成在悟性之后生效，先除哪个后除哪个不影响结果）
/// - 悟性加成：固定表，10 级 +39.3%。
/// - 灵性加成：**按「计算悟性后的资质」分三档**（＜1800 / 1800~2199 / ≥2200），
///   且超灵 / 非超灵品种各有一套表（10 级最高 34% / 31%）。
///   ⚠️ 原型 JS 把灵性表硬编码成「≥2200」这一档，低资质宝宝会算错，本实现已修正。
/// 成长率与资质相互独立，不影响本计算。
library;

import 'package:flutter/foundation.dart';

/// 悟性加成表（0~10 级）：4级+3% / 5级+8% / 8级+23.5% / 10级+39.3%。
const List<double> kWuTable = [
  0,
  .010,
  .015,
  .021,
  .030,
  .080,
  .110,
  .145,
  .235,
  .300,
  .393,
];

/// 灵性加成档位边界（按「计算悟性后的资质」判定）。
const int kLingTierMid = 1800;
const int kLingTierHigh = 2200;

/// 灵性加成表（普通品种）—— 三个档位依次为 ＜1800 / 1800~2199 / ≥2200。
///
/// 官方说明：资质越高，同等灵性等级带来的加成越多（10 级分别为 +10% / +23% / +31%）。
const List<List<double>> kLingTable = [
  // ＜1800：1%~10%
  [0, .010, .020, .030, .040, .050, .060, .070, .080, .090, .100],
  // 1800~2199：10 级 +23%
  [0, .010, .020, .040, .060, .090, .100, .130, .160, .190, .230],
  // ≥2200：10 级 +31%
  [0, .010, .020, .050, .070, .110, .140, .180, .220, .260, .310],
];

/// 灵性加成表（超灵品种）—— 同档位下各级加成均高于普通品种。
const List<List<double>> kLingSuperTable = [
  // ＜1800：10 级 +12%
  [0, .010, .020, .030, .040, .060, .070, .080, .090, .100, .120],
  // 1800~2199：10 级 +25%
  [0, .010, .020, .040, .070, .100, .110, .140, .170, .200, .250],
  // ≥2200：10 级 +34%
  [0, .010, .020, .050, .070, .120, .150, .200, .240, .280, .340],
];

/// 悟灵等级边界。
const int kWuLingMin = 0;
const int kWuLingMax = 10;

/// 评级阈值：目标资质 ≥ [kGradeS] 为 S / 极品，≥ A 为 A / 优秀，
/// ≥ B 为 B / 良好，其余为 C / 一般。
const int kGradeS = 5000;
const int kGradeA = 4200;
const int kGradeB = 3400;

/// 计算输入。
@immutable
class PetCalcInput {
  const PetCalcInput({
    required this.base,
    required this.currentWu,
    required this.currentLing,
    required this.targetWu,
    required this.targetLing,
    required this.isSuperLing,
  });

  /// 当前资质（攻击 / 属性资质，按当前悟灵状态填写）。
  final int base;

  /// 当前悟性（0~10）。
  final int currentWu;

  /// 当前灵性（0~10）。
  final int currentLing;

  /// 目标悟性（0~10）。
  final int targetWu;

  /// 目标灵性（0~10）。
  final int targetLing;

  /// 是否超灵品种（同档位下灵性加成高于普通品种：10 级最高 34% / 普通 31%）。
  final bool isSuperLing;
}

/// 计算结果（字段即页面展示所需）。
@immutable
class PetCalcResult {
  const PetCalcResult({
    required this.naked,
    required this.result,
    required this.pct,
    required this.grade,
    required this.gradeText,
    required this.blueGrade,
    required this.currentWlText,
    required this.targetWlText,
    required this.clText,
    required this.maxEst,
    required this.tip,
  });

  /// 推算裸资质（整数，千分位展示）。
  final int naked;

  /// 预估成品资质（目标悟灵下的资质）。
  final int result;

  /// 相对当前资质的变化百分比（整数）。
  final int pct;

  /// 评级字母 S / A / B / C。
  final String grade;

  /// 评级文案 极品 / 优秀 / 良好 / 一般。
  final String gradeText;

  /// 是否为「蓝字」评级（B/C 用 tag-blue，S/A 用金色）。
  final bool blueGrade;

  /// 当前悟性/灵性展示文案，如「悟性+0% / 灵性+0%」。
  final String currentWlText;

  /// 目标悟性/灵性展示文案。
  final String targetWlText;

  /// 品种与目标灵性档位文案，如「超灵品种 · ≥2200 档」。
  final String clText;

  /// 满悟满灵估算（裸资 × 悟性10 × 灵性10，灵性档位按悟性 10 后的资质判定）。
  final int maxEst;

  /// 建议培养方向。
  final String tip;

  /// 预估成品资质（千分位，如 5,432）。
  String get resultLocale => _localeInt(result);

  /// 推算裸资质（千分位）。
  String get nakedLocale => _localeInt(naked);

  /// 满悟满灵估算（千分位）。
  String get maxEstLocale => _localeInt(maxEst);

  /// 相对当前资质变化，如「+37%」。
  String get pctText => '${pct >= 0 ? '+' : ''}$pct%';
}

/// 灵性加成档位下标：0 = ＜1800 / 1 = 1800~2199 / 2 = ≥2200。
///
/// 官方口径：「灵性提升的几率和效果与珍兽计算悟性后的资质有关」
/// —— 档位按 [wuBoosted]（裸资 × (1+悟性加成)）判定，而非裸资本身。
int lingTierOf(num wuBoosted) {
  if (wuBoosted < kLingTierMid) return 0;
  if (wuBoosted < kLingTierHigh) return 1;
  return 2;
}

/// 灵性档位文案，如 `≥2200 档`。
String lingTierLabel(int tier) => switch (tier) {
  0 => '＜1800 档',
  1 => '1800~2199 档',
  _ => '≥2200 档',
};

/// 反推裸资的中间结果。
typedef _NakedSolve = ({double naked, int tier, double lingBoost});

/// 由「当前资质 + 当前悟性 + 当前灵性」反推裸资，并定位当前灵性档位。
///
/// 循环依赖：灵性档位取决于「悟性后资质」= 裸资 × (1+悟性)，而裸资又要用
/// 灵性加成反推。故用不动点迭代：先按「灵性加成 = 0」定位档位，再逐轮修正
/// （档位单调，通常 1 轮即收敛）。
_NakedSolve _solveNaked({
  required int base,
  required int wu,
  required int ling,
  required List<List<double>> lingTable,
}) {
  final wuBoost = kWuTable[wu];
  if (base <= 0) return (naked: 0, tier: 0, lingBoost: lingTable[0][ling]);

  var tier = lingTierOf(base / (1 + wuBoost));
  var lingBoost = lingTable[tier][ling];
  for (var i = 0; i < 3; i++) {
    // 悟性后资质 = base ÷ (1+灵性加成)（与 ×(1+悟性) 等价）
    final next = lingTierOf(base / (1 + lingBoost));
    if (next == tier) break;
    tier = next;
    lingBoost = lingTable[tier][ling];
  }
  return (
    naked: base / (1 + wuBoost) / (1 + lingBoost),
    tier: tier,
    lingBoost: lingBoost,
  );
}

/// 核心计算（官方「珍兽养成」口径，已修正原型的灵性硬编码档位）。
PetCalcResult computePetCalc(PetCalcInput input) {
  final lingTable = input.isSuperLing ? kLingSuperTable : kLingTable;

  // 反推裸资（同时定位「当前」灵性档位）
  final cur = _solveNaked(
    base: input.base,
    wu: input.currentWu,
    ling: input.currentLing,
    lingTable: lingTable,
  );
  final naked = cur.naked;

  // 目标资质：悟性后资质 → 定档 → 叠灵性加成
  final targetWuBoost = kWuTable[input.targetWu];
  final targetWuBoosted = naked * (1 + targetWuBoost);
  final targetTier = lingTierOf(targetWuBoosted);
  final targetLingBoost = lingTable[targetTier][input.targetLing];
  final r = (targetWuBoosted * (1 + targetLingBoost)).round();

  // 相对当前资质变化
  final pct = input.base != 0 ? ((r / input.base - 1) * 100).round() : 0;

  // 评级
  String grade, gradeText;
  bool blueGrade;
  if (r >= kGradeS) {
    grade = 'S';
    gradeText = '极品';
    blueGrade = false;
  } else if (r >= kGradeA) {
    grade = 'A';
    gradeText = '优秀';
    blueGrade = false;
  } else if (r >= kGradeB) {
    grade = 'B';
    gradeText = '良好';
    blueGrade = true;
  } else {
    grade = 'C';
    gradeText = '一般';
    blueGrade = true;
  }

  // 建议培养方向
  final tip = r < input.base
      ? '目标悟灵低于当前，成品资质将回落'
      : grade == 'S'
      ? '可直接培养至成品'
      : grade == 'A'
      ? '裸资优秀，可继续培养'
      : '建议更换胚子再培养';

  // 满悟满灵估算（悟性 10 → 再按所处档位取灵性 10）
  final maxWuBoosted = naked * (1 + kWuTable[kWuLingMax]);
  final maxEst =
      (maxWuBoosted * (1 + lingTable[lingTierOf(maxWuBoosted)][kWuLingMax]))
          .round();

  return PetCalcResult(
    naked: naked.round(),
    result: r,
    pct: pct,
    grade: grade,
    gradeText: gradeText,
    blueGrade: blueGrade,
    currentWlText:
        '悟性${_pct(kWuTable[input.currentWu])} / 灵性${_pct(cur.lingBoost)}',
    targetWlText: '悟性${_pct(targetWuBoost)} / 灵性${_pct(targetLingBoost)}',
    clText:
        '${input.isSuperLing ? '超灵' : '普通'}品种 · ${lingTierLabel(targetTier)}',
    maxEst: maxEst,
    tip: tip,
  );
}

/// 百分比展示：`+1.5%`（x=0.015 → +1.5%；x=0.01 → +1%）。
/// 对应原型 `pc = x => '+' + ((x*100).toFixed(1).replace(/\.0$/,'')) + '%'`。
String _pct(double x) {
  final v = (x * 100).toStringAsFixed(1);
  final trimmed = v.endsWith('.0') ? v.substring(0, v.length - 2) : v;
  return '+$trimmed%';
}

/// 千分位：12345 → 12,345（对应 JS `toLocaleString()`）。
String _localeInt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
