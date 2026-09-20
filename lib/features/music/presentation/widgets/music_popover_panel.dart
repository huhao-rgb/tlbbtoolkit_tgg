import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../domain/entities/music_player_state.dart';
import '../../domain/entities/music_track.dart';
import '../providers/music_player_providers.dart';
import 'music_eq_bars.dart';

/// 弹层理想宽度（原型 `.bgm-pop{width:min(320px,94vw)}`）。
const double kMusicPopoverWidth = 320;

/// 列表最大高度（原型 `.bgm-list{max-height:264px}`）。
const double _listMaxHeight = 264;

/// 列表占视口高度的上限：窗口过矮（如横屏手机）时收敛列表高度，
/// 保证「标题 + 列表 + 控制条」整体不出屏。
const double _listViewportRatio = .45;

/// hover 底色（与侧栏导航项一致：深色白 4% / 浅色墨 5%）。
const _hoverDark = Color(0x0AFFFFFF);
const _hoverLight = Color(0x0D2A251D);

/// 「怀旧音律」面板内容（标题 + 播放列表 + 播放控制条）。
///
/// 桌面弹层 [MusicPopoverPanel] 与移动端底部面板（`music_panel_sheet.dart`）
/// 共用这份内容，只在外层 chrome（宽度/圆角/阴影/拖拽手柄）上区分。
///
/// ⚠️ 桌面弹层挂在 `CompositedTransformFollower`（`RenderFollowerLayer`）之下，
/// 该 layer 的 paint transform 只在**绘制阶段**才建立。因此面板内部**不要**放
/// `Tooltip` / `DropdownMenu` 等依赖 `OverlayPortal.overlayChildLayoutBuilder`
/// 的组件 —— 它们在 layout 阶段取不到 transform，会抛
/// "The paint transform cannot be reliably computed because of RenderFollowerLayer(s)"。
/// 提示语义改用 `Icon.semanticLabel` / `Semantics` 表达（见 `_CtlButton`）。
class MusicPanelContent extends ConsumerWidget {
  const MusicPanelContent({super.key, required this.maxListHeight});

  /// 列表区最大高度（由外层按视口高度算好）。
  final double maxListHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Head(state: state),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: _TrackList(state: state),
          ),
        ),
        const _Controls(),
      ],
    );
  }
}

/// 桌面弹层（对应原型 `#bgmPop`）：锚定信息栏按钮右下方的浮层。
///
/// 仅用于桌面布局（≥ [Breakpoints.desktop]）。窄窗口/移动端改用底部面板
/// （`showMusicPanelSheet`）：`CompositedTransformFollower` 的锚定位置依赖
/// 目标已绘制的位置，窄屏下弹层容易被推到屏幕外。
class MusicPopoverPanel extends StatelessWidget {
  const MusicPopoverPanel({super.key, required this.width});

  /// 由弹出方按屏幕宽度算好的实际宽度。
  final double width;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final maxListHeight = math.min(
      _listMaxHeight,
      MediaQuery.sizeOf(context).height * _listViewportRatio,
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tg.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: tg.borderHi, width: 1),
          // 原型 box-shadow:0 18px 46px rgba(0,0,0,.5)
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 46,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: MusicPanelContent(maxListHeight: maxListHeight),
      ),
    );
  }
}

/// 弹层标题（原型 `.bgm-head`）：衬线金色主标题 + 说明附注。
class _Head extends StatelessWidget {
  const _Head({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final subtitle = state.isEmpty
        ? '本地音乐 · 待添加'
        : '本地音乐 · 共 ${state.tracks.length} 首';
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '怀旧音律',
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 14.5,
              letterSpacing: 2,
              color: tg.gold,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, letterSpacing: 1, color: tg.t3),
            ),
          ),
        ],
      ),
    );
  }
}

/// 播放列表（原型 `.bgm-list`）；列表为空时展示引导文案。
class _TrackList extends StatelessWidget {
  const _TrackList({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) return const _EmptyHint();
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(6),
      itemCount: state.tracks.length,
      itemBuilder: (context, index) => _TrackItem(
        index: index,
        track: state.tracks[index],
        active: index == state.currentIndex,
        playing: state.playing,
        unavailable: state.unavailable.contains(state.tracks[index].path),
      ),
    );
  }
}

/// 空列表引导（原型的内置曲目未接入，首次打开时列表为空）。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TgIcon('note', size: 22, color: tg.t3),
          const SizedBox(height: 10),
          Text('播放列表还是空的', style: TextStyle(fontSize: 12.5, color: tg.t2)),
          const SizedBox(height: 4),
          Text(
            '点击右下角「本地」添加音乐文件',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, letterSpacing: .5, color: tg.t3),
          ),
        ],
      ),
    );
  }
}

/// 列表行（原型 `.bgm-item`）：音符图标 + 曲名/来源 + 播放中均衡器。
class _TrackItem extends ConsumerStatefulWidget {
  const _TrackItem({
    required this.index,
    required this.track,
    required this.active,
    required this.playing,
    required this.unavailable,
  });

  final int index;
  final MusicTrack track;
  final bool active;
  final bool playing;
  final bool unavailable;

  @override
  ConsumerState<_TrackItem> createState() => _TrackItemState();
}

