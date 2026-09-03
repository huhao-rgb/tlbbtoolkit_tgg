import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/shell_navigation/shell_navigation_state.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/platform/app_window.dart';
import '../../gen/assets.gen.dart';

/// 自定义窗口标题栏高度（原型 `.titlebar` height:40px）。
const double windowTitleBarHeight = 40;

/// 窗口按钮 hover 底色（原型 `rgba(127,137,154,.18)`）。
const _hoverWin = Color(0x2E7F899A);

/// 关闭按钮 hover 底色（原型 `#E81123`）。
const _closeHover = Color(0xFFE81123);

/// 桌面自定义窗口标题栏（frameless），对应原型 `<header class="titlebar">`。
///
/// 顶置 40px 全宽，结构：品牌(logo + 天工阁 + 应用名) | 当前页 | 拖拽区 |
/// （Windows/Linux）最小化 · 最大化/还原 · 关闭。
/// - macOS：保留系统红绿灯，不绘制自定义按钮，左侧给红绿灯留位；
/// - Windows / Linux：隐藏系统标题栏，右侧自绘按钮接管窗口控制；
/// - 中段为拖拽区（按住拖动窗口，双击最大化/还原）。
class TgWindowTitleBar extends ConsumerStatefulWidget {
  const TgWindowTitleBar({super.key});

  @override
  ConsumerState<TgWindowTitleBar> createState() => _TgWindowTitleBarState();
}

class _TgWindowTitleBarState extends ConsumerState<TgWindowTitleBar> {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    subscribeMaximize(_onMaximizeChanged);
    _syncMaximized();
  }

  @override
  void dispose() {
    unsubscribeMaximize(_onMaximizeChanged);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final m = await windowIsMaximized();
    if (mounted) setState(() => _maximized = m);
  }

  void _onMaximizeChanged(bool value) {
    if (mounted) setState(() => _maximized = value);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final nav = ref.watch(shellNavigationProvider);
    final pageTitle = nav.title.isEmpty ? '首页' : nav.title;

    // 标题栏位于 MaterialApp.builder、在 Navigator/Scaffold 之上，
    // Text 没有可提供默认样式的 Material 祖先，桌面端会出现黄色双下划线；
    // 故外层补一个透明 Material，文字显式 decoration:none。
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: const Key('window-title-bar'),
        height: windowTitleBarHeight,
        decoration: BoxDecoration(
          color: tg.bg,
          border: Border(bottom: BorderSide(color: tg.border, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧留位：macOS 红绿灯 / 原型 padding-left 14
            SizedBox(width: titleBarLeadingPadding),
            const _BrandMark(),
            const SizedBox(width: 9),
            // tb-name：serif 13.5 · 600 · 字距2 · 金
            Align(
              alignment: Alignment.center,
              child: Text(
                '天工阁',
                style: TextStyle(
                  fontFamily: TgFonts.serif,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: tg.gold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 9),
            // tb-app：11 · t3 · 字距1 · 左侧细分隔
            _TitleSegment(text: '天龙八部怀旧版 · 工具箱', color: tg.t3, size: 11),
            const SizedBox(width: 10),
            // tb-page：当前页 12 · t2 · 字距1 · 最大 180 省略
            _TitleSegment(
              text: pageTitle,
              color: tg.t2,
              size: 12,
              maxWidth: 180,
            ),
            const SizedBox(width: 14),
            // 拖拽区
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => windowMaximizeToggle(),
                  onPanStart: (_) => windowStartDragging(),
                ),
              ),
            ),
            // Windows / Linux：自定义窗口按钮
            if (showCustomWindowButtons) _WindowControls(maximized: _maximized),
          ],
        ),
      ),
    );
  }
}

/// 品牌 mark（原型 tb-mark 21×21 seal）。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SvgPicture.asset(
        Assets.logo.logo,
        width: 21,
        height: 21,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// 标题栏带左侧分隔的文字段（原型 `.tb-app` / `.tb-page`：
/// `border-left:1px + padding-left:10px`）。
class _TitleSegment extends StatelessWidget {
  const _TitleSegment({
    required this.text,
    required this.color,
    required this.size,
    this.maxWidth,
  });

  final String text;
  final Color color;
  final double size;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: maxWidth == null
            ? null
            : BoxConstraints(maxWidth: maxWidth!),
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tg.borderHi, width: 1)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size,
            letterSpacing: 1,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// 窗口控制按钮组（最小化 / 最大化·还原 / 关闭），每个 46×标题栏高。
class _WindowControls extends StatelessWidget {
  const _WindowControls({required this.maximized});

  final bool maximized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          key: const Key('win-min'),
          icon: Icons.remove,
          onTap: windowMinimize,
        ),
        _WindowButton(
          key: const Key('win-max'),
          icon: maximized ? Icons.filter_none : Icons.crop_square,
          onTap: windowMaximizeToggle,
        ),
        _WindowButton(
          key: const Key('win-close'),
          icon: Icons.close,
          close: true,
          onTap: windowClose,
        ),
      ],
    );
  }
}

/// 单个窗口按钮：46 宽 · hover 底色（关闭钮为红）。
/// 注意：标题栏位于 Navigator 之上的 builder 层，没有 Overlay 祖先，
/// 不能用 Tooltip（会因找不到 Overlay 报错），故不加气泡提示。
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.close = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool close;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final hoverBg = widget.close ? _closeHover : _hoverWin;
    final hoverFg = widget.close ? Colors.white : tg.t1;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            width: 46,
            height: windowTitleBarHeight,
            color: _hover ? hoverBg : Colors.transparent,
            child: Icon(widget.icon, size: 14, color: _hover ? hoverFg : tg.t3),
          ),
        ),
      ),
    );
  }
}
