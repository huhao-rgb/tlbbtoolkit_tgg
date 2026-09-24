import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_bar_row.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_note_bar.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_scroll_top_button.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_select.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_text_field.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market_stats.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_common.dart';
import 'package:tlbbtoolkit/features/misc/presentation/widgets/misc_detail_widgets.dart';

/// 珍兽行情分析（对应原型 `v-pet-market` + `v-pet-detail`）。
///
/// - 数据完全来自神仙代售平台真实接口（`fetchSxdsMarket`），无静态快照；
/// - 首次进入自动拉取；顶部筛选（大区 / 服务器 / 可携带等级）联动统计；
/// - 统计卡、价位分布、价位段画像、性价比推荐、在售明细；
/// - 明细支持标题关键字搜索（防抖 180ms）；
/// - 「详情」进入商品详情子视图，可返回行情列表；
/// - 「一键获取」可手动重新拉取；Web 端被 CORS 拦截时显示
///   「浏览器跨域拦截」提示与空态，桌面/移动端可直连。
class MiscMarketPage extends StatefulWidget {
  const MiscMarketPage({super.key, this.fetchSxds, this.fetchRegions});

  /// 抓取函数（测试注入用）；默认走 `fetchSxdsMarket` 真实接口。
  final Future<PetMarketFetchResult> Function()? fetchSxds;

  /// 区服目录抓取（测试注入用）；默认走 `fetchSxdsRegions` 真实接口。
  final Future<List<SxdsRegion>> Function()? fetchRegions;

  @override
  State<MiscMarketPage> createState() => _MiscMarketPageState();
}

class _MiscMarketPageState extends State<MiscMarketPage> {
  String _area = '';
  String _server = '';
  PetCarryBand _band = PetCarryBand.all;
  String _kw = '';
  Timer? _kwTimer;

  // 数据源：初始为空，进入页面后自动从接口拉取。
  List<PetListing> _items = const [];

  // 区服目录候选（下拉选项来源）：从平台 gamefilter 加载，避免聚焦后缩水。
  List<SxdsRegion> _regions = const [];

  // 加载状态：none 隐藏 / loading / ok（绿）/ warn（琥珀）。
  _FetchState _fetch = _FetchState.loading;
  String _fetchMsg = '';

  /// 整页唯一滚动体的控制器（「回到顶部」悬浮按钮共用）。
  final ScrollController _scroll = ScrollController();

  PetMarketFilter get _filter =>
      PetMarketFilter(area: _area, server: _server, carryBand: _band);

  @override
  void initState() {
    super.initState();
    // 首次进入自动拉取真实行情 + 区服目录（目录失败静默，回退数据驱动）。
    _loadLatest();
    _loadRegions();
  }

  /// 加载平台区服目录作为下拉候选；失败静默（回退到基于数据的选项）。
  Future<void> _loadRegions() async {
    try {
      final list = widget.fetchRegions != null
          ? await widget.fetchRegions!()
          : await fetchSxdsRegions();
      if (mounted && list.isNotEmpty) {
        setState(() => _regions = list);
      }
    } catch (_) {
      // 静默：未加载到目录时下拉回退到数据驱动选项。
    }
  }

