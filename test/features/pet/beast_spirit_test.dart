import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/beast_spirit.dart';

void main() {
  test('阶位结构为 20 级 7 阶', () {
    expect(kBeastTierSteps.length, 7);
    expect(kBeastTierSteps.first.name, '一阶');
    expect(kBeastTierSteps.first.lv, '1-3 级');
    expect(kBeastTierSteps.last.name, '七阶');
    expect(kBeastTierSteps.last.lv, '20 级');
  });

  test('完整数据兽灵：7 阶齐备且阶位与阶位结构一致', () {
    final complete = kBeastSpirits.where((s) => s.isComplete).toList();
    expect(complete.map((s) => s.id), ['poyu', 'podan', 'bingjing']);

    for (final s in complete) {
      expect(s.status.label, '完整数据');
      expect(s.tiers.length, 7, reason: s.name);
      for (var i = 0; i < kBeastTierSteps.length; i++) {
        expect(s.tiers[i].name, kBeastTierSteps[i].name, reason: s.name);
        expect(s.tiers[i].lv, kBeastTierSteps[i].lv, reason: s.name);
      }
      // 完整数据兽灵不使用待补字段
      expect(s.pendingBody, isEmpty, reason: s.name);
      expect(s.pendingNote, isEmpty, reason: s.name);
    }
  });

  test('冰精兽灵逐阶数值（小程序「TLBB怀旧攻略」核验）', () {
    final ice = kBeastSpirits.firstWhere((s) => s.id == 'bingjing');
    expect(ice.name, '冰精兽灵');
    expect(ice.isComplete, isTrue);

    // 阶位说明：减伤 / 增伤 2 → 4 → 10 → 15（四阶起保持 15）
    expect(ice.tiers.map((t) => t.dec).toList(), [
      '受到冰攻伤害再次减少 <b>2%</b>，受到火攻伤害增加 <b>2%</b>',
      '受到冰攻伤害再次减少 <b>4%</b>，受到火攻伤害增加 <b>4%</b>',
      '受到冰攻伤害再次减少 <b>10%</b>，受到火攻伤害增加 <b>10%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
    ]);

    // 效果一：一阶未解锁 → 二 / 三阶 15% → 四阶起 30%
    expect(ice.tiers[0].effect1, '<i>4 级解锁</i>');
    expect(ice.tiers[1].effect1, contains('减少 <b>15%</b>'));
    expect(ice.tiers[2].effect1, contains('增加 <b>15%</b>'));
    expect(ice.tiers[3].effect1, contains('减少 <b>30%</b>'));
    expect(ice.tiers[6].effect1, contains('增加 <b>30%</b>'));

    // 效果二：一 / 二 / 三阶未解锁 → 四阶起 冰冻 3/6/12/24%、爆炸 1/2/4/8%
    for (final i in [0, 1, 2]) {
      expect(ice.tiers[i].effect2, '<i>10 级解锁</i>');
    }
    const freeze = [3, 6, 12, 24];
    const blast = [1, 2, 4, 8];
    for (var i = 0; i < 4; i++) {
      final fx = ice.tiers[3 + i].effect2;
      expect(fx, contains('有 <b>${freeze[i]}%</b> 概率冰冻目标 <b>0.5 秒</b>'));
      expect(fx, contains('有 <b>${blast[i]}%</b> 概率额外受到一次爆炸伤害'));
      expect(fx, contains('普通攻击的 <b>150%</b> 伤害'));
    }
  });

  test('待补兽灵：无逐阶数据但含攻略共识正文与 ※ 注', () {
    final pending = kBeastSpirits.where((s) => !s.isComplete).toList();
    expect(pending.map((s) => s.id), [
      'pinming',
      'tongji',
      'lianji',
      'lingdong',
    ]);

    for (final s in pending) {
      expect(s.status.label, '待补');
      expect(s.tiers, isEmpty, reason: s.name);
      expect(s.pendingBody, isNotEmpty, reason: s.name);
      expect(s.pendingNote.startsWith('※'), isTrue, reason: s.name);
    }
  });

  test('破御 / 破胆关键数值与原型 TIERS 一致', () {
    final poyu = kBeastSpirits.firstWhere((s) => s.id == 'poyu');
    expect(poyu.tiers[0].dec, contains('<b>2%</b>'));
    expect(poyu.tiers[2].dec, contains('<b>8%</b>'));
    expect(poyu.tiers[3].dec, contains('<b>16%</b>'));
    expect(poyu.tiers[0].effect1, '<i>4 级解锁</i>');
    expect(poyu.tiers[0].effect2, '<i>10 级解锁</i>');
    expect(poyu.tiers[3].effect2, contains('免疫 1 次'));
    expect(poyu.tiers[6].effect2, contains('免疫 5 次'));

    final podan = kBeastSpirits.firstWhere((s) => s.id == 'podan');
    expect(podan.tiers[0].dec, contains('<b>1%</b>'));
    expect(podan.tiers[2].dec, contains('<b>4%</b>'));
    expect(podan.tiers[3].dec, contains('<b>10%</b>'));
    expect(podan.tiers[6].effect2, contains('额外提升 <b>4%</b>'));
  });

  test('图鉴说明文案取自原型 calc-note', () {
    expect(kBeastIndexIntroNote, contains('<b>20 级 · 7 阶</b>'));
    expect(kBeastIndexIntroNote, contains('效果一 4 级解锁、效果二 10 级解锁'));
    expect(kBeastIndexFootNote, startsWith('※ 拼命/痛击/连击/灵动'));
  });
}
