import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_prob.dart';

void main() {
  group('珍兽技能发动概率 —— 与玩家整理的概率表一致', () {
    PetChar char(String key) => kPetChars.firstWhere((c) => c.key == key);
    PetSkill skill(String name) => kPetSkills.firstWhere((s) => s.name == name);

    test('性格表：只有图片里的五种性格（无通用 / 内敛）', () {
      expect(kPetChars.map((c) => c.name).toList(), [
        '胆小',
        '谨慎',
        '忠诚',
        '精明',
        '勇猛',
      ]);
      expect(kPetChars.any((c) => c.name == '通用'), isFalse);
      expect(kPetChars.any((c) => c.name == '内敛'), isFalse);
      expect(kPetChars.any((c) => c.key == 'neilian'), isFalse);
    });

    test('系数矩阵逐格对应图片顶表（行=技能系，列=性格）', () {
      // 顺序：物攻 / 法攻 / 护主 / 防御 / 报复
      const expected = <String, List<double>>{
        '胆小': [.5, 2, .5, 1, .5],
        '谨慎': [.8, 1.3, 1.3, 2, .8],
        '忠诚': [1, 1, 2, 1, 1],
        '精明': [1.3, .8, 1, .8, 2],
        '勇猛': [2, .5, .8, .5, 1.3],
      };
      for (final entry in expected.entries) {
        final ch = char(kPetChars.firstWhere((c) => c.name == entry.key).key);
        final actual = [
          for (final family in PetSkillFamily.values) ch.factorFor(family),
        ];
        expect(actual, entry.value, reason: '${entry.key} 系数');
      }
    });

    test('基础概率与图片底部数据表一致（16 个技能）', () {
      const expected = <String, int>{
        '反击': 20,
        '高级反击': 30,
        '吸血': 20,
        '高级吸血': 30,
        '反震': 20,
        '高级反震': 30,
        '灵动': 20,
        '高级灵动': 30,
        '吸魔': 20,
        '高级吸魔': 30,
        '打怒': 20,
        '高级打怒': 30,
        '忠心': 7,
        '高级忠心': 12,
        '灵气': 15,
        '高级灵气': 25,
      };
      expect(kPetSkills.length, expected.length);
      for (final entry in expected.entries) {
        expect(skill(entry.key).base, entry.value, reason: '${entry.key} 基础概率');
      }
    });

    test('归系：报复（反击/吸血/反震）· 防御（灵动/吸魔/打怒）· 护主（忠心/灵气）', () {
      const expected = <String, PetSkillFamily>{
        '反击': PetSkillFamily.revenge,
        '高级反击': PetSkillFamily.revenge,
        '吸血': PetSkillFamily.revenge,
        '高级吸血': PetSkillFamily.revenge,
        '反震': PetSkillFamily.revenge,
        '高级反震': PetSkillFamily.revenge,
        '灵动': PetSkillFamily.defense,
        '高级灵动': PetSkillFamily.defense,
        '吸魔': PetSkillFamily.defense,
        '高级吸魔': PetSkillFamily.defense,
        '打怒': PetSkillFamily.defense,
        '高级打怒': PetSkillFamily.defense,
        '忠心': PetSkillFamily.guard,
        '高级忠心': PetSkillFamily.guard,
        '灵气': PetSkillFamily.guard,
        '高级灵气': PetSkillFamily.guard,
      };
      for (final entry in expected.entries) {
        expect(skill(entry.key).family, entry.value, reason: '${entry.key} 系别');
      }
    });

    test('图片举例：高级反击 30% → 精明（×2）= 60%、忠诚（×1）= 30%', () {
      final fanji = skill('高级反击');
      expect(petProbOf(fanji, char('jingming')), 60);
      expect(petProbOf(fanji, char('zhongcheng')), 30);
    });

    test('基础概率即技能自身的生效几率，条宽 = round(p*3.3)', () {
      final cases = <(String, int, int)>[
        ('反击', 20, 66),
        ('高级反击', 30, 99),
        ('忠心', 7, 23),
        ('高级忠心', 12, 40),
        ('灵气', 15, 50),
        ('高级灵气', 25, 83),
      ];
      for (final (name, base, w) in cases) {
        final s = skill(name);
        expect(s.base, base, reason: '$name 基础概率');
        expect(petProbBarWidth(base), w, reason: '$name 条宽');
      }
    });

    test('胆小：报复 ×0.5、防御 ×1、护主 ×0.5', () {
      final ch = char('danxiao');
      expect(petProbOf(skill('反击'), ch), 10); // 20*0.5
      expect(petProbOf(skill('高级反击'), ch), 15); // 30*0.5
      expect(petProbOf(skill('灵动'), ch), 20); // 20*1
      expect(petProbOf(skill('忠心'), ch), 4); // 7*0.5=3.5→4
      expect(petProbOf(skill('高级灵气'), ch), 13); // 25*0.5=12.5→13
    });

    test('谨慎：防御 ×2、护主 ×1.3、报复 ×0.8', () {
      final ch = char('jinshen');
      expect(petProbOf(skill('灵动'), ch), 40); // 20*2
      expect(petProbOf(skill('高级打怒'), ch), 60); // 30*2
      expect(petProbOf(skill('高级忠心'), ch), 16); // 12*1.3=15.6→16
      expect(petProbOf(skill('吸血'), ch), 16); // 20*0.8
    });

    test('忠诚：护主 ×2、报复 / 防御 ×1', () {
      final ch = char('zhongcheng');
      expect(petProbOf(skill('忠心'), ch), 14); // 7*2
      expect(petProbOf(skill('高级忠心'), ch), 24); // 12*2
      expect(petProbOf(skill('高级灵气'), ch), 50); // 25*2
      expect(petProbOf(skill('反震'), ch), 20); // 20*1
      expect(petProbOf(skill('吸魔'), ch), 20); // 20*1
    });

    test('精明：报复 ×2、防御 ×0.8、护主 ×1', () {
      final ch = char('jingming');
      expect(petProbOf(skill('吸血'), ch), 40); // 20*2
      expect(petProbOf(skill('高级吸血'), ch), 60); // 30*2
      expect(petProbOf(skill('灵动'), ch), 16); // 20*0.8
      expect(petProbOf(skill('高级吸魔'), ch), 24); // 30*0.8
      expect(petProbOf(skill('高级忠心'), ch), 12); // 12*1
    });

    test('勇猛：报复 ×1.3、防御 ×0.5、护主 ×0.8', () {
      final ch = char('yongmeng');
      expect(petProbOf(skill('反击'), ch), 26); // 20*1.3
      expect(petProbOf(skill('高级反震'), ch), 39); // 30*1.3
      expect(petProbOf(skill('打怒'), ch), 10); // 20*0.5
      expect(petProbOf(skill('忠心'), ch), 6); // 7*0.8=5.6→6
    });

    test('概率上限 100%：高基础概率 + 高系数不越界', () {
      const big = PetSkill(
        name: '测试技',
        desc: '',
        family: PetSkillFamily.revenge,
        base: 80,
        judge: '受击判定',
        icon: 'sk-fanji',
        fx: '',
      );
      expect(petProbOf(big, char('jingming')), 100); // 80*2=160 → 100
      expect(petProbBarWidth(100), 100);
    });

    test('数据完整性：16 技能 · 5 性格 · 图标/判定/文案齐全', () {
      expect(kPetSkills.length, 16);
      expect(kPetChars.length, 5);

      // 系别覆盖与计数
      expect(PetSkillFamily.values.map((f) => f.label).toList(), [
        '物攻',
        '法攻',
        '护主',
        '防御',
        '报复',
      ]);
      expect(
        kPetSkills.where((s) => s.family == PetSkillFamily.revenge).length,
        6,
      );
      expect(
        kPetSkills.where((s) => s.family == PetSkillFamily.defense).length,
        6,
      );
      expect(
        kPetSkills.where((s) => s.family == PetSkillFamily.guard).length,
        4,
      );

      for (final s in kPetSkills) {
        expect(s.judge, isNotEmpty, reason: '${s.name} 判定');
        expect(s.tag, s.family.label, reason: '${s.name} 系 tag');
        expect(s.desc, isNotEmpty, reason: '${s.name} 描述');
        expect(s.fx, isNotEmpty, reason: '${s.name} 详情');
        expect(
          File('assets/icons/${s.icon}.svg').existsSync(),
          isTrue,
          reason: '${s.name} 图标 assets/icons/${s.icon}.svg 不存在',
        );
      }

      // 系数文案：整数不带小数点
      expect(petFactorText(1), '1');
      expect(petFactorText(2), '2');
      expect(petFactorText(.5), '0.5');
      expect(petFactorText(1.3), '1.3');
    });
  });
}