  @override
  void dispose() {
    _kwTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onArea(String v) {
    setState(() {
      _area = v;
      _server = ''; // 大区变化重置服务器
    });
  }

  void _onKw(String v) {
    _kwTimer?.cancel();
    _kwTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _kw = v.trim());
    });
  }

  void _clearKw() {
    _kwTimer?.cancel();
    setState(() => _kw = '');
  }

  /// 由区服名称解析平台大区 id（目录优先，数据兜底）。
  int? _areaIdOf(String name) {
    for (final r in _regions) {
      if (r.areaName == name) return r.areaId;
    }
    for (final it in _items) {
      if (it.area == name && it.areaId != null) return it.areaId;
    }
    return null;
  }

  /// 由服务器名称解析平台服务器 id 集合（目录优先，数据兜底）。
  String? _serverIdsOf(String name) {
    final ids = <int>{};
    for (final r in _regions) {
      for (final s in r.servers) {
        if (s.serverName == name) ids.add(s.serverId);
      }
    }
    for (final it in _items) {
      if (it.server == name && it.serverId != null) ids.add(it.serverId!);
    }
    return ids.isEmpty ? null : ids.join(',');
  }

  /// 把当前下拉选择（名称）翻译成平台接口查询条件。
  ///
  /// 区服目录已加载时用目录映射名称→id（不依赖聚焦后缩水的数据）；
  /// 否则回退从已抓数据里找同名称商品。携带等级直接映射 `packId`。
  /// 全空时返回 [PetMarketQuery]（全部 → 只取前 400 条）。
  PetMarketQuery _buildQuery() {
    return PetMarketQuery(
      areaId: _area.isEmpty ? null : _areaIdOf(_area),
      serverId: _server.isEmpty ? null : _serverIdsOf(_server),
      packId: _band == PetCarryBand.all ? null : _band.packId,
    );
  }

  /// 当前检索条件的人类可读文案（用于成功提示）。
  String get _queryLabel {
    final parts = <String>[
      if (_area.isNotEmpty) _area,
      if (_server.isNotEmpty) _server,
      if (_band != PetCarryBand.all) _band.label,
    ];
    return parts.isEmpty ? '全部大区' : parts.join(' · ');
  }

  /// 拉取平台真实行情（首次进入自动 + 「一键获取」手动共用）。
  ///
  /// - 自动携带当前筛选条件（大区/服务器/携带等级）；
  /// - 无筛选（全部）→ 只取前 400 条；有筛选 → 分页拉取该条件下全部数据；
  /// - 成功后**保留**当前筛选与搜索（不重置）；
  /// - Web 端 CORS 拦截 / 网络失败 → 琥珀提示，展示空态。
  Future<void> _loadLatest() async {
    if (mounted) {
      setState(() {
        _fetch = _FetchState.loading;
        _fetchMsg = '';
      });
    }
    final query = _buildQuery();
    // 测试注入的 fetch 无参调用；真实路径带当前查询条件。
    final fetch = widget.fetchSxds != null
        ? widget.fetchSxds!
        : () => fetchSxdsMarket(query: query);
    try {
      final result = await fetch();
      if (!mounted) return;
      if (result.parsed.isNotEmpty) {
        setState(() {
          _items = result.parsed;
          // 保留筛选与搜索，仅当原选择已不在新数据时自动回落。
          _kw = '';
          _fetch = _FetchState.ok;
          _fetchMsg =
              '获取成功：${result.parsed.length} 条（$_queryLabel）实时在售，'
              '上方统计已刷新。';
        });
      } else {
        setState(() {
          _fetch = _FetchState.warn;
          _fetchMsg =
              '获取到 ${result.raw} 条原始记录，'
              '但未识别出有效商品，请稍后重试。';
        });
      }
    } on PetMarketFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _fetch = _FetchState.warn;
        _fetchMsg = e.isWebBlocked ? '浏览器跨域拦截（CORS）$_webCorsText' : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetch = _FetchState.warn;
        _fetchMsg = '网络请求失败：$e';
      });
    }
  }

  /// Web 端跨域提示正文。
  static const String _webCorsText =
      '：神仙代售接口未开放跨域访问，'
      '页内直连被浏览器安全策略阻止（接口逻辑已内置，部署到同域后端代理后'
      '即可生效）。当前无在售数据可展示。';

  void _openDetail(PetListing pet) {
    // 详情是独立嵌套子路由：push 到列表之上，列表页仍在路由栈中保持滚动；
    // 返回（pop）后列表滚动位置天然保留，无需手动恢复，不会页面跳动。
    FocusManager.instance.primaryFocus?.unfocus();
    context.push('/misc/market/detail', extra: pet);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final data = _items;
        // 页面头部区块（头 + 筛选 + 状态 + 统计/分布/画像/推荐）作为垂直序列，
        // 在下方拼进同一个 CustomScrollView；在售明细整表也是它的 sliver，
        // 因此全页只有一个纵向滚动体（明细随页滚动，惯性/缓动原生）。
        final blocks = <Widget>[
          _MarketHead(
            onCrumbTap: () =>
                context.go(ToolCatalog.miscMarket.group.hubLocation),
          ),
          _FilterBar(
            regions: _regions,
            data: data,
            filter: _filter,
            fetching: _fetch == _FetchState.loading,
            onArea: _onArea,
            onServer: (v) => setState(() => _server = v),
            onBand: (v) => setState(() => _band = v),
            onFetch: _loadLatest,
          ),
          const SizedBox(height: 12),
          if (_fetch == _FetchState.ok)
            MiscStatusOk(message: _fetchMsg)
          else if (_fetch == _FetchState.warn && _items.isEmpty)
            MiscStatusWarn(message: _fetchMsg),
          const SizedBox(height: 4),
          const _MarketNote(),
          const SizedBox(height: 14),
          if (_items.isEmpty && _fetch == _FetchState.loading)
            const MiscLoadingPanel(text: '正在从神仙代售获取实时行情…')
          else if (_items.isEmpty)
            const MiscEmptyPanel(
              icon: 'paw',
              title: '暂无在售数据',
              hint: '可点击上方「一键获取最新数据」重试，或稍后再进入页面自动刷新。',
            )
          else ...[
            _StatsRow(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 12),
            _DistCard(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 14),
            _SegCard(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 14),
            _BestCard(
              filtered: pmFiltered(data, _filter),
              onDetail: _openDetail,
            ),
            const SizedBox(height: 14),
          ],
        ];
        // 页面内边距（compact / 桌面两套）。
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
        // 宽视口把内容限宽 1180 并居中：换算为 sliver 的横向 padding。
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
          child: Stack(
            children: [
              // 整页唯一滚动体（头部区块 + 在售明细表）：控制器供回到顶部按钮共用。
              Positioned.fill(
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(
                      padding: pad,
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverList(delegate: SliverChildListDelegate(blocks)),
                          // 在售明细整表（表头 + 行列表）并入同一个 CustomScrollView：
                          // 行由 SliverList 惰性构建，但不再需要内层纵向 ListView 与
                          // 横向滚动容器，也就不必再手动转交越界滚动。
                          if (data.isNotEmpty)
                            _DetailTableSliver(
                              key: const ValueKey('pet-detail-table'),
                              data: data,
                              filter: _filter,
                              kw: _kw,
                              onKw: _onKw,
                              onClearKw: _clearKw,
                              onDetail: _openDetail,
                            ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: TgSpacing.s34,
                              ),
                              child: const TgPageFoot(
                                text: '行情数据仅供交易参考 · 天工阁与神仙代售平台无隶属关系',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 「回到顶部」悬浮按钮（原型 #backTop）：滚动过阈值后淡入。
              TgScrollTopButton(controller: _scroll),
            ],
          ),
        );
      },
    );
  }
}

