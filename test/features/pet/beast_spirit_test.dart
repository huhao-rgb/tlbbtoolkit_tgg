import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/beast_spirit.dart';

/// 按 id 取兽灵。
BeastSpirit byId(String id) => kBeastSpirits.firstWhere((s) => s.id == id);

/// 全部 39 只兽灵（顺序 = 图鉴手风琴顺序）。
const _allIds = [
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
  'tongji',
  'lianji',
  'lingdong',
  'fahun',
  'manli',
  'jieli',
  'yihun',
  'shunying',
  'qiangshen',
  'ningshen',
  'hanbingzhou',
  'liehuozhou',
  'xueduzhou',
  'xuanleizhou',
  'fanji',
  'fanzhen',
  'xiqi',
  'danu',
  'zhongxin',
  'lingqi',
  'mengji',
  'shipo',
  'xuruo',
  'pozhan',
  'shuaiban',
  'binghun',
  'huohun',
  'duhun',
  'xuanhun',
  // 手动技能（29）
  'linghuzhixi',
  'tonghu',
  'jibingningsha',
  'jiehuofensha',
  'fudushisha',
  'xuanleijisha',
  'xuebao',
  'bingbao',
  'jinghua',
  'chongsheng',
  'gongsheng',
  'zhiliao',
  'rouqiang',
  'shenyou',
  'shixue',
  'xueji',
  'weizhuang',
  'fushen',
  'jiexue',
  'qingxing',
  'mingmu',
  'qingling',
  'guyuan',
  'satuo',
  'bingtianxuedi',
  'liehuoliaoyuan',
  'xueduwanli',
  'wuleihongding',
  'paoxiao',
];

