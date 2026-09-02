import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_tokens.dart';
import '../tools/tool_catalog.dart';
import 'tg_icon.dart';

/// 工具卡片（按原型 `.tool-card` 还原）：
/// - 图标砖：44×44·r12，按分组着色（宝宝=金 / 兽灵·兽魂=紫 / 职业=蓝），
///   同色 10% 底 + 28% 描边，图标 21px；
/// - padding 17/16 · gap 14 · 描述单行省略；
/// - hover（200ms）：上浮 -2px · 描边泛金(.32) · 背景 card2 · 右箭头滑出泛金。
class ToolCard extends StatefulWidget {
  const ToolCard({super.key, required this.tool});

  final ToolDef tool;

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _hover ? tg.card2 : tg.card,
          borderRadius: TgRadius.card,
          border: Border.all(
            color: _hover ? tg.goldTint(.32) : tg.border,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: TgRadius.card,
          child: InkWell(
            borderRadius: TgRadius.card,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () => context.go(widget.tool.location),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              child: Row(
                children: [
                  _ToolTile(tool: widget.tool),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // tc-name：14.5/500 · 与热门角标 gap8
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.tool.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TgType.cardTitle.copyWith(color: tg.t1),
                              ),
                            ),
                            if (widget.tool.isHot) ...[
                              const SizedBox(width: 8),
                              const TgHotBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        // tc-desc：12 · t3 · 单行省略
                        Text(
                          widget.tool.cardDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TgType.caption.copyWith(color: tg.t3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // chev：16 · hover 泛金并右移
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                      _hover ? 3 : 0,
                      0,
                      0,
                    ),
                    child: TgIcon(
                      'chev',
                      size: 16,
                      color: _hover ? tg.gold : tg.t3,
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

/// 图标砖：44×44 r12 · 分组主色 10% 底 + 28% 描边 · 图标 21。
class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final main = switch (tool.group) {
      ToolGroup.pet => tg.gold,
      ToolGroup.beast => tg.purple,
      ToolGroup.job => tg.blue,
    };
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: main.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(TgRadius.r12),
        border: Border.all(color: main.withValues(alpha: .28), width: 1),
      ),
      child: TgIcon(tool.icon, size: 21, color: main),
    );
  }
}

/// 「热门」角标：金渐变底 · r5 · 10/600 墨字（内联于 tc-name）。
class TgHotBadge extends StatelessWidget {
  const TgHotBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        gradient: tg.gradGold,
        borderRadius: BorderRadius.circular(TgRadius.xs),
        boxShadow: TgShadows.goldBadge,
      ),
      child: Text(
        '热门',
        style: TgType.hot.copyWith(color: TgTokens.btnInk),
      ),
    );
  }
}
