import 'package:flutter/material.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';

/// 悬停状态构造器：设计稿大量依赖 hover 反馈。
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(context, _hovered),
  );
}

enum AppButtonKind { ghost, primary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.ghost,
    this.height = 36,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final textColor = switch (kind) {
      AppButtonKind.primary || AppButtonKind.danger => Colors.white,
      AppButtonKind.ghost => T.t2,
    };

    return HoverBuilder(
      builder: (context, hovered) {
        final primary = kind != AppButtonKind.ghost;
        return MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: onPressed,
            child: Opacity(
              opacity: enabled ? 1 : 0.35,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: switch (kind) {
                    AppButtonKind.primary => T.goldGradient,
                    AppButtonKind.danger => T.dangerGradient,
                    AppButtonKind.ghost => null,
                  },
                  color: primary ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: primary
                      ? null
                      : Border.all(
                          color: hovered && enabled
                              ? T.gold
                              : const Color(0x26FFFFFF),
                        ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (primary && hovered && enabled)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    Text(
                      label,
                      style: T.sans(
                        size: 13,
                        color: kind == AppButtonKind.primary
                            ? T.ink
                            : textColor,
                        weight: primary ? FontWeight.w600 : FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 方形印章 Logo（设计稿的 46 / 96 两种尺寸）。
class Seal extends StatelessWidget {
  const Seal({required this.character, this.size = 46, super.key});

  final String character;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: T.goldGradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: T.gold.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x8CFFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x40000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Center(
              child: Text(
                character,
                style: T.serif(
                  size: size * 0.45,
                  color: T.ink,
                  weight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左侧步骤栏：完成态 / 当前态 / 待办态。
class StepRail extends StatelessWidget {
  const StepRail({required this.labels, required this.currentIndex, super.key});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12.25),
              child: Container(width: 1.5, height: 14, color: T.hairline),
            ),
          _StepItem(
            index: i,
            label: labels[i],
            done: i < currentIndex,
            current: i == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.label,
    required this.done,
    required this.current,
  });

  final int index;
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? T.goldGradient : null,
              color: current ? T.gold.withValues(alpha: 0.1) : null,
              border: Border.all(
                color: current
                    ? T.gold
                    : done
                    ? T.deep
                    : const Color(0x29FFFFFF),
                width: 1.5,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: T.gold.withValues(alpha: 0.13),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: T.ink)
                : Text(
                    '${index + 1}',
                    style: T.sans(
                      size: 11.5,
                      color: current ? T.gold2 : T.t3,
                      height: 1,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Text(
            label,
            style: T.sans(
              size: 13,
              color: current
                  ? T.gold2
                  : done
                  ? T.t2
                  : T.t3,
              weight: current ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// 组件选择 / 保留数据用的整块可点卡片。
class CheckCard extends StatelessWidget {
  const CheckCard({
    required this.checked,
    required this.title,
    required this.description,
    this.onTap,
    this.tag,
    this.locked = false,
    super.key,
  });

  final bool checked;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? tag;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, hovered) => MouseRegion(
        cursor: locked ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: locked ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: checked ? T.gold.withValues(alpha: 0.04) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: checked
                    ? T.gold.withValues(alpha: 0.42)
                    : hovered && !locked
                    ? T.gold.withValues(alpha: 0.4)
                    : T.hairline,
              ),
            ),
            child: Opacity(
              opacity: locked ? 0.65 : 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckBoxSquare(checked: checked, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: T.sans(size: 13.5, color: T.t1),
                              ),
                            ),
                            if (tag != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: T.goldBorder),
                                ),
                                child: Text(
                                  tag!,
                                  style: T.sans(
                                    size: 10,
                                    color: T.gold2,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: T.sans(size: 11.5, color: T.t3, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckBoxSquare extends StatelessWidget {
  const CheckBoxSquare({required this.checked, this.size = 18, super.key});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: checked ? T.goldGradient : null,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: checked ? Colors.transparent : const Color(0x40FFFFFF),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.check,
        size: size * 0.68,
        color: checked ? T.ink : Colors.transparent,
      ),
    );
  }
}

/// 协议页底部 / 完成页使用的小号勾选行。
class CheckLine extends StatelessWidget {
  const CheckLine({
    required this.checked,
    required this.label,
    required this.onTap,
    this.fontSize = 13,
    this.gap = 10,
    super.key,
  });

  final bool checked;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckBoxSquare(checked: checked, size: fontSize > 12 ? 18 : 16),
            SizedBox(width: gap),
            Flexible(
              child: Text(
                label,
                style: T.sans(size: fontSize, color: T.t2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    required this.caption,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    super.key,
  });

  final String caption;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: T.titleBarHeight,
      decoration: const BoxDecoration(
        color: Color(0x06FFFFFF),
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: T.goldGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '天',
              style: T.serif(
                size: 12,
                color: T.ink,
                weight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            caption,
            style: T.sans(size: 12.5, color: T.t2, letterSpacing: 0.5),
          ),
          const Spacer(),
          _WindowButton(icon: Icons.remove, tooltip: '最小化', onTap: onMinimize),
          _WindowButton(
            icon: Icons.crop_square,
            iconSize: 10,
            tooltip: '最大化',
            onTap: onMaximize,
          ),
          _WindowButton(
            icon: Icons.close,
            iconSize: 13,
            tooltip: '关闭',
            danger: true,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 11,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: HoverBuilder(
        builder: (context, hovered) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: T.titleBarHeight,
            alignment: Alignment.center,
            color: hovered
                ? danger
                      ? T.danger
                      : T.hover
                : Colors.transparent,
            child: Icon(
              icon,
              size: iconSize,
              color: hovered && danger ? Colors.white : T.t3,
            ),
          ),
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    required this.version,
    required this.steps,
    required this.currentIndex,
    required this.footTip,
    this.extra,
    super.key,
  });

  final String version;
  final List<String> steps;
  final int currentIndex;
  final Widget footTip;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: T.sideWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121216), Color(0xFF0E0E12)],
        ),
        border: Border(right: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Seal(character: '工'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '天工阁',
                      style: T.sans(
                        size: 17,
                        weight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '天龙怀旧工具箱 · $version',
                      style: T.sans(size: 11, color: T.t3, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('工欲善其事，必先利其器', style: T.serif(size: 12.5, color: T.t3)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: StepRail(labels: steps, currentIndex: currentIndex),
            ),
          ),
          if (extra != null) ...[extra!, const SizedBox(height: 12)],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
            ),
            child: footTip,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.subtitle,
    this.gap = 20,
    super.key,
  });

  final String title;
  final String subtitle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: T.sans(size: 21, weight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 7),
        Text(subtitle, style: T.sans(size: 12.5, color: T.t3, height: 1.7)),
        SizedBox(height: gap),
        Container(height: 1, color: const Color(0x12FFFFFF)),
      ],
    );
  }
}

class FooterBar extends StatelessWidget {
  const FooterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: T.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: const BoxDecoration(
        color: Color(0x04FFFFFF),
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Row(children: children),
    );
  }
}
