import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_suit.dart';

void main() {
  group('珍兽套装数据 —— 怀旧服（经典版宝宝套）', () {
    test('共 27 个系列：75 / 85 / 95 档各 9 套', () {
      expect(kPetSuitSeries.length, 27);
      expect(petSuitsAt('75').length, 9);
      expect(petSuitsAt('85').length, 9);
      expect(petSuitsAt('95').length, 9);

      // 每档是独立的一批系列（系列不跨档复用）
      for (final lv in kSuitLvKeys) {
        for (final s in petSuitsAt(lv)) {
          expect(s.lv, lv, reason: s.name);
        }
      }
      // 系列名唯一
      expect(kPetSuitSeries.map((s) => s.name).toSet().length, 27);
    });

    test('75 档系列名照《珍兽套装明细》表', () {
      expect(petSuitsAt('75').map((s) => s.name).toList(), [
        '黄雀戏水·怯',
        '黄雀戏水·狡',
        '黄雀戏水·慎',
        '苍狼啸月·勇',
        '苍狼啸月·狡',
        '苍狼啸月·慎',
        '乌鹏望日·忠',
        '乌鹏望日·慎',
        '白兔隐林·慎',
      ]);
    });

    test('85 档系列名照《珍兽套装明细》表', () {
      expect(petSuitsAt('85').map((s) => s.name).toList(), [
        '飞鹰翔空·怯',
        '飞鹰翔空·狡',
        '飞鹰翔空·慎',
        '猛虎越山·勇',
        '猛虎越山·狡',
        '猛虎越山·慎',
        '巨熊踏路·忠',
        '巨熊踏路·慎',
        '奔马逐风·慎',
      ]);
    });

    test('95 档系列名照《珍兽套装明细》表', () {
      expect(petSuitsAt('95').map((s) => s.name).toList(), [
        '鲲鹏异羽·怯',
        '鲲鹏异羽·狡',
        '鲲鹏异羽·慎',
        '雄狮逆鳞·勇',
        '雄狮逆鳞·狡',
        '雄狮逆鳞·慎',
        '玄龟奇血·忠',
        '玄龟奇血·慎',
        '墨豹惊山·慎',
      ]);
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

    test('每套都有性格与 5 列词条（自带 / 兽环 / 组合 / 技能 / 推荐）', () {
      for (final s in kPetSuitSeries) {
        expect(s.personality, isNotEmpty, reason: s.name);
        expect(s.ownEntries, isNotEmpty, reason: s.name);
        expect(s.ringEntries, isNotEmpty, reason: s.name);
        expect(s.comboEntries, isNotEmpty, reason: s.name);
        expect(s.skillEffect, isNotEmpty, reason: s.name);
        expect(s.recommendation, isNotEmpty, reason: s.name);
        expect(s.fitText, '${s.type}型 · ${s.personality}性格', reason: s.name);
      }
      // 性格覆盖经典版六种适配
      final persons = kPetSuitSeries.map((s) => s.personality).toSet();
      expect(persons, {'勇猛', '精明', '谨慎', '胆小', '忠诚', '谨慎平衡'});
    });

    test('词条按表原文录入（抽样逐条核对）', () {
      final byName = {for (final s in kPetSuitSeries) s.name: s};

      // 75 档
      expect(byName['黄雀戏水·怯']!.ownEntries, '内功+会心');
      expect(byName['黄雀戏水·怯']!.ringEntries, '灵气+体力');
      expect(byName['黄雀戏水·怯']!.comboEntries, '内功+命中+灵气');
      expect(byName['黄雀戏水·怯']!.skillEffect, '四咒伤害');
      expect(byName['黄雀戏水·怯']!.recommendation, '内功宝宝入门选择');
      expect(byName['苍狼啸月·勇']!.skillEffect, '猛击伤害');
      expect(byName['乌鹏望日·忠']!.ownEntries, '内外防');
      expect(byName['乌鹏望日·忠']!.skillEffect, '灵动触发概率');
      expect(byName['白兔隐林·慎']!.ownEntries, '命中+闪避');
      expect(byName['白兔隐林·慎']!.ringEntries, '身法');

      // 85 档
      expect(byName['飞鹰翔空·怯']!.skillEffect, '痛击伤害');
      expect(byName['飞鹰翔空·怯']!.ownEntries, '内功+命+会');
      expect(byName['猛虎越山·勇']!.skillEffect, '猛击释放几率');
      expect(byName['猛虎越山·勇']!.discouraged, isTrue);
      expect(byName['巨熊踏路·忠']!.comboEntries, '内外防+血上限');
      expect(byName['奔马逐风·慎']!.recommendation, '吸气宝宝可选');

      // 95 档（表格里自带词条用缩写写法，按原文录入）
      expect(byName['鲲鹏异羽·怯']!.ownEntries, '内+命+会+灵');
      expect(byName['鲲鹏异羽·怯']!.skillEffect, '四咒释放几率');
      expect(byName['雄狮逆鳞·勇']!.ownEntries, '外+命+会+力');
      expect(byName['玄龟奇血·忠']!.ownEntries, '内外防+闪+体');
      expect(byName['玄龟奇血·慎']!.recommendation, '谨慎+精明体力毕业套');
      expect(byName['墨豹惊山·慎']!.comboEntries, '命中+身法+血上限');

      // 只有猛虎越山·勇被标红劝退
      expect(
        kPetSuitSeries.where((s) => s.discouraged).map((s) => s.name).toList(),
        ['猛虎越山·勇'],
      );
    });

    test('组合词条照表：类型 + 性格决定 2~3 条', () {
      const expected = {
        ('内功', '胆小'): '内功+命中+灵气',
        ('内功', '精明'): '命中+血上限+灵气',
        ('内功', '谨慎'): '命中+血上限+灵气',
        ('外功', '勇猛'): '外功+命中+力量',
        ('外功', '精明'): '命中+血上限+力量',
        ('外功', '谨慎'): '命中+血上限+力量',
        ('体力', '忠诚'): '内外防+血上限',
        ('体力', '谨慎'): '身法+命中+血上限',
        ('体力', '谨慎平衡'): '身法+命中+血上限',
        ('身法', '谨慎'): '命中+身法+血上限',
        ('身法', '谨慎平衡'): '命中+身法+血上限',
      };
      for (final s in kPetSuitSeries) {
        expect(
          s.comboEntries,
          expected[(s.type, s.personality)],
          reason: s.name,
        );
      }
    });

    test('兽环属性照表：类型 + 性格决定 1~2 条', () {
      const expected = {
        ('内功', '胆小'): '灵气+体力',
        ('内功', '精明'): '命中+会心',
        ('内功', '谨慎'): '灵气+身法',
        ('外功', '勇猛'): '力量+体力',
        ('外功', '精明'): '命中+会心',
        ('外功', '谨慎'): '力量+身法',
        ('体力', '忠诚'): '体力',
        ('体力', '谨慎'): '体力+身法',
        ('体力', '谨慎平衡'): '体力+身法',
        ('身法', '谨慎'): '身法',
        ('身法', '谨慎平衡'): '身法',
      };
      for (final s in kPetSuitSeries) {
        expect(
          s.ringEntries,
          expected[(s.type, s.personality)],
          reason: s.name,
        );
      }
    });

    test('五件套部位：兽盔 / 兽爪 / 兽甲 / 兽环 / 兽饰', () {
      expect(kPetSuitSlots.map((s) => s.slot).toList(), [
        '头',
        '爪',
        '躯干',
        '颈',
        '护符',
      ]);
      expect(kPetSuitSlots.map((s) => s.name).toList(), [
        '兽盔',
        '兽爪',
        '兽甲',
        '兽环',
        '兽饰',
      ]);
      // 每个部位都带图标资产名（assets/pet_suit/<icon>.png）
      expect(kPetSuitSlots.map((s) => s.icon).toList(), [
        'part_helm',
        'part_claw',
        'part_armor',
        'part_ring',
        'part_charm',
      ]);
      // 只有兽环（颈）带出战后生效的系列属性
      expect(kPetSuitSlots[3].note, contains('出战'));
      for (final slot in kPetSuitSlots) {
        expect(slot.note, isNotEmpty, reason: slot.name);
      }
    });
  });

  test('内置分片 assets/catalog/pet.suits.json 与常量一致（改了数据必须重新导出）', () {
    final raw = File('assets/catalog/pet.suits.json').readAsStringSync();
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final items = doc['items'] as Map<String, dynamic>;
    final series = (items['series'] as List).cast<Map<String, dynamic>>();

    expect(series.length, kPetSuitSeries.length);
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final c = kPetSuitSeries[i];
      expect(s['name'], c.name);
      expect(s['lv'], c.lv);
      expect(s['type'], c.type);
      expect(s['personality'], c.personality);
      expect(s['ownEntries'], c.ownEntries);
      expect(s['ringEntries'], c.ringEntries);
      expect(s['comboEntries'], c.comboEntries);
      expect(s['skillEffect'], c.skillEffect);
      expect(s['recommendation'], c.recommendation);
    }
    // 75 档兑换口径：分片里 exchange 为 0（副本掉落）
    final matCost = items['matCost'] as Map<String, dynamic>;
    expect((matCost['75'] as Map<String, dynamic>)['exchange'], 0);
  });

  group('圣兽鳞消耗表 —— 怀旧服口径（每件）', () {
    test('兑换单价：75 → 0（副本掉落）/ 85 → 30 / 95 → 100', () {
      expect(kSuitMatCost['75']!.exchange, 0);
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

    test('每件升满 5★：75 → 26 / 85 → 108 / 95 → 285', () {
      expect(kSuitMatCost['75']!.perPieceTo(5), 26);
      expect(kSuitMatCost['85']!.perPieceTo(5), 108);
      expect(kSuitMatCost['95']!.perPieceTo(5), 285);
      expect(kSuitMatCost['75']!.perPieceTo(1), 0);
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

    test('目标 5★（75 档）：部件掉落、无兑换，升星 130 个', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '75', targetStar: 5, withExchange: true),
      );
      expect(r.exchangePerPiece, 0);
      expect(r.exchangeSet, 0);
      expect(r.upgradeSet, 130);
      expect(r.total, 130);
      expect(r.fullSetTotal, 130);
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
