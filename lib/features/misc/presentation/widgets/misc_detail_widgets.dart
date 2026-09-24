import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_image_gallery.dart';

/// 实用工具模块「商品 / 账号详情」页的共用组件。
///
/// 珍兽详情（`/misc/market/detail`）与账号详情（`/misc/acc-market/detail`）
/// 结构完全同款，差异只在图片占位图标与文案，故统一在此实现。

/// 计算调用方小图在全局坐标系中的矩形（供画廊 Hero 动画定位）。
Rect? _widgetRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/* ============================== 详情页头 ============================== */

/// 详情页头：面包屑（返回 hub）+ 圆点标题 + 副标题。
///
/// [crumbTail] 形如 ` / 珍兽行情 / 商品详情`；[subtitle] 形如
/// `大区 · 服务器 · 编号 xxx`。
class MiscDetailHead extends StatelessWidget {
  const MiscDetailHead({
    super.key,
    required this.title,
    required this.subtitle,
    required this.crumbTail,
    required this.onCrumbTap,
    this.crumbRoot = '实用',
  });

  final String title;
  final String subtitle;
  final String crumbTail;
  final VoidCallback onCrumbTap;

  /// 面包屑首页文字（点击回模块 hub）。
  final String crumbRoot;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.only(bottom: TgSpacing.s22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CrumbLink(crumbRoot, onTap: onCrumbTap),
              Text(
                crumbTail,
                style: TgType.caption.copyWith(color: tg.t2, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: TgSpacing.sm),
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
          Text(subtitle, style: TgType.body14.copyWith(color: tg.t2)),
        ],
      ),
    );
  }
}

class _CrumbLink extends StatelessWidget {
  const _CrumbLink(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return InkWell(
      onTap: onTap,
      borderRadius: TgRadius.pillShape,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: TgType.caption.copyWith(color: tg.gold, letterSpacing: 1),
        ),
      ),
    );
  }
}

/* ============================== 详情主体 ============================== */

/// 详情主体卡：宽屏左图右信息（≥700），窄屏上下堆叠（图限宽 320 居中）。
class MiscDetailBody extends StatelessWidget {
  const MiscDetailBody({super.key, required this.image, required this.info});

  final Widget image;
  final Widget info;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth >= 700;
        return TgCard(
          basePadding: const EdgeInsets.all(22),
          child: stack
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: image),
                    const SizedBox(width: 22),
                    Expanded(child: info),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: image,
                      ),
                    ),
                    const SizedBox(height: 16),
                    info,
                  ],
                ),
        );
      },
    );
  }
}

/// 详情大图（远程商品图，加载失败回退 [fallbackIcon] 占位；点击放大）。
class MiscDetailImage extends StatefulWidget {
  const MiscDetailImage({
    super.key,
    required this.url,
    required this.caption,
    required this.fallbackIcon,
  });

  final String? url;
  final String caption;

  /// 占位 / 失败回退图标资产名（见 `TgIcon._paths`）。
  final String fallbackIcon;

  @override
  State<MiscDetailImage> createState() => _MiscDetailImageState();
}

class _MiscDetailImageState extends State<MiscDetailImage> {
  bool _hover = false;

