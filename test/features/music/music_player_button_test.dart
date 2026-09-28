import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_store.dart';
import 'package:tlbbtoolkit/features/music/data/repositories/music_player_repository_impl.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_eq_bars.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_player_button.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_popover_panel.dart';

import 'music_fakes.dart';

void main() {
  const trackA = MusicTrack(path: '/music/a.mp3', name: '大理城');
  const trackB = MusicTrack(path: '/music/b.mp3', name: '苏州');

  late FakeMusicEngine engine;
  late FakeMusicPlayerRepository repository;
  late FakeMusicFilePicker picker;
  late FakeMusicFileStore store;

  setUp(() {
    engine = FakeMusicEngine();
    repository = FakeMusicPlayerRepository(
      const MusicPlayerState(tracks: [trackA, trackB], volume: .4),
    );
    picker = FakeMusicFilePicker();
    store = FakeMusicFileStore();
  });

  /// 泵入按钮。[mobile] 为 true 时用手机尺寸（390×844，< 1024 断点），
  /// 否则用桌面尺寸（1440×1024）。
  Future<void> pumpButton(WidgetTester tester, {bool mobile = false}) async {
    tester.view.physicalSize = mobile
        ? const Size(390, 844)
        : const Size(1440, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicPlayerRepositoryProvider.overrideWithValue(repository),
          musicEngineProvider.overrideWithValue(engine),
          musicFilePickerProvider.overrideWithValue(picker),
          musicFileStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          theme: TgTheme.dark,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: MusicPlayerButton(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// 点按钮打开面板并消化入场动画（浮层 200ms / sheet 250ms）。
  Future<void> openPopover(WidgetTester tester) async {
    await tester.tap(find.byTooltip('怀旧音律'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 弹层控制条按钮内的图标（用于断言播放/暂停等视觉状态）。
  Icon ctlIcon(WidgetTester tester, String key) => tester.widget<Icon>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Icon)),
  );

  /// 弹层进度条（原型 `.bgm-prog` 里的 range）。
  Slider progressSlider(WidgetTester tester) =>
      tester.widget<Slider>(find.byKey(const Key('music-progress')));

  /// 左滑 [finder] 所在的行（分步移动：首个 move 事件会被触点阈值吃掉）。
  Future<void> swipeLeft(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    for (var step = 0; step < 10; step++) {
      await gesture.moveBy(const Offset(-26, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
  }

  /// 消化 Dismissible 的退场动画（位移 200ms + 收缩 300ms）。
  ///
  /// 不能用 `pumpAndSettle`：播放中列表项的 EQ 跳动条是无限动画。
  Future<void> settleDismiss(WidgetTester tester) async {
    for (var frame = 0; frame < 50; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('点击按钮弹出面板：标题 + 列表 + 控制条', (tester) async {
    await pumpButton(tester);
    expect(find.text('怀旧音律'), findsNothing);

    await openPopover(tester);
    expect(find.text('怀旧音律'), findsOneWidget);
    // 桌面：锚定浮层，不是底部 sheet
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('本地音乐 · 共 2 首'), findsOneWidget);
    expect(find.text('大理城'), findsOneWidget);
    expect(find.text('苏州'), findsOneWidget);
    // 控制条：上一首 / 播放暂停 / 下一首 / 音量 / 循环 / 本地
    expect(find.byKey(const Key('music-prev')), findsOneWidget);
    expect(find.byKey(const Key('music-play-toggle')), findsOneWidget);
    expect(find.byKey(const Key('music-next')), findsOneWidget);
    expect(find.byKey(const Key('music-volume')), findsOneWidget);
    expect(find.byKey(const Key('music-loop')), findsOneWidget);
    expect(find.byKey(const Key('music-add-local')), findsOneWidget);
    expect(find.text('本地'), findsOneWidget);
    // 进度条：未选曲时为 0:00 / 0:00
    expect(find.byKey(const Key('music-progress')), findsOneWidget);
    expect(find.text('0:00'), findsNWidgets(2));
  });

  testWidgets('进度条：播放后显示引擎上报的位置/时长，拖动松手才 seek', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);
    await tester.tap(find.text('苏州'));
    await tester.pump();
    expect(engine.playedPaths, ['/music/b.mp3']);

    // 引擎加载完成后上报时长，再周期性上报位置
    engine.emitDuration(const Duration(seconds: 100));
    await tester.pump();
    expect(find.text('1:40'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    engine.emitPosition(const Duration(seconds: 25));
    await tester.pump();
    expect(find.text('0:25'), findsOneWidget);
    expect(progressSlider(tester).value, closeTo(.25, .001));

    // 拖动：onChanged 只改本地显示，onChangeEnd 才落到引擎
    final slider = progressSlider(tester);
    slider.onChanged!(.8);
    await tester.pump();
    expect(find.text('1:20'), findsOneWidget, reason: '拖动中时间跟随手指');
    expect(engine.seeks, isEmpty, reason: '未松手不应 seek');

    slider.onChangeEnd!(.8);
    await tester.pump();
    expect(engine.seeks, [const Duration(seconds: 80)]);
    expect(progressSlider(tester).value, closeTo(.8, .001));
  });

  testWidgets('进度条：已选曲但时长未知时显示 --:-- 且不可拖动', (tester) async {
    repository = FakeMusicPlayerRepository(
      const MusicPlayerState(tracks: [trackA, trackB], currentIndex: 1),
    );
    await pumpButton(tester);
    await openPopover(tester);

    expect(find.text('--:--'), findsOneWidget);
    expect(progressSlider(tester).onChanged, isNull);
  });

  testWidgets('弹层内不允许出现 Tooltip（RenderFollowerLayer 下会崩布局）', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);

    // 面板挂在 CompositedTransformFollower 内，Tooltip 的气泡依赖
    // OverlayPortal.overlayChildLayoutBuilder，会在 layout 阶段取不到
    // paint transform 而抛断言。
    expect(
      find.descendant(
        of: find.byType(MusicPopoverPanel),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空列表：显示引导文案，播放控制置灰', (tester) async {
    repository = FakeMusicPlayerRepository();
    await pumpButton(tester);
    await openPopover(tester);

    expect(find.text('本地音乐 · 待添加'), findsOneWidget);
    expect(find.text('播放列表还是空的'), findsOneWidget);
    expect(find.text('点击右下角「本地」添加音乐文件'), findsOneWidget);

    await tester.tap(find.byKey(const Key('music-play-toggle')));
    await tester.pump();
    expect(engine.playedPaths, isEmpty);
  });

  testWidgets('再点按钮 / 点面板外 / Esc 均收起面板', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);
    // 打开时全屏遮罩盖住按钮，点按钮即"点面板外"关闭（与原型行为一致，
    // 因此这里命中遮罩而非按钮本身）。
    await tester.tap(find.byTooltip('怀旧音律'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('大理城'), findsNothing);

    await openPopover(tester);
    await tester.tapAt(const Offset(10, 400)); // 面板外（左下方空白区）
    await tester.pump();
    expect(find.text('大理城'), findsNothing);

    await openPopover(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('大理城'), findsNothing);
  });

  testWidgets('点「本地」把所选音乐追加进列表', (tester) async {
    picker.result = const [MusicTrack(path: '/music/c.mp3', name: '洛阳')];
    await pumpButton(tester);
    await openPopover(tester);
    expect(find.text('本地音乐 · 共 2 首'), findsOneWidget);

    await tester.tap(find.text('本地'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('洛阳'), findsOneWidget);
    expect(find.text('本地音乐 · 共 3 首'), findsOneWidget);
  });

  testWidgets('点曲目起播：引擎收到音量/循环，按钮与列表项转为均衡器', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);

    await tester.tap(find.text('苏州'));
    await tester.pump();

    expect(engine.playedPaths, ['/music/b.mp3']);
    expect(engine.volume, .4);
    expect(engine.loop, isFalse);
    // 顶栏按钮 + 当前列表项各一个
    expect(find.byType(MusicEqBars), findsNWidgets(2));
    // 播放中：控制条主按钮由「播放」变「暂停」
    expect(ctlIcon(tester, 'music-play-toggle').icon, Icons.pause_rounded);
  });

  testWidgets('点循环按钮切换状态并下发引擎', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);
    expect(ctlIcon(tester, 'music-loop').icon, Icons.repeat_rounded);

    await tester.tap(find.byKey(const Key('music-loop')));
    await tester.pump();

    expect(repository.state.loop, isTrue);
    // 选中态着色：图标转 gold2（浅/深色主题下分别为 TgColors 的对应值）
    expect(ctlIcon(tester, 'music-loop').color, TgColors.dark.gold2);
  });

  testWidgets('移动端（<1024 断点）：改为底部 sheet', (tester) async {
    await pumpButton(tester, mobile: true);
    expect(find.byType(BottomSheet), findsNothing);

    await openPopover(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('本地音乐 · 共 2 首'), findsOneWidget);
    expect(find.text('大理城'), findsOneWidget);
    expect(find.byKey(const Key('music-next')), findsOneWidget);
    expect(find.text('本地'), findsOneWidget);
    // 窄屏下整宽贴底，不再有横向/纵向出屏
    expect(tester.takeException(), isNull);
  });

  testWidgets('列表左滑删除：移除该曲目、停表并回收副本', (tester) async {
    await pumpButton(tester);
    await openPopover(tester);
    // 先播放第二首，验证删除当前曲目会停表（而不是继续播别的）
    await tester.tap(find.text('苏州'));
    await tester.pump();
    expect(engine.playedPaths, ['/music/b.mp3']);
    expect(ctlIcon(tester, 'music-play-toggle').icon, Icons.pause_rounded);

    await swipeLeft(tester, find.text('苏州'));
    await settleDismiss(tester);

    expect(store.removed, ['/music/b.mp3']);
    expect(find.byKey(const ValueKey('/music/b.mp3')), findsNothing);
    expect(find.byKey(const ValueKey('/music/a.mp3')), findsOneWidget);
    expect(find.text('本地音乐 · 共 1 首'), findsOneWidget);
    expect(engine.calls, contains('stop'));
    expect(store.removed, ['/music/b.mp3']);
    expect(ctlIcon(tester, 'music-play-toggle').icon, Icons.play_arrow_rounded);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移动端：sheet 内同样可以左滑删除', (tester) async {
    await pumpButton(tester, mobile: true);
    await openPopover(tester);

    await swipeLeft(tester, find.text('大理城'));
    await settleDismiss(tester);

    expect(store.removed, ['/music/a.mp3']);
    expect(find.text('大理城'), findsNothing);
    expect(find.text('本地音乐 · 共 1 首'), findsOneWidget);
    expect(store.removed, ['/music/a.mp3']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('移动端：点遮罩关闭 sheet', (tester) async {
    await pumpButton(tester, mobile: true);
    await openPopover(tester);

    await tester.tapAt(const Offset(195, 80)); // sheet 上方空白（遮罩）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('大理城'), findsNothing);
  });

  testWidgets('移动端：sheet 内点曲目起播，按钮转均衡器', (tester) async {
    await pumpButton(tester, mobile: true);
    await openPopover(tester);

    await tester.tap(find.text('苏州'));
    await tester.pump();

    expect(engine.playedPaths, ['/music/b.mp3']);
    expect(find.byType(MusicEqBars), findsNWidgets(2));
    expect(ctlIcon(tester, 'music-play-toggle').icon, Icons.pause_rounded);
  });
}
