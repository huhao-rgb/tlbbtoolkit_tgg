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
    expect(complete.map((s) => s.id), [
      'poyu',
      'podan',
      'bingjing',
      'huoling',
      'dugu',
      'xuanshou',
      'chidun',
      'jiaohua',
      'hanhou',
      'pinming',
    ]);

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

  test('技能类型维度：当前收录均为被动，手动待补', () {
    expect(
      kBeastSpirits.every((s) => s.kind == BeastSpiritKind.passive),
      isTrue,
    );
    expect(
      kBeastSpirits.where((s) => s.kind == BeastSpiritKind.manual),
      isEmpty,
    );
    expect(BeastSpiritKind.passive.label, '被动技能');
    expect(BeastSpiritKind.manual.label, '手动技能');
  });

  test('冰精兽灵逐阶数值（小程序「TLBB怀旧攻略」核验）', () {
    final ice = kBeastSpirits.firstWhere((s) => s.id == 'bingjing');
    expect(ice.name, '冰精');
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

  test('火灵 / 毒蛊 / 玄兽：元素减伤三兄弟（对位互克）', () {
    // 说明行：本元素减伤 / 对位元素增伤，2 → 4 → 10 → 15
    final pairs = {
      'huoling': ('火攻', '冰攻'),
      'dugu': ('毒攻', '玄攻'),
      'xuanshou': ('玄攻', '毒攻'),
    };
    for (final e in pairs.entries) {
      final s = kBeastSpirits.firstWhere((x) => x.id == e.key);
      final (self, other) = e.value;
      expect(
        s.tiers[0].dec,
        '受到$self伤害再次减少 <b>2%</b>，受到$other伤害增加 <b>2%</b>',
        reason: s.name,
      );
      expect(s.tiers[1].dec, contains('<b>4%</b>'), reason: s.name);
      expect(s.tiers[2].dec, contains('<b>10%</b>'), reason: s.name);
      expect(s.tiers[6].dec, contains('<b>15%</b>'), reason: s.name);
      // 效果一：15% → 30%
      expect(s.tiers[1].effect1, contains('减少 <b>15%</b>'), reason: s.name);
      expect(s.tiers[3].effect1, contains('减少 <b>30%</b>'), reason: s.name);
      for (final i in [0, 1, 2]) {
        expect(s.tiers[i].effect2, '<i>10 级解锁</i>', reason: s.name);
      }
    }

    // 火灵效果二：额外爆炸 + 被冰冻
    final huo = kBeastSpirits.firstWhere((s) => s.id == 'huoling');
    expect(huo.tiers[3].effect2, contains('有 <b>3%</b> 概率使目标额外受到一次爆炸伤害'));
    expect(huo.tiers[3].effect2, contains('有 <b>1%</b> 概率被冰冻 <b>0.5 秒</b>'));
    expect(huo.tiers[6].effect2, contains('有 <b>24%</b> 概率'));
    expect(huo.tiers[6].effect2, contains('有 <b>8%</b> 概率被冰冻'));

    // 毒蛊效果二：剧毒陷阱 + 玄罡；陷阱持续统一 6 秒
    final du = kBeastSpirits.firstWhere((s) => s.id == 'dugu');
    expect(
      du.tiers[3].effect2,
      contains('有 <b>2%</b> 概率在目标脚底产生一个半径 <b>3 米</b>持续 <b>6 秒</b>的剧毒陷阱'),
    );
    expect(du.tiers[3].effect2, contains('有 <b>0.4%</b> 概率使攻击者'));
    expect(du.tiers[3].effect2, contains('获得<b>玄罡</b>效果'));
    expect(du.tiers[4].effect2, contains('持续 <b>6 秒</b>的剧毒陷阱'));
    expect(du.tiers[5].effect2, contains('有 <b>1.8%</b> 概率'));
    expect(du.tiers[6].effect2, contains('有 <b>15%</b> 概率'));
    expect(du.tiers[6].effect2, contains('有 <b>3%</b> 概率使攻击者'));

    // 玄兽效果二：玄罡护体在前、陷阱在自身脚底
    final xuan = kBeastSpirits.firstWhere((s) => s.id == 'xuanshou');
    expect(
      xuan.tiers[3].effect2,
      contains('有 <b>2%</b> 概率使自身 <b>15 米</b>范围内所有小队成员获得<b>玄罡</b>效果'),
    );
    expect(
      xuan.tiers[3].effect2,
      contains('在自身脚底产生一个半径 <b>3 米</b>持续 <b>6 秒</b>的剧毒陷阱'),
    );
    expect(xuan.tiers[6].effect2, contains('有 <b>15%</b> 概率使自身'));
    expect(xuan.tiers[6].effect2, contains('有 <b>3%</b> 概率在自身脚底'));
  });

  test('迟钝 / 狡猾 / 憨厚 / 拼命：被动强化四件套', () {
    // 迟钝：血上限 2/4/8/10，效果二为心法增伤（代价冷却 +20%）
    final dun = kBeastSpirits.firstWhere((s) => s.id == 'chidun');
    expect(dun.tiers.map((t) => t.dec).toList(), [
      '血上限额外增加 <b>2%</b>',
      '血上限额外增加 <b>4%</b>',
      '血上限额外增加 <b>8%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
    ]);
    expect(dun.tiers[1].effect1, contains('血上限增加 <b>10%</b>'));
    expect(dun.tiers[3].effect1, contains('立即恢复 <b>6%</b> 的血量'));
    expect(dun.tiers[6].effect1, contains('立即恢复 <b>8%</b> 的血量'));
    expect(dun.tiers[3].effect2, contains('伤害增加 <b>5%</b>'));
    expect(dun.tiers[6].effect2, contains('伤害增加 <b>40%</b>'));
    expect(dun.tiers[6].effect2, contains('冷却时间增加 <b>20%</b>'));

    // 狡猾：身法换命中 / 闪避，三阶 3 / 1（用户核验修正）
    final jiao = kBeastSpirits.firstWhere((s) => s.id == 'jiaohua');
    expect(jiao.tiers[2].dec, '每点身法资质可额外增加 <b>3</b> 点命中和 <b>1</b> 点闪避');
    expect(jiao.tiers[3].dec, contains('<b>4.5</b> 点命中和 <b>1.5</b> 点闪避'));
    expect(jiao.tiers[3].effect2, contains('可增加 <b>1%</b> 闪避率'));
    expect(jiao.tiers[6].effect2, contains('可增加 <b>8%</b> 闪避率'));

    // 憨厚：内外功减伤 4/8/20/30，效果二为 PVE 减伤
    final hou = kBeastSpirits.firstWhere((s) => s.id == 'hanhou');
    expect(hou.tiers[0].dec, '受到的内外功伤害降低 <b>4%</b>');
    expect(hou.tiers[1].dec, '受到的内外功伤害降低 <b>8%</b>');
    expect(hou.tiers[2].dec, '受到的内外功伤害降低 <b>20%</b>');
    expect(hou.tiers[6].dec, '受到的内外功伤害降低 <b>30%</b>');
    expect(hou.tiers[3].effect2, contains('非玩家和非珍兽目标的伤害降低 <b>6%</b>'));
    expect(hou.tiers[6].effect2, contains('伤害降低 <b>40%</b>'));

    // 拼命：会心 / 会伤递增，效果二为双刃（会心一击率与受伤同增）
    final pin = kBeastSpirits.firstWhere((s) => s.id == 'pinming');
    expect(pin.isComplete, isTrue);
    expect(pin.tiers[0].dec, contains('<b>0.004%</b> 的会心和 <b>0.02%</b> 的会心伤害'));
    expect(pin.tiers[2].dec, contains('<b>0.016%</b> 的会心和 <b>0.08%</b> 的会心伤害'));
    expect(pin.tiers[6].dec, contains('<b>0.02%</b> 的会心和 <b>0.1%</b> 的会心伤害'));
    expect(pin.tiers[1].effect1, contains('会心攻击增加 <b>10%</b>'));
    expect(pin.tiers[6].effect1, contains('会心攻击增加 <b>20%</b>'));
    expect(
      pin.tiers[3].effect2,
      contains('会心一击率增加 <b>2%</b>，受到的伤害增加 <b>2%</b>'),
    );
    expect(
      pin.tiers[6].effect2,
      contains('会心一击率增加 <b>15%</b>，受到的伤害增加 <b>15%</b>'),
    );
  });

  test('待补兽灵：无逐阶数据但含攻略共识正文与 ※ 注', () {
    final pending = kBeastSpirits.where((s) => !s.isComplete).toList();
    expect(pending.map((s) => s.id), ['tongji', 'lianji', 'lingdong']);

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
    expect(kBeastIndexFootNote, startsWith('※ 痛击/连击/灵动'));
  });
}