enum _FetchState { loading, ok, warn }

/// 桌面端筛选下拉统一宽度（窄屏走两列等宽自适应）。
const double _kSelectWidth = 160;

/// 金额千分位（浏览量等）。
String _thousands(int n) => pmThousands(n);

/// 金额 fmt + 前缀 ￥（价格列/统计）。
String _p(num n) => '￥${pmFmt(n)}';

/* ============================== 主视图头 ============================== */

class _MarketHead extends StatelessWidget {
  const _MarketHead({required this.onCrumbTap});

  final VoidCallback onCrumbTap;

  @override
  Widget build(BuildContext context) {
    return TgPageHead(
      crumbLeft: ToolCatalog.miscMarket.crumbRoot,
      crumbTail: ToolCatalog.miscMarket.crumb.substring(
        ToolCatalog.miscMarket.crumbRoot.length,
      ),
      onCrumbLeftTap: onCrumbTap,
      title: '珍兽行情分析',
      subtitle: ToolCatalog.miscMarket.pageSubtitle,
    );
  }
}

/* ============================== 筛选条 ============================== */

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.regions,
    required this.data,
    required this.filter,
    required this.fetching,
    required this.onArea,
    required this.onServer,
    required this.onBand,
    required this.onFetch,
  });

  /// 平台区服目录候选；非空时优先用它生成下拉选项（不随数据缩水）。
  final List<SxdsRegion> regions;

  final List<PetListing> data;
  final PetMarketFilter filter;
  final bool fetching;
  final ValueChanged<String> onArea;
  final ValueChanged<String> onServer;
  final ValueChanged<PetCarryBand> onBand;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    // 区服下拉候选：优先平台目录（全量）；目录未加载时回退到当前数据推导。
    final useRegions = regions.isNotEmpty;
    final areas = useRegions
        ? [for (final r in regions) r.areaName]
        : pmAreas(data);
    final serverPool = useRegions
        ? <SxdsServer>[
            for (final r in regions)
              if (filter.area.isEmpty || r.areaName == filter.area)
                ...r.servers,
          ]
        : null;
    final serverNames = serverPool != null
        ? [for (final s in serverPool) s.serverName]
        : pmServers(data, filter.area);
    return LayoutBuilder(
      builder: (context, w) {
        // 窄屏（移动端）收窄筛选卡左右内边距，提升横向内容容纳；桌面保持 18。
        final h = w.maxWidth < 640 ? TgSpacing.cardPaddingMobileH : 18.0;
        return Container(
          padding: EdgeInsets.fromLTRB(h, 16, h, 16),
          decoration: BoxDecoration(
            color: tg.card,
            borderRadius: TgRadius.card,
            border: Border.all(color: tg.border, width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              // 窄屏：筛选框两列等宽（一行两个）；桌面：统一固定宽。
              const gap = 12.0;
              final compact = c.maxWidth < 640;
              final colW = compact ? (c.maxWidth - gap) / 2 : _kSelectWidth;
              final selects = <Widget>[
                TgSelect(
                  label: '大区',
                  value: filter.area,
                  hint: '全部大区',
                  width: colW,
                  options: [for (final a in areas) (a, a)],
                  onChanged: onArea,
                ),
                TgSelect(
                  label: '服务器',
                  value: filter.server,
                  hint: '全部服务器',
                  width: colW,
                  options: [for (final s in serverNames) (s, s)],
                  onChanged: onServer,
                ),
                TgSelect(
                  label: '可携带等级',
                  value: filter.carryBand.label,
                  hint: PetCarryBand.all.label,
                  width: colW,
                  options: [
                    for (final b in PetCarryBand.values) (b.label, b.label),
                  ],
                  onChanged: (v) {
                    final band = PetCarryBand.values.firstWhere(
                      (b) => b.label == v,
                      orElse: () => PetCarryBand.all,
                    );
                    onBand(band);
                  },
                ),
              ];
              if (compact) {
                // 移动端：筛选框一行两个（两列等宽），获取按钮独占一行。
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: gap, runSpacing: 12, children: selects),
                    const SizedBox(height: 14),
                    MiscFetchButton(fetching: fetching, onTap: onFetch),
                  ],
                );
              }
              // 桌面：三下拉之间保留 12px 间距，获取按钮右对齐。
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < selects.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    selects[i],
                  ],
                  const Spacer(),
                  MiscFetchButton(fetching: fetching, onTap: onFetch),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/* ============================== 筛选条 ============================== */

/// 数据说明 note（`note`）。
class _MarketNote extends StatelessWidget {
  const _MarketNote();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgNoteBar(
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 12.5,
            color: tg.t2,
            height: 1.7,
            letterSpacing: .2,
          ),
          children: [
            const TextSpan(text: '数据抓取自 '),
            TextSpan(
              text: '神仙代售 sxds.com',
              style: TextStyle(color: tg.gold2, fontWeight: FontWeight.w600),
            ),
            const TextSpan(
              text:
                  ' 怀旧原始服宝宝类目公开在售列表（实时接口，进入页面'
                  '自动拉取最新数据）。筛选条件联动全部统计模块；点击'
                  '缩略图查看大图，「详情」进入商品详情页，「一键获取」'
                  '可手动刷新。',
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== 统计卡 ============================== */

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.filtered});

  final List<PetListing> filtered;

  @override
  Widget build(BuildContext context) {
    final s = pmComputeStats(filtered);
    return MiscStatGrid(
      items: [
        ('在售样本', '${s.count} 条'),
        ('价格区间', s.rangeText),
        ('中位价', s.medianText),
        ('均价', s.meanText),
      ],
    );
  }
}

/* ============================== 通用区块卡 ============================== */

/* ============================== 价位分布 ============================== */

class _DistCard extends StatelessWidget {
  const _DistCard({required this.filtered});

  final List<PetListing> filtered;

  @override
  Widget build(BuildContext context) {
    final segs = pmDistSegs(filtered);
    return TgCard(
      basePadding: const EdgeInsets.all(18),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MiscSectionHead(title: '价位分布 · 在售数量'),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const MiscEmptyTip(text: '当前筛选无数据')
          else
            for (final r in segs) _DistRow(seg: r, total: filtered.length),
        ],
      ),
    );
  }
}

