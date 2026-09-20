import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
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

  setUp(() {
    engine = FakeMusicEngine();
    repository = FakeMusicPlayerRepository(
      const MusicPlayerState(tracks: [trackA, trackB], volume: .4),
    );
    picker = FakeMusicFilePicker();
  });

  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicPlayerRepositoryProvider.overrideWithValue(repository),
          musicEngineProvider.overrideWithValue(engine),
          musicFilePickerProvider.overrideWithValue(picker),
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

  /// 点按钮打开弹层并消化 200ms 入场动画。
  Future<void> openPopover(WidgetTester tester) async {
    await tester.tap(find.byTooltip('怀旧音律'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  /// 弹层控制条按钮内的图标（用于断言播放/暂停等视觉状态）。
  Icon ctlIcon(WidgetTester tester, String key) => tester.widget<Icon>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Icon)),
  );

  testWidgets('点击按钮弹出面板：标题 + 列表 + 控制条', (tester) async {
    await pumpButton(tester);
    expect(find.text('怀旧音律'), findsNothing);

    await openPopover(tester);
    expect(find.text('怀旧音律'), findsOneWidget);
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

  testWidgets('移动端窄屏（390×844）：弹层仍完整可点且不溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpButton(tester);
    await openPopover(tester);

    // 面板宽度取 min(320, 94vw)：窄屏下仍能完整容纳控制条。
    expect(tester.takeException(), isNull);
    expect(find.text('大理城'), findsOneWidget);
    expect(find.byKey(const Key('music-next')), findsOneWidget);
    expect(find.text('本地'), findsOneWidget);
  });
}
