import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/pet_market_snapshot.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market_stats.dart';

void main() {
  group('pet_market_snapshot', () {
    test('176 条快照可解析且字段完整', () {
      final data = kPetMarketData;
      expect(data, hasLength(176));
      final first = data.first;
      expect(first.title, isNotEmpty);
      expect(first.price, greaterThan(0));
      expect(first.area, '原始一区');
      expect(first.server, isNotEmpty);
      expect(first.sn, isNotEmpty);
      expect(first.pet, isNotEmpty);
    });

    test('携带等级 = cl 优先，否则 lv', () {
      // cl 有值的样本 carryLevel == cl；无 cl 则 == lv
      for (final x in kPetMarketData) {
        expect(x.carryLevel, x.carry ?? x.lv);
      }
    });
  });

  group('pmFiltered', () {
    test('空筛选返回全部', () {
      final r = pmFiltered(kPetMarketData, const PetMarketFilter());
      expect(r, hasLength(176));
    });

    test('服务器筛选', () {
      final r = pmFiltered(
        kPetMarketData,
        const PetMarketFilter(server: '少年游'),
      );
      expect(r, isNotEmpty);
      expect(r.every((x) => x.server == '少年游'), isTrue);
    });

    test('携带等级档位：65 级档只保留 band==p65', () {
      final r = pmFiltered(
        kPetMarketData,
        const PetMarketFilter(carryBand: PetCarryBand.p65),
      );
      expect(r.every((x) => x.band == PetCarryBand.p65), isTrue);
    });

    test('携带等级档位：95 级档只保留 band==p95', () {
      final r = pmFiltered(
        kPetMarketData,
        const PetMarketFilter(carryBand: PetCarryBand.p95),
      );
      expect(r.every((x) => x.band == PetCarryBand.p95), isTrue);
    });

    test('携带等级档位：其他等级档只保留 band==other', () {
      final r = pmFiltered(
        kPetMarketData,
        const PetMarketFilter(carryBand: PetCarryBand.other),
      );
      expect(r.every((x) => x.band == PetCarryBand.other), isTrue);
    });
  });

  group('pmComputeStats', () {
    test('全部数据统计：count 176 且区间/中位/均价有值', () {
      final s = pmComputeStats(
        pmFiltered(kPetMarketData, const PetMarketFilter()),
      );
      expect(s.count, 176);
      expect(s.loPrice, isNotNull);
      expect(s.hiPrice, isNotNull);
      expect(s.loPrice! <= s.hiPrice!, isTrue);
      expect(s.median, greaterThan(0));
      expect(s.mean, greaterThan(0));
      // 空态
      final empty = pmComputeStats(const []);
      expect(empty.count, 0);
      expect(empty.rangeText, '—');
      expect(empty.medianText, '—');
    });
  });

  group('pmDistSegs / pmSegProfiles', () {
    test('5 段分段之和等于总数', () {
      final segs = pmDistSegs(kPetMarketData);
      expect(segs, hasLength(5));
      final sum = segs.fold<int>(0, (a, s) => a + s.count);
      expect(sum, 176);
      expect(segs.first.label, contains('入门'));
      expect(segs.last.label, contains('顶级'));
    });

    test('画像表 5 行且字段生成不抛错', () {
      final rows = pmSegProfiles(pmDistSegs(kPetMarketData));
      expect(rows, hasLength(5));
      for (final r in rows) {
        expect(r.lvTop, isNotEmpty);
        expect(r.avg, greaterThanOrEqualTo(0));
      }
    });
  });

  group('pmBestItems', () {
    test('性价比推荐：资质≥3800 且至多 8 条，按 ix 降序', () {
      final best = pmBestItems(kPetMarketData);
      expect(best.length, lessThanOrEqualTo(8));
      for (final b in best) {
        expect(b.listing.apt ?? 0, greaterThanOrEqualTo(3800));
        expect(b.listing.price, greaterThan(0));
      }
      for (var i = 1; i < best.length; i++) {
        expect(best[i - 1].ix >= best[i].ix, isTrue);
      }
    });
  });

  group('pmDetailRows', () {
    test('默认按价格升序', () {
      final rows = pmDetailRows(kPetMarketData, const PetMarketFilter(), '');
      expect(rows, hasLength(176));
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i - 1].price <= rows[i].price, isTrue);
      }
    });

    test('关键字过滤：命中 标题/品种/性格/区服', () {
      final kw = pmDetailRows(kPetMarketData, const PetMarketFilter(), '谨慎');
      expect(kw, isNotEmpty);
      final none = pmDetailRows(
        kPetMarketData,
        const PetMarketFilter(),
        '__不存在的关键字__',
      );
      expect(none, isEmpty);
    });
  });
}