class _DistRow extends StatelessWidget {
  const _DistRow({required this.seg, required this.total});

  final PmDistSeg seg;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final width = seg.maxCount == 0 ? 0.0 : seg.count / seg.maxCount;
    final pct = total == 0 ? 0 : (seg.count / total * 100).round();
    final hasApt = seg.avgApt > 0;
    return TgBarRow(
      label: seg.label,
      widthFactor: width,
      labelWidth: 110,
      trailingWidth: 150,
      trailing: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: tg.t3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          children: [
            TextSpan(
              text: '${seg.count} 条',
              style: TextStyle(
                fontSize: 12.5,
                color: tg.gold2,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  ' $pct% · 均价${_p(seg.avg)}'
                  '${hasApt ? ' · 均资质${seg.avgApt}' : ''}',
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/* ============================== 价位段画像 ============================== */

class _SegCard extends StatelessWidget {
  const _SegCard({required this.filtered});

  final List<PetListing> filtered;

  @override
  Widget build(BuildContext context) {
    final segs = pmSegProfiles(pmDistSegs(filtered));
    return TgCard(
      basePadding: const EdgeInsets.all(18),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MiscSectionHead(title: '价位段画像'),
          const SizedBox(height: 12),
          _SegTable(rows: segs),
        ],
      ),
    );
  }
}

class _SegTable extends StatelessWidget {
  const _SegTable({required this.rows});

  final List<PmSegProfile> rows;

  /// 窄屏（移动端）表格最小宽度：低于此宽度时横向滚动，
  /// 避免 6 列在可用宽度内被压缩（与在售明细表同策略）。
  static const double _minTableWidth = 700;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );
    Widget th(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 11,
          color: tg.t3,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    Widget tr(List<Widget> cells) => Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells),
    );
    return LayoutBuilder(
      builder: (context, c) {
        // 窄屏（移动端）下 6 列在可用宽度内会被压缩成细条，
        // 因此给表格一个最小宽度并允许横向滚动（与在售明细表同策略）。
        final tableW = math.max(c.maxWidth, _minTableWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tr([
                  Expanded(flex: 3, child: th('价位段')),
                  SizedBox(width: 52, child: th('数量')),
                  Expanded(flex: 2, child: th('均价')),
                  Expanded(flex: 2, child: th('均资质')),
                  Expanded(flex: 3, child: th('主流携带级')),
                  Expanded(flex: 5, child: th('高频特征')),
                ]),
                for (final r in rows)
                  tr([
                    Expanded(
                      flex: 3,
                      child: cell(
                        Text(
                          r.label,
                          style: TextStyle(fontSize: 12, color: tg.t2),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: cell(
                        Text(
                          '${r.count}',
                          style: TextStyle(
                            fontSize: 12,
                            color: tg.gold2,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: cell(
                        Text(
                          r.list.isEmpty ? '—' : _p(r.avg),
                          style: TextStyle(fontSize: 12, color: tg.t2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: cell(
                        Text(
                          '${r.avgApt ?? '—'}',
                          style: TextStyle(fontSize: 12, color: tg.t2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: cell(
                        Text(
                          r.lvTop,
                          style: TextStyle(fontSize: 12, color: tg.t2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: cell(
                        r.features.isEmpty
                            ? Text(
                                '—',
                                style: TextStyle(fontSize: 12, color: tg.t2),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final f in r.features) MiscTag(text: f),
                                ],
                              ),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ============================== 性价比推荐 ============================== */

class _BestCard extends StatelessWidget {
  const _BestCard({required this.filtered, required this.onDetail});

  final List<PetListing> filtered;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    return TgCard(
      basePadding: const EdgeInsets.all(18),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MiscSectionHead(title: '性价比推荐 · 资质 / 千元价（资质 ≥3800）'),
          const SizedBox(height: 12),
          _BestList(filtered: filtered, onDetail: onDetail),
        ],
      ),
    );
  }
}

TgColors tgOf(BuildContext context) => context.tg;

class _BestList extends StatelessWidget {
  const _BestList({required this.filtered, required this.onDetail});

  final List<PetListing> filtered;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    final best = pmBestItems(filtered);
    if (best.isEmpty) {
      return const MiscEmptyTip(text: '当前筛选无高资质样本');
    }
    return Column(
      children: [
        for (var i = 0; i < best.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BestRow(index: i, item: best[i], onDetail: onDetail),
          ),
      ],
    );
  }
}

class _BestRow extends StatelessWidget {
  const _BestRow({
    required this.index,
    required this.item,
    required this.onDetail,
  });

  final int index;
  final PmBestItem item;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final t = item.listing;
    final sub = t.area.isEmpty ? '' : '${t.area}-${t.server}';
    Widget rank() => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tg.goldTint(.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontFamily: TgFonts.serif,
          fontSize: 12,
          color: tg.gold2,
        ),
      ),
    );
    Widget titleText() => Expanded(
      child: Text(
        t.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: tg.t2),
      ),
    );
    Widget ixText() => SizedBox(
      width: 64, // 指数列放宽：展示「资质/千元价」比值更醒目
      child: Text(
        item.ixText,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: TgFonts.serif,
          fontSize: 17,
          color: tg.gold2,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    Widget goBtn() => MiscMiniButton(
      label: '详情',
      onTap: () => onDetail(t),
      height: 22,
      radius: 7,
      fontSize: 11,
      horizontalPadding: 9,
    );
    final outer = BoxDecoration(
      color: tg.inset,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: tg.border, width: 1),
    );
    final pad = const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Container(
            padding: pad,
            decoration: outer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    rank(),
                    const SizedBox(width: 10),
                    titleText(),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: tg.t3),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MiscTag(text: '资质 ${t.apt}', gold: true),
                    const SizedBox(width: 10),
                    Text(
                      _p(t.price),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tg.gold2,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    ixText(),
                    const SizedBox(width: 8),
                    goBtn(),
                  ],
                ),
              ],
            ),
          );
        }
        return Container(
          padding: pad,
          decoration: outer,
          child: Row(
            children: [
              rank(),
              const SizedBox(width: 10),
              titleText(),
              if (sub.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tg.t3),
                ),
              ],
              const SizedBox(width: 8),
              MiscTag(text: '资质 ${t.apt}', gold: true),
              const SizedBox(width: 10),
              Text(
                _p(t.price),
                style: TextStyle(
                  fontSize: 12.5,
                  color: tg.gold2,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              ixText(),
              const SizedBox(width: 8),
              goBtn(),
            ],
          ),
        );
      },
    );
  }
}

/* ============================== 在售明细 ============================== */

/// 明细表布局档位（按可用宽度降级）。
///
/// 去掉横向滚动后所有列都必须落在可用宽度内，因此按宽度下钻：
/// - [wide]（≥900）：表头/行显示全部列（含 灵/悟、区服）；
/// - [mid]（560~900）：收起 灵/悟、区服 两列，信息折叠为标题下的副行；
/// - [card]（<560）：整行降级为堆叠卡片，与同页「性价比推荐」窄屏行一致。
enum _DetailLayout { wide, mid, card }

/// 由可用宽度推导明细表布局档位。
_DetailLayout _detailLayoutOf(double width) {
  if (width < 560) return _DetailLayout.card;
  return width < 900 ? _DetailLayout.mid : _DetailLayout.wide;
}

/// 明细表列（顺序即渲染顺序；表头与数据行共用同一列模型，天然对齐）。
enum _DetailCol { thumb, title, price, carry, ling, area, feature, op }

/// 指定布局下可见的列（[card] 档整行是卡片，不渲染表格列）。
List<_DetailCol> _detailCols(_DetailLayout layout) {
  if (layout == _DetailLayout.card) return const [];
  return [
    _DetailCol.thumb,
    _DetailCol.title,
    _DetailCol.price,
    _DetailCol.carry,
    if (layout == _DetailLayout.wide) ...[_DetailCol.ling, _DetailCol.area],
    _DetailCol.feature,
    _DetailCol.op,
  ];
}

/// 固定列宽（含左右各 10px 单元格内距）。
double _detailColWidth(_DetailCol col) => switch (col) {
  _DetailCol.thumb => 84, // 64 缩略图 + 两侧 10 内距
  _DetailCol.price => 76,
  _DetailCol.carry => 78, // 携带档位文本（如「其他等级」）
  _DetailCol.ling => 70,
  _DetailCol.area => 116, // 区服两行
  _DetailCol.op => 84,
  _DetailCol.title || _DetailCol.feature => 0, // 弹性列，见 _detailColFlex
};

/// 弹性列权重（固定列返回 0，表示按 [_detailColWidth] 定宽）。
int _detailColFlex(_DetailCol col) => switch (col) {
  _DetailCol.title => 3,
  _DetailCol.feature => 4,
  _ => 0,
};

/// 表头文案。
String _detailColLabel(_DetailCol col) => switch (col) {
  _DetailCol.thumb => '图',
  _DetailCol.title => '标题',
  _DetailCol.price => '价格',
  _DetailCol.carry => '携带',
  _DetailCol.ling => '灵/悟',
  _DetailCol.area => '区服',
  _DetailCol.feature => '特征',
  _DetailCol.op => '操作',
};

/// 按列模型套壳：弹性列用 `Expanded`，固定列用 `SizedBox`。
Widget _detailColBox(_DetailCol col, Widget child) {
  final flex = _detailColFlex(col);
  if (flex > 0) return Expanded(flex: flex, child: child);
  return SizedBox(width: _detailColWidth(col), child: child);
}

/// 明细行副行文案（区服 · 灵/悟 [· 携带]），空项自动跳过。
String _detailSubLine(PetListing t, {required bool includeCarry}) {
  final parts = <String>[
    if (t.area.isNotEmpty) '${t.area}-${t.server}',
    if (t.ling != '0' || t.wu != '0')
      '灵${t.ling != '0' ? t.ling : '—'} / 悟${t.wu != '0' ? t.wu : '—'}',
    if (includeCarry && t.carryText.isNotEmpty) t.carryText,
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// 在售明细整表（表头 + 行列表），以 sliver 形式并入页面唯一的滚动体。
///
/// - 卡片外观：用 `DecoratedSliver`（底色 / 圆角 / 1px 描边）包住内部两个
///   sliver，等价于「卡片壳 + 内部两个 sliver」的写法，但不引入任何滚动容器；
/// - 行列表：`SliverList.builder` 惰性构建，只 inflate 可视区（含
///   cacheExtent）附近的行，缩略图随之按需加载，避免上千行 widget +
///   上千个 `Image.network` 同时创建；
/// - 横向：不再使用横向滚动容器，列按可用宽度自适应（见 [_DetailLayout]）。
class _DetailTableSliver extends StatelessWidget {
  const _DetailTableSliver({
    super.key,
    required this.data,
    required this.filter,
    required this.kw,
    required this.onKw,
    required this.onClearKw,
    required this.onDetail,
  });

  final List<PetListing> data;
  final PetMarketFilter filter;
  final String kw;
  final ValueChanged<String> onKw;
  final VoidCallback onClearKw;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final rows = pmDetailRows(data, filter, kw);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final layout = _detailLayoutOf(constraints.crossAxisExtent);
        final cols = _detailCols(layout);
        // 窄屏（移动端）收窄卡片左右内边距（与 TgCard 同规则）。
        final h = constraints.crossAxisExtent < 640
            ? math.min(TgSpacing.cardPaddingMobileH, 18.0)
            : 18.0;
        Widget th(_DetailCol col) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            _detailColLabel(col),
            style: TextStyle(
              fontSize: 11,
              color: tg.t3,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        return DecoratedSliver(
          decoration: BoxDecoration(
            color: tg.card,
            borderRadius: TgRadius.card,
            border: Border.all(color: tg.border, width: 1),
          ),
          sliver: SliverPadding(
            padding: EdgeInsets.fromLTRB(h, 18, h, 18),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MiscSectionHead(
                        title: '在售明细 · 按价格排序',
                        titleExpanded: false,
                        trailing: Text(
                          '共 ${rows.length} 条',
                          style: TextStyle(
                            fontFamily: TgFonts.sans,
                            fontSize: 11.5,
                            color: tg.t3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SearchBox(kw: kw, onKw: onKw, onClear: onClearKw),
                      const SizedBox(height: 6),
                      if (rows.isNotEmpty && cols.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: tg.border, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              for (final col in cols)
                                _detailColBox(col, th(col)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (rows.isEmpty)
                  const SliverToBoxAdapter(child: MiscEmptyTip(text: '当前筛选无数据'))
                else
                  SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final t = rows[i];
                      // 整行可点击：点击行内任意位置直接进入该条详情。行内
                      // 自带的交互（缩略图预览大图、「详情」按钮）在命中区
                      // 优先，互不冲突。
                      return MiscTappableRow(
                        onTap: () => onDetail(t),
                        child: _DetailRow(
                          pet: t,
                          layout: layout,
                          last: i == rows.length - 1,
                          onDetail: () => onDetail(t),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 搜索框（`pm-search`）。
class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.kw,
    required this.onKw,
    required this.onClear,
  });

  final String kw;
  final ValueChanged<String> onKw;
  final VoidCallback onClear;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _c = TextEditingController(text: widget.kw);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgTextField(
      controller: _c,
      hintText: '搜索标题关键字：品种 / 性格 / 资质 / 顶变 …',
      prefixIcon: 'search',
      fontSize: 12.5,
      height: 38,
      horizontalPadding: 12,
      radius: BorderRadius.circular(9),
      onChanged: widget.onKw,
      suffix: widget.kw.isEmpty
          ? null
          : InkWell(
              onTap: () {
                _c.clear();
                widget.onClear();
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('清空', style: TextStyle(fontSize: 11, color: tg.t3)),
              ),
            ),
    );
  }
}

/// 明细行：宽/中档为表格行（列模型与表头一致），窄屏为堆叠卡片。
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.pet,
    required this.layout,
    required this.last,
    required this.onDetail,
  });

  final PetListing pet;
  final _DetailLayout layout;
  final bool last;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: tg.border, width: 1),
        ),
      ),
      child: layout == _DetailLayout.card
          ? _DetailCardRow(pet: pet, onDetail: onDetail)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final col in _detailCols(layout))
                  _detailColBox(col, _cell(context, col)),
              ],
            ),
    );
  }

  /// 单元格内距（与表头一致）。
  Widget _cell(BuildContext context, _DetailCol col) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    child: _cellChild(context, col),
  );

  Widget _cellChild(BuildContext context, _DetailCol col) {
    final tg = context.tg;
    switch (col) {
      case _DetailCol.thumb:
        return MiscThumb(url: pet.img, caption: pet.title, fallbackIcon: 'paw');
      case _DetailCol.title:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pet.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tg.t1),
            ),
            // 中档布局已收起 灵/悟、区服 列，信息折叠到标题下的副行。
            if (layout == _DetailLayout.mid) ...[
              const SizedBox(height: 3),
              Text(
                _detailSubLine(pet, includeCarry: false),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tg.t3, height: 1.3),
              ),
            ],
          ],
        );
      case _DetailCol.price:
        return Text(
          _p(pet.price),
          style: TextStyle(
            fontSize: 12,
            color: tg.gold2,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      case _DetailCol.carry:
        return Text(
          pet.carryText,
          style: TextStyle(fontSize: 12, color: tg.t2),
        );
      case _DetailCol.ling:
        return Text(
          '${pet.ling != '0' ? pet.ling : '—'} / ${pet.wu != '0' ? pet.wu : '—'}',
          style: TextStyle(fontSize: 12, color: tg.t2),
        );
      case _DetailCol.area:
        return Text(
          pet.area.isEmpty ? '—' : '${pet.area}-${pet.server}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: tg.t2, height: 1.35),
        );
      case _DetailCol.feature:
        // 宽档布局已有 灵/悟 列，标签里不再重复「灵N」。
        return _FeatureCell(pet: pet, showLing: layout == _DetailLayout.wide);
      case _DetailCol.op:
        return Center(
          child: MiscMiniButton(label: '详情', onTap: onDetail),
        );
    }
  }
}

/// 窄屏（<560）明细行：堆叠卡片（标题 + 副行 / 特征标签 + 详情），
/// 与同页「性价比推荐」窄屏行同款，避免出现横向滚动表格。
class _DetailCardRow extends StatelessWidget {
  const _DetailCardRow({required this.pet, required this.onDetail});

