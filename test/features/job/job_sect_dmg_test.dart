import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect_info.dart';

/// 「伤害系数总表」核对表：门派 → (外功, 内功, 冰, 火, 玄, 毒)。
///
/// 数值原样照抄表格，避免转录时看错一位小数；改数据必须同步改这里。
const Map<String, List<double>> _expected = {
  'shaolin': [0.0575, 0.015, 1, 1, 1.5, 1],
  'mingjiao': [0.0575, 0.015, 1, 1.5, 1, 1],
  'gaibang': [0.0575, 0.015, 1, 1.25, 1, 1.3],
  'wudang': [0.003875, 0.07125, 1.25, 1.2, 1.1, 1],
  'emei': [0.003875, 0.07125, 1.2, 1, 1.25, 1],
  'xingxiu': [0.003875, 0.07125, 1, 1, 1, 1.5],
  'tianlong': [0.04375, 0.04375, 1.15, 1.15, 1.15, 1.15],
  'tianshan': [0.0575, 0.015, 1.5, 1, 1, 1],
  'xiaoyao': [0.003875, 0.07125, 1, 1.3, 1, 1.25],
  'mantuo': [0.003875, 0.07125, 1, 1, 1.3, 1.25],
  'erengu': [0.003875, 0.07125, 1.25, 1, 1, 1.3],
  'murong': [0.003875, 0.07125, 1, 1, 1.5, 1],
  'kunlun': [0.003875, 0.07125, 1.25, 1, 1.3, 1],
};

void main() {
  group('门派伤害系数', () {
    test('每个门派的数据与总表一致', () {
      for (final entry in _expected.entries) {
        final dmg = kJobSectInfo[entry.key]?.dmg;
        expect(dmg, isNotNull, reason: entry.key);
        final got = [
          dmg!.phys,
          dmg.magic,
          dmg.ice,
          dmg.fire,
          dmg.xuan,
          dmg.poison,
        ];
        for (var i = 0; i < got.length; i++) {
          expect(
            got[i],
            closeTo(entry.value[i], 1e-9),
            reason: '${entry.key} 第 ${i + 1} 列',
          );
        }
      }
    });

    test('十三门派全部有系数', () {
      for (final sect in kJobSects) {
        expect(kJobSectInfo[sect.key]?.dmg, isNotNull, reason: sect.name);
      }
    });

    test('四属性系数不为负、内外功系数为正', () {
      for (final info in kJobSectInfo.values) {
        final dmg = info.dmg;
        if (dmg == null) continue;
        expect(dmg.phys, greaterThan(0));
        expect(dmg.magic, greaterThan(0));
        for (final v in [dmg.ice, dmg.fire, dmg.xuan, dmg.poison]) {
          expect(v, greaterThan(0));
        }
      }
    });

    test('系数文案：整数不带小数点，其余按原值', () {
      expect(jobDmgCoefText(1), '1');
      expect(jobDmgCoefText(1.5), '1.5');
      expect(jobDmgCoefText(1.15), '1.15');
      expect(jobDmgCoefText(0.015), '0.015');
      expect(jobDmgCoefText(0.003875), '0.003875');
      expect(jobDmgCoefText(0.0575), '0.0575');
    });
  });
}
