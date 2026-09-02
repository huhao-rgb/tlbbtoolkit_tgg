import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/design_tokens.dart';
import '../tools/tool_catalog.dart';
import 'page_head.dart';
import 'tg_icon.dart';

/// 工具页骨架占位（在逐个工具落地前统一渲染）。
///
/// 结构忠实于原型工具页：面包屑（首段可返回分组 hub）+ 页头 + 主体占位，
/// 主体先放「建设中」说明；后续每实现一个工具即替换为真实页面。
class ToolPlaceholderPage extends StatelessWidget {
  const ToolPlaceholderPage({super.key, required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return SingleChildScrollView(
          padding: compact
              ? const EdgeInsets.fromLTRB(16, 20, 16, 40)
              : TgSpacing.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TgPageHead(
                    crumbLeft: tool.crumbRoot,
                    crumbTail: tool.crumb.substring(tool.crumbRoot.length),
                    onCrumbLeftTap: () => context.go(tool.group.hubLocation),
                    title: tool.title,
                    subtitle: tool.pageSubtitle,
                  ),
                  _PlaceholderCard(tool: tool),
                  const SizedBox(height: TgSpacing.s34),
                  const _PageFoot(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 主体占位：图标 + 说明 + 数据版本注释。
class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.tool});

  final ToolDef tool;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: TgSpacing.cardPadding,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tg.card2,
              borderRadius: BorderRadius.circular(TgRadius.r14),
              border: Border.all(color: tg.goldTint(.35), width: 1),
            ),
            child: TgIcon(tool.icon, size: 28, color: tg.gold),
          ),
          const SizedBox(height: TgSpacing.md),
          Text(
            '「${tool.title}」内容建设中',
            style: TgType.control15.copyWith(color: tg.t1),
          ),
          const SizedBox(height: TgSpacing.xs),
          Text(
            '页面骨架已就位，下一步接入 tg JSON v1.6.0 数据并实现真实交互。',
            textAlign: TextAlign.center,
            style: TgType.caption.copyWith(color: tg.t2),
          ),
        ],
      ),
    );
  }
}

/// 页脚：或nament + 免责声明（对应原型 `.page-foot`）。
class _PageFoot extends StatelessWidget {
  const _PageFoot();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Column(
      children: [
        Container(width: 64, height: 1, color: tg.border),
        const SizedBox(height: TgSpacing.sm),
        Text(
          '天工阁 · 玩家自制工具集合，与畅游官方无关',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
        const SizedBox(height: 2),
        Text(
          '界面数据均为演示样例，正式版接入实战回归数值',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
      ],
    );
  }
}
