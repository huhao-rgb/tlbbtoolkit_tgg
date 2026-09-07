import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_snapshot.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_market_page.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_text_field.dart';

/// 默认 mock：注入 176 条快照数据（页面进入即自动拉取，模拟接口成功）。
Future<PetMarketFetchResult> _defaultFetch() async =>
    PetMarketFetchResult(raw: kPetMarketData.length, parsed: kPetMarketData);

/// 默认 mock：从快照数据推导区服目录（保证含"原始一区/少年游"等，与
/// 数据驱动下拉行为一致，避免注入真实区服目录请求）。
Future<List<SxdsRegion>> _defaultRegions() async {
  final areaOrder = <String, List<(int, String)>>{};
  var id = 1000;
  for (final p in kPetMarketData) {
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

/// 以完整主题（含 TgColors extension）泵入珍兽行情页。
/// [fetch] 可注入模拟抓取函数（为空则用快照 mock，避免真实网络）。
/// [regions] 可注入模拟区服目录（为空则用快照推导）。
/// 默认视口较高，容纳整页各区块与明细卡（页面为 CustomScrollView 惰性构建，
/// 高视口等价于「内容全部可见」以便直接断言各模块）。
/// 通过 GoRouter 提供 `/misc/market` 与 `/misc/market/detail` 两条路由，
/// 「详情」点击会按真实逻辑 push 独立商品详情页，返回为 pop。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 14000),
  Future<PetMarketFetchResult> Function()? fetch,
  Future<List<SxdsRegion>> Function()? regions,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  final f = fetch ?? _defaultFetch;
  final r = regions ?? _defaultRegions;
  final router = GoRouter(
    initialLocation: '/misc/market',
    routes: [
      GoRoute(
        path: '/misc/market',
        builder: (_, _) => Scaffold(
          body: MiscMarketPage(fetchSxds: f, fetchRegions: r),
        ),
      ),
      GoRoute(
        path: '/misc/market/detail',
        builder: (_, state) {
          final pet = state.extra is PetListing
              ? state.extra! as PetListing
              : null;
          return Scaffold(body: PetDetailPage(pet: pet));
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

/// 一条可映射的测试商品（模拟接口 goodsList 单条）。
Map<String, dynamic> _good({
  required String title,
  required int price,
  String area = '原始一区',
  String server = '少年游',
  int lv = 100,
  String ling = '10',
  String wu = '10',
  String pet = '狐狸',
  String? ch = '谨慎',
  int? apt = 4100,
  bool ss = true,
  bool ding = false,
  String sn = 'BBTEST001',
}) => {
  't': title,
  'p': price,
  'a': area,
  's': server,
  'lv': lv,
  'lx': ling,
  'wx': wu,
  'pet': pet,
  'ch': ch,
  'apt': apt,
  'ss': ss,
  'ding': ding,
  'sk': null,
  'cl': null,
  'v': 10,
  'sn': sn,
};

void main() {
  testWidgets('默认渲染：页头 + 筛选 + note + 统计 + 各分析模块 + 明细表', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('实用'), findsWidgets); // crumb
    expect(find.text('珍兽行情分析'), findsOneWidget);
    expect(find.textContaining('天龙八部怀旧原始服'), findsOneWidget);

    // 筛选区
    expect(find.text('大区'), findsOneWidget);
    expect(find.text('服务器'), findsOneWidget);
    expect(find.text('可携带等级'), findsOneWidget);
    expect(find.text('全部大区'), findsWidgets);
    expect(find.text('全部服务器'), findsWidgets);
    expect(find.text('一键获取最新数据'), findsOneWidget);

    // note
    expect(find.textContaining('数据抓取自'), findsOneWidget);

    // 统计卡（均价也出现于价位段画像表头，故用 findsWidgets）
    expect(find.text('在售样本'), findsOneWidget);
    expect(find.text('价格区间'), findsOneWidget);
    expect(find.text('中位价'), findsOneWidget);
    expect(find.text('均价'), findsWidgets);
    expect(find.text('176 条'), findsOneWidget);

    // 分析模块标题（品种中位价排行已移除，仅保留性价比推荐）
    expect(find.text('价位分布 · 在售数量'), findsOneWidget);
    expect(find.text('价位段画像'), findsOneWidget);
    expect(find.text('品种中位价排行（样本 ≥3）'), findsNothing);
    expect(find.text('性价比推荐 · 资质 / 千元价（资质 ≥3800）'), findsOneWidget);

    // 价位分布段（5 段 label，同时出现在下方价位段画像行，故 findsWidgets）
    expect(find.text('入门 · <300 元'), findsWidgets);
    expect(find.text('顶级 · ≥5000 元'), findsWidgets);

    // 明细表头 + 计数
    expect(find.text('在售明细 · 按价格排序'), findsOneWidget);
    expect(find.text('共 176 条'), findsOneWidget);
    expect(find.text('搜索标题关键字：品种 / 性格 / 资质 / 顶变 …'), findsOneWidget);
    // 表头列
    expect(find.text('图'), findsOneWidget);
    expect(find.text('价格'), findsOneWidget);
    expect(find.text('携带'), findsOneWidget);
    expect(find.text('特征'), findsOneWidget);
    expect(find.text('操作'), findsOneWidget);

    // 页脚
    expect(find.text('行情数据仅供交易参考 · 天工阁与神仙代售平台无隶属关系'), findsOneWidget);
  });

  testWidgets('服务器筛选联动：选「少年游」后统计更新为 110 条', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('全部服务器').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('少年游').last);
    await tester.pumpAndSettle();

    // 少年游样本 110 条（数据快照服务器分布）
    expect(find.text('110 条'), findsOneWidget);
    expect(find.text('共 110 条'), findsOneWidget);
  });

  testWidgets('聚焦区服后下拉仍保留全部目录选项（不随数据缩水）', (tester) async {
    // 数据仅含「少年游」（模拟聚焦到单服），但区服目录含少年游+紫气东来。
    final onlySh = kPetMarketData
        .where((p) => p.server == '少年游')
        .toList(growable: false);
    await pumpPage(
      tester,
      fetch: () async =>
          PetMarketFetchResult(raw: onlySh.length, parsed: onlySh),
      regions: () async => const [
        SxdsRegion(
          areaId: 1207,
          areaName: '原始一区',
          servers: [
            SxdsServer(serverId: 8405, serverName: '少年游'),
            SxdsServer(serverId: 22311, serverName: '紫气东来'),
          ],
        ),
      ],
    );

    // 大区下拉仍有目录大区（即使当前数据只有少年游所在大区）
    expect(find.text('全部大区'), findsWidgets);

    // 服务器下拉展开后应仍能看到目录里的「紫气东来」
    await tester.tap(find.text('全部服务器').first);
    await tester.pumpAndSettle();
    expect(find.text('紫气东来'), findsWidgets);
    expect(find.text('少年游'), findsWidgets);
    // 关闭弹层
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('明细搜索：输入「谨慎」后行数减少且出现「清空」', (tester) async {
    await pumpPage(tester);

    // 搜索框位于明细卡，需要滚动到底部区域。
    final scrollable = find.byType(Scrollable).first;
    final search = find.byType(TextField);
    await tester.scrollUntilVisible(search, 300, scrollable: scrollable);
    await tester.enterText(search, '谨慎');
    await tester.pump(const Duration(milliseconds: 250)); // 防抖 180ms
    await tester.pumpAndSettle();

    expect(find.text('清空'), findsOneWidget);
    // 过滤后行数 < 176
    expect(find.text('共 176 条'), findsNothing);

    // 点击清空恢复全部
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('共 176 条'), findsOneWidget);
  });

  testWidgets('详情：点第一行「详情」进入商品详情子视图并可返回', (tester) async {
    await pumpPage(tester);

    final scrollable = find.byType(Scrollable).first;
    final detailBtn = find.text('详情').first;
    await tester.scrollUntilVisible(detailBtn, 300, scrollable: scrollable);
    await tester.tap(detailBtn);
    await tester.pumpAndSettle();

    // 详情视图（编号同时出现在副标题与来源行）
    expect(find.text('珍兽详情'), findsOneWidget);
    expect(find.textContaining('编号'), findsWidgets);
    expect(find.text('资质'), findsOneWidget);
    expect(find.text('可携带等级'), findsOneWidget);
    expect(find.text('浏览量'), findsOneWidget);
    expect(find.text('在神仙代售查看原帖'), findsOneWidget);
    expect(find.text('返回行情列表'), findsOneWidget);

    // 返回
    await tester.tap(find.text('返回行情列表'));
    await tester.pumpAndSettle();
    expect(find.text('珍兽行情分析'), findsOneWidget);
  });

  testWidgets('一键获取成功：注入接口结果后出现绿色成功提示并刷新统计', (tester) async {
    // 模拟接口返回 3 条（页 1）+2 条（页 2）= 5 条解析商品。
    PetMarketFetchResult? captured;
    await pumpPage(
      tester,
      fetch: () async {
        final r = PetMarketFetchResult(
          raw: 5,
          parsed: [
            PetListing.fromJson(_good(title: '红猴王顶变双十', price: 1500)),
            PetListing.fromJson(_good(title: '谨慎成品妖魔', price: 530, sn: 'BB2')),
            PetListing.fromJson(_good(title: '蓝魔顶变', price: 1799, sn: 'BB3')),
            PetListing.fromJson(
              _good(title: '忠诚姥姥', price: 150, ss: false, sn: 'BB4'),
            ),
            PetListing.fromJson(
              _good(title: '胆小楚小九', price: 2000, ding: true, sn: 'BB5'),
            ),
          ],
        );
        captured = r;
        return r;
      },
    );

    await tester.tap(find.text('一键获取最新数据'));
    await tester.pumpAndSettle();

    // 成功提示 + 统计刷新（5 条）
    expect(find.textContaining('获取成功'), findsOneWidget);
    expect(find.textContaining('上方统计已刷新'), findsOneWidget);
    expect(find.text('5 条'), findsOneWidget); // 在售样本
    expect(find.text('共 5 条'), findsOneWidget);
    expect(captured, isNotNull);
    // 按钮文案恢复
    expect(find.text('一键获取最新数据'), findsOneWidget);
  });

  testWidgets('首次进入 Web CORS 拦截：显示提示与空态，无快照数据', (tester) async {
    await pumpPage(
      tester,
      fetch: () async =>
          throw const PetMarketFetchException('接口未开放跨域', isWebBlocked: true),
    );

    expect(find.textContaining('浏览器跨域拦截'), findsOneWidget);
    expect(find.textContaining('无在售数据可展示'), findsOneWidget);
    // 空态卡 + 状态条提示（不展示本地快照）
    expect(find.text('暂无在售数据'), findsOneWidget);
    expect(find.text('176 条'), findsNothing);
    expect(find.text('共 176 条'), findsNothing);
    // 仍可手动重试
    expect(find.text('一键获取最新数据'), findsOneWidget);
  });

  testWidgets('首次进入网络失败：显示错误提示与空态', (tester) async {
    await pumpPage(
      tester,
      fetch: () async => throw const PetMarketFetchException(
        '网络请求失败：连接超时',
        isWebBlocked: false,
      ),
    );

    expect(find.textContaining('网络请求失败'), findsOneWidget);
    expect(find.text('暂无在售数据'), findsOneWidget);
    expect(find.text('176 条'), findsNothing);
    expect(find.text('一键获取最新数据'), findsOneWidget);
  });

  testWidgets('在售明细：计数跟随标题同行 + 搜索框为 TgTextField + 表头列完整', (tester) async {
    await pumpPage(tester);

    final scrollable = find.byType(Scrollable).first;
    final title = find.text('在售明细 · 按价格排序');
    final count = find.text('共 176 条');
    await tester.scrollUntilVisible(title, 300, scrollable: scrollable);
    await tester.pumpAndSettle();

    // 标题与计数同行（y 重叠且不换行单行）——计数在标题后跟随。
    final titleRect = tester.getRect(title);
    final countRect = tester.getRect(count);
    expect(countRect.top >= titleRect.top - 1, isTrue);
    expect(countRect.bottom <= titleRect.bottom + 1, isTrue);
    expect(countRect.left > titleRect.right, isTrue); // 在标题右侧

    // 搜索框使用 TgTextField（内部含 TextField），无嵌套自绘边框。
    expect(find.byType(TgTextField), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索标题关键字：品种 / 性格 / 资质 / 顶变 …'), findsOneWidget);

    // 表头列齐全
    for (final h in ['图', '价格', '携带', '灵/悟', '区服', '特征', '标题', '操作']) {
      expect(find.text(h), findsOneWidget, reason: '表头 $h');
    }

    // 操作列「详情」按钮单行不换行（取第一个，宽高比合理）
    final firstDetail = find.text('详情').first;
    await tester.scrollUntilVisible(firstDetail, 300, scrollable: scrollable);
    await tester.pumpAndSettle();
    final dRect = tester.getRect(find.text('详情').first);
    expect(dRect.height, lessThan(26)); // 单行按钮高度
  });

  testWidgets('在售明细缩略图：方形缩略图点击后打开商品图片预览弹窗', (tester) async {
    // 注入一条带 oss 商品图链接的记录（测试环境图片加载失败会自动回退 paw，
    // 不影响验证「点击缩略图 → 预览弹窗」这一交互）。
    Future<PetMarketFetchResult> withImg() async {
      final one = PetListing.fromJson({
        't': '变异狐狸·双十',
        'p': 888,
        'a': '原始一区',
        's': '少年游',
        'lv': 100,
        'lx': '10',
        'wx': '10',
        'pet': '狐狸',
        'ch': '谨慎',
        'apt': 4100,
        'ss': true,
        'ding': false,
        'v': 10,
        'sn': 'BBIMG001',
        'img': 'https://oss.sxds.com/thumb/test.png',
      });
      return PetMarketFetchResult(raw: 1, parsed: [one]);
    }

    await pumpPage(tester, fetch: withImg);

    final scrollable = find.byType(Scrollable).first;
    final thumb = find.byType(Image).first;
    await tester.scrollUntilVisible(thumb, 300, scrollable: scrollable);
    await tester.pumpAndSettle();

    await tester.tap(thumb);
    await tester.pumpAndSettle();

    // 预览弹窗（TgModal 卡片样式）已打开，标题带 caption
    expect(find.text('商品图片预览'), findsOneWidget);
    expect(find.textContaining('变异狐狸'), findsWidgets);
  });

  testWidgets('详情返回后恢复行情列表滚动位置', (tester) async {
    // 用较小视口，让列表确实处于滚动状态。
    await pumpPage(tester, size: const Size(1180, 900));

    final scrollable = find.byType(Scrollable).first;
    // 惰性 sliver：分多次下拖，直到明细行出现「详情」按钮。
    var guard = 0;
    while (find.text('详情').evaluate().isEmpty && guard < 40) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pump();
      guard++;
    }
    await tester.pumpAndSettle();
    expect(find.text('详情'), findsWidgets, reason: '滚动后应出现明细行');

    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(before, greaterThan(0)); // 确认确实已滚动离开页首

    final detailBtn = find.text('详情').first;
    await tester.ensureVisible(detailBtn);
    await tester.pumpAndSettle();
    await tester.tap(detailBtn);
    await tester.pumpAndSettle();
    expect(find.text('珍兽详情'), findsOneWidget);

    await tester.tap(find.text('返回行情列表'));
    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(scrollable).position.pixels;
    // 返回后不再回到页首，且与点击前位置处于同一屏（惰性 Sliver 构建/对齐
    // 可能带来小幅位移，允许一个视口内的偏差）。
    expect(after, greaterThan(300));
    expect((after - before).abs(), lessThan(900));
  });

  testWidgets('性价比推荐：行内「详情」进入独立商品详情页', (tester) async {
    await pumpPage(tester);

    // 性价比推荐卡位于明细表之前，其行尾的「详情」按钮是页面第一个「详情」。
    // （明细表同样使用「详情」文案，二者行为一致：push 独立商品详情页）
    final goBtn = find.text('详情').first;
    await tester.ensureVisible(goBtn);
    await tester.pumpAndSettle();
    await tester.tap(goBtn);
    await tester.pumpAndSettle();

    // 进入独立详情页（路由 push）
    expect(find.text('珍兽详情'), findsOneWidget);
    expect(find.text('返回行情列表'), findsOneWidget);
  });
}