class _TrackItemState extends ConsumerState<_TrackItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    // 原型配色优先级：.on（金 .12 底 · gold2 字）> hover（hover 底 · t1 字）> 常态
    final Color titleColor = widget.active
        ? tg.gold2
        : (_hover ? tg.t1 : tg.t2);
    final Color? background = widget.active
        ? tg.goldTint(.12)
        : (_hover ? (isDark ? _hoverDark : _hoverLight) : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref
              .read(musicPlayerControllerProvider.notifier)
              .playAt(widget.index),
          borderRadius: BorderRadius.circular(TgRadius.md),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(TgRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                TgIcon(
                  'note',
                  size: 15,
                  color: widget.active ? tg.gold : tg.t3,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .5,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.unavailable ? '文件不可用' : '本地音乐',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: widget.unavailable ? tg.red : tg.t3,
                        ),
                      ),
                    ],
                  ),
                ),
                // 原型 `.bgm-item .eq-on{margin-left:auto}`：仅当前播放项显示
                if (widget.active && widget.playing) const MusicEqBars(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 控制条（原型 `.bgm-foot`）：上一首 / 播放暂停 / 下一首 / 音量 / 循环 / 本地。
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final empty = state.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          _CtlButton(
            key: const Key('music-prev'),
            icon: Icons.skip_previous_rounded,
            label: '上一首',
            enabled: !empty,
            onTap: controller.previous,
          ),
          const SizedBox(width: 6),
          _CtlButton(
            key: const Key('music-play-toggle'),
            icon: state.playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            label: state.playing ? '暂停' : '播放',
            main: true,
            enabled: !empty,
            onTap: controller.toggle,
          ),
          const SizedBox(width: 6),
          _CtlButton(
            key: const Key('music-next'),
            icon: Icons.skip_next_rounded,
            label: '下一首',
            enabled: !empty,
            onTap: controller.next,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _VolumeSlider(
              key: const Key('music-volume'),
              volume: state.volume,
              onChanged: controller.setVolume,
            ),
          ),
          const SizedBox(width: 6),
          _CtlButton(
            key: const Key('music-loop'),
            icon: Icons.repeat_rounded,
            label: state.loop ? '循环播放：开' : '循环播放：关',
            active: state.loop,
            onTap: controller.toggleLoop,
          ),
          const SizedBox(width: 6),
          const _LocalAddButton(key: Key('music-add-local')),
        ],
      ),
    );
  }
}

/// 控制条按钮（原型 `.bgm-ctl`）：常态 28×28，主按钮（播放/暂停）34×34 金色。
///
/// 这里**没有**用 `Tooltip`（原因见 [MusicPopoverPanel] 的说明），
/// 提示文案改为图标的无障碍标签 `Icon.semanticLabel`。
class _CtlButton extends StatefulWidget {
  const _CtlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.main = false,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;

  /// 按钮语义标签（同时用作测试定位的说明文案）。
  final String label;

  final VoidCallback onTap;

  /// 主按钮样式（原型 `.bgm-ctl.main`）。
  final bool main;

  /// 选中态着色（原型循环按钮开时 `color:gold2`）。
  final bool active;

  final bool enabled;

  @override
  State<_CtlButton> createState() => _CtlButtonState();
}

class _CtlButtonState extends State<_CtlButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    final hovered = _hover && widget.enabled;

    final Color iconColor;
    final Color background;
    final Color border;
    if (widget.main) {
      iconColor = tg.gold;
      background = tg.goldTint(.1);
      border = tg.goldTint(hovered ? .7 : .5);
    } else {
      iconColor = hovered ? tg.gold2 : (widget.active ? tg.gold2 : tg.t2);
      background = isDark ? _hoverDark : _hoverLight;
      border = hovered || widget.active ? tg.goldTint(.45) : tg.borderHi;
    }

    final size = widget.main ? 34.0 : 28.0;
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Opacity(
        opacity: widget.enabled ? 1 : .45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(TgRadius.s8),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(TgRadius.s8),
                border: Border.all(color: border, width: 1),
              ),
              child: Icon(
                widget.icon,
                size: widget.main ? 20 : 18,
                color: iconColor,
                semanticLabel: widget.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 音量滑杆（原型 `#bgmVol`）：金色细轨（3px）+ 小圆点。
///
/// 不用 `Tooltip` 显示百分比（原因见 [MusicPopoverPanel]）：
/// `Slider` 自带 value semantics，读屏可直接播报当前音量。
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: tg.gold,
        inactiveTrackColor: tg.borderHi,
        thumbColor: tg.gold,
        overlayColor: tg.goldTint(.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: SizedBox(
        height: 24,
        child: Slider(value: volume, onChanged: onChanged),
      ),
    );
  }
}

/// 「本地」按钮（原型 `.bgm-add`）：虚线描边 + 选中音频文件追加到列表。
///
/// 不用 `Tooltip`（原因见 [MusicPopoverPanel]）：按钮自带「本地」文字，
/// 语义已完整。
class _LocalAddButton extends ConsumerStatefulWidget {
  const _LocalAddButton({super.key});

  @override
  ConsumerState<_LocalAddButton> createState() => _LocalAddButtonState();
}

class _LocalAddButtonState extends ConsumerState<_LocalAddButton> {
  bool _hover = false;

  Future<void> _pick() async {
    final result = await ref
        .read(musicPlayerControllerProvider.notifier)
        .addLocalFiles();
    if (!mounted) return;
    // 选中了但一首都没加：说明全是列表里已有的曲目。
    if (result.picked > 0 && result.added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所选音乐已在播放列表中'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: _hover ? tg.goldTint(.5) : tg.borderHi,
          radius: TgRadius.s8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pick,
            borderRadius: BorderRadius.circular(TgRadius.s8),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: SizedBox(
              height: 28,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '本地',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1,
                      color: _hover ? tg.gold2 : tg.t3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 虚线圆角边框（对应原型 `.bgm-add{border:1px dashed}`）。
///
/// 与 `beast_soul_page` 的同名私有画笔实现一致（参数不同：radius / color），
/// 暂未提升为共享组件以免改动既有页面。
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, math.min(dist + _dash, metric.length)),
          paint,
        );
        dist += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
