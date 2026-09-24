import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

/// 实用工具模块的通用小组件（行情 / 账号 / 回归等页面共用）。
///
/// 与 `shared/widgets/` 的分工：这里只放**只在 misc 模块成型**的组件
/// （区块标题、胶囊标签、统计格、拉取状态条、空态、小按钮 …）；
/// 跨 feature 复用的（卡片壳 [TgCard]、页脚 [TgPageFoot]、note 条
/// [TgNoteBar]、占比条行 [TgBarRow]）一律走 shared。

/* ============================== 区块标题 ============================== */

/// 区块标题（原型 `pm-sec h4`：金条 + serif 标题 + 可选尾部内容）。
class MiscSectionHead extends StatelessWidget {
  const MiscSectionHead({
    super.key,
    required this.title,
    this.trailing,
    this.titleExpanded = true,
  });

  final String title;
  final Widget? trailing;

  /// 标题是否占满整行；false 时标题按自然宽度排布，
  /// 使 [trailing]（如「共 N 条」小字）紧跟标题文字。
  final bool titleExpanded;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final titleWidget = Text(
      title,
      style: TextStyle(
        fontFamily: TgFonts.serif,
        fontSize: 15,
        color: tg.t1,
        letterSpacing: 1,
        height: 1.3,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: tg.gradGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        if (titleExpanded)
          Expanded(child: titleWidget)
        else
          Flexible(child: titleWidget),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

/* ============================== 胶囊标签 ============================== */

/// 胶囊标签（原型 `pm-tag`）：金描边（重点）/ 中性描边（普通）。
class MiscTag extends StatelessWidget {
  const MiscTag({super.key, required this.text, this.gold = false});

  final String text;

  /// true = 金描边 + `gold2` 文字；false = `borderHi` 描边 + `t3` 文字。
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold ? tg.goldTint(.4) : tg.borderHi,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: gold ? tg.gold2 : tg.t3),
      ),
    );
  }
}

/* ============================== 统计格 ============================== */

/// 统计卡组（`label / value` 列表）：窄屏两列、桌面四列。
class MiscStatGrid extends StatelessWidget {
  const MiscStatGrid({super.key, required this.items});

