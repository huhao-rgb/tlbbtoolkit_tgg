import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_tokens.dart';
import '../tools/tool_catalog.dart';
import 'tg_icon.dart';

/// 工具卡片：图标砖 + 名称（含「热门」角标）+ 描述 + 右箭头。
///
/// 用于首页工具网格与各 hub 列表，点击经目录中的 `location` 跳转。
/// 规格对应设计规范：卡片 r16 / 无投影，图标砖 44×44 r12，hot 角标 10/600 金底墨字。
class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      borderRadius: TgRadius.card,
      child: Ink(
        decoration: BoxDecoration(
          color: tg.card,
          borderRadius: TgRadius.card,
          border: Border.all(color: tg.border, width: 1),
        ),
        child: InkWell(
          borderRadius: TgRadius.card,
          onTap: () => context.go(tool.location),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TgSpacing.lg,
              vertical: TgSpacing.md,
            ),
            child: Row(
              children: [
                _ToolTile(tool: tool),
                const SizedBox(width: TgSpacing.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tool.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TgType.cardTitle.copyWith(color: tg.t1),
                            ),
                          ),
                          if (tool.isHot) ...[
                            const SizedBox(width: TgSpacing.xs),
                            const TgHotBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: TgSpacing.xs),
                      Text(
                        tool.cardDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TgType.caption.copyWith(color: tg.t2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TgSpacing.xs),
                Icon(Icons.chevron_right, size: 18, color: tg.t3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 图标砖：44×44 r12，底色 card2。
class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tg.card2,
        borderRadius: BorderRadius.circular(TgRadius.r12),
      ),
      child: TgIcon(tool.icon, size: 20, color: tg.gold),
    );
  }
}

/// 「热门」角标：金渐变底 · r5 · 10/600 墨字。
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
