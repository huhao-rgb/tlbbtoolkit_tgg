import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/job/domain/job_skill.dart';
import 'package:tlbbtoolkit/features/job/domain/job_skill_icons.dart';

/// 技能图标映射的完整性守卫。
///
/// 名录入错一个字，图标就会静默消失（页面是按技能名查表的），所以这里把
/// 「映射里没有死路径」和「重点门派全量覆盖」都钉成断言。
void main() {
  test('映射里的每个资源都真实存在', () {
    final missing = <String>[];
    for (final entry in kJobSkillIcons.entries) {
      if (!File(entry.value).existsSync())
        missing.add('${entry.key} → ${entry.value}');
    }
    expect(missing, isEmpty, reason: '有 ${missing.length} 条映射指向不存在的文件');
  });

  test('昆仑 24 门技能都有图标', () {
    final skills = kJobSkills['kunlun']!;
    final lacking = [
      for (final s in skills)
        if (!kJobSkillIcons.containsKey(s.name)) s.name,
    ];
    expect(lacking, isEmpty, reason: '缺图标：$lacking');
    expect(skills.length, 24);
  });

  test('曼陀山庄 24 门技能都有图标', () {
    final skills = kJobSkills['mantuo']!;
    final lacking = [
      for (final s in skills)
        if (!kJobSkillIcons.containsKey(s.name)) s.name,
    ];
    expect(lacking, isEmpty, reason: '缺图标：$lacking');
  });
}
