import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_image_gallery.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/account_market.dart';
import '../../domain/account_market_stats.dart';

/// 账号详情页（独立嵌套子路由 `/misc/acc-market/detail`）。
///
/// 从行情列表点击「详情」时 `context.push(..., extra: account)` 压栈到列表之上；
/// 返回（pop）后列表滚动位置天然保留，不会页面跳动。
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, this.account});

  /// 账号数据经路由 extra 传入；null（如直接深链）时展示缺失提示。
  final AccountListing? account;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final p = account;
        final blocks = <Widget>[
          if (p == null)
            _DetailMissing(onBack: () => context.pop())
          else ...[
            _DetailHead(
              account: p,
              onHub: () => context.go(
                ToolCatalog.miscAccountMarket.group.hubLocation,
              ),
              onBack: () => context.pop(),
            ),
            _DetailBody(account: p, onBack: () => context.pop()),
            const SizedBox(height: TgSpacing.s34),
            const _DetailFoot(),
          ],
        ];
        final basePad = compact
            ? const EdgeInsets.fromLTRB(
                16,
                20 + Breakpoints.topbarOverlayHeight,
                16,
                48,
              )
            : TgSpacing.pagePadding.copyWith(
                top:
                    TgSpacing.pagePadding.top +
                    Breakpoints.topbarOverlayHeight, // 预留悬浮顶栏
              );
        final avail = math.max(
          0.0,
          constraints.maxWidth - basePad.left - basePad.right,
        );
        final inner = math.min(avail, 1180.0);
        final extra = math.max(0.0, (avail - inner) / 2);
        final pad = basePad.copyWith(
          left: basePad.left + extra,
          right: basePad.right + extra,
        );
        return TgPageEntrance(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: pad,
                sliver: SliverList(
                  delegate: SliverChildListDelegate(blocks),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ============================== 页头 ============================== */

class _DetailHead extends StatelessWidget {
  const _DetailHead({
    required this.account,
    required this.onHub,
    required this.onBack,
  });

  final AccountListing account;
  final VoidCallback onHub;
  final VoidCallback onBack;

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
              _CrumbLink('实用', onTap: onHub),
              Text(
                ' / 账号行情 / 账号详情',
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
                child: Text(
                  '账号详情',
                  style: TgType.pageH1.copyWith(color: tg.t1),
                ),
              ),
            ],
          ),
          const SizedBox(height: TgSpacing.s10),
          Text(
            '${account.area.isEmpty ? '' : '${account.area} · ${account.server}'}'
            ' · 编号 ${account.sn}',
            style: TgType.body14.copyWith(color: tg.t2),
          ),
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.account, required this.onBack});

  final AccountListing account;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth >= 700;
        return _BlockCard(
          padding: const EdgeInsets.all(22),
          child: stack
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: _DetailImg(account: account)),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _DetailInfo(account: account, onBack: onBack),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _DetailImg(account: account),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailInfo(account: account, onBack: onBack),
                  ],
                ),
        );
      },
    );
  }
}

/// 详情大图（真实远程商品图，加载失败回退 user 占位；点击放大）。
class _DetailImg extends StatefulWidget {
  const _DetailImg({required this.account});

  final AccountListing account;

  @override
  State<_DetailImg> createState() => _DetailImgState();
}

class _DetailImgState extends State<_DetailImg> {
  bool _hover = false;