  Widget _placeholder(double size, Color color) {
    return TgIcon(widget.fallbackIcon, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.url;
    final hasImg = url != null && url.isNotEmpty;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: hasImg ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (!hasImg) return;
          showTgImageGallery(
            context,
            images: [
              TgGalleryImage(
                url: url,
                caption: widget.caption,
                errorIcon: widget.fallbackIcon,
              ),
            ],
            sourceRect: _widgetRect(context),
            title: '商品图片预览',
          );
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tg.inset,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hover ? tg.goldTint(.5) : tg.border,
                width: 1,
              ),
            ),
            child: url == null || url.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _placeholder(52, _hover ? tg.gold2 : tg.t3),
                        const SizedBox(height: 10),
                        Text(
                          '商品图暂不可用',
                          style: TextStyle(fontSize: 11, color: tg.t3),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: 960, // 详情方形图约 320-400 宽，解码上限 @2x-@3x
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tg.gold2,
                                backgroundColor: tg.goldTint(.15),
                              ),
                            ),
                          ),
                    errorBuilder: (_, _, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _placeholder(52, tg.t3),
                          const SizedBox(height: 10),
                          Text(
                            '商品图暂不可用',
                            style: TextStyle(fontSize: 11, color: tg.t3),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 列表缩略图：方形裁切（64×64）；有图时可点击预览大图。
class MiscThumb extends StatefulWidget {
  const MiscThumb({
    super.key,
    required this.url,
    required this.caption,
    required this.fallbackIcon,
  });

  final String? url;
  final String caption;

  /// 占位 / 失败回退图标资产名（见 `TgIcon._paths`）。
  final String fallbackIcon;

  @override
  State<MiscThumb> createState() => _MiscThumbState();
}

class _MiscThumbState extends State<MiscThumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.url;
    final hasImg = url != null && url.isNotEmpty;
    final hot = _hover && hasImg; // 无可点图时不进入可点 hover 态
    Widget inner() {
      if (!hasImg) {
        return TgIcon(
          widget.fallbackIcon,
          size: 28,
          color: hot ? tg.gold2 : tg.t3,
        );
      }
      return Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        cacheWidth: 192, // 64×64 显示，解码上限到 @3x，避免原图全尺寸解码
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => TgIcon(
          widget.fallbackIcon,
          size: 28,
          color: hot ? tg.gold2 : tg.t3,
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : TgIcon(widget.fallbackIcon, size: 28, color: tg.t3),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: hasImg ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: hasImg
            ? () => showTgImageGallery(
                context,
                images: [
                  TgGalleryImage(
                    url: url,
                    caption: widget.caption,
                    errorIcon: widget.fallbackIcon,
                  ),
                ],
                sourceRect: _widgetRect(context),
                title: '商品图片预览',
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tg.inset,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hot ? tg.goldTint(.5) : tg.border,
                width: 1,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: inner(),
          ),
        ),
      ),
    );
  }
}

/* ============================== 详情信息 ============================== */

/// 信息格（原型 `pd-cell`）：小标签 + 值，[width] 由调用方按列宽算好。
class MiscInfoCell extends StatelessWidget {
  const MiscInfoCell({
    super.key,
    required this.label,
    required this.value,
    this.gold = false,
    this.width = 168,
  });

  final String label;
  final String value;

  /// 值是否用金色（重点信息）。
  final bool gold;

  final double width;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: tg.t3, letterSpacing: 1),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              color: gold ? tg.gold2 : tg.t1,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== 详情按钮 ============================== */

/// 金色主按钮（对应 `.btn btn-primary`）。
class MiscPrimaryButton extends StatefulWidget {
  const MiscPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;

  /// 可选前置图标资产名（见 `TgIcon._paths`）。
  final String? icon;

  @override
  State<MiscPrimaryButton> createState() => _MiscPrimaryButtonState();
}

class _MiscPrimaryButtonState extends State<MiscPrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(9),
          hoverColor: Colors.transparent,
          child: Ink(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: _hover
                  ? const LinearGradient(
                      colors: [Color(0xFFF6DCA8), Color(0xFFD4A86A)],
                    )
                  : tg.gradGold,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  TgIcon(widget.icon!, size: 15, color: TgTokens.btnInk),
                  const SizedBox(width: 7),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TgTokens.btnInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 描边按钮（对应 `.btn btn-line`）。
class MiscLineButton extends StatefulWidget {
  const MiscLineButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<MiscLineButton> createState() => _MiscLineButtonState();
}

class _MiscLineButtonState extends State<MiscLineButton> {
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
        borderRadius: BorderRadius.circular(9),
        hoverColor: Colors.transparent,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hover ? tg.goldTint(.45) : tg.borderHi,
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hover ? tg.t1 : tg.t2,
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== 兜底 ============================== */

/// 直接深链且无 extra 数据时的兜底提示。
class MiscDetailMissing extends StatelessWidget {
  const MiscDetailMissing({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onBack,
  });

  final String icon;
  final String title;
  final String hint;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgCard(
      basePadding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
          MiscLineButton(label: '返回行情列表', onTap: onBack),
        ],
      ),
    );
  }
}
