/// 宝宝资质计算 —— 领域模型与公式（与 UI 原型「资质公式 v4」一致）。
///
/// 公式来源 17173 等游戏资料站：
/// - 裸资 = 当前资质 ÷ (1+当前悟性加成) ÷ (1+当前灵性加成)
/// - 目标资质 = 裸资 × (1+目标悟性加成) × (1+目标灵性加成)
/// - 超灵品种差异：灵性 10 级加成 34%（普通宝宝 31%），其余等级相同。
/// 成长率与资质相互独立，不影响本计算。
library;

import 'package:flutter/foundation.dart';

/// 悟性加成表（0~10 级）：4级+3% / 5级+8% / 8级+23.5% / 10级+39.3%。
const List<double> kWuTable = [
  0, .010, .015, .021, .030, .080, .110, .145, .235, .300, .393,
];

/// 灵性加成表（普通品种，0~10 级）：5级+11% / 8级+22% / 10级+31%。
const List<double> kLingTable = [
  0, .010, .020, .050, .070, .110, .140, .180, .220, .260, .310,
];

/// 灵性加成表（超灵品种）：仅 10 级不同（+34%），其余等级与普通一致。
const List<double> kLingSuperTable = [
  0, .010, .020, .050, .070, .110, .140, .180, .220, .260, .340,
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

  /// 是否超灵品种（灵性 10 加成 34%，普通 31%）。
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

  /// 超灵加成展示文案。
  final String clText;

  /// 满悟满灵估算（目标裸资 × 悟性10 × 灵性10 档）。
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

/// 核心计算（与原型 `doCalc` 一致）。
PetCalcResult computePetCalc(PetCalcInput input) {
  final lt = input.isSuperLing ? kLingSuperTable : kLingTable;
  final base = input.base.toDouble();

  // 反推裸资：max(0, base / (1+当前悟性) / (1+当前灵性))
  final naked = base <= 0
      ? 0.0
      : (base / (1 + kWuTable[input.currentWu]) /
              (1 + lt[input.currentLing]))
          .clamp(0.0, double.infinity);

  // 目标资质 = 裸资 × (1+目标悟性) × (1+目标灵性)
  final r = (naked * (1 + kWuTable[input.targetWu]) *
          (1 + lt[input.targetLing]))
      .round();

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

  // 满悟满灵估算
  final maxEst =
      (naked * (1 + kWuTable[kWuLingMax]) * (1 + lt[kWuLingMax])).round();

  return PetCalcResult(
    naked: naked.round(),
    result: r,
    pct: pct,
    grade: grade,
    gradeText: gradeText,
    blueGrade: blueGrade,
    currentWlText:
        '悟性${_pct(kWuTable[input.currentWu])} / 灵性${_pct(lt[input.currentLing])}',
    targetWlText:
        '悟性${_pct(kWuTable[input.targetWu])} / 灵性${_pct(lt[input.targetLing])}',
    clText: input.isSuperLing ? '超灵品种（灵10 +34%）' : '普通品种（灵10 +31%）',
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
