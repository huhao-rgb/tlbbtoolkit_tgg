import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/misc/data/account_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/data/account_market_snapshot.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_account_detail_page.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_account_market_page.dart';

/// 默认 mock：注入 132 条快照数据（页面进入即自动拉取，模拟接口成功）。
Future<AccountMarketFetchResult> _defaultFetch() async =>
    AccountMarketFetchResult(raw: kAccountMarketData.length, parsed: kAccountMarketData);

/// 默认 mock：从快照数据推导区服目录。
Future<List<SxdsRegion>> _defaultRegions() async {
  final areaOrder = <String, List<(int, String)>>{};
  var id = 1000;
  for (final p in kAccountMarketData) {
    if (p.area.isEmpty) continue;
    final list = areaOrder.putIfAbsent(p.area, () => []);
    if (!list.any((e) => e.$2 == p.server)) {
      list.add((++id, p.server));
    }
  }
  return [
    for (final e in areaOrder.entries)
      SxdsRegion(
        areaId: ++id,
        areaName: e.key,
        servers: [
          for (final (sid, name) in e.value)
            SxdsServer(serverId: sid, serverName: name),
        ],
      ),
  ];
}

/// 以完整主题（含 TgColors extension）泵入账号行情页。
/// [fetch] 可注入模拟抓取函数（为空则用快照 mock，避免真实网络）。
/// [regions] 可注入模拟区服目录（为空则用快照推导）。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 14000),
  Future<AccountMarketFetchResult> Function()? fetch,
  Future<List<SxdsRegion>> Function()? regions,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  final f = fetch ?? _defaultFetch;
  final r = regions ?? _defaultRegions;
  final router = GoRouter(
    initialLocation: '/misc/acc-market',
    routes: [
      GoRoute(
        path: '/misc/acc-market',
        builder: (_, _) => Scaffold(
          body: MiscAccountMarketPage(fetchAccounts: f, fetchRegions: r),
        ),
      ),
      GoRoute(
        path: '/misc/acc-market/detail',
        builder: (_, state) {
          final acc = state.extra is AccountListing
              ? state.extra! as AccountListing
              : null;
          return Scaffold(body: AccountDetailPage(account: acc));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 筛选 + note + 统计 + 各分析模块 + 明细表', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('实用'), findsWidgets); // crumb
    expect(find.text('账号行情分析'), findsOneWidget);
    expect(find.textContaining('在售数据分析'), findsOneWidget);

    // 筛选区
    expect(find.text('大区'), findsOneWidget);
    expect(find.text('服务器'), findsOneWidget);
    expect(find.text('角色等级'), findsOneWidget);
    expect(find.text('全部大区'), findsWidgets);
    expect(find.text('全部服务器'), findsWidgets);
    expect(find.text('全部等级'), findsWidgets);
    expect(find.text('一键获取最新数据'), findsOneWidget);

    // note
    expect(find.textContaining('数据抓取自'), findsOneWidget);

    // 统计卡
    expect(find.text('在售样本'), findsOneWidget);
    expect(find.text('价格区间'), findsOneWidget);
    expect(find.text('中位价'), findsOneWidget);
    expect(find.text('均价'), findsWidgets);
    expect(find.text('132 条'), findsOneWidget);

    // 分析模块标题
    expect(find.text('价位分布 · 在售数量'), findsOneWidget);
    expect(find.text('价位段画像'), findsOneWidget);
    expect(find.text('区服在售分布'), findsOneWidget);
    expect(find.text('性价比推荐 · 主属性 / 万元价（主属性 ≥4000）'), findsOneWidget);

    // 价位分布段（5 段 label，同时出现在下方价位段画像行，故 findsWidgets）
    expect(find.text('入门 · <1000 元'), findsWidgets);
    expect(find.text('顶级 · ≥5 万元'), findsWidgets);

    // 明细表头 + 计数（含新增 图 / 操作 列）
    expect(find.text('在售明细 · 按价格排序'), findsOneWidget);
    expect(find.text('共 132 条'), findsOneWidget);
    expect(find.text('图'), findsOneWidget);
    expect(find.text('价格'), findsOneWidget);
    expect(find.text('等级'), findsWidgets); // 表头 + 统计卡? 仅表头一处
    expect(find.text('主属性·攻'), findsOneWidget);
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('操作'), findsOneWidget);

    // 页脚
    expect(find.text('行情数据仅供交易参考 · 天工阁与神仙代售平台无隶属关系'), findsOneWidget);
  });

  testWidgets('详情：点第一行「详情」进入账号详情页并可返回', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('详情').first);
    await tester.pumpAndSettle();

    // 详情页头 + 关键信息
    expect(find.text('账号详情'), findsOneWidget);
    expect(find.text('职业'), findsWidgets); // 详情信息格
    expect(find.text('在神仙代售查看原帖'), findsOneWidget);

    // 返回行情列表
    await tester.tap(find.text('返回行情列表'));
    await tester.pumpAndSettle();
    expect(find.text('账号行情分析'), findsOneWidget);
    expect(find.text('共 132 条'), findsOneWidget);
  });

  testWidgets('大数据量（500 条）：明细表惰性构建，无异常且首行可操作', (tester) async {
    // 由快照数据循环生成 500 条（无 img，避免测试网络请求）。
    final big = List<AccountListing>.generate(500, (i) {
      final base = kAccountMarketData[i % kAccountMarketData.length];
      return AccountListing(
        sn: '${base.sn}-$i',
        title: '测试账号 ${i + 1} · ${base.title}',
        price: base.price + i,
        views: base.views,
        area: base.area,
        server: base.server,
        job: base.job,
        sex: base.sex,
        lv: base.lv,
        atk: base.atk,
        attr: base.attr,
        attr2: base.attr2,
        areaId: base.areaId,
        serverId: base.serverId,
      );
    });
    await pumpPage(
      tester,
      fetch: () async => AccountMarketFetchResult(raw: big.length, parsed: big),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('共 500 条'), findsOneWidget);
    // 表体区独立滚动且惰性构建：页面上只构建可视区附近的行，而非全部 500 行。
    expect(find.text('操作'), findsOneWidget); // 表头固定在表体上方
    final detailCount = find.text('详情').evaluate().length;
    expect(detailCount, greaterThan(0));
    expect(detailCount, lessThan(100));

    // 首行「详情」仍可进入账号详情页。
    await tester.tap(find.text('详情').first);
    await tester.pumpAndSettle();
    expect(find.text('账号详情'), findsOneWidget);
  });

  testWidgets('在售明细滚到顶/底后，越界滚动转交外层整页', (tester) async {
    // 500 条数据让表体进入「区内滚动 + 越界转交」模式；视口 900 高让整页可滚动。
    final big = List<AccountListing>.generate(500, (i) {
      final base = kAccountMarketData[i % kAccountMarketData.length];
      return AccountListing(
        sn: '${base.sn}-$i',
        title: '测试账号 ${i + 1} · ${base.title}',
        price: base.price + i,
        views: base.views,
        area: base.area,
        server: base.server,
        job: base.job,
        sex: base.sex,
        lv: base.lv,
        atk: base.atk,
        attr: base.attr,
        attr2: base.attr2,
        areaId: base.areaId,
        serverId: base.serverId,
      );
    });
    await pumpPage(
      tester,
      size: const Size(1180, 900),
      fetch: () async => AccountMarketFetchResult(raw: big.length, parsed: big),
    );

    final list = find.byKey(const ValueKey('acc-detail-list'));
    // 外层整页滚动位置（页面 CustomScrollView 是最外层 Scrollable）。
    final outerScrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    // 先把在售明细表（页尾）构建出来，再把表体居中到视口（视口高 900），
    // 避免表体中心落到屏幕外导致拖拽落空。
    outerScrollable.position.jumpTo(outerScrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(list, findsOneWidget);
    Future<void> centerList() async {
      final rect = tester.getRect(list);
      final target = (outerScrollable.position.pixels + rect.center.dy - 450)
          .clamp(0.0, outerScrollable.position.maxScrollExtent);
      outerScrollable.position.jumpTo(target);
      await tester.pumpAndSettle();
    }
    await centerList();

    final outerBottom = outerScrollable.position.pixels;
    expect(outerBottom, greaterThan(0));

    // 场景 A：内层在顶部，手指下移 → 内层不动，越界位移转交外层 → 整页向上滚动。
    await tester.drag(list, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(outerScrollable.position.pixels, lessThan(outerBottom));

    // 场景 B：把内层直接滚到自身底部；整页上移 200px 留出下方余量（表体仍可见）；
    // 再上滑 → 内层已到底，越界位移转交外层 → 整页向下滚动。
    await centerList();
    final innerScrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    innerScrollable.position.jumpTo(innerScrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    outerScrollable.position.jumpTo(
      (outerScrollable.position.pixels - 200).clamp(
        0.0,
        outerScrollable.position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
    final beforeDown = outerScrollable.position.pixels;
    await tester.drag(list, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(outerScrollable.position.pixels, greaterThan(beforeDown));
  });

  testWidgets('大区筛选联动：选「万人大区」后统计更新为该大区样本数', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('全部大区').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('万人大区').last);
    await tester.pumpAndSettle();

    // 万人大区样本 10 条（快照区服分布）
    final count = kAccountMarketData
        .where((x) => x.area == '万人大区')
        .length;
    expect(find.text('$count 条'), findsWidgets);
    expect(find.text('共 $count 条'), findsOneWidget);
  });

  testWidgets('角色等级筛选联动：选「100级以上」后只保留 lv≥100', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('全部等级').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('100级以上').last);
    await tester.pumpAndSettle();

    final count = kAccountMarketData.where((x) => x.lv >= 100).length;
    expect(count, greaterThan(0));
    expect(find.text('共 $count 条'), findsOneWidget);
  });

  testWidgets('空数据：展示空态与提示', (tester) async {
    await pumpPage(
      tester,
      fetch: () async => const AccountMarketFetchResult(raw: 0, parsed: []),
    );

    expect(find.text('暂无在售数据'), findsOneWidget);
    expect(find.text('可点击上方「一键获取最新数据」重试，或稍后再进入页面自动刷新。'), findsOneWidget);
  });

  testWidgets('紧凑（移动）宽度下渲染无溢出，核心模块可见', (tester) async {
    await pumpPage(tester, size: const Size(390, 16000));

    expect(tester.takeException(), isNull);
    expect(find.text('账号行情分析'), findsOneWidget);
    expect(find.text('价位分布 · 在售数量'), findsOneWidget);
    expect(find.text('在售明细 · 按价格排序'), findsOneWidget);
    // 紧凑隐藏 职业/区服 表头列，但保留 图 / 操作 列
    expect(find.text('职业'), findsNothing);
    expect(find.text('区服'), findsNothing);
    expect(find.text('图'), findsOneWidget);
    expect(find.text('操作'), findsOneWidget);
  });
}
