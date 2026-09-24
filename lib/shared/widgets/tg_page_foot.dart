import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';

/// 页脚（原型 `.page-foot`）：64×1 分隔线 + 居中说明文案。
///
/// 全站各页页脚同款（首页 / 门派 / 职业 / 珍兽 / 实用 / 设置 …），
/// 差异只在文案与行数：[text] 为第一行，[sub] 为可选的第二行小字。
class TgPageFoot extends StatelessWidget {
  const TgPageFoot({super.key, required this.text, this.sub});

  /// 第一行说明文案。
  final String text;

  /// 可选第二行小字（如「界面数据均为演示样例…」）。
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final style = TgType.tag.copyWith(color: tg.t3);
    return Center(
      child: Column(
        children: [
          Container(width: 64, height: 1, color: tg.border),
          const SizedBox(height: TgSpacing.sm),
          Text(text, textAlign: TextAlign.center, style: style),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, textAlign: TextAlign.center, style: style),
          ],
        ],
      ),
    );
  }
}
