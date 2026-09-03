import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_calc.dart';

void main() {
  group('computePetCalc —— 与 UI 原型「资质公式 v4」一致', () {
    test('默认值：2200 / 当前0-0 / 目标悟8灵5 / 普通 → C 一般', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 2200,
          currentWu: 0,
          currentLing: 0,
          targetWu: 8,
          targetLing: 5,
          isSuperLing: false,
        ),
      );
      // 裸资 = 2200
      expect(r.naked, 2200);
      // 目标 = round(2200*1.235*1.11) = round(3015.87) = 3016
      expect(r.result, 3016);
      expect(r.pct, 37);
      expect(r.pctText, '+37%');
      // <3400 → C / 一般（蓝字）
      expect(r.grade, 'C');
      expect(r.gradeText, '一般');
      expect(r.blueGrade, isTrue);
      expect(r.currentWlText, '悟性+0% / 灵性+0%');
      expect(r.targetWlText, '悟性+23.5% / 灵性+11%');
      expect(r.clText, '普通品种（灵10 +31%）');
      // 满悟满灵 = round(2200*1.393*1.31) = round(4014.626) = 4015
      expect(r.maxEst, 4015);
      expect(r.tip, '建议更换胚子再培养');
      expect(r.resultLocale, '3,016');
      expect(r.nakedLocale, '2,200');
      expect(r.maxEstLocale, '4,015');
    });

    test('满悟满灵：裸资往返一致，目标资质回升至原值', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 3000,
          currentWu: 10,
          currentLing: 10,
          targetWu: 10,
          targetLing: 10,
          isSuperLing: false,
        ),
      );
      // 裸资 = 3000/1.393/1.31 = 1643.99 → 1644
      expect(r.naked, 1644);
      // 满悟满灵恢复回 3000
      expect(r.result, 3000);
      expect(r.maxEst, 3000);
      // 需要满悟满灵才到 3000，裸资较低 → C
      expect(r.grade, 'C');
      expect(r.blueGrade, isTrue);
    });

    test('超灵品种：灵性10 加成 34%（对比普通 31%）', () {
      final normal = computePetCalc(
        const PetCalcInput(
          base: 2500,
          currentWu: 0,
          currentLing: 0,
          targetWu: 10,
          targetLing: 10,
          isSuperLing: false,
        ),
      );
      final superLing = computePetCalc(
        const PetCalcInput(
          base: 2500,
          currentWu: 0,
          currentLing: 0,
          targetWu: 10,
          targetLing: 10,
          isSuperLing: true,
        ),
      );
      // 普通：2500*1.393*1.31
      expect(normal.result, (2500 * 1.393 * 1.31).round());
      // 超灵：2500*1.393*1.34
      expect(superLing.result, (2500 * 1.393 * 1.34).round());
      expect(superLing.result, greaterThan(normal.result));
      expect(superLing.clText, '超灵品种（灵10 +34%）');
      expect(normal.clText, '普通品种（灵10 +31%）');
    });

    test('评级边界：S≥5000 / A≥4200 / B≥3400 / C<3400', () {
      PetCalcResult calc(int base, int wu, int ling) => computePetCalc(
            PetCalcInput(
              base: base,
              currentWu: 0,
              currentLing: 0,
              targetWu: wu,
              targetLing: ling,
              isSuperLing: false,
            ),
          );
      // 裸资 2750 → 2750*1.393*1.31 = 5018.29 → S / 极品
      final s = calc(2750, 10, 10);
      expect(s.result, 5018);
      expect(s.grade, 'S');
      expect(s.gradeText, '极品');
      expect(s.blueGrade, isFalse);
      expect(s.tip, '可直接培养至成品');
      // 裸资 2600 → 2600*1.393*1.31 = 4744.56 → A / 优秀
      final a = calc(2600, 10, 10);
      expect(a.result, 4745);
      expect(a.grade, 'A');
      expect(a.gradeText, '优秀');
      expect(a.blueGrade, isFalse);
      expect(a.tip, '裸资优秀，可继续培养');
      // 裸资 2480 → 2480*1.235*1.11 = 3399.97 → 恰好 3400 → B / 良好（蓝字）
      final b = calc(2480, 8, 5);
      expect(b.result, 3400);
      expect(b.grade, 'B');
      expect(b.gradeText, '良好');
      expect(b.blueGrade, isTrue);
      // 裸资 1900 → 1900*1.235*1.11 = 2604.62 → C / 一般
      final c = calc(1900, 8, 5);
      expect(c.result, 2605);
      expect(c.grade, 'C');
      expect(c.gradeText, '一般');
      expect(c.blueGrade, isTrue);
    });

    test('目标低于当前：成品资质回落提示', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 4000,
          currentWu: 8,
          currentLing: 5,
          targetWu: 0,
          targetLing: 0,
          isSuperLing: false,
        ),
      );
      // 裸资 = 4000/1.235/1.11 = 2917.90 → 2918
      expect(r.naked, 2918);
      // 目标 = 2918（回落）
      expect(r.result, 2918);
      expect(r.result, lessThan(4000));
      expect(r.tip, '目标悟灵低于当前，成品资质将回落');
      // pct 为负：round((2918/4000-1)*100)=round(-27.05)=-27 → '-27%'
      expect(r.pct, -27);
      expect(r.pctText, '-27%');
    });

    test('base 为 0 或空：不崩溃，pct=0', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 0,
          currentWu: 0,
          currentLing: 0,
          targetWu: 8,
          targetLing: 5,
          isSuperLing: false,
        ),
      );
      expect(r.naked, 0);
      expect(r.result, 0);
      expect(r.pct, 0);
      expect(r.pctText, '+0%');
      expect(r.grade, 'C');
      expect(r.gradeText, '一般');
      expect(r.tip, '建议更换胚子再培养');
    });

    test('展示文案：pc 格式（+1% / +1.5% / +23.5% / +39.3%）', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 2000,
          currentWu: 1, // 0.01 → +1%
          currentLing: 2, // 0.02 → +2%
          targetWu: 3, // 0.021 → +2.1%
          targetLing: 4, // 0.07 → +7%
          isSuperLing: false,
        ),
      );
      expect(r.currentWlText, '悟性+1% / 灵性+2%');
      expect(r.targetWlText, '悟性+2.1% / 灵性+7%');
      // 超灵品种：悟性8 = 23.5% / 灵性10 = 34%
      final r2 = computePetCalc(
        const PetCalcInput(
          base: 2000,
          currentWu: 8,
          currentLing: 10,
          targetWu: 10,
          targetLing: 10,
          isSuperLing: true,
        ),
      );
      expect(r2.currentWlText, '悟性+23.5% / 灵性+34%');
      expect(r2.targetWlText, '悟性+39.3% / 灵性+34%');
    });

    test('千分位格式化', () {
      final r = computePetCalc(
        const PetCalcInput(
          base: 9999,
          currentWu: 0,
          currentLing: 0,
          targetWu: 10,
          targetLing: 10,
          isSuperLing: false,
        ),
      );
      // 9999*1.393*1.31 = 18246.48 → 18246 → 18,246
      expect(r.result, 18246);
      expect(r.resultLocale, '18,246');
      expect(r.maxEstLocale, '18,246');
    });
  });
}
