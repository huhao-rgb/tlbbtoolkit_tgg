import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// 页头（page-head）：面包屑 → 标题（含金色圆点）→ 描述。
///
/// 对应原型 `.page-head`：面包屑 12 / 字距1~2，标题 serif 24（h1），
/// 描述 14 / t2，标题前有金色圆点，标题下距 22px。
class TgPageHead extends StatelessWidget {
  const TgPageHead({
    super.key,
    this.crumbLeft,
    this.crumbTail,
    this.onCrumbLeftTap,
    required this.title,
    required this.subtitle,
  });

  /// 面包屑首段（可点击，如分组名「宝宝」）；为空则不渲染链接段。
  final String? crumbLeft;

  /// 面包屑其余部分（含分隔符与当前片段），如 `' / 资质计算'`。
  final String? crumbTail;

  /// 点击面包屑首段回调（通常返回该分组 hub）。
  final VoidCallback? onCrumbLeftTap;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final hasLeft = crumbLeft != null && crumbLeft!.isNotEmpty;
    final tail = crumbTail ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: TgSpacing.s22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 面包屑（首段链接 + 尾部同基线；不加固定高/垂直内边距，
          // 避免首段文字错位或被裁切）
          Row(
            children: [
              if (hasLeft) ...[
                InkWell(
                  key: Key('crumb-$crumbLeft'),
                  onTap: onCrumbLeftTap,
                  borderRadius: TgRadius.pillShape,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      crumbLeft!,
                      style: TgType.caption.copyWith(
                        color: tg.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                if (tail.isNotEmpty)
                  Text(
                    tail,
                    style: TgType.caption.copyWith(
                      color: tg.t2,
                      letterSpacing: 1,
                    ),
                  ),
              ] else if (tail.isNotEmpty)
                Text(
                  tail,
                  style: TgType.caption.copyWith(
                    color: tg.t2,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: TgSpacing.sm),
          // 标题（金色圆点 + serif 24）
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: tg.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: TgSpacing.s10),
              Flexible(
                child: Text(title, style: TgType.pageH1.copyWith(color: tg.t1)),
              ),
            ],
          ),
          const SizedBox(height: TgSpacing.s10),
          // 描述
          Text(subtitle, style: TgType.body14.copyWith(color: tg.t2)),
        ],
      ),
    );
  }
}
