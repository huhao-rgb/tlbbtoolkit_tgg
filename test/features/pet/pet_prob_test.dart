import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/pet/domain/pet_prob.dart';

void main() {
  group('技能释放概率 —— 与 UI 原型一致', () {
    PetChar char(String key) => kPetChars.firstWhere((c) => c.key == key);

    test('通用性格：基准值即概率，条宽 = round(p*3.3)', () {
      final ch = char('general');
      // 猛击 20 / 连击 15 / 痛击 12 / 寒冰咒 10 / 虚弱 8 / 迟缓 6 / 护主 100
      final cases = <(String, int, int)>[
        ('猛击', 20, 66),
        ('连击', 15, 50),
        ('痛击', 12, 40),
        ('寒冰咒', 10, 33),
        ('烈火咒', 10, 33),
        ('虚弱', 8, 26),
        ('打怒', 8, 26),
        ('迟缓', 6, 20),
        ('吸血', 6, 20),
        ('护主', 100, 100),
      ];
      for (final (name, p, w) in cases) {
        final skill = kPetSkills.firstWhere((s) => s.name == name);
        expect(petProbOf(skill, ch), p, reason: '$name 概率');
        expect(petProbBarWidth(p), w, reason: '$name 条宽');
      }
    });

    test('勇猛性格：攻击类 ×1.3', () {
      final ch = char('yongmeng');
      final mengji = kPetSkills.firstWhere((s) => s.name == '猛击');
      final lianji = kPetSkills.firstWhere((s) => s.name == '连击');
      expect(petProbOf(mengji, ch), 26); // 20*1.3
      expect(petProbOf(lianji, ch), 20); // 15*1.3
      // 辅助类 ×0.9
      final xixue = kPetSkills.firstWhere((s) => s.name == '吸血');
      expect(petProbOf(xixue, ch), 5); // 6*0.9 = 5.4 → 5
    });

    test('精明性格：状态类 ×1.4', () {
      final ch = char('jingming');
      final xurou = kPetSkills.firstWhere((s) => s.name == '虚弱');
      final chihuan = kPetSkills.firstWhere((s) => s.name == '迟缓');
      expect(petProbOf(xurou, ch), 11); // 8*1.4 = 11.2 → 11
      expect(petProbOf(chihuan, ch), 8); // 6*1.4 = 8.4 → 8
    });

    test('谨慎性格：辅助类 ×1.3（对状态类也 ×1.1）', () {
      final ch = char('jinshen');
      final huzhu = kPetSkills.firstWhere((s) => s.name == '护主');
      final chihuan = kPetSkills.firstWhere((s) => s.name == '迟缓');
      expect(petProbOf(huzhu, ch), 100); // 100*1.3 → 上限 100
      expect(petProbOf(chihuan, ch), 7); // 6*1.1 = 6.6 → 7
    });

    test('忠诚性格：辅助类 ×1.5', () {
      final ch = char('zhongcheng');
      final xixue = kPetSkills.firstWhere((s) => s.name == '吸血');
      expect(petProbOf(xixue, ch), 9); // 6*1.5 = 9
      // 攻击类 ×0.85
      final mengji = kPetSkills.firstWhere((s) => s.name == '猛击');
      expect(petProbOf(mengji, ch), 17); // 20*0.85 = 17
    });

    test('内敛性格：攻击类 ×1.2', () {
      final ch = char('neilian');
      final mengji = kPetSkills.firstWhere((s) => s.name == '猛击');
      expect(petProbOf(mengji, ch), 24); // 20*1.2 = 24
    });

    test('概率上限 100%：护主 + 高系数不越界', () {
      final ch = char('zhongcheng'); // 辅助 ×1.5
      final huzhu = kPetSkills.firstWhere((s) => s.name == '护主');
      expect(petProbOf(huzhu, ch), 100);
      expect(petProbBarWidth(100), 100);
    });

    test('数据完整性：10 技能 · 7 性格 · 分类/判定齐全', () {
      expect(kPetSkills.length, 10);
      expect(kPetChars.length, 7);
      // 分类覆盖
      expect(kPetSkills.where((s) => s.cat == PetSkillCat.atk).length, 5);
      expect(kPetSkills.where((s) => s.cat == PetSkillCat.st).length, 3);
      expect(kPetSkills.where((s) => s.cat == PetSkillCat.sup).length, 2);
      // 分类 label
      expect(PetSkillCat.atk.label, '攻击类');
      expect(PetSkillCat.st.label, '状态类');
      expect(PetSkillCat.sup.label, '辅助类');
      // 所有技能都有判定
      for (final s in kPetSkills) {
        expect(s.judge, isNotEmpty, reason: '${s.name} 判定');
        expect(s.tag, isNotEmpty, reason: '${s.name} tag');
      }
    });
  });
}