  Widget _placeholder(double size, Color color) {
    return TgIcon('user', size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.account.img;
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
                caption: widget.account.title,
                errorIcon: 'user',
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
                    cacheWidth: 960,
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

/// 计算调用方小图在全局坐标系中的矩形（供画廊 Hero 动画定位）。
Rect? _widgetRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// 详情右侧信息。
class _DetailInfo extends StatelessWidget {
  const _DetailInfo({required this.account, required this.onBack});

  final AccountListing account;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final t = account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.title,
          style: TextStyle(
            fontFamily: TgFonts.serif,
            fontSize: 18,
            color: tg.t1,
            letterSpacing: 1,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              amP(t.price),
              style: TextStyle(
                fontFamily: TgFonts.serif,
                fontSize: 26,
                color: tg.gold2,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text('不议价', style: TextStyle(fontSize: 13, color: tg.t3)),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PdCell(label: '职业', value: t.job.isEmpty ? '—' : t.job),
            _PdCell(label: '性别', value: t.sex.isEmpty ? '—' : t.sex, gold: true),
            _PdCell(label: '角色等级', value: t.lv > 0 ? '${t.lv} 级' : '—'),
            _PdCell(
              label: '主属性·攻',
              value: t.attr > 0 ? '${amFmt(t.attr)}${t.atk.isNotEmpty ? ' · ${t.atkShort}' : ''}' : '—',
            ),
            _PdCell(
              label: '副属性',
              value: t.attr2 != null && t.attr2! > 0 ? amFmt(t.attr2!) : '—',
            ),
            _PdCell(label: '浏览量', value: amThousands(t.views)),
            _PdCell(
              label: '大区 · 服务器',
              value: t.area.isEmpty ? '—' : '${t.area}-${t.server}',
            ),
            _PdCell(label: '编号', value: t.sn),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (t.job.isNotEmpty) _PmTag(text: t.job, gold: true),
            if (t.sex.isNotEmpty) _PmTag(text: t.sex, gold: false),
            if (t.atk.isNotEmpty) _PmTag(text: t.atk, gold: true),
            if (t.attr2 != null && t.attr2! > 0)
              _PmTag(text: '副属性${amFmt(t.attr2!)}', gold: false),
            if (t.job.isEmpty &&
                t.sex.isEmpty &&
                t.atk.isEmpty &&
                (t.attr2 == null || t.attr2! <= 0))
              const _PmTag(text: '无附加标签', gold: false),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _GoldButton(
              label: '在神仙代售查看原帖',
              icon: 'spark',
              onTap: () => _openSourcePage(context, t.sn),
            ),
            _LineButton(label: '返回行情列表', onTap: onBack),
          ],
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 11, color: tg.t3, height: 1.6),
            children: [
              TextSpan(text: '商品编号 ${t.sn} · '),
              TextSpan(
                text: '数据来源：神仙代售平台（sxds.com）',
                style: TextStyle(color: tg.gold2),
              ),
              const TextSpan(text: ' · 点击左侧图片可放大'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 用系统浏览器/新标签打开神仙代售原帖（URL 与平台商品详情页一致）。
Future<void> _openSourcePage(BuildContext context, String sn) async {
  final url = 'https://www.sxds.com/detail/$sn';
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!context.mounted) return;
  if (!opened) {
    final tg = context.tg;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: tg.card2,
        content: Text(
          '无法打开浏览器，请手动访问：$url',
          style: TextStyle(fontSize: 12.5, color: tg.t1),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// `pd-cell` 信息格。
class _PdCell extends StatelessWidget {
  const _PdCell({required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: 168,
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

/// `pm-tag` 标签。
class _PmTag extends StatelessWidget {
  const _PmTag({required this.text, required this.gold});

  final String text;
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

/// 金色主按钮（对应 `.btn btn-primary`）。
class _GoldButton extends StatefulWidget {
  const _GoldButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final String? icon;

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
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
class _LineButton extends StatefulWidget {
  const _LineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_LineButton> createState() => _LineButtonState();
}

class _LineButtonState extends State<_LineButton> {
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

/* ============================== 页脚 ============================== */

class _DetailFoot extends StatelessWidget {
  const _DetailFoot();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Column(
      children: [
        Container(width: 64, height: 1, color: tg.border),
        const SizedBox(height: TgSpacing.sm),
        Text(
          '点击商品图片可放大查看',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
      ],
    );
  }
}

/* ============================== 兜底 ============================== */

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: child,
    );
  }
}

/// 直接深链且无 extra 账号数据时的兜底提示。
class _DetailMissing extends StatelessWidget {
  const _DetailMissing({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _BlockCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TgIcon('user', size: 26, color: tg.t3),
          const SizedBox(height: 12),
          Text('账号数据缺失', style: TextStyle(fontSize: 14, color: tg.t2)),
          const SizedBox(height: 6),
          Text(
            '未获取到该账号的行情数据，请从行情列表重新进入。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: tg.t3, height: 1.6),
          ),
          const SizedBox(height: 16),
          _LineButton(label: '返回行情列表', onTap: onBack),
        ],
      ),
    );
  }
}
