import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/features/music/presentation/providers/music_player_providers.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_eq_bars.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_panel_sheet.dart';
import 'package:tlbbtoolkit/features/music/presentation/widgets/music_popover_panel.dart';

/// hover 底色（与侧栏导航项一致：深色白 4% / 浅色墨 5%）。
const _hoverDark = Color(0x0AFFFFFF);
const _hoverLight = Color(0x0D2A251D);

/// 信息栏「怀旧音律」按钮（对应原型 `.bgm-btn` / `#bgmBtn`）。
///
/// 点击后打开播放列表与控制面板，按布局分流（断点同 shell）：
/// - 桌面（≥ [Breakpoints.desktop]）：在按钮**右下方 9px、右对齐**弹出浮层
///   （原型 `position:fixed` 的效果，这里用 [OverlayPortal] +
///   [CompositedTransformFollower] 锚定按钮，窗口缩放时自动跟随），
///   点击面板外或按 Esc 关闭（原型 `document click` / `Escape`）；
/// - 移动端（< [Breakpoints.desktop]）：从底部弹出 sheet
///   （见 `showMusicPanelSheet`），避免窄屏下浮层出屏。
class MusicPlayerButton extends ConsumerStatefulWidget {
  const MusicPlayerButton({super.key});

  @override
  ConsumerState<MusicPlayerButton> createState() => _MusicPlayerButtonState();
}

class _MusicPlayerButtonState extends ConsumerState<MusicPlayerButton> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _hover = false;

  /// 打开播放面板：窄窗口/移动端走底部 sheet，桌面走锚定浮层。
  void _togglePanel() {
    final isMobileLayout =
        Breakpoints.layoutOf(MediaQuery.sizeOf(context).width) ==
        DeviceLayout.mobile;
    if (isMobileLayout) {
      showMusicPanelSheet(context);
      return;
    }
    _portal.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    final playing = ref.watch(
      musicPlayerControllerProvider.select((s) => s.playing),
    );

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPopover,
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Tooltip(
            message: '怀旧音律',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePanel,
                borderRadius: BorderRadius.circular(TgRadius.md),
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Ink(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    // 播放中：金 .12 底 + 金 .6 描边；hover：金 .45 描边。
                    color: playing
                        ? tg.goldTint(.12)
                        : (_hover
                              ? (isDark ? _hoverDark : _hoverLight)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(TgRadius.md),
                    border: Border.all(
                      color: playing
                          ? tg.goldTint(.6)
                          : (_hover ? tg.goldTint(.45) : tg.borderHi),
                      width: 1,
                    ),
                  ),
                  // 播放中显示跳动的均衡器，静默时显示音符图标。
                  child: Center(
                    child: playing
                        ? const MusicEqBars()
                        : TgIcon(
                            'note',
                            size: 17,
                            color: _hover ? tg.gold2 : tg.t2,
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

  /// 弹层：全屏透明遮罩（点空白关闭）+ 锚定按钮右下的面板。
  Widget _buildPopover(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // 原型 width:min(320px,94vw)
    final width = math.min(kMusicPopoverWidth, screen.width * .94);

    return Positioned.fill(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _portal.hide();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _portal.hide,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              // 原型：top = 按钮底 + 9，右缘与按钮对齐。
              offset: const Offset(0, 9),
              child: Align(
                alignment: Alignment.topRight,
                child: _PopoverEntrance(child: MusicPopoverPanel(width: width)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹层入场动画（原型 `@keyframes bgmIn`：`.2s` 内 opacity 0→1 · 上移 7px 归位）。
class _PopoverEntrance extends StatelessWidget {
  const _PopoverEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -7 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
