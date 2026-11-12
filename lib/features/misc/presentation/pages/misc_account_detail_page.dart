import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/features/misc/data/sxds_goods_detail_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/domain/sxds_goods_detail.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market_stats.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_common.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_detail_widgets.dart';

/// 账号详情页（独立嵌套子路由 `/misc/acc-market/detail`）。
///
/// 从行情列表点击「详情」时 `context.push(..., extra: account)` 压栈到列表之上；
/// 返回（pop）后列表滚动位置天然保留，不会页面跳动。
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, this.account, this.fetchDetail});

  /// 账号数据经路由 extra 传入；null（如直接深链）时展示缺失提示。
  final AccountListing? account;

  /// 详情抓取（测试注入用）；默认走 [fetchSxdsGoodsDetail] 真实接口。
  final Future<SxdsGoodsDetail> Function(String sn)? fetchDetail;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  /// 详情（含全部商品图）；列表摘要已够渲染骨架，详情到位后补齐。
  SxdsGoodsDetail? _detail;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 拉取商品详情（含几十张实拍图）。失败不影响摘要展示。
  Future<void> _load() async {
    final sn = widget.account?.sn ?? '';
    if (sn.isEmpty) {
      // 没有编号就拉不到详情（也拿不到多图）：明确提示而不是静默只显示封面。
      setState(() => _error = '商品编号缺失');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final fetch =
          widget.fetchDetail ?? (String sn) => fetchSxdsGoodsDetail(sn: sn);
      final d = await fetch(sn);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final p = widget.account;
        final d = _detail;
        final images = d != null && d.images.isNotEmpty
            ? d.images
            : <String>[if (p?.img != null && p!.img!.isNotEmpty) p.img!];
        final desc = d?.description ?? '';
        final blocks = <Widget>[
          if (p == null)
            MiscDetailMissing(
              icon: 'user',
              title: '账号数据缺失',
              hint: '未获取到该账号的行情数据，请从行情列表重新进入。',
              onBack: () => context.pop(),
            )
          else ...[
            MiscDetailHead(
              title: '账号详情',
              subtitle:
                  '${p.area.isEmpty ? '' : '${p.area} · ${p.server}'}'
                  ' · 编号 ${p.sn}'
                  '${images.length > 1 ? ' · ${images.length} 图' : ''}',
              crumbTail: ' / 账号行情 / 账号详情',
              onCrumbTap: () =>
                  context.go(ToolCatalog.miscAccountMarket.group.hubLocation),
            ),
            if (_loading || _error.isNotEmpty)
              MiscDetailLoadStatus(
                loading: _loading,
                error: _error,
                onRetry: _load,
              ),
            MiscDetailBody(
              image: MiscDetailGallery(
                images: images,
                caption: p.title,
                fallbackIcon: 'user',
              ),
              info: _DetailInfo(
                account: p,
                detail: d,
                onBack: () => context.pop(),
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 16),
              TgCard(
                basePadding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MiscSectionHead(title: '商品描述'),
                    const SizedBox(height: 12),
                    SelectableText(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.85,
                        color: tg.t2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: TgSpacing.s34),
            const TgPageFoot(text: '点击商品图片可放大查看（多图可左右滑动）'),
          ],
        ];
        final basePad = compact
            ? const EdgeInsets.fromLTRB(
                TgSpacing.pagePaddingMobileH,
                20 + Breakpoints.topbarOverlayHeight,
                TgSpacing.pagePaddingMobileH,
                48 + Breakpoints.tabbarOverlayHeight, // 预留悬浮底栏
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
                sliver: SliverList(delegate: SliverChildListDelegate(blocks)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ============================== 详情主体 ============================== */

/// 详情右侧信息：列表摘要（[account]）+ 详情补齐字段（[detail]）。
class _DetailInfo extends StatelessWidget {
  const _DetailInfo({
    required this.account,
    required this.detail,
    required this.onBack,
  });

  final AccountListing account;
  final SxdsGoodsDetail? detail;
  final VoidCallback onBack;

  /// 平台时间 → `yyyy-MM-dd HH:mm`（本地时区）。
  static String _fmtTime(DateTime? v) {
    if (v == null) return '';
    final l = v.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final t = account;
    final d = detail;

    // 列表摘要优先，详情到位后用详情字段补齐（字段口径一致，取非空者）。
    String pick(String fromDetail, String fallback) =>
        fromDetail.isNotEmpty ? fromDetail : fallback;
    final job = pick(d?.job ?? '', t.job);
    final sex = pick(d?.sex ?? '', t.sex);
    final lv = (d?.level ?? 0) > 0 ? d!.level : t.lv;
    final atk = pick(d?.mainAtk ?? '', t.atk);
    final atkShort = atk.replaceAll('主', '').replaceAll('攻', '');
    final attr = (d?.attr ?? 0) > 0 ? d!.attr : t.attr;
    final attr2 = (d?.attr2 ?? 0) > 0 ? d!.attr2 : (t.attr2 ?? 0);
    final views = (d?.views ?? 0) > 0 ? d!.views : t.views;
    final area = pick(d?.area ?? '', t.area);
    final server = pick(d?.server ?? '', t.server);
    final price = (d?.price ?? 0) > 0 ? d!.price : t.price;

    final cells = <(String, String)>[
      ('职业', job.isEmpty ? '—' : job),
      ('性别', sex.isEmpty ? '—' : sex),
      ('角色等级', lv > 0 ? '$lv 级' : '—'),
      (
        '主属性·攻',
        attr > 0
            ? '${amFmt(attr)}${atkShort.isNotEmpty ? ' · $atkShort' : ''}'
            : '—',
      ),
      ('副属性', attr2 > 0 ? amFmt(attr2) : '—'),
      ('浏览量', amThousands(views)),
      ('大区 · 服务器', area.isEmpty ? '—' : '$area-$server'),
      if ((d?.accountType ?? '').isNotEmpty) ('账号类型', d!.accountType),
      if ((d?.sourceName ?? '').isNotEmpty) ('商品来源', d!.sourceName),
      if ((d?.seller ?? '').isNotEmpty) ('卖家', d!.seller),
      if (d?.createdAt != null) ('上架时间', _fmtTime(d!.createdAt)),
      ('编号', t.sn),
    ];

    // 标签：详情亮点优先；否则由摘要字段拼出。
    final tags = <String>[
      if ((d?.tags ?? const <String>[]).isNotEmpty)
        ...d!.tags
      else ...[
        if (job.isNotEmpty) job,
        if (sex.isNotEmpty) sex,
        if (atk.isNotEmpty) atk,
        if (attr2 > 0) '副属性${amFmt(attr2)}',
      ],
      if (d?.hasEnsure ?? false) '已开通交易保障',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.title,
          style: TextStyle(
            fontFamily: TgFonts.serif,
            fontWeight: FontWeight.w500,
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
              amP(price),
              style: TextStyle(
                fontFamily: TgFonts.serif,
                fontWeight: FontWeight.w500,
                fontSize: 26,
                color: tg.gold2,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                d == null
                    ? '不议价'
                    : switch (d.canBargain) {
                        true =>
                          '可议价${d.minBargainPrice != null ? ' · 最低 ${amP(d.minBargainPrice!)}' : ''}',
                        false => '不议价',
                        null => '议价以原帖为准',
                      },
                style: TextStyle(fontSize: 13, color: tg.t3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            // 属性格弹性排布：按可用宽度自适应每行卡片数（移动端保证 ≥2 个/行，
            // 高 DPR 机型逻辑宽度偏窄也能放下两张；桌面随宽度增至 4~6 个/行），
            // 卡片铺满整行避免水平留白。
            const gap = 10.0;
            const cellMin = 150.0;
            final cols = ((c.maxWidth + gap) / (cellMin + gap)).floor().clamp(
              2,
              6,
            );
            final cellW = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (label, value) in cells)
                  MiscInfoCell(
                    label: label,
                    value: value,
                    gold: label == '性别' || label == '商品来源',
                    width: cellW,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (tags.isEmpty)
              const MiscTag(text: '无附加标签')
            else
              for (final tag in tags) MiscTag(text: tag, gold: true),
          ],
        ),
        const SizedBox(height: 18),
        MiscDetailActionRow(sn: t.sn, onBack: onBack),
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

/// 信息格 / 标签 / 主按钮 / 描边按钮 / 详情操作区 / 卡片壳 / 兜底提示均已抽到
/// `widgets/misc_common.dart`（[MiscTag]）、
/// `widgets/misc_detail_widgets.dart`（[MiscInfoCell] /
/// [MiscPrimaryButton] / [MiscLineButton] / [MiscDetailActionRow] /
/// [MiscDetailMissing]）与 shared 的 [TgCard] / [TgPageFoot]。
