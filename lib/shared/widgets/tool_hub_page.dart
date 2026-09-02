import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';
import '../../core/responsive/breakpoints.dart';
import '../tools/tool_catalog.dart';
import 'page_head.dart';
import 'tool_card.dart';

/// 分组 hub 页（如「宝宝工具」）：页头 + 该分组工具列表。
///
/// 对应原型 `v-hub-*`：crumb / h1 / 描述 + hub-list（工具卡片纵排）。
class ToolHubPage extends StatelessWidget {
  const ToolHubPage({super.key, required this.group});

  final ToolGroup group;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final tools = ToolCatalog.ofGroup(group);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return SingleChildScrollView(
          padding: _pagePadding(compact),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TgPageHead(
                    crumbTail: group.hubCrumb,
                    title: group.hubTitle,
                    subtitle: group.hubSubtitle,
                  ),
                  const SizedBox(height: 4),
                  // hub-list：该分组下的工具卡片
                  for (var i = 0; i < tools.length; i++) ...[
                    ToolCard(tool: tools[i]),
                    if (i != tools.length - 1)
                      const SizedBox(height: TgSpacing.s14),
                  ],
                  const SizedBox(height: TgSpacing.s34),
                  Center(
                    child: Text(
                      '共 ${tools.length} 个工具 · 与畅游官方无关',
                      style: TgType.tag.copyWith(color: tg.t3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _pagePadding(bool compact) => compact
      ? const EdgeInsets.fromLTRB(
          16, 20 + Breakpoints.topbarOverlayHeight, 16, 40)
      : TgSpacing.pagePadding.copyWith(
          top: TgSpacing.pagePadding.top +
              Breakpoints.topbarOverlayHeight, // 预留悬浮顶栏
        );
}
