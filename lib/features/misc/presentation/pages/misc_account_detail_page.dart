import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market.dart';
import 'package:tlbbtoolkit/features/misc/domain/account_market_stats.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_common.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_detail_widgets.dart';

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
                  ' · 编号 ${p.sn}',
              crumbTail: ' / 账号行情 / 账号详情',
              onCrumbTap: () =>
                  context.go(ToolCatalog.miscAccountMarket.group.hubLocation),
            ),
            MiscDetailBody(
              image: MiscDetailImage(
                url: p.img,
                caption: p.title,
                fallbackIcon: 'user',
              ),
              info: _DetailInfo(account: p, onBack: () => context.pop()),
            ),
            const SizedBox(height: TgSpacing.s34),
            const TgPageFoot(text: '点击商品图片可放大查看'),
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
                MiscInfoCell(
                  label: '职业',
                  value: t.job.isEmpty ? '—' : t.job,
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '性别',
                  value: t.sex.isEmpty ? '—' : t.sex,
                  gold: true,
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '角色等级',
                  value: t.lv > 0 ? '${t.lv} 级' : '—',
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '主属性·攻',
                  value: t.attr > 0
                      ? '${amFmt(t.attr)}${t.atk.isNotEmpty ? ' · ${t.atkShort}' : ''}'
                      : '—',
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '副属性',
                  value: t.attr2 != null && t.attr2! > 0
                      ? amFmt(t.attr2!)
                      : '—',
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '浏览量',
                  value: amThousands(t.views),
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '大区 · 服务器',
                  value: t.area.isEmpty ? '—' : '${t.area}-${t.server}',
                  width: cellW,
                ),
                MiscInfoCell(label: '编号', value: t.sn, width: cellW),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (t.job.isNotEmpty) MiscTag(text: t.job, gold: true),
            if (t.sex.isNotEmpty) MiscTag(text: t.sex),
            if (t.atk.isNotEmpty) MiscTag(text: t.atk, gold: true),
            if (t.attr2 != null && t.attr2! > 0)
              MiscTag(text: '副属性${amFmt(t.attr2!)}'),
            if (t.job.isEmpty &&
                t.sex.isEmpty &&
                t.atk.isEmpty &&
                (t.attr2 == null || t.attr2! <= 0))
              const MiscTag(text: '无附加标签'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MiscPrimaryButton(
              label: '在神仙代售查看原帖',
              icon: 'spark',
              onTap: () => _openSourcePage(context, t.sn),
            ),
            MiscLineButton(label: '返回行情列表', onTap: onBack),
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

/// 信息格 / 标签 / 主按钮 / 描边按钮 / 卡片壳 / 兜底提示均已抽到
/// `widgets/misc_common.dart`（[MiscInfoCell] / [MiscTag] /
/// [MiscPrimaryButton] / [MiscLineButton]）、
/// `widgets/misc_detail_widgets.dart`（[MiscDetailMissing]）
/// 与 shared 的 [TgCard] / [TgPageFoot]。