  /// (标签, 数值) 列表。
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 600 ? 2 : 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value) in items)
              SizedBox(
                width: (c.maxWidth - 12 * (cols - 1)) / cols,
                child: MiscStatCell(label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

/// 统计卡单格：小标签 + serif 大数值。
class MiscStatCell extends StatelessWidget {
  const MiscStatCell({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: tg.t3, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 22,
              color: tg.gold2,
              letterSpacing: 1,
              height: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== 拉取状态 ============================== */

/// 获取成功提示（绿）。
class MiscStatusOk extends StatelessWidget {
  const MiscStatusOk({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MiscStatusBar(color: const Color(0xFF7FC88F), message: message);
  }
}

/// CORS / 网络失败提示（琥珀）。
class MiscStatusWarn extends StatelessWidget {
  const MiscStatusWarn({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MiscStatusBar(color: const Color(0xFFE0B25C), message: message);
  }
}

/// 状态条外壳（ok 绿 / warn 琥珀共用），message 含标题段（首个「：」前加粗）。
class MiscStatusBar extends StatelessWidget {
  const MiscStatusBar({super.key, required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    final idx = message.indexOf('：');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: .28), width: 1),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12, color: color, height: 1.6),
          children: [
            if (idx > 0) ...[
              TextSpan(
                text: message.substring(0, idx + 1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: message.substring(idx + 1)),
            ] else
              TextSpan(text: message),
          ],
        ),
      ),
    );
  }
}

/// 「一键获取最新数据」主按钮（`.btn btn-primary pm-fetch`）。
///
/// 金渐变 · 墨字 · 常态辉光（0 5 20 rgba(198,152,86,.3)）·
/// hover 上浮 1px 并提亮（brightness 1.08）；[fetching] 时禁用为灰金底。
class MiscFetchButton extends StatefulWidget {
  const MiscFetchButton({
    super.key,
    required this.fetching,
    required this.onTap,
  });

  final bool fetching;
  final VoidCallback onTap;

  @override
  State<MiscFetchButton> createState() => _MiscFetchButtonState();
}

class _MiscFetchButtonState extends State<MiscFetchButton> {
  bool _hover = false;

  // hover 提亮渐变（≈ 原型 brightness(1.08)）。
  static const _hoverGradient = LinearGradient(
    colors: [Color(0xFFF8E1AF), Color(0xFFE0B27A)],
  );

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final fetching = widget.fetching;
    final on = !fetching;
    // hover 增强辉光（≈ 原型 filter:brightness(1.08) 使辉光一并提亮）。
    final glow = _hover && on
        ? const [
            BoxShadow(
              offset: Offset(0, 6),
              blurRadius: 26,
              color: Color(0x59C69856),
            ),
          ]
        : TgShadows.primaryButton;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover && on ? -1 : 0, 0),
        decoration: BoxDecoration(
          gradient: on ? tg.gradGold : null,
          color: on ? null : tg.goldTint(.14),
          borderRadius: BorderRadius.circular(11),
          boxShadow: on ? glow : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: on ? widget.onTap : null,
            borderRadius: BorderRadius.circular(11),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Ink(
              height: 41,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                // hover 提亮叠加（放 Ink 上，随辉光一同呈现）
                gradient: on && _hover ? _hoverGradient : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TgIcon(
                    'spark',
                    size: 15,
                    color: on ? TgTokens.btnInk : tg.gold2,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    fetching ? '正在获取…' : '一键获取最新数据',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: on ? TgTokens.btnInk : tg.gold2,
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

/* ============================== 小按钮 ============================== */

/// 描边小按钮（`pm-detail-btn` / 性价比行的「详情」）：hover 金描边 + 金字。
///
/// 尺寸可配：明细行用默认（12/5 · 8 圆角 · 11.5），性价比行用
/// `height: 22, radius: 7, fontSize: 11, horizontalPadding: 9`。
class MiscMiniButton extends StatefulWidget {
  const MiscMiniButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height,
    this.radius = 8,
    this.fontSize = 11.5,
    this.horizontalPadding = 12,
    this.verticalPadding = 5,
  });

  final String label;
  final VoidCallback onTap;

  /// 固定高度；null 时由 [verticalPadding] 撑起。
  final double? height;

  final double radius;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  State<MiscMiniButton> createState() => _MiscMiniButtonState();
}

class _MiscMiniButtonState extends State<MiscMiniButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.radius),
        hoverColor: Colors.transparent,
        child: Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: _hover ? tg.goldTint(.45) : tg.borderHi,
              width: 1,
            ),
            color: _hover ? tg.goldTint(.06) : Colors.transparent,
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: _hover ? tg.gold2 : tg.t2,
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== 整行点击 ============================== */

/// 明细行可点击外壳：整行点击进入详情；hover 显示点击光标 + 金色高亮底。
///
/// 行内子控件（缩略图预览、小按钮）自身注册的点击在命中区优先，
/// 外层整行点击只负责其余空白区域的跳转。
class MiscTappableRow extends StatefulWidget {
  const MiscTappableRow({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<MiscTappableRow> createState() => _MiscTappableRowState();
}

class _MiscTappableRowState extends State<MiscTappableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hover ? tg.goldTint(.05) : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

/* ============================== 空态 / 加载 ============================== */

/// 区块内空态文案（`当前筛选无数据`）。
class MiscEmptyTip extends StatelessWidget {
  const MiscEmptyTip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: 13, color: tg.t3)),
    );
  }
}

/// 首次拉取 loading 占位。
class MiscLoadingPanel extends StatelessWidget {
  const MiscLoadingPanel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: tg.gold2,
              backgroundColor: tg.goldTint(.15),
            ),
          ),
          const SizedBox(height: 14),
          Text(text, style: TextStyle(fontSize: 13, color: tg.t3)),
        ],
      ),
    );
  }
}

/// 无数据空态（接口失败或返回空时）。
class MiscEmptyPanel extends StatelessWidget {
  const MiscEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  /// 占位图标资产名（见 `TgIcon._paths`）。
  final String icon;

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          TgIcon(icon, size: 26, color: tg.t3),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, color: tg.t2)),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: tg.t3, height: 1.6),
          ),
        ],
      ),
    );
  }
}