void main() {
  test('阶位结构为 20 级 7 阶', () {
    expect(kBeastTierSteps.length, 7);
    expect(kBeastTierSteps.first.name, '一阶');
    expect(kBeastTierSteps.first.lv, '1-3 级');
    expect(kBeastTierSteps.last.name, '七阶');
    expect(kBeastTierSteps.last.lv, '20 级');
  });

  test('68 只兽灵：全部完整数据、7 阶齐备且阶位与阶位结构一致', () {
    expect(kBeastSpirits.map((s) => s.id), _allIds);

    for (final s in kBeastSpirits) {
      expect(s.status.label, '完整数据', reason: s.name);
      expect(s.tiers.length, 7, reason: s.name);
      for (var i = 0; i < kBeastTierSteps.length; i++) {
        expect(s.tiers[i].name, kBeastTierSteps[i].name, reason: s.name);
        expect(s.tiers[i].lv, kBeastTierSteps[i].lv, reason: s.name);
      }
      // 完整数据兽灵不使用待补字段
      expect(s.pendingBody, isEmpty, reason: s.name);
      expect(s.pendingNote, isEmpty, reason: s.name);
      // 每只都有一句话定位
      expect(s.sub, isNotEmpty, reason: s.name);
    }
    // 待补归零
    expect(kBeastSpirits.where((s) => !s.isComplete), isEmpty);
  });

  test('技能类型维度：被动 39 只、手动 29 只', () {
    expect(
      kBeastSpirits.where((s) => s.kind == BeastSpiritKind.passive).length,
      39,
    );
    expect(
      kBeastSpirits.where((s) => s.kind == BeastSpiritKind.manual).length,
      29,
    );
    expect(BeastSpiritKind.passive.label, '被动技能');
    expect(BeastSpiritKind.manual.label, '手动技能');
    // 手动技能触发语为「怒意二阶释放」，被动为「怒意三阶抽取」
    final manual = kBeastSpirits.where((s) => s.kind == BeastSpiritKind.manual);
    final withTrigger = manual
        .where(
          (s) => s.tiers.any(
            (t) => t.effect1.contains('怒意二阶') || t.effect2.contains('怒意二阶'),
          ),
        )
        .toList();
    // 27 只带「释放」触发语；灵狐之息 / 同护 为持续状态型，无触发语
    expect(withTrigger.length, 27);
    expect(withTrigger.map((s) => s.name), isNot(contains('灵狐之息')));
    expect(withTrigger.map((s) => s.name), isNot(contains('同护')));
    // 手动技能一律不使用被动的「怒意三阶抽取」触发语
    for (final s in manual) {
      for (final t in s.tiers) {
        expect(t.effect1, isNot(contains('怒意三阶')), reason: s.name);
        expect(t.effect2, isNot(contains('怒意三阶')), reason: s.name);
      }
    }
  });

  test('破御 / 破胆关键数值与原型 TIERS 一致', () {
    final poyu = byId('poyu');
    expect(poyu.tiers[0].dec, contains('<b>2%</b>'));
    expect(poyu.tiers[2].dec, contains('<b>8%</b>'));
    expect(poyu.tiers[3].dec, contains('<b>16%</b>'));
    expect(poyu.tiers[0].effect1, '<i>4 级解锁</i>');
    expect(poyu.tiers[0].effect2, '<i>10 级解锁</i>');
    expect(poyu.tiers[3].effect2, contains('免疫 1 次'));
    expect(poyu.tiers[6].effect2, contains('免疫 5 次'));

    final podan = byId('podan');
    expect(podan.tiers[0].dec, contains('<b>1%</b>'));
    expect(podan.tiers[2].dec, contains('<b>4%</b>'));
    expect(podan.tiers[3].dec, contains('<b>10%</b>'));
    expect(podan.tiers[6].effect2, contains('额外提升 <b>4%</b>'));
  });

  test('冰精：减伤 / 增伤 2→4→10→15，冰冻 3/6/12/24%', () {
    final ice = byId('bingjing');
    expect(ice.tiers.map((t) => t.dec).toList(), [
      '受到冰攻伤害再次减少 <b>2%</b>，受到火攻伤害增加 <b>2%</b>',
      '受到冰攻伤害再次减少 <b>4%</b>，受到火攻伤害增加 <b>4%</b>',
      '受到冰攻伤害再次减少 <b>10%</b>，受到火攻伤害增加 <b>10%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
      '受到冰攻伤害再次减少 <b>15%</b>，受到火攻伤害增加 <b>15%</b>',
    ]);
    expect(ice.tiers[1].effect1, contains('减少 <b>15%</b>'));
    expect(ice.tiers[3].effect1, contains('减少 <b>30%</b>'));
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
    final pairs = {
      'huoling': ('火攻', '冰攻'),
      'dugu': ('毒攻', '玄攻'),
      'xuanshou': ('玄攻', '毒攻'),
    };
    for (final e in pairs.entries) {
      final s = byId(e.key);
      final (self, other) = e.value;
      expect(
        s.tiers[0].dec,
        '受到$self伤害再次减少 <b>2%</b>，受到$other伤害增加 <b>2%</b>',
        reason: s.name,
      );
      expect(s.tiers[1].dec, contains('<b>4%</b>'), reason: s.name);
      expect(s.tiers[2].dec, contains('<b>10%</b>'), reason: s.name);
      expect(s.tiers[6].dec, contains('<b>15%</b>'), reason: s.name);
      expect(s.tiers[1].effect1, contains('减少 <b>15%</b>'), reason: s.name);
      expect(s.tiers[3].effect1, contains('减少 <b>30%</b>'), reason: s.name);
      for (final i in [0, 1, 2]) {
        expect(s.tiers[i].effect2, '<i>10 级解锁</i>', reason: s.name);
      }
    }

    final huo = byId('huoling');
    expect(huo.tiers[3].effect2, contains('有 <b>3%</b> 概率使目标额外受到一次爆炸伤害'));
    expect(huo.tiers[3].effect2, contains('有 <b>1%</b> 概率被冰冻 <b>0.5 秒</b>'));
    expect(huo.tiers[6].effect2, contains('有 <b>24%</b> 概率'));
    expect(huo.tiers[6].effect2, contains('有 <b>8%</b> 概率被冰冻'));

    final du = byId('dugu');
    expect(
      du.tiers[3].effect2,
      contains('有 <b>2%</b> 概率在目标脚底产生一个半径 <b>3 米</b>持续 <b>6 秒</b>的剧毒陷阱'),
    );
    expect(du.tiers[3].effect2, contains('有 <b>0.4%</b> 概率使攻击者'));
    expect(du.tiers[3].effect2, contains('获得<b>玄罡</b>效果'));
    expect(du.tiers[5].effect2, contains('有 <b>1.8%</b> 概率'));
    expect(du.tiers[6].effect2, contains('有 <b>3%</b> 概率使攻击者'));

    final xuan = byId('xuanshou');
    expect(
      xuan.tiers[3].effect2,
      contains('有 <b>2%</b> 概率使自身 <b>15 米</b>范围内所有小队成员获得<b>玄罡</b>效果'),
    );
    expect(
      xuan.tiers[3].effect2,
      contains('在自身脚底产生一个半径 <b>3 米</b>持续 <b>6 秒</b>的剧毒陷阱'),
    );
    expect(xuan.tiers[6].effect2, contains('有 <b>3%</b> 概率在自身脚底'));
  });

  test('迟钝 / 狡猾 / 憨厚 / 拼命：被动强化四件套', () {
    final dun = byId('chidun');
    expect(dun.tiers.map((t) => t.dec).toList(), [
      '血上限额外增加 <b>2%</b>',
      '血上限额外增加 <b>4%</b>',
      '血上限额外增加 <b>8%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
      '血上限额外增加 <b>10%</b>',
    ]);
    expect(dun.tiers[3].effect1, contains('立即恢复 <b>6%</b> 的血量'));
    expect(dun.tiers[6].effect1, contains('立即恢复 <b>8%</b> 的血量'));
    expect(dun.tiers[3].effect2, contains('伤害增加 <b>5%</b>'));
    expect(dun.tiers[6].effect2, contains('伤害增加 <b>40%</b>'));
    expect(dun.tiers[6].effect2, contains('冷却时间增加 <b>20%</b>'));

    final jiao = byId('jiaohua');
    expect(jiao.tiers[2].dec, '每点身法资质可额外增加 <b>3</b> 点命中和 <b>1</b> 点闪避');
    expect(jiao.tiers[3].dec, contains('<b>4.5</b> 点命中和 <b>1.5</b> 点闪避'));
    expect(jiao.tiers[3].effect2, contains('可增加 <b>1%</b> 闪避率'));
    expect(jiao.tiers[6].effect2, contains('可增加 <b>8%</b> 闪避率'));

    final hou = byId('hanhou');
    expect(hou.tiers[0].dec, '受到的内外功伤害降低 <b>4%</b>');
    expect(hou.tiers[1].dec, '受到的内外功伤害降低 <b>8%</b>');
    expect(hou.tiers[2].dec, '受到的内外功伤害降低 <b>20%</b>');
    expect(hou.tiers[6].dec, '受到的内外功伤害降低 <b>30%</b>');
    expect(hou.tiers[3].effect2, contains('非玩家和非珍兽目标的伤害降低 <b>6%</b>'));
    expect(hou.tiers[6].effect2, contains('伤害降低 <b>40%</b>'));

    final pin = byId('pinming');
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

  test('属性类 5 只：给主人加属性点，并把加成共享给珍兽', () {
    const cases = {
      'jieli': ('力量', '外功攻击'),
      'yihun': ('定力', '闪避'),
      'qiangshen': ('体力', '会心防御'),
      'ningshen': ('灵气', '内功攻击'),
    };
    for (final e in cases.entries) {
      final s = byId(e.key);
      final (attr, share) = e.value;
      expect(s.tiers[0].dec, '额外给玩家增加$attr <b>10</b> 点', reason: s.name);
      expect(s.tiers[1].dec, '额外给玩家增加$attr <b>20</b> 点', reason: s.name);
      expect(s.tiers[2].dec, '额外给玩家增加$attr <b>50</b> 点', reason: s.name);
      expect(s.tiers[6].dec, '额外给玩家增加$attr <b>75</b> 点', reason: s.name);
      expect(
        s.tiers[1].effect1,
        contains('增加 <b>5%</b> 的$attr'),
        reason: s.name,
      );
      expect(
        s.tiers[3].effect1,
        contains('增加 <b>10%</b> 的$attr'),
        reason: s.name,
      );
      expect(s.tiers[3].effect2, '珍兽获得主人 <b>3%</b> 的$share加成', reason: s.name);
      expect(s.tiers[6].effect2, '珍兽获得主人 <b>24%</b> 的$share加成', reason: s.name);
    }

    // 瞬影共享的是命中 + 会心两项
    final shun = byId('shunying');
    expect(shun.tiers[0].dec, '额外给玩家增加身法 <b>10</b> 点');
    expect(shun.tiers[3].effect2, '珍兽获得主人 <b>2%</b> 的命中和 <b>2%</b> 的会心加成');
    expect(shun.tiers[6].effect2, '珍兽获得主人 <b>15%</b> 的命中和 <b>15%</b> 的会心加成');
  });

  test('咒类 4 只：释放加自身属性攻，主人减抗下限 +1/2/4/8', () {
    const cases = {
      'hanbingzhou': '冰',
      'liehuozhou': '火',
      'xueduzhou': '毒',
      'xuanleizhou': '玄',
    };
    for (final e in cases.entries) {
      final s = byId(e.key);
      final el = e.value;
      expect(
        s.tiers[0].dec,
        '释放时，珍兽自身获得 <b>100</b> 点$el攻击，持续 <b>5 秒</b>',
        reason: s.name,
      );
      expect(s.tiers[1].dec, contains('<b>200</b> 点$el攻击'), reason: s.name);
      expect(s.tiers[2].dec, contains('<b>500</b> 点$el攻击'), reason: s.name);
      expect(s.tiers[3].dec, contains('<b>750</b> 点$el攻击'), reason: s.name);
      expect(
        s.tiers[1].effect1,
        contains('主人$el攻增加 <b>200</b> 点，减$el抗增加 <b>20</b> 点'),
        reason: s.name,
      );
      expect(
        s.tiers[3].effect1,
        contains('主人$el攻增加 <b>400</b> 点，减$el抗增加 <b>40</b> 点'),
        reason: s.name,
      );
      const lower = [1, 2, 4, 8];
      for (var i = 0; i < 4; i++) {
        expect(
          s.tiers[3 + i].effect2,
          contains('主人减$el抗下限增加 <b>${lower[i]}</b> 点'),
          reason: s.name,
        );
      }
    }
  });

  test('魂类 4 只：所有属性 +4/8/20/40，甲状态反伤 100/200/400/800', () {
    const cases = {
      'binghun': ('冰', '冰甲', '减速 <b>65%</b>，持续 <b>3 秒</b>'),
      'huohun': ('火', '火甲', '灼烧'),
      'duhun': ('毒', '毒甲', '虚弱'),
      'xuanhun': ('玄', '玄甲', '玄门大开，会心防御降低 <b>25%</b>'),
    };
    for (final e in cases.entries) {
      final s = byId(e.key);
      final (el, armor, tail) = e.value;
      expect(s.tiers[0].dec, '所有属性增加 <b>4</b> 点', reason: s.name);
      expect(s.tiers[1].dec, '所有属性增加 <b>8</b> 点', reason: s.name);
      expect(s.tiers[2].dec, '所有属性增加 <b>20</b> 点', reason: s.name);
      expect(s.tiers[3].dec, '所有属性增加 <b>40</b> 点', reason: s.name);
      expect(
        s.tiers[1].effect1,
        contains('使主人$el抗增加 <b>20</b> 点，所有属性增加 <b>40</b> 点'),
        reason: s.name,
      );
      expect(
        s.tiers[3].effect1,
        contains('使主人$el抗增加 <b>40</b> 点，所有属性增加 <b>80</b> 点'),
        reason: s.name,
      );
      const dmg = [100, 200, 400, 800];
      const pct = [2, 5, 9, 15];
      for (var i = 0; i < 4; i++) {
        final fx = s.tiers[3 + i].effect2;
        expect(fx, contains('主人获得<b>$armor</b>状态'), reason: s.name);
        expect(fx, contains('造成 <b>${dmg[i]}</b> 点$el属性伤害'), reason: s.name);
        expect(fx, contains('有 <b>${pct[i]}%</b> 概率'), reason: s.name);
        expect(fx, contains(tail), reason: s.name);
      }
    }
  });

  test('法魂 / 蛮力：内·外功额外增加 + 控制效果', () {
    const cases = {
      'fahun': ('内功', '激荡目标灵魂，使其陷入昏睡，持续 <b>0.6 秒</b>', [2, 5, 9, 15]),
      'manli': ('外功', '抵住对方肉身，使其定身，持续 <b>2 秒</b>', [3, 6, 12, 24]),
    };
    for (final e in cases.entries) {
      final s = byId(e.key);
      final (stat, ctrl, chance) = e.value;
      expect(s.tiers[0].dec, '$stat额外增加 <b>2%</b>', reason: s.name);
      expect(s.tiers[1].dec, '$stat额外增加 <b>4%</b>', reason: s.name);
      expect(s.tiers[2].dec, '$stat额外增加 <b>10%</b>', reason: s.name);
      expect(s.tiers[3].dec, '$stat额外增加 <b>15%</b>', reason: s.name);
      expect(
        s.tiers[1].effect1,
        contains('$stat伤害增加 <b>8%</b>'),
        reason: s.name,
      );
      expect(
        s.tiers[3].effect1,
        contains('$stat伤害增加 <b>16%</b>'),
        reason: s.name,
      );
      for (final i in [0, 1, 2]) {
        expect(s.tiers[i].effect2, '<i>10 级解锁</i>', reason: s.name);
      }
      for (var i = 0; i < 4; i++) {
        expect(
          s.tiers[3 + i].effect2,
          contains('有 <b>${chance[i]}%</b> 概率$ctrl'),
          reason: s.name,
        );
      }
    }
  });

  test('反击 / 反震 / 灵动：触发型强化', () {
    final fanji = byId('fanji');
    expect(fanji.tiers[0].dec, '触发反击的概率增加 <b>2%</b>');
    expect(fanji.tiers[3].dec, '触发反击的概率增加 <b>15%</b>');
    expect(fanji.tiers[1].effect1, contains('<b>7%</b> 概率反击对方'));
    expect(fanji.tiers[3].effect1, contains('<b>15%</b> 概率反击对方'));
    expect(fanji.tiers[3].effect2, '珍兽和主人反击目标造成的伤害提高 <b>4%</b>');
    expect(fanji.tiers[6].effect2, '珍兽和主人反击目标造成的伤害提高 <b>30%</b>');

    final fanzhen = byId('fanzhen');
    expect(fanzhen.tiers[0].dec, '触发反震的概率增加 <b>2%</b>');
    expect(
      fanzhen.tiers[3].effect1,
      contains('<b>20%</b> 概率反弹所受伤害的 <b>50%</b>'),
    );
    const fz = [2, 5, 9, 15];
    for (var i = 0; i < 4; i++) {
      expect(
        fanzhen.tiers[3 + i].effect2,
        contains('有 <b>${fz[i]}%</b> 概率解除麻痹、失明、散功、封穴、封印中的 1 个效果'),
      );
    }

    final ling = byId('lingdong');
    expect(ling.tiers[0].dec, '将最终受到伤害的 <b>10%</b> 暂时减免，平摊到后续的 <b>5 秒</b>内扣除');
    expect(ling.tiers[2].dec, contains('<b>50%</b>'));
    expect(ling.tiers[6].dec, contains('<b>75%</b>'));
    expect(ling.tiers[1].effect1, contains('<b>10%</b> 概率减少所受伤害的 <b>35%</b>'));
    expect(ling.tiers[3].effect1, contains('<b>20%</b> 概率减少所受伤害的 <b>35%</b>'));
    const ld = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        ling.tiers[3 + i].effect2,
        contains('若主人血量低于 <b>25%</b>，则闪避率增加 <b>${ld[i]}%</b>'),
      );
    }
  });

  test('吸气 / 打怒：吸蓝与打怒', () {
    final xi = byId('xiqi');
    const qi = [200, 400, 1000, 1500, 1500, 1500, 1500];
    for (var i = 0; i < 7; i++) {
      expect(xi.tiers[i].dec, contains('每次额外打掉目标 <b>${qi[i]}</b> 点的气'));
    }
    expect(xi.tiers[1].effect1, contains('会打掉目标 <b>5%</b> 所受伤害的气量'));
    expect(xi.tiers[3].effect1, contains('会打掉目标 <b>10%</b> 所受伤害的气量'));
    const xq = ['0.5', '1', '2', '4'];
    for (var i = 0; i < 4; i++) {
      expect(xi.tiers[3 + i].effect2, contains('自身气上限 <b>${xq[i]}%</b> 的气量'));
    }
    expect(xi.tiers[3].effect2, contains('周围 <b>10 米</b>范围内最多 <b>3 个</b>敌对目标'));
    expect(xi.tiers[3].effect2, contains('按各 <b>50%</b> 转化为自身的血和气'));

    final da = byId('danu');
    const nu = [4, 8, 20, 30, 30, 30, 30];
    for (var i = 0; i < 7; i++) {
      expect(
        da.tiers[i].dec,
        contains('有 <b>${nu[i]}%</b> 概率使目标无法恢复怒气，持续 <b>5 秒</b>'),
      );
    }
    expect(da.tiers[1].effect1, contains('打掉目标 <b>20</b> 点怒气'));
    expect(da.tiers[3].effect1, contains('打掉目标 <b>40</b> 点怒气'));
    const dnu = [40, 100, 180, 300];
    for (var i = 0; i < 4; i++) {
      expect(
        da.tiers[3 + i].effect2,
        contains('最多 <b>6 个</b>目标打掉 <b>${dnu[i]}</b> 点怒气'),
      );
    }
  });

  test('忠心 / 灵气：会心防护与解控', () {
    final zhong = byId('zhongxin');
    const dec = [1, 2, 5, 7, 7, 7, 7];
    for (var i = 0; i < 7; i++) {
      expect(zhong.tiers[i].dec, '使主人受到的会心伤害降低 <b>${dec[i]}%</b>');
    }
    expect(zhong.tiers[1].effect1, contains('会心最终伤害降低 <b>10%</b>'));
    expect(zhong.tiers[3].effect1, contains('会心最终伤害降低 <b>20%</b>'));
    const bear = [6, 15, 27, 45];
    for (var i = 0; i < 4; i++) {
      expect(
        zhong.tiers[3 + i].effect2,
        contains('有 <b>${bear[i]}%</b> 概率由珍兽承担'),
      );
    }
    expect(zhong.tiers[3].effect2, contains('若主人血量低于 <b>50%</b>'));
    expect(zhong.tiers[3].effect2, contains('珍兽固定损失血上限 <b>5%</b> 的血量'));

    final ling = byId('lingqi');
    const grid = [4, 8, 20, 30, 30, 30, 30];
    for (var i = 0; i < 7; i++) {
      expect(
        ling.tiers[i].dec,
        contains('有 <b>${grid[i]}%</b> 概率给主人一个 <b>25%</b> 加速效果，持续 <b>3 秒</b>'),
      );
    }
    expect(ling.tiers[1].effect1, contains('持续时间减少 <b>20%</b>'));
    expect(ling.tiers[3].effect1, contains('持续时间减少 <b>40%</b>'));
    const reduce = [4, 10, 18, 30];
    const immune = [1, 2, 4, 8];
    for (var i = 0; i < 4; i++) {
      expect(
        ling.tiers[3 + i].effect2,
        contains('持续时间减少 <b>${reduce[i]}%</b>'),
      );
      expect(
        ling.tiers[3 + i].effect2,
        contains('有 <b>${immune[i]}%</b> 概率获得一个状态'),
      );
    }
  });

  test('猛击 / 痛击 / 识破：破防与弱点', () {
    const conv = [10, 25, 50, 100];
    const crit = ['0.4', '1', '1.8', '3'];

    final meng = byId('mengji');
    const wai = [6, 12, 30, 45, 45, 45, 45];
    for (var i = 0; i < 7; i++) {
      expect(
        meng.tiers[i].dec,
        contains('无视对方 <b>${wai[i]}%</b> 外防的状态，持续 <b>5 秒</b>'),
      );
    }
    expect(meng.tiers[1].effect1, contains('外功伤害增加 <b>15%</b>'));
    expect(meng.tiers[3].effect1, contains('外功伤害增加 <b>30%</b>'));
    for (var i = 0; i < 4; i++) {
      expect(
        meng.tiers[3 + i].effect2,
        contains('内功攻击 <b>${conv[i]}%</b> 转化为外功攻击'),
      );
      expect(
        meng.tiers[3 + i].effect2,
        contains('增加 <b>${crit[i]}%</b> 的会心一击率'),
      );
    }

    final tong = byId('tongji');
    const nei = [4, 8, 20, 30, 30, 30, 30];
    for (var i = 0; i < 7; i++) {
      expect(
        tong.tiers[i].dec,
        contains('无视对方 <b>${nei[i]}%</b> 内防的状态，持续 <b>5 秒</b>'),
      );
    }
    expect(tong.tiers[1].effect1, contains('内功伤害增加 <b>15%</b>'));
    expect(tong.tiers[3].effect1, contains('内功伤害增加 <b>30%</b>'));
    for (var i = 0; i < 4; i++) {
      expect(
        tong.tiers[3 + i].effect2,
        contains('外功攻击 <b>${conv[i]}%</b> 转化为内功攻击'),
      );
      expect(
        tong.tiers[3 + i].effect2,
        contains('增加 <b>${crit[i]}%</b> 的会心一击率'),
      );
    }

    final shi = byId('shipo');
    const hid = [2, 4, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(
        shi.tiers[i].dec,
        contains('有 <b>${hid[i]}%</b> 概率使目标无法隐身，持续 <b>5 秒</b>'),
      );
    }
    expect(shi.tiers[1].effect1, contains('造成的伤害提高 <b>10%</b>'));
    expect(shi.tiers[3].effect1, contains('造成的伤害提高 <b>20%</b>'));
    const wk = ['4', '10', '18', '30'];
    const rng = ['102%-106%', '105%-115%', '109%-127%', '115%-145%'];
    for (var i = 0; i < 4; i++) {
      expect(
        shi.tiers[3 + i].effect2,
        contains('有 <b>${wk[i]}%</b> 概率对目标造成 <b>${rng[i]}</b> 的伤害'),
      );
    }
  });

  test('虚弱 / 破绽 / 摔绊 / 连击：削弱与控制', () {
    const rate = [8, 16, 40, 60, 60, 60, 60];
    const cut = [8, 20, 36, 60];

    final xu = byId('xuruo');
    for (var i = 0; i < 7; i++) {
      expect(
        xu.tiers[i].dec,
        contains('有 <b>${rate[i]}%</b> 概率使自身和主人减免 <b>35%</b> 内外功伤害'),
      );
    }
    expect(xu.tiers[1].effect1, contains('使目标内外功降低 <b>3500</b> 点'));
    expect(xu.tiers[3].effect1, contains('使目标内外功降低 <b>7000</b> 点'));
    for (var i = 0; i < 4; i++) {
      expect(
        xu.tiers[3 + i].effect2,
        contains('使其内外功降低 <b>${cut[i]}%</b>，持续 <b>10 秒</b>'),
      );
    }

    final po = byId('pozhan');
    for (var i = 0; i < 7; i++) {
      expect(
        po.tiers[i].dec,
        contains('有 <b>${rate[i]}%</b> 概率使目标减少 <b>20%</b> 内外防'),
      );
    }
    expect(po.tiers[1].effect1, contains('使目标内外防降低 <b>3500</b> 点'));
    expect(po.tiers[3].effect1, contains('使目标内外防降低 <b>7000</b> 点'));
    for (var i = 0; i < 4; i++) {
      expect(
        po.tiers[3 + i].effect2,
        contains('使其内外防降低 <b>${cut[i]}%</b>，持续 <b>10 秒</b>'),
      );
    }

    final shuai = byId('shuaiban');
    const sd = [6, 12, 30, 45, 45, 45, 45];
    for (var i = 0; i < 7; i++) {
      expect(shuai.tiers[i].dec, '摔绊触发时，有 <b>${sd[i]}%</b> 概率定身目标 <b>3 秒</b>');
    }
    expect(
      shuai.tiers[1].effect1,
      contains('有 <b>10%</b> 概率使目标移动速度减慢 <b>50%</b>'),
    );
    expect(
      shuai.tiers[3].effect1,
      contains('有 <b>20%</b> 概率使目标移动速度减慢 <b>50%</b>'),
    );
    const bind = [1, 2, 4, 8];
    for (var i = 0; i < 4; i++) {
      expect(
        shuai.tiers[3 + i].effect2,
        contains('上一个定身状态，持续 <b>${bind[i]} 秒</b>'),
      );
    }

    final lian = byId('lianji');
    expect(
      lian.tiers[0].dec,
      '触发连击时，有 <b>2%</b> 概率触发第三次伤害，同时第三次伤害触发时，有 <b>2%</b> 概率触发第四次伤害',
    );
    expect(lian.tiers[2].dec, contains('有 <b>10%</b> 概率触发第三次伤害'));
    expect(lian.tiers[2].dec, contains('有 <b>8%</b> 概率触发第四次伤害'));
    expect(lian.tiers[6].dec, contains('有 <b>15%</b> 概率触发第三次伤害'));
    expect(lian.tiers[1].effect1, contains('有 <b>5%</b> 概率额外造成 1 次伤害'));
    expect(lian.tiers[3].effect1, contains('有 <b>10%</b> 概率额外造成 1 次伤害'));
    const rage = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        lian.tiers[3 + i].effect2,
        contains('有 <b>${rage[i]}%</b> 概率额外造成 1 次会心一击伤害'),
      );
    }
  });

  test('手动 · 群攻四兄弟：元素攻 + 减抗，怒意二阶 2/2/3 次伤害', () {
    const cases = {
      'jibingningsha': '冰',
      'jiehuofensha': '火',
      'fudushisha': '毒',
      'xuanleijisha': '玄',
    };
    const atk = [200, 400, 1000, 1500, 1500, 1500, 1500];
    const red = [10, 20, 50, 75, 75, 75, 75];
    for (final e in cases.entries) {
      final s = byId(e.key);
      final el = e.value;
      for (var i = 0; i < 7; i++) {
        expect(
          s.tiers[i].dec,
          '释放时，珍兽自身获得 <b>${atk[i]}</b> 点$el攻击和 <b>${red[i]}</b> 点减$el抗，持续 <b>5 秒</b>',
          reason: s.name,
        );
      }
      expect(s.tiers[0].effect1, '<i>4 级解锁</i>', reason: s.name);
      expect(s.tiers[1].effect1, contains('造成 <b>2</b> 次伤害'), reason: s.name);
      expect(s.tiers[2].effect1, contains('造成 <b>2</b> 次伤害'), reason: s.name);
      expect(s.tiers[3].effect1, contains('造成 <b>3</b> 次伤害'), reason: s.name);
      for (final i in [0, 1, 2]) {
        expect(s.tiers[i].effect2, '<i>10 级解锁</i>', reason: s.name);
      }
    }
    // 效果二各自不同
    expect(
      byId('jibingningsha').tiers[3].effect2,
      contains('冷却时间增加 <b>1 秒</b>'),
    );
    expect(
      byId('jibingningsha').tiers[6].effect2,
      contains('冷却时间增加 <b>8 秒</b>'),
    );
    expect(
      byId('jiehuofensha').tiers[6].effect2,
      contains('珍兽主人 <b>80%</b> 的普通攻击伤害'),
    );
    expect(
      byId('fudushisha').tiers[6].effect2,
      contains('非会心一击伤害增加 <b>15%</b>，会心一击伤害增加 <b>40%</b>'),
    );
    const thunder = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        byId('xuanleijisha').tiers[3 + i].effect2,
        contains('有 <b>${thunder[i]}%</b> 概率'),
      );
    }
  });

  test('手动 · 减抗四兄弟：8/16/40/60 点减抗，共享主人减抗并清冷却', () {
    const cases = {
      'bingtianxuedi': '冰',
      'liehuoliaoyuan': '火',
      'xueduwanli': '毒',
      'wuleihongding': '玄',
    };
    const red = [8, 16, 40, 60, 60, 60, 60];
    const share = [10, 20, 40, 80];
    const cd = [1, 2, 4, 8];
    for (final e in cases.entries) {
      final s = byId(e.key);
      final el = e.value;
      for (var i = 0; i < 7; i++) {
        expect(
          s.tiers[i].dec,
          '释放时，珍兽自身获得 <b>${red[i]}</b> 点减$el抗，持续 <b>5 秒</b>',
          reason: s.name,
        );
      }
      expect(
        s.tiers[1].effect1,
        contains('珍兽$el攻击增加 <b>400</b> 点，持续 <b>8 秒</b>'),
        reason: s.name,
      );
      expect(
        s.tiers[3].effect1,
        contains('珍兽$el攻击增加 <b>800</b> 点'),
        reason: s.name,
      );
      for (var i = 0; i < 4; i++) {
        expect(
          s.tiers[3 + i].effect2,
          contains('能获得主人 <b>${share[i]}%</b> 的减$el抗'),
          reason: s.name,
        );
        expect(
          s.tiers[3 + i].effect2,
          contains('有 <b>${cd[i]}%</b> 概率清除${s.name}的冷却时间'),
          reason: s.name,
        );
      }
    }
  });

  test('手动 · 免控六兄弟：免疫 0.6/1.2/3/4.5 秒 + 反制同类控制', () {
    const cases = {
      'jiexue': ('封穴', ['0.2', '0.5', '0.9', '1.5']),
      'qingxing': ('昏睡', ['0.4', '1', '1.8', '3']),
      'mingmu': ('失明', ['0.2', '0.5', '0.9', '1.5']),
      'qingling': ('僵硬', ['0.2', '0.5', '0.9', '1.5']),
      'guyuan': ('散功', ['0.2', '0.5', '0.9', '1.5']),
      'satuo': ('定身', ['0.2', '0.5', '0.9', '1.5']),
    };
    const immune = ['0.6', '1.2', '3', '4.5', '4.5', '4.5', '4.5'];
    const chance = [2, 2, 4, 4, 4, 4];
    for (final e in cases.entries) {
      final s = byId(e.key);
      final (ctrl, back) = e.value;
      for (var i = 0; i < 7; i++) {
        expect(
          s.tiers[i].dec,
          '并免疫$ctrl <b>${immune[i]} 秒</b>',
          reason: s.name,
        );
      }
      expect(s.tiers[0].effect1, '<i>4 级解锁</i>', reason: s.name);
      for (var i = 0; i < 6; i++) {
        expect(
          s.tiers[1 + i].effect1,
          contains('有 <b>${chance[i]}%</b> 的概率使主人获得免疫控制效果，持续 <b>5 秒</b>'),
          reason: s.name,
        );
      }
      for (var i = 0; i < 4; i++) {
        expect(
          s.tiers[3 + i].effect2,
          contains('则会对主人当前目标进行$ctrl，持续 <b>${back[i]} 秒</b>'),
          reason: s.name,
        );
      }
    }
  });

  test('手动 · 生存回复系：灵狐之息 / 同护 / 重生 / 共生 / 治疗 / 肉墙 / 神佑 / 血祭 / 净化', () {
    final ling = byId('linghuzhixi');
    const dmg = [1, 2, 4, 10, 10, 10, 10];
    for (var i = 0; i < 7; i++) {
      expect(ling.tiers[i].dec, '状态持续期间，珍兽造成的伤害增加 <b>${dmg[i]}%</b>');
    }
    expect(ling.tiers[1].effect1, contains('使珍兽受到的伤害减少 <b>30%</b>'));
    expect(ling.tiers[1].effect1, contains('恢复伤害量 <b>5%</b> 的血量'));
    expect(ling.tiers[3].effect1, contains('恢复伤害量 <b>10%</b> 的血量'));
    const extend = [1, 2, 3, 4];
    for (var i = 0; i < 4; i++) {
      expect(
        ling.tiers[3 + i].effect2,
        contains('使状态增加 <b>${extend[i]} 秒</b>，最多增加 <b>20 秒</b>'),
      );
    }

    final tong = byId('tonghu');
    const imm = [2, 4, 8, 20, 20, 20, 20];
    for (var i = 0; i < 7; i++) {
      expect(tong.tiers[i].dec, '护盾持续期间，有 <b>${imm[i]}%</b> 概率免疫部分控制技能');
    }
    expect(tong.tiers[1].effect1, contains('附带 <b>5%</b> 珍兽血上限的伤害'));
    expect(tong.tiers[3].effect1, contains('附带 <b>10%</b> 珍兽血上限的伤害'));
    const shield = [15, 20, 25, 30];
    for (var i = 0; i < 4; i++) {
      expect(tong.tiers[3 + i].effect2, '额外获得珍兽血上限 <b>${shield[i]}%</b> 的护盾');
    }

    final chong = byId('chongsheng');
    const dur = [20, 40, 100, 150, 150, 150, 150];
    for (var i = 0; i < 7; i++) {
      expect(chong.tiers[i].dec, '重生状态持续时间增加 <b>${dur[i]} 秒</b>');
    }
    expect(chong.tiers[1].effect1, contains('珍兽获得 <b>7%</b> 减伤'));
    expect(chong.tiers[3].effect1, contains('珍兽获得 <b>15%</b> 减伤'));
    const again = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        chong.tiers[3 + i].effect2,
        '重生时，有 <b>${again[i]}%</b> 概率再次获得重生状态',
      );
    }

    final gong = byId('gongsheng');
    const heal = [2, 4, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(
        gong.tiers[i].dec,
        '额外使主人每秒恢复珍兽牺牲血量 <b>${heal[i]}%</b> 的血量，持续 <b>5 秒</b>',
      );
    }
    expect(gong.tiers[1].effect1, contains('有 <b>10%</b> 概率恢复双倍血量'));
    expect(gong.tiers[3].effect1, contains('有 <b>20%</b> 概率恢复双倍血量'));
    const guard = [2, 5, 9, 15];
    for (var i = 0; i < 4; i++) {
      expect(
        gong.tiers[3 + i].effect2,
        contains('则珍兽最低降低到 <b>1 点</b>血，不会死亡，持续 <b>${guard[i]} 秒</b>'),
      );
    }

    final zhi = byId('zhiliao');
    const cap = [4, 8, 20, 30, 30, 30, 30];
    for (var i = 0; i < 7; i++) {
      expect(zhi.tiers[i].dec, '额外恢复珍兽血上限 <b>${cap[i]}%</b> 的血量');
    }
    expect(zhi.tiers[1].effect1, contains('每秒恢复珍兽 <b>10%</b> 血量'));
    expect(zhi.tiers[3].effect1, contains('每秒恢复珍兽 <b>20%</b> 血量'));
    const owner = ['0.75', '1.5', '3', '6'];
    for (var i = 0; i < 4; i++) {
      expect(
        zhi.tiers[3 + i].effect2,
        contains('按照珍兽血上限 <b>${owner[i]}%</b> 的血量恢复主人血量'),
      );
    }

    final rou = byId('rouqiang');
    const cut = [2, 4, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(rou.tiers[i].dec, '开启肉墙后，珍兽替主人承担伤害时，受到的伤害降低 <b>${cut[i]}%</b>');
    }
    expect(rou.tiers[1].effect1, contains('有 <b>5%</b> 概率给主人恢复此次伤害相同的血量'));
    expect(rou.tiers[3].effect1, contains('有 <b>10%</b> 概率给主人恢复此次伤害相同的血量'));
    const def = [5, 10, 20, 40];
    for (var i = 0; i < 4; i++) {
      expect(rou.tiers[3 + i].effect2, contains('会心防御增加 <b>${def[i]}%</b>'));
    }

    final shen = byId('shenyou');
    const inv = ['1.2', '1.6', '2.8', '4', '4', '4', '4'];
    for (var i = 0; i < 7; i++) {
      expect(shen.tiers[i].dec, contains('持续 <b>${inv[i]} 秒</b>'));
    }
    expect(shen.tiers[1].effect1, contains('都有 <b>15%</b> 概率恢复主人血量'));
    expect(shen.tiers[3].effect1, contains('都有 <b>30%</b> 概率恢复主人血量'));
    const team = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        shen.tiers[3 + i].effect2,
        contains('有 <b>${team[i]}%</b> 概率给主人 <b>10 米</b>范围内的小队成员'),
      );
    }

    final xue = byId('xueji');
    const ji = [2, 4, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(xue.tiers[i].dec, '有 <b>${ji[i]}%</b> 概率使主人恢复气量一半的血量');
    }
    expect(xue.tiers[1].effect1, contains('有 <b>20%</b> 概率回血翻倍'));
    expect(xue.tiers[3].effect1, contains('有 <b>40%</b> 概率回血翻倍'));
    const add = [2, 5, 9, 15];
    for (var i = 0; i < 4; i++) {
      expect(
        xue.tiers[3 + i].effect2,
        contains('有 <b>${add[i]}%</b> 概率给主人释放一个持续 <b>8 秒</b>的状态'),
      );
    }

    final jing = byId('jinghua');
    const dispel = [6, 12, 30, 45, 45, 45, 45];
    for (var i = 0; i < 7; i++) {
      expect(
        jing.tiers[i].dec,
        '有 <b>${dispel[i]}%</b> 概率额外驱散主人身上 1 个不良效果并恢复主人 <b>10%</b> 血量',
      );
    }
    expect(jing.tiers[1].effect1, contains('有 <b>7%</b> 概率免疫不良效果'));
    expect(jing.tiers[3].effect1, contains('有 <b>15%</b> 概率免疫不良效果'));
    const clear = [2, 5, 9, 15];
    for (var i = 0; i < 4; i++) {
      expect(
        jing.tiers[3 + i].effect2,
        contains('有 <b>${clear[i]}%</b> 概率清除所有不良效果'),
      );
    }
  });

  test('手动 · 输出与特殊：血爆 / 冰爆 / 嗜血 / 咆哮 / 伪装 / 附身', () {
    final xuebao = byId('xuebao');
    const cost = [2, 4, 8, 10, 10, 10, 10];
    for (var i = 0; i < 7; i++) {
      expect(xuebao.tiers[i].dec, contains('消耗珍兽 <b>${cost[i]}%</b> 当前血量'));
    }
    expect(xuebao.tiers[1].effect1, contains('范围增加至 <b>8 米</b>'));
    expect(xuebao.tiers[3].effect1, contains('范围增加至 <b>10 米</b>'));
    const extra = [6, 15, 27, 45];
    for (var i = 0; i < 4; i++) {
      expect(
        xuebao.tiers[3 + i].effect2,
        contains('额外消耗珍兽 <b>${extra[i]}%</b> 当前血量'),
      );
    }
    expect(xuebao.tiers[3].effect2, contains('主人受到伤害的 <b>60%</b> 由护盾承担'));

    final bingbao = byId('bingbao');
    const slow = [15, 25, 45, 60, 60, 60, 60];
    for (var i = 0; i < 7; i++) {
      expect(
        bingbao.tiers[i].dec,
        '结束后给目标一个 <b>${slow[i]}%</b> 的减速，持续 <b>5 秒</b>',
      );
    }
    expect(bingbao.tiers[1].effect1, contains('移动速度增加 <b>15%</b>'));
    expect(bingbao.tiers[3].effect1, contains('移动速度增加 <b>30%</b>'));
    const frozen = [2, 3, 4, 6];
    for (var i = 0; i < 4; i++) {
      expect(
        bingbao.tiers[3 + i].effect2,
        contains('减速修改为冰封，持续 <b>${frozen[i]} 秒</b>'),
      );
    }

    final shi = byId('shixue');
    const both = [2, 4, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(shi.tiers[i].dec, '珍兽受到的伤害和造成的伤害都提高 <b>${both[i]}%</b>');
    }
    expect(shi.tiers[1].effect1, contains('额外获得主人 <b>15%</b> 的外功攻击'));
    expect(shi.tiers[3].effect1, contains('额外获得主人 <b>30%</b> 的外功攻击'));
    const chase = [30, 50, 60, 70];
    for (var i = 0; i < 4; i++) {
      expect(
        shi.tiers[3 + i].effect2,
        contains('附加上一次伤害的 <b>${chase[i]}%</b> 伤害'),
      );
    }

    final pao = byId('paoxiao');
    const dot = [3, 5, 10, 15, 15, 15, 15];
    for (var i = 0; i < 7; i++) {
      expect(
        pao.tiers[i].dec,
        '对击中的目标造成惊恐效果，每秒掉血 <b>100</b> 点，持续 <b>${dot[i]} 秒</b>',
      );
    }
    expect(
      pao.tiers[1].effect1,
      contains('有 <b>10%</b> 概率使目标惊恐，失明 <b>1 秒</b>'),
    );
    expect(
      pao.tiers[3].effect1,
      contains('有 <b>20%</b> 概率使目标惊恐，失明 <b>1 秒</b>'),
    );
    const pull = [2, 5, 9, 15];
    for (var i = 0; i < 4; i++) {
      final fx = pao.tiers[3 + i].effect2;
      expect(fx, contains('有 <b>${pull[i]}%</b> 概率将目标往主人方向拉近 <b>5 米</b>'));
      expect(fx, contains('有 <b>${pull[i]}%</b> 概率将目标往主人相反方向拉远 <b>5 米</b>'));
    }

    final wei = byId('weizhuang');
    const hide = ['2.3', '2.9', '4.4', '6', '6', '6', '6'];
    for (var i = 0; i < 7; i++) {
      expect(wei.tiers[i].dec, '首次受到伤害时，可继续隐身 <b>${hide[i]} 秒</b>，中间受到伤害仍可隐身');
    }
    expect(wei.tiers[1].effect1, contains('移动速度降低 <b>50%</b>，持续 <b>2 秒</b>'));
    expect(wei.tiers[3].effect1, contains('移动速度降低 <b>50%</b>，持续 <b>5 秒</b>'));
    const fake = [4, 10, 18, 30];
    for (var i = 0; i < 4; i++) {
      expect(
        wei.tiers[3 + i].effect2,
        contains('有 <b>${fake[i]}%</b> 概率给主人伪装'),
      );
    }

    final fu = byId('fushen');
    const nu = [10, 20, 50, 75, 75, 75, 75];
    const qi = ['0.2', '0.4', '1', '1.5', '1.5', '1.5', '1.5'];
    for (var i = 0; i < 7; i++) {
      expect(
        fu.tiers[i].dec,
        '附身 <b>3 秒</b>后，每 <b>2 秒</b>扣除目标 <b>${nu[i]}</b> 点怒气和珍兽血上限 <b>${qi[i]}%</b> 的气量',
      );
    }
    expect(fu.tiers[1].effect1, contains('会眩晕 <b>0.5 秒</b>'));
    expect(fu.tiers[3].effect1, contains('会眩晕 <b>1 秒</b>'));
    const ctrl = [8, 20, 36, 60];
    for (var i = 0; i < 4; i++) {
      expect(fu.tiers[3 + i].effect2, contains('有 <b>${ctrl[i]}%</b> 概率操控目标'));
    }
  });

  test('图鉴说明文案：数据来源与触发差异', () {
    expect(kBeastIndexIntroNote, contains('<b>20 级 · 7 阶</b>'));
    expect(kBeastIndexIntroNote, contains('效果一 4 级解锁、效果二 10 级解锁'));
    expect(kBeastIndexIntroNote, contains('被动技能在珍兽进入<b>怒意三阶</b>抽取到该技能时触发'));
    expect(kBeastIndexIntroNote, contains('手动技能在珍兽进入<b>怒意二阶</b>释放该技能时触发'));
    expect(kBeastIndexIntroNote, contains('「兽灵被动技能 / 兽灵手动技能」'));
    expect(kBeastIndexFootNote, startsWith('※ 共 68 只兽灵（被动 39 · 手动 29）'));
  });
}
