import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_suit.dart';

void main() {
  group('套装图鉴数据 —— 与 UI 原型一致', () {
    test('六大性格套装齐全：名称 / 分类 / 配色 / 图标', () {
      expect(kPetSuits.length, 6);
      final names = kPetSuits.map((s) => s.name).toList();
      expect(
        names,
        ['勇猛套装', '胆小套装', '谨慎套装', '精明套装', '忠诚套装', '内敛套装'],
      );

      final cats = kPetSuits.map((s) => s.cat).toList();
      expect(
        cats,
        ['外功输出', '灵巧输出', '生存防护', '内功输出', '守护辅助', '爆发会心'],
      );

      // 分类配色与图标
      expect(kPetSuits[0].catColor, PetSuitCatColor.gold);
      expect(kPetSuits[0].icon, 'sword');
      expect(kPetSuits[1].catColor, PetSuitCatColor.cyan);
      expect(kPetSuits[2].catColor, PetSuitCatColor.green);
      expect(kPetSuits[3].catColor, PetSuitCatColor.blue);
      expect(kPetSuits[4].catColor, PetSuitCatColor.purple);
      expect(kPetSuits[5].catColor, PetSuitCatColor.gold);
      expect(kPetSuits[5].icon, 'flame');
    });

    test('每套：三档（75/85/95）件数效果 2+3，且随档位递增', () {
      for (final s in kPetSuits) {
        expect(s.levels.keys.toList(), kSuitLvKeys, reason: s.name);
        for (final lv in kSuitLvKeys) {
          final eff = s.levels[lv]!;
          expect(eff.length, 2, reason: '${s.name} $lv');
          expect(eff[0].pieces, '2 件', reason: '${s.name} $lv');
          expect(eff[1].pieces, '3 件', reason: '${s.name} $lv');
        }
        // 2 件效果文字随档位变化（75 → 95 数值更高）
        expect(s.levels['75']![0].text, isNot(s.levels['95']![0].text),
            reason: '${s.name} 2件效果随档位变化');
      }
    });

    test('每套五件套部件：头饰/铠甲/项圈/利爪/玉佩，三档属性', () {
      for (final s in kPetSuits) {
        final slots = s.parts.map((p) => p.slot).toList();
        expect(slots, ['头饰', '铠甲', '项圈', '利爪', '玉佩'], reason: s.name);
        for (final p in s.parts) {
          expect(p.attr.length, 3, reason: '${s.name} ${p.slot}');
          expect(p.sub.length, 3, reason: '${s.name} ${p.slot}');
          // 主属性随档位递增（数值字符串不同即可）
          expect(p.attr[0], isNot(p.attr[2]), reason: '${s.name} ${p.slot}');
          // 部位首字用于徽章
          expect(p.slot.substring(0, 1), isNotEmpty);
        }
      }
    });

    test('适配类型：每套 2 个，含对应性格', () {
      final expectFit = {
        '勇猛套装': '勇猛性格',
        '胆小套装': '胆小性格',
        '谨慎套装': '谨慎性格',
        '精明套装': '精明性格',
        '忠诚套装': '忠诚性格',
        '内敛套装': '内敛性格',
      };
      for (final s in kPetSuits) {
        expect(s.fits.length, 2, reason: s.name);
        expect(s.fits, contains(expectFit[s.name]), reason: s.name);
      }
    });
  });

  group('材料数据与计算 —— 与原型 suitMatsCalc 一致', () {
    test('兑换材料：85/95 两档；升星基础：75/85/95 三档', () {
      expect(kSuitMats.exchange.keys.toList(), ['85', '95']);
      expect(kSuitMats.starBase.keys.toList(), ['75', '85', '95']);
      // 95 兑换：赤金令 ×16（单件）→ 整套 ×5 = 80
      final ex = kSuitMats.exchange['95']!;
      expect(ex.first.name, '赤金令');
      expect(ex.first.count, 16);
    });

    test('默认：85 档 / 0 星 / 含兑换 → 兑换 + 升星 + 合计', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', currentStar: 0, withExchange: true),
      );
      // 兑换整套：玄铁令 8×5=40、锻魂石 4×5=20、银两 150000×5=75万
      expect(r.exchange.map((m) => '${m.name}:${m.count}').toList(),
          ['玄铁令:40', '锻魂石:20', '银两:750000']);
      // 升星 1★→5★（5 行）
      expect(r.starRows.length, 5);
      expect(r.starRows.map((x) => x.star).toList(), [1, 2, 3, 4, 5]);
      // 合计含银两（兑换 + 升星）
      final totalMap = {for (final m in r.total) m.name: m.count};
      expect(totalMap['银两'], greaterThan(750000));
      expect(totalMap.containsKey('套装精魄'), isTrue);
    });

    test('当前星级从 3 星起算：只算 4★、5★', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '75', currentStar: 3, withExchange: false),
      );
      expect(r.exchange, isEmpty);
      expect(r.starRows.length, 2);
      expect(r.starRows.map((x) => x.star).toList(), [4, 5]);
      // 75 基础：套装精魄 ×6 ×k ×5
      expect(r.starRows.last.mats.first.name, '套装精魄');
      expect(r.starRows.last.mats.first.count, 6 * 5 * 5);
    });

    test('关闭含兑换材料：exchange 为空且合计不含兑换项', () {
      final r = suitMatsCalc(
        const SuitMatCalcInput(lv: '85', currentStar: 0, withExchange: false),
      );
      expect(r.exchange, isEmpty);
      expect(r.total.any((m) => m.name == '玄铁令'), isFalse);
      expect(r.total.any((m) => m.name == '套装精魄'), isTrue);
    });

    test('大数字格式化 suitFmtCount', () {
      expect(suitFmtCount(40), '40');
      expect(suitFmtCount(150000), '15万');
      expect(suitFmtCount(1500000), '150万');
      expect(suitFmtCount(175000), '17.5万');
    });
  });
}
