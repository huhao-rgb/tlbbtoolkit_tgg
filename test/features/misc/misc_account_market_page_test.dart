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
import 'package:tlbbtoolkit/shared/widgets/tg_scroll_top_button.dart';

/// 默认 mock：注入 132 条快照数据（页面进入即自动拉取，模拟接口成功）。
Future<AccountMarketFetchResult> _defaultFetch() async =>
    AccountMarketFetchResult(
      raw: kAccountMarketData.length,
      parsed: kAccountMarketData,
    );

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

    // 首行「详情」来自「性价比推荐」卡（22 高紧凑规格），文案不得被压扁裁切。
    expect(tester.getSize(find.text('详情').first).height, greaterThan(14));
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

  testWidgets('大数据量（500 条）：明细行惰性构建，无异常且行内可操作', (tester) async {
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
    // 常规视口（900 高）：整页只有一个纵向滚动体，明细行由 SliverList 惰性构建。
    await pumpPage(
      tester,
      size: const Size(1180, 900),
      fetch: () async => AccountMarketFetchResult(raw: big.length, parsed: big),
    );

    expect(tester.takeException(), isNull);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('在售明细 · 按价格排序'),
      400,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('共 500 条'), findsOneWidget);
    expect(find.text('操作'), findsOneWidget); // 表头在明细表顶部

    // 单一滚动体：明细表内不再有嵌套的纵向 ListView / 横向滚动容器。
    final table = find.byKey(const ValueKey('acc-detail-table'));
    expect(table, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.byType(ListView)),
      findsNothing,
    );
    expect(
      find.descendant(of: table, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );

    // 惰性构建：只 inflate 可视区附近的行，而非全部 500 行。
    final detailCount = find.text('详情').evaluate().length;
    expect(detailCount, greaterThan(0));
    expect(detailCount, lessThan(100));

    // 明细表内首行「详情」仍可进入账号详情页。
    final tableDetail = find.descendant(of: table, matching: find.text('详情'));
    await tester.ensureVisible(tableDetail.first);
    await tester.pumpAndSettle();
    await tester.tap(tableDetail.first);
    await tester.pumpAndSettle();
    expect(find.text('账号详情'), findsOneWidget);
  });

  testWidgets('在售明细并入整页单一滚动体：一路下拖可直达页尾', (tester) async {
    // 500 条数据让明细表足够长；视口 900 高保证整页可滚动。
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

    final scrollable = find.byType(Scrollable).first;
    final pos = tester.state<ScrollableState>(scrollable).position;
    final foot = find.textContaining('行情数据仅供交易参考');
    // 500 行明细之后仍能继续滚动到页尾：不存在内层滚动把内容「卡住」。
    var guard = 0;
    while (foot.evaluate().isEmpty && guard < 400) {
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pump();
      guard++;
    }
    await tester.pumpAndSettle();
    expect(foot, findsOneWidget, reason: '明细表之后仍应能滚到页尾');
    expect(pos.pixels, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('acc-detail-table')),
        matching: find.byType(ListView),
      ),
      findsNothing,
      reason: '明细表不应再有内层 ListView',
    );
  });

  testWidgets('明细表列随宽度降级：宽档全列 / 中档折叠为副行 / 窄屏堆叠卡片', (tester) async {
    // 明细行副行文案（职业 · 区服），用于校验中/窄布局的折叠呈现。
    final subLines = [
      for (final t in kAccountMarketData)
        [
          if (t.job.isNotEmpty) t.job,
          if (t.area.isNotEmpty) '${t.area}-${t.server}',
        ].join(' · '),
    ].where((s) => s.isNotEmpty).toList();

    // 宽档（内容宽 ≥900）：8 列表头齐全（含 职业、区服）。
    await pumpPage(tester, size: const Size(1280, 900));
    await tester.scrollUntilVisible(
      find.text('在售明细 · 按价格排序'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    for (final h in ['图', '标题', '价格', '等级', '职业', '区服', '主属性·攻', '操作']) {
      expect(find.text(h), findsOneWidget, reason: '宽档表头 $h');
    }

    // 中档（560~900）：收起 职业、区服 列，折叠为标题下的副行。
    await pumpPage(tester, size: const Size(800, 900));
    await tester.scrollUntilVisible(
      find.text('在售明细 · 按价格排序'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('职业'), findsNothing);
    expect(find.text('区服'), findsNothing);
    expect(find.text('等级'), findsOneWidget);
    expect(
      subLines.any((s) => find.text(s).evaluate().isNotEmpty),
      isTrue,
      reason: '职业 · 区服 应折叠为标题下的副行',
    );

    // 窄屏（<560）：整行堆叠卡片，不渲染表头列。
    await pumpPage(tester, size: const Size(480, 900));
    await tester.scrollUntilVisible(
      find.text('在售明细 · 按价格排序'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('图'), findsNothing);
    expect(find.text('主属性·攻'), findsNothing);
    expect(find.text('详情'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('大区筛选联动：选「万人大区」后统计更新为该大区样本数', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('全部大区').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('万人大区').last);
    await tester.pumpAndSettle();

    // 万人大区样本 10 条（快照区服分布）
    final count = kAccountMarketData.where((x) => x.area == '万人大区').length;
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

  testWidgets('紧凑（移动）宽度下渲染无溢出，明细行降级为堆叠卡片', (tester) async {
    await pumpPage(tester, size: const Size(390, 16000));

    expect(tester.takeException(), isNull);
    expect(find.text('账号行情分析'), findsOneWidget);
    expect(find.text('价位分布 · 在售数量'), findsOneWidget);
    expect(find.text('在售明细 · 按价格排序'), findsOneWidget);
    // 窄屏下明细整行是堆叠卡片，不再渲染表头列（图 / 职业 / 区服 / 操作 均无表头）。
    expect(find.text('职业'), findsNothing);
    expect(find.text('区服'), findsNothing);
    expect(find.text('图'), findsNothing);
    expect(find.text('操作'), findsNothing);
    expect(find.text('详情'), findsWidgets);
  });

  testWidgets('紧凑（移动）宽度：筛选下拉两列等宽，一行两个', (tester) async {
    await pumpPage(tester, size: const Size(390, 16000));

    Rect box(String label) =>
        tester.getRect(find.byKey(ValueKey('tg-select-$label')));
    final area = box('大区');
    final server = box('服务器');
    final band = box('角色等级');

    // 三个筛选框宽度完全一致
    expect(area.width, server.width);
    expect(area.width, band.width);
    // 前两个同一行（顶部对齐），第三个换行到下一行
    expect((area.top - server.top).abs(), lessThan(1));
    expect(band.top, greaterThan(server.top));
    expect(server.right, lessThanOrEqualTo(390));
  });

  testWidgets('回到顶部：滚动超过 420px 后浮现，点击平滑回到页首', (tester) async {
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

    final button = find.byKey(TgScrollTopButton.buttonKey);
    final fade = find.ancestor(
      of: button,
      matching: find.byType(AnimatedOpacity),
    );
    double opacity() => tester.widget<AnimatedOpacity>(fade.first).opacity;
    final scrollable = find.byType(Scrollable).first;
    final pos = tester.state<ScrollableState>(scrollable).position;

    // 页首（offset < 420）：按钮不可见且不拦截指针。
    expect(pos.pixels, 0);
    expect(opacity(), 0);
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(of: button, matching: find.byType(IgnorePointer))
                .first,
          )
          .ignoring,
      isTrue,
    );

    // 下拖 600px：超过阈值后淡入，并停在右下角（桌面：右 20 / 下 24）。
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(pos.pixels, greaterThan(420));
    expect(opacity(), 1);
    final rect = tester.getRect(button);
    expect(rect.width, 42);
    expect(rect.height, 42);
    expect(rect.right, moreOrLessEquals(1180 - 20, epsilon: 0.5));
    expect(rect.bottom, moreOrLessEquals(900 - 24, epsilon: 0.5));
    expect(tester.takeException(), isNull);

    // 点击 → 平滑滚回页首，按钮随之隐去。
    await tester.tapAt(tester.getCenter(button));
    await tester.pumpAndSettle();
    expect(pos.pixels, 0);
    expect(opacity(), 0);
  });
}
