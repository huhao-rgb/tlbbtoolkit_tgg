import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/account_market_snapshot.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market_stats.dart';

void main() {
  group('account_market_snapshot', () {
    test('132 条快照可解析且字段完整', () {
      final data = kAccountMarketData;
      expect(data, hasLength(132));
      final first = data.first;
      expect(first.sn, isNotEmpty);
      expect(first.title, isNotEmpty);
      expect(first.price, greaterThan(0));
      expect(first.area, isNotEmpty);
      expect(first.server, isNotEmpty);
      expect(first.job, isNotEmpty);
      expect(first.sex, isNotEmpty);
      expect(first.attr, greaterThan(0));
    });

    test('atk 主攻简写：主玄攻→玄 / 主火攻→火', () {
      expect(const AccountListing(sn: '', title: '', price: 0, views: 0,
        area: '', server: '', job: '', sex: '', lv: 119, atk: '主玄攻',
        attr: 100).atkShort, '玄');
      expect(const AccountListing(sn: '', title: '', price: 0, views: 0,
        area: '', server: '', job: '', sex: '', lv: 119, atk: '主火攻',
        attr: 100).atkShort, '火');
    });
  });

  group('amFmt', () {
    test('≥10000 显示 x.x 万，去尾 .0', () {
      expect(amFmt(10000), '1 万');
      expect(amFmt(12000), '1.2 万');
      expect(amFmt(608888), '60.9 万');
    });

    test('<10000 千分位整数', () {
      expect(amFmt(999), '999');
      expect(amFmt(12345), '1.2 万');
      expect(amFmt(355), '355');
    });
  });

  group('amFiltered', () {
    test('空筛选返回全部 132 条', () {
      expect(
        amFiltered(kAccountMarketData, const AccountMarketFilter()),
        hasLength(132),
      );
    });

    test('大区筛选只保留该大区', () {
      final r = amFiltered(
        kAccountMarketData,
        const AccountMarketFilter(area: '万人大区'),
      );
      expect(r, isNotEmpty);
      expect(r.every((x) => x.area == '万人大区'), isTrue);
    });

    test('服务器筛选只保留该服务器', () {
      final r = amFiltered(
        kAccountMarketData,
        const AccountMarketFilter(server: '紫气东来'),
      );
      expect(r, isNotEmpty);
      expect(r.every((x) => x.server == '紫气东来'), isTrue);
    });

    test('角色等级段 60-70：只保留 60 ≤ lv < 70', () {
      final r = amFiltered(
        kAccountMarketData,
        const AccountMarketFilter(band: AccountLevelBand.s60),
      );
      expect(r, isNotEmpty);
      expect(r.every((x) => x.lv >= 60 && x.lv < 70), isTrue);
    });

    test('角色等级段 100级以上：只保留 lv ≥ 100', () {
      final r = amFiltered(
        kAccountMarketData,
        const AccountMarketFilter(band: AccountLevelBand.ge100),
      );
      expect(r, isNotEmpty);
      expect(r.every((x) => x.lv >= 100), isTrue);
    });
  });

  group('amComputeStats', () {
    test('全部数据统计：count 132 且区间/中位/均价有值', () {
      final s = amComputeStats(
        amFiltered(kAccountMarketData, const AccountMarketFilter()),
      );
      expect(s.count, 132);
      expect(s.loPrice, isNotNull);
      expect(s.hiPrice, isNotNull);
      expect(s.loPrice! <= s.hiPrice!, isTrue);
      expect(s.median, greaterThan(0));
      expect(s.mean, greaterThan(0));
    });
  });

  group('amDistSegs / amSegProfiles', () {
    test('5 段价位分布，段计数之和等于总数', () {
      final segs = amDistSegs(kAccountMarketData);
      expect(segs, hasLength(5));
      final sum = segs.fold<int>(0, (a, b) => a + b.count);
      expect(sum, 132);
      expect(segs.map((s) => s.label).first, contains('入门'));
      expect(segs.map((s) => s.label).last, contains('顶级'));
    });

    test('价位段画像：5 行，主流等级为「N 级」或 —', () {
      final profiles = amSegProfiles(amDistSegs(kAccountMarketData));
      expect(profiles, hasLength(5));
      for (final p in profiles) {
        expect(p.lvTop == '—' || p.lvTop.endsWith('级'), isTrue);
        expect(p.avg, greaterThanOrEqualTo(0));
      }
    });
  });

  group('amSectRows / amJobRows / amBestItems / amDetailRows', () {
    test('区服在售分布按数量降序', () {
      final rows = amSectRows(kAccountMarketData);
      expect(rows, isNotEmpty);
      for (var i = 0; i + 1 < rows.length; i++) {
        expect(rows[i].count >= rows[i + 1].count, isTrue);
      }
    });

    test('职业中位价排行样本 ≥3 且按中位价降序', () {
      final rows = amJobRows(kAccountMarketData);
      expect(rows, isNotEmpty);
      expect(rows.every((r) => r.count >= 3), isTrue);
      for (var i = 0; i + 1 < rows.length; i++) {
        expect(rows[i].median >= rows[i + 1].median, isTrue);
      }
    });

    test('性价比推荐：主属性≥4000、≤8 条、按指数降序', () {
      final best = amBestItems(kAccountMarketData);
      expect(best.length, lessThanOrEqualTo(8));
      expect(best.every((b) => b.account.attr >= 4000), isTrue);
      for (var i = 0; i + 1 < best.length; i++) {
        expect(best[i].ix >= best[i + 1].ix, isTrue);
      }
    });

    test('明细按价格升序', () {
      final rows = amDetailRows(kAccountMarketData, const AccountMarketFilter());
      expect(rows, hasLength(132));
      for (var i = 0; i + 1 < rows.length; i++) {
        expect(rows[i].price <= rows[i + 1].price, isTrue);
      }
    });
  });
}
