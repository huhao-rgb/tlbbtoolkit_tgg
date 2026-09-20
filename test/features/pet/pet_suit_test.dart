import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_suit.dart';

void main() {
  group('珍兽套装数据 —— 怀旧服（经典版宝宝套）', () {
    test('共 22 个系列：75 档 4 / 85 档 9 / 95 档 9', () {
      expect(kPetSuitSeries.length, 22);
      expect(petSuitsAt('75').length, 4);
      expect(petSuitsAt('85').length, 9);
      expect(petSuitsAt('95').length, 9);

      // 每档是独立的一批系列（系列不跨档复用）
      for (final lv in kSuitLvKeys) {
        for (final s in petSuitsAt(lv)) {
          expect(s.lv, lv, reason: s.name);
        }
      }
    });

    test('75 档系列名照经典版资料', () {
      expect(
        petSuitsAt('75').map((s) => s.name).toList(),
        ['黄雀戏水·怯', '苍狼啸月·勇', '苍狼啸月·狡', '乌豚望日·忠'],
      );
    });

    test('85 档系列名照经典版资料', () {
      expect(
        petSuitsAt('85').map((s) => s.name).toList(),
        [
          '猛虎越山·勇',
          '猛虎越山·狡',
          '猛虎越山·慎',
          '飞鹰翔空·狡',
          '飞鹰翔空·怯',
          '飞鹰翔空·慎',
          '巨熊哮路·忠',
          '巨熊哮路·慎',
          '奔马逐风·慎',
        ],
      );
    });

    test('95 档系列名照经典版资料', () {
      expect(
        petSuitsAt('95').map((s) => s.name).toList(),
        [
          '雄狮逆鳞·勇',
          '雄狮逆鳞·狡',
          '雄狮逆鳞·慎',
          '鲲鹏异羽·狡',
          '鲲鹏异羽·怯',
          '鲲鹏异羽·慎',
          '玄龟奇血·忠',
          '玄龟奇血·慎',
          '墨豹惊步·慎',
        ],
      );
    });

    test('类型四大类齐全，且配色 / 图标一一对应', () {
      final types = kPetSuitSeries.map((s) => s.type).toSet();
      expect(types, {'外功', '内功', '体力', '身法'});

      for (final s in kPetSuitSeries) {
        switch (s.type) {
          case '外功':
            expect(s.typeColor, PetSuitCatColor.gold, reason: s.name);
            expect(s.icon, 'sword', reason: s.name);
          case '内功':
            expect(s.typeColor, PetSuitCatColor.blue, reason: s.name);
            expect(s.icon, 'spark', reason: s.name);
          case '体力':
            expect(s.typeColor, PetSuitCatColor.green, reason: s.name);
            expect(s.icon, 'shield', reason: s.name);
          case '身法':
            expect(s.typeColor, PetSuitCatColor.cyan, reason: s.name);
            expect(s.icon, 'pct', reason: s.name);
        }
      }
    });

    test('每套都有性格与「穿齐 5 件」全套效果', () {
      for (final s in kPetSuitSeries) {
        expect(s.personality, isNotEmpty, reason: s.name);
        expect(s.fullEffect, isNotEmpty, reason: s.name);
        expect(s.fitText, '${s.type}型 · ${s.personality}性格', reason: s.name);
      }
      // 性格覆盖经典版六种适配
      final persons = kPetSuitSeries.map((s) => s.personality).toSet();
      expect(persons, {'勇猛', '精明', '谨慎', '胆小', '忠诚', '谨慎平衡'});
    });

    test('散件属性方向仅 75 档逐系列给出（4 套）', () {
      final withStats =
          kPetSuitSeries.where((s) => s.stats.isNotEmpty).toList();
      expect(withStats.length, 4);
      for (final s in withStats) {
        expect(s.lv, '75', reason: s.name);
        expect(s.stats.length, greaterThanOrEqualTo(2), reason: s.name);
      }

      final byName = {for (final s in kPetSuitSeries) s.name: s.stats};
      expect(byName['黄雀戏水·怯'], ['内功攻击', '灵气', '命中']);
      expect(byName['苍狼啸月·勇'], ['外功攻击', '力量', '命中']);
      expect(byName['苍狼啸月·狡'], ['外功攻击', '力量', '血上限']);
      expect(byName['乌豚望日·忠'], ['内外功防御', '血上限']);
    });

    test('项圈出战效果：能查到的都非空', () {
      final byName = {for (final s in kPetSuitSeries) s.name: s.collar};
      expect(byName['苍狼啸月·勇'], '提升体力');
      expect(byName['黄雀戏水·怯'], '提升灵气、体力');
      expect(byName['飞鹰翔空·怯'], '提升灵气、体力');
      expect(byName['玄龟奇血·慎'], '提升体力、身法');
      expect(byName['奔马逐风·慎'], '提升身法');
      // 官方资料未逐系列列出项圈效果的两套
      expect(byName['苍狼啸月·狡'], isNull);
      expect(byName['乌豚望日·忠'], '提升体力');
    });

    test('五件套部位：兽盔 / 兽爪 / 兽甲 / 兽环 / 兽饰', () {
      expect(
        kPetSuitSlots.map((s) => s.slot).toList(),
        ['头', '爪', '躯干', '颈', '护符'],
      );
      expect(
        kPetSuitSlots.map((s) => s.name).toList(),
        ['兽盔', '兽爪', '兽甲', '兽环', '兽饰'],
      );
      // 每个部位都带图标资产名（assets/pet_suit/<icon>.png）
      expect(
        kPetSuitSlots.map((s) => s.icon).toList(),
        ['part_helm', 'part_claw', 'part_armor', 'part_ring', 'part_charm'],
      );
      // 只有兽环（颈）带出战后生效的系列效果
      expect(kPetSuitSlots[3].note, contains('出战'));
      for (final slot in kPetSuitSlots) {
        expect(slot.note, isNotEmpty, reason: slot.name);
      }
    });
  });

  group('圣兽鳞消耗表 —— 怀旧服口径（每件）', () {
    test('兑换单价：75 → 1 / 85 → 30 / 95 → 100', () {
      expect(kSuitMatCost['75']!.exchange, 1);
      expect(kSuitMatCost['85']!.exchange, 30);
      expect(kSuitMatCost['95']!.exchange, 100);
      expect(kSuitMatName, '圣兽鳞');
    });

    test('升星消耗：75 [3,5,7,11] / 85 [16,18,20,24] / 95 [36,43,50,56]', () {
      expect(kSuitMatCost['75']!.starUp, [3, 5, 7, 11]);
      expect(kSuitMatCost['85']!.starUp, [16, 18, 20, 24]);
      expect(kSuitMatCost['95']!.starUp, [36, 43, 50, 56]);
    });

    test('拆解返还（每件 1★~5★）', () {
      expect(kSuitMatCost['75']!.salvage, [1, 3, 7, 12, 20]);
      expect(kSuitMatCost['85']!.salvage, [20, 30, 35, 42, 57]);
      expect(kSuitMatCost['95']!.salvage, [50, 68, 90, 115, 143]);
    });

    test('每件升满 5★：75 → 27 / 85 → 108 / 95 → 285；整套 ×5', () {
      expect(kSuitMatCost['75']!.perPieceTo(5), 27);
      expect(kSuitMatCost['85']!.perPieceTo(5), 108);
      expect(kSuitMatCost['95']!.perPieceTo(5), 285);
      expect(kSuitMatCost['75']!.perPieceTo(1), 1);
      expect(kSuitMatCost['95']!.perPieceTo(3), 100 + 36 + 43);
    });
  });

  group('suitMatsCalc —— 按「目标星级」算兑换 + 升星', () {
    test('目标 5★（85 档，含兑换）：150 + 390 = 540', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', targetStar: 5, withExchange: true),
      );
      expect(r.lv, '85');
      expect(r.targetStar, 5);
      expect(r.exchangePerPiece, 30);
      expect(r.exchangeSet, 150); // 30 × 5 件
      expect(r.starRows.map((x) => x.star).toList(), [2, 3, 4, 5]);
      expect(r.starRows.map((x) => x.perPiece).toList(), [16, 18, 20, 24]);
      expect(r.starRows.map((x) => x.setTotal).toList(), [80, 90, 100, 120]);
      expect(r.upgradeSet, 390);
      expect(r.total, 540);
      expect(r.fullSetTotal, 540);
    });

    test('目标 1★：只需兑换整套，没有升星行', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', targetStar: 1, withExchange: true),
      );
      expect(r.starRows, isEmpty);
      expect(r.upgradeSet, 0);
      expect(r.total, 150);
    });

    test('目标星级越高，合计越大（85 档 1★ → 5★）', () {
      int totalAt(int star) => suitMatsCalc(
        SuitMatCalcInput(lv: '85', targetStar: star, withExchange: true),
      ).total;
      expect(totalAt(1), 150);
      expect(totalAt(2), 230);
      expect(totalAt(3), 320);
      expect(totalAt(4), 420);
      expect(totalAt(5), 540);
    });

    test('目标 5★（75 档）：兑换 5 + 升星 130 = 135', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '75', targetStar: 5, withExchange: true),
      );
      expect(r.exchangeSet, 5);
      expect(r.upgradeSet, 130);
      expect(r.total, 135);
      expect(r.fullSetTotal, 135);
    });

    test('目标 5★（95 档）：兑换 500 + 升星 925 = 1425', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '95', targetStar: 5, withExchange: true),
      );
      expect(r.exchangeSet, 500);
      expect(r.upgradeSet, 925);
      expect(r.total, 1425);
      expect(r.fullSetTotal, 1425);
    });

    test('目标 3★（75 档，不含兑换）：只算 1★→2★、2★→3★ 两行', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '75', targetStar: 3, withExchange: false),
      );
      expect(r.exchangeSet, 0);
      expect(r.starRows.map((x) => x.star).toList(), [2, 3]);
      expect(r.starRows.map((x) => x.perPiece).toList(), [3, 5]);
      expect(r.starRows.map((x) => x.setTotal).toList(), [15, 25]);
      expect(r.total, 40);
    });

    test('关闭含兑换材料：exchangeSet 为 0', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '95', targetStar: 5, withExchange: false),
      );
      expect(r.exchangeSet, 0);
      expect(r.total, r.upgradeSet);
      expect(r.salvagePerPiece, kSuitMatCost['95']!.salvage);
    });

    test('目标星级越界按 1★~5★ 边界处理', () {
      final lo = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', targetStar: 0, withExchange: false),
      );
      expect(lo.targetStar, 1);
      expect(lo.starRows, isEmpty);

      final hi = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', targetStar: 9, withExchange: false),
      );
      expect(hi.targetStar, 5);
      expect(hi.starRows.length, 4);
    });
  });
}
