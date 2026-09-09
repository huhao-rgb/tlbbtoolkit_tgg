import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/shared/widgets/tg_image_gallery.dart';

/// 全屏图片画廊（TgImageGallery）交互测试：
/// - 打开后显示页码 / 标题 / 说明，缩略图 Hero 飞入不阻塞；
/// - 左右滑动翻页，页码与说明联动；
/// - 未放大时上下滑动关闭（超过阈值 / 快速甩动），小位移回弹；
/// - 顶栏关闭按钮飞回缩略图后关闭。
///
/// 测试环境网络图加载失败走 errorBuilder 占位，不影响手势逻辑。
void main() {
  const triggerKey = Key('open-gallery');
  final sourceRect = const Rect.fromLTWH(120, 120, 64, 64);

  Widget harness() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showTgImageGallery(
                context,
                images: const [
                  TgGalleryImage(
                    url: 'https://example.com/a.png',
                    caption: '图 A',
                    errorIcon: 'paw',
                  ),
                  TgGalleryImage(
                    url: 'https://example.com/b.png',
                    caption: '图 B',
                    errorIcon: 'paw',
                  ),
                ],
                sourceRect: sourceRect,
                title: '图片预览',
              ),
              child: const SizedBox(
                key: triggerKey,
                width: 64,
                height: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openGallery(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    // SizedBox 本身不可命中，但其外层 GestureDetector（opaque）会收到点击。
    await tester.tap(find.byKey(triggerKey), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(TgImageGallery), findsOneWidget);
  }

  testWidgets('打开画廊：页码、标题、说明展示；顶部关闭按钮存在', (tester) async {
    await openGallery(tester);

    expect(find.text('图片预览'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('图 A'), findsOneWidget);
    expect(find.byKey(const Key('tg-gallery-close')), findsOneWidget);
  });

  testWidgets('左右滑动翻页：页码与底部说明联动', (tester) async {
    await openGallery(tester);

    // 第一页 → 第二页（PageView 横向翻页）
    await tester.fling(
      find.byType(TgImageGallery),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('图 B'), findsOneWidget);
  });

  testWidgets('未放大时向下滑动超过阈值：关闭画廊', (tester) async {
    await openGallery(tester);

    await tester.drag(find.byType(TgImageGallery), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(TgImageGallery), findsNothing);
  });

  testWidgets('小位移上下滑动：回弹不关闭', (tester) async {
    await openGallery(tester);

    await tester.drag(find.byType(TgImageGallery), const Offset(0, 60));
    await tester.pumpAndSettle();

    expect(find.byType(TgImageGallery), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('点击顶栏关闭按钮：画廊关闭', (tester) async {
    await openGallery(tester);

    await tester.tap(find.byKey(const Key('tg-gallery-close')));
    await tester.pumpAndSettle();

    expect(find.byType(TgImageGallery), findsNothing);
  });

  testWidgets('鼠标滚轮：上滚放大（禁用翻页），下滚最小缩放到 0.5x', (tester) async {
    await openGallery(tester);

    final center = tester.getCenter(find.byType(TgImageGallery));
    final pageViewFinder = find.byType(PageView);

    // 初始 1x：可横向翻页
    expect(pageScale(tester), closeTo(1.0, 0.001));
    expect(
      tester.widget<PageView>(pageViewFinder).physics,
      isA<PageScrollPhysics>(),
    );

    // 上滚（dy < 0）→ 放大 → 缩放中禁用翻页
    await wheelScroll(tester, center, -10);
    expect(pageScale(tester), greaterThan(1.0));
    expect(
      tester.widget<PageView>(pageViewFinder).physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    // 连续下滚（dy > 0）→ 越过 1x 继续缩到最小 0.5x → 恢复翻页
    for (var i = 0; i < 8; i++) {
      await wheelScroll(tester, center, 20);
    }
    expect(pageScale(tester), closeTo(0.5, 0.001));
    expect(
      tester.widget<PageView>(pageViewFinder).physics,
      isA<PageScrollPhysics>(),
    );
  });
}

/// 读取画廊当前页缩放值（页面内缩放的 Transform.scale 矩阵 x 轴比例）。
double pageScale(WidgetTester tester) {
  final t = tester.widget<Transform>(
    find.byKey(const Key('gallery-page-zoom')).first,
  );
  return t.transform.storage[0];
}

/// 向绑定派发一次鼠标滚轮事件（用于验证桌面端滚轮缩放）。
Future<void> wheelScroll(
  WidgetTester tester,
  Offset position,
  double dy,
) async {
  tester.binding.handlePointerEvent(
    PointerScrollEvent(
      position: position,
      scrollDelta: Offset(0, dy),
      kind: PointerDeviceKind.mouse,
    ),
  );
  await tester.pump();
}
