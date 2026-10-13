import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/core/storage/secure_kv_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_memory.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/presentation/providers/reg_sync_providers.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_regress_page.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_modal.dart';

/// 以完整主题 + ProviderScope（注入 mock prefs）泵入卡回归页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1200, 1000),
  Map<String, Object> initial = const {},
  MemorySecureStore? secureStore,
  RegSyncGatewayMemory? gateway,
  bool cloudConfigured = false,
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (secureStore != null)
          secureKvStoreProvider.overrideWithValue(secureStore),
        if (gateway != null) regSyncGatewayProvider.overrideWithValue(gateway),
        if (cloudConfigured)
          regSyncConfigProvider.overrideWithValue((
            enabled: true,
            baseUrl: 'https://sync.example.com',
            path: '/reg',
          )),
      ],
      child: MaterialApp(
        theme: TgTheme.dark,
        darkTheme: TgTheme.dark,
        home: const Scaffold(body: MiscRegressPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 造 n 个账号的 v2 本地存储数据（同步码 / 二维码用例共用）。
Map<String, Object> seedAccounts(int n) => {
  RegRepository.key: jsonEncode({
    'v': 2,
    'accts': [
      for (var i = 0; i < n; i++)
        {
          'id': 'id$i',
          'name': '测试账号$i',
          'lv': 89 + i,
          'sect': 'xiaoyao',
          'cur': null,
          'runs': [
            {'s': 1700000000000 + i, 'e': 1700600000000 + i},
          ],
          'u': 1700000000000 + i,
        },
    ],
    'sel': null,
  }),
};

/// 打开「数据同步」弹窗并切到「一次性同步码」tab。
///
/// 默认构建没有注入 SYNC_BASE_URL，弹窗本就落在这个 tab；这里显式点一次，
/// 保证无论构建开关如何都稳定。
Future<void> openOneShotTab(WidgetTester tester) async {
  await tester.tap(find.text('同步'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('一次性同步码'));
  await tester.pumpAndSettle();
}

/// 内存版安全存储（页面测试不碰平台通道）。
class MemorySecureStore implements SecureKvStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  testWidgets('默认渲染：页头 + 规则 + 空态账号卡 + 未选中提示', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('卡回归计算器'), findsWidgets); // crumb/h1/info
    expect(find.textContaining('多账号回归周期记录'), findsOneWidget);
    // 规则
    expect(find.textContaining('规则：账号连续'), findsOneWidget);
    // 我的账号卡 + 计数 0 + 导入/导出/添加按钮
    expect(find.text('我的账号'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('导入'), findsOneWidget);
    expect(find.text('导出'), findsOneWidget);
    expect(find.text('添加账号'), findsOneWidget);
    expect(find.textContaining('暂无账号'), findsOneWidget);
    // 底部未选中提示
    expect(find.textContaining('在上方选择一个账号'), findsOneWidget);
  });

  testWidgets('添加账号：弹窗输入名称/等级，保存后账号卡出现并进入空闲面板', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    expect(find.text('角色名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '逍遥生');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    // 账号卡出现（名称在卡与选中面板头部各一次）；计数 1；空闲面板可见。
    expect(find.text('逍遥生'), findsWidgets);
    expect(find.textContaining('Lv.89'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('开始回归计时'), findsWidgets);
  });

  testWidgets('开始回归计时后进入倒计时面板', (tester) async {
    await pumpPage(tester);

    // 预置一个账号直接选中并空闲
    // （通过界面添加最快）
    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '武当山长');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    // 空闲面板「开始回归计时」主按钮（与标题区分，取按钮 key）
    await tester.tap(find.widgetWithText(InkWell, '开始回归计时').last);
    await tester.pumpAndSettle();

    // 倒计时面板特征
    expect(find.text('距回归任务开启还剩'), findsOneWidget);
    expect(find.text('天'), findsOneWidget);
    expect(find.text('时'), findsOneWidget);
    expect(find.text('分'), findsOneWidget);
    expect(find.text('秒'), findsOneWidget);
    expect(find.textContaining('周期进度'), findsOneWidget);
    expect(find.textContaining('请勿登录'), findsOneWidget);
    expect(find.text('放弃本轮计时'), findsOneWidget);
  });

  testWidgets('删除账号：两次点击确认后移除', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '丐帮帮主');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    expect(find.text('丐帮帮主'), findsWidgets);

    // 点删除（第一次 arm → 显示“确认?”），再点即真删除。
    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    await tester.tap(find.byTooltip('确认删除？'));
    await tester.pumpAndSettle();

    expect(find.text('丐帮帮主'), findsNothing);
    expect(find.textContaining('暂无账号'), findsOneWidget);

    // 消化删除确认的 2.6s 复位 Timer，避免 dispose 时仍 pending。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('长按拖拽：拖动账号卡换位并持久化排序', (tester) async {
    await pumpPage(tester);

    Future<void> addAccount(String name) async {
      await tester.tap(find.text('添加账号'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, name);
      await tester.tap(find.text('保存账号'));
      await tester.pumpAndSettle();
    }

    await addAccount('逍遥生');
    await addAccount('武当山长');

    // 两张账号卡（选中面板头部也会出现名称，取树序第一个 = 网格卡）。
    // 名称左对齐 + 固定内边距，用左上角 x 精确比较卡片位置。
    final first = tester.getTopLeft(find.text('逍遥生').first);
    final second = tester.getTopLeft(find.text('武当山长').first);

    // 长按第一张卡（超过 400ms 阈值），拖到第二张卡处松手。
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('逍遥生').first),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(find.text('武当山长').first));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // 顺序互换：逍遥生卡现在应位于第二张卡原位置（同一行，比较 dx）。
    final moved = tester.getTopLeft(find.text('逍遥生').first);
    expect((moved.dx - second.dx).abs(), lessThan(2));

    // 已持久化：本地 JSON 中 accts 顺序互换。
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(RegRepository.key);
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final names = [
      for (final a in json['accts'] as List) (a as Map)['name'] as String,
    ];
    expect(names, ['武当山长', '逍遥生']);
  });

  testWidgets('同步码：展示本机同步码，粘贴他机同步码后合并入列表', (tester) async {
    await pumpPage(tester);

    // 本机先有一个账号
    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '逍遥生');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    await openOneShotTab(tester);

    expect(find.text('数据同步'), findsOneWidget);
    expect(find.textContaining('本机同步码'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('复制同步码'), findsOneWidget);
    expect(find.text('合并到本机'), findsOneWidget);
    // 同步码能装进二维码 → 渲染出真实 QR（装不下时会退化成降级提示）
    expect(find.byType(PrettyQrView), findsOneWidget);

    // 模拟另一台设备的同步码（含本机没有的账号）
    final prefs = await SharedPreferences.getInstance();
    final code = RegRepository(LocalStorage(prefs)).buildSyncCode([
      RegAccount(id: 'remote-1', name: '武当山长', lv: 92, sectKey: 'wudang'),
    ]);
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      code,
    );
    await tester.tap(find.text('合并到本机'));
    await tester.pumpAndSettle();

    // 弹窗关闭 + 他机账号已并入（本机账号保留）
    expect(find.text('数据同步'), findsNothing);
    expect(find.text('武当山长'), findsWidgets);
    expect(find.text('逍遥生'), findsWidgets);
    expect(find.text('2'), findsOneWidget);

    // 消化合并提示 SnackBar 的 3s 自动消失 Timer
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('窄屏 390：页头按钮组折行、同步码弹窗不溢出', (tester) async {
    await pumpPage(tester, size: const Size(390, 900));

    // 4 个操作按钮 + 账号卡在窄屏的最挤状态（溢出即抛 RenderFlex 异常）
    expect(find.text('导入'), findsOneWidget);
    expect(find.text('同步'), findsOneWidget);

    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '逍遥生');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    await openOneShotTab(tester);
    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('合并到本机'), findsOneWidget);
    expect(find.byType(PrettyQrView), findsOneWidget);
  });

  testWidgets('同步码：账号较多（二维码密集）时仍能渲染，不触发库内断言', (tester) async {
    // 10 个账号 → 同步码 ≈1.9K 字符 → 二维码约 161 模块 / 220px ≈ 1.3 逻辑像素每模块。
    // 回归：PrettyQrSquaresSymbol / PrettyQrDotsSymbol 内部按
    // clamp(x, 1, moduleSize/2) 计算，模块 <2px 时 min>max 直接断言崩溃。
    await pumpPage(tester, initial: seedAccounts(10));

    await openOneShotTab(tester);

    expect(find.byType(PrettyQrView), findsOneWidget);
    expect(find.textContaining('超出二维码容量'), findsNothing);
  });

  testWidgets('同步码：账号过多超出二维码容量时降级为复制提示', (tester) async {
    // 每账号 JSON ≈ 143 字节 → 40 个（≈5.7K Base64 字符）必然超出 QR 容量上限
    await pumpPage(tester, initial: seedAccounts(40));
    expect(find.text('40'), findsOneWidget); // 账号计数

    await openOneShotTab(tester);

    // 编码失败 → 走 errorBuilder 降级，而不是抛异常 / 白屏
    expect(find.byType(PrettyQrView), findsNothing);
    expect(find.textContaining('超出二维码容量'), findsOneWidget);
    // 复制通道仍然可用
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('复制同步码'), findsOneWidget);
  });

  testWidgets('云同步未配置：页头不显示徽标，弹窗默认落在「一次性同步码」', (tester) async {
    await pumpPage(tester);

    expect(find.text('未开启'), findsNothing, reason: '未配置云同步不应出现状态徽标');
    expect(find.text('已同步'), findsNothing);

    await tester.tap(find.text('同步'));
    await tester.pumpAndSettle();
    expect(find.text('数据同步'), findsOneWidget);
    // 未配置 → 默认落在可用的那条通道
    expect(find.textContaining('本机同步码'), findsOneWidget);

    await tester.tap(find.text('云同步'));
    await tester.pumpAndSettle();
    expect(find.textContaining('未配置云同步'), findsOneWidget);
  });

  testWidgets('云同步已配置：页头徽标「未开启」→ 生成配对码后上传并转「已同步」', (tester) async {
    final secure = MemorySecureStore();
    final gateway = RegSyncGatewayMemory();
    await pumpPage(
      tester,
      secureStore: secure,
      gateway: gateway,
      cloudConfigured: true,
    );

    // 先造一条本机数据
    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '逍遥生');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    expect(find.text('未开启'), findsOneWidget, reason: '页面标题旁的状态徽标');

    await tester.tap(find.text('同步'));
    await tester.pumpAndSettle();
    // 已配置 → 默认落在云同步
    expect(find.text('生成配对码并开启同步'), findsOneWidget);

    await tester.tap(find.text('生成配对码并开启同步'));
    await tester.pumpAndSettle();

    // 配对完成：上传了密文，界面给出配对码与状态
    expect(gateway.recordCount, 1);
    expect(find.textContaining('已同步'), findsWidgets);
    expect(find.text('复制配对码'), findsOneWidget);
    expect(find.byType(PrettyQrView), findsOneWidget);
    // 凭据进了安全存储
    expect(secure.data[RegPairingStore.key], isNotNull);

    // 关掉弹窗后，页头徽标为「已同步」
    await tester.tap(find.byType(TgModalCloseButton));
    await tester.pumpAndSettle();
    expect(find.text('已同步'), findsOneWidget);
  });

  testWidgets('云同步已配对：本地新增账号后防抖自动推送（无需手动点同步）', (tester) async {
    final secure = MemorySecureStore();
    final gateway = RegSyncGatewayMemory();
    await pumpPage(
      tester,
      secureStore: secure,
      gateway: gateway,
      cloudConfigured: true,
    );

    await tester.tap(find.text('同步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成配对码并开启同步'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TgModalCloseButton));
    await tester.pumpAndSettle();

    final pushes = gateway.pushCount;

    // 新增账号 → 页面落盘后交给同步控制器防抖
    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '武当山长');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();
    expect(gateway.pushCount, pushes, reason: '防抖窗口内不该立刻推送');
    expect(find.text('待同步'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(gateway.pushCount, pushes + 1, reason: '防抖结束后自动推送一次');
    expect(find.text('已同步'), findsOneWidget);
  });

  testWidgets('窄屏 390（已配置云同步）：标题行徽标 + 按钮组 + 弹窗均不溢出', (tester) async {
    final secure = MemorySecureStore();
    final gateway = RegSyncGatewayMemory();
    await pumpPage(
      tester,
      size: const Size(390, 900),
      secureStore: secure,
      gateway: gateway,
      cloudConfigured: true,
    );

    expect(find.text('未开启'), findsOneWidget);

    await tester.tap(find.text('同步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成配对码并开启同步'));
    await tester.pumpAndSettle();

    // 配对完成后的视图（含二维码）在窄屏也必须完整可见（溢出会直接抛异常）
    expect(find.textContaining('复制配对码'), findsOneWidget);
    expect(find.byType(PrettyQrView), findsOneWidget);
  });
}