  final PetListing pet;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiscThumb(url: pet.img, caption: pet.title, fallbackIcon: 'paw'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tg.t1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _detailSubLine(pet, includeCarry: true),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tg.t3, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _p(pet.price),
                style: TextStyle(
                  fontSize: 13,
                  color: tg.gold2,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: _FeatureCell(pet: pet, showLing: false)),
              const SizedBox(width: 8),
              MiscMiniButton(label: '详情', onTap: onDetail),
            ],
          ),
        ],
      ),
    );
  }
}

/// 特征 tag 组合（对应 `pmTag(t)`）。
class _FeatureCell extends StatelessWidget {
  const _FeatureCell({required this.pet, this.showLing = true});

  final PetListing pet;

  /// 是否在标签里展示「灵N」；宽表格已有 灵/悟 列、中/窄布局的副行已含灵悟，
  /// 这两种情况下传 false 避免重复。
  final bool showLing;

  @override
  Widget build(BuildContext context) {
    final t = pet;
    final tags = <(String, bool)>[
      if (t.ding) ('顶变', true),
      if (t.ss) ('双十', true),
      if (t.ch != null) (t.ch!, false),
      if (t.skill != null && t.skill! > 0) ('技能全${t.skill}', false),
      if (t.pet.isNotEmpty && t.pet != '其他') (t.pet, true),
      if (showLing && t.ling != '0') ('灵${t.ling}', false),
    ];
    if (tags.isEmpty) {
      return Text('—', style: TextStyle(fontSize: 12, color: tgOf(context).t2));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (text, gold) in tags) MiscTag(text: text, gold: gold),
      ],
    );
  }
}

/* ============================== 详情主体 ============================== */

/// 详情右侧信息（`pd-name/price/grid/tags/act/src`）。
class _DetailInfo extends StatelessWidget {
  const _DetailInfo({required this.pet, required this.onBack});

  final PetListing pet;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final t = pet;
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
              _p(t.price),
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
                  label: '资质',
                  value: t.apt?.toString() ?? '未标注',
                  gold: true,
                  width: cellW,
                ),
                MiscInfoCell(label: '可携带等级', value: t.carryText, width: cellW),
                MiscInfoCell(
                  label: '灵性 / 悟性',
                  value:
                      '${t.ling != '0' ? t.ling : '—'} / ${t.wu != '0' ? t.wu : '—'}',
                  width: cellW,
                ),
                MiscInfoCell(label: '上架时间', value: '—', width: cellW),
                MiscInfoCell(
                  label: '浏览量',
                  value: _thousands(t.views),
                  width: cellW,
                ),
                MiscInfoCell(
                  label: '大区 · 服务器',
                  value: t.area.isEmpty ? '—' : '${t.area}-${t.server}',
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
            if (t.ding) const MiscTag(text: '顶变', gold: true),
            if (t.ss) const MiscTag(text: '双十', gold: true),
            if (t.ch != null) MiscTag(text: t.ch!),
            if (t.skill != null && t.skill! > 0) MiscTag(text: '技能全${t.skill}'),
            if (t.pet.isNotEmpty && t.pet != '其他')
              MiscTag(text: t.pet, gold: true),
            if (t.ling != '0') MiscTag(text: '灵${t.ling}'),
            if (t.ding == false &&
                t.ss == false &&
                t.ch == null &&
                t.skill == null &&
                (t.pet.isEmpty || t.pet == '其他') &&
                t.ling == '0')
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

/* ============================== 商品详情独立页 ============================== */

/// 商品详情页（独立嵌套子路由 `/misc/market/detail`）。
///
/// 从行情列表点击「详情」时 `context.push(..., extra: pet)` 压栈到列表之上；
/// 列表页仍在路由栈中、滚动位置天然保留。返回（系统返回 / 「返回行情列表」
/// 按钮）走 `context.pop()`，因此不会出现页内切换那种回顶跳动。
class PetDetailPage extends StatelessWidget {
  const PetDetailPage({super.key, this.pet});

  /// 商品数据经路由 extra 传入；null（如直接深链）时展示缺失提示。
  final PetListing? pet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final p = pet;
        final blocks = <Widget>[
          if (p == null)
            MiscDetailMissing(
              icon: 'paw',
              title: '商品数据缺失',
              hint: '未获取到该商品的行情数据，请从行情列表重新进入。',
              onBack: () => context.pop(),
            )
          else ...[
            MiscDetailHead(
              title: '珍兽详情',
              subtitle:
                  '${p.area.isEmpty ? '' : '${p.area} · ${p.server}'}'
                  ' · 编号 ${p.sn}',
              crumbTail: ' / 珍兽行情 / 商品详情',
              onCrumbTap: () =>
                  context.go(ToolCatalog.miscMarket.group.hubLocation),
            ),
            MiscDetailBody(
              image: MiscDetailImage(
                url: p.img,
                caption: p.title,
                fallbackIcon: 'paw',
              ),
              info: _DetailInfo(pet: p, onBack: () => context.pop()),
            ),
            const SizedBox(height: TgSpacing.s34),
            const TgPageFoot(text: '点击商品图片可放大查看'),
          ],
        ];
        // 与行情列表一致的内边距 / 限宽 1180 居中换算。
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
