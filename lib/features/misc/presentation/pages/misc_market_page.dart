import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../../../shared/widgets/tg_select.dart';
import '../../../../shared/widgets/tg_text_field.dart';
import '../../data/pet_market_fetcher.dart';
import '../../domain/pet_market.dart';
import '../../domain/pet_market_stats.dart';

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
        // 页面主体（行情列表）作为垂直区块序列，交由整页 CustomScrollView
        // 统一滚动（单滚动体：明细随页滚动，惯性/缓动原生）。
        final blocks = <Widget>[
          _MarketHead(
            onCrumbTap: () => context.go(
              ToolCatalog.miscMarket.group.hubLocation,
            ),
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
            _StatusOk(message: _fetchMsg)
          else if (_fetch == _FetchState.warn && _items.isEmpty)
            _StatusWarn(message: _fetchMsg),
          const SizedBox(height: 4),
          const _MarketNote(),
          const SizedBox(height: 14),
          if (_items.isEmpty && _fetch == _FetchState.loading)
            const _LoadingPanel()
          else if (_items.isEmpty)
            const _EmptyDataTip()
          else ...[
            _StatsRow(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 12),
            _DistCard(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 14),
            _SegCard(filtered: pmFiltered(data, _filter)),
            const SizedBox(height: 14),
            _BestCard(filtered: pmFiltered(data, _filter), onDetail: _openDetail),
            const SizedBox(height: 14),
            _ListCard(
              data: data,
              filter: _filter,
              kw: _kw,
              onKw: _onKw,
              onClearKw: _clearKw,
              onDetail: _openDetail,
            ),
          ],
          const SizedBox(height: TgSpacing.s34),
          const _PageFoot(),
        ];
        // 页面内边距（compact / 桌面两套）。
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
        // 宽视口把内容限宽 1180 并居中：换算为 sliver 的横向 padding。
        final avail = math.max(0.0, constraints.maxWidth - basePad.left - basePad.right);
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

enum _FetchState { loading, ok, warn }

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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final selects = <Widget>[
            TgSelect(
              label: '大区',
              value: filter.area,
              hint: '全部大区',
              width: 150,
              options: [for (final a in areas) (a, a)],
              onChanged: onArea,
            ),
            TgSelect(
              label: '服务器',
              value: filter.server,
              hint: '全部服务器',
              width: 160,
              options: [for (final s in serverNames) (s, s)],
              onChanged: onServer,
            ),
            TgSelect(
              label: '可携带等级',
              value: filter.carryBand.label,
              hint: PetCarryBand.all.label,
              width: 168,
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
          const gap = 12.0;
          final compact = c.maxWidth < 640;
          if (compact) {
            return Wrap(
              spacing: gap,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                ...selects,
                _FetchButton(fetching: fetching, onTap: onFetch),
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
              _FetchButton(fetching: fetching, onTap: onFetch),
            ],
          );
        },
      ),
    );
  }
}

/* ============================== 筛选条 ============================== */

/// 「一键获取最新数据」主按钮（`.btn btn-primary pm-fetch`）。
///
/// 金渐变 · 墨字 · 常态辉光（0 5 20 rgba(198,152,86,.3)）·
/// hover 上浮 1px 并提亮（brightness 1.08）；[fetching] 时禁用为灰金底。
class _FetchButton extends StatefulWidget {
  const _FetchButton({required this.fetching, required this.onTap});

  final bool fetching;
  final VoidCallback onTap;

  @override
  State<_FetchButton> createState() => _FetchButtonState();
}

class _FetchButtonState extends State<_FetchButton> {
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

/// 获取成功提示（`pm-status.ok` 绿）。
class _StatusOk extends StatelessWidget {
  const _StatusOk({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatusBar(color: const Color(0xFF7FC88F), message: message);
  }
}

/// CORS / 网络失败提示（`pm-status.warn` 琥珀）。
class _StatusWarn extends StatelessWidget {
  const _StatusWarn({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatusBar(color: const Color(0xFFE0B25C), message: message);
  }
}

/// 状态条外壳（ok 绿 / warn 琥珀共用），message 含标题段（首个「：」前加粗）。
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.color, required this.message});

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

/// 数据说明 note（`note`）。
class _MarketNote extends StatelessWidget {
  const _MarketNote();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: tg.goldTint(.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.goldTint(.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: TgIcon('info', size: 15, color: tg.gold2),
          ),
          const SizedBox(width: 9),
          Expanded(
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
                    style: TextStyle(
                      color: tg.gold2,
                      fontWeight: FontWeight.w600,
                    ),
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
          ),
        ],
      ),
    );
  }
}

/// 首次拉取 loading 占位。
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

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
          Text('正在从神仙代售获取实时行情…', style: TextStyle(fontSize: 13, color: tg.t3)),
        ],
      ),
    );
  }
}

/// 无数据空态（接口失败或返回空时）。
class _EmptyDataTip extends StatelessWidget {
  const _EmptyDataTip();

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
          TgIcon('paw', size: 26, color: tg.t3),
          const SizedBox(height: 12),
          Text('暂无在售数据', style: TextStyle(fontSize: 14, color: tg.t2)),
          const SizedBox(height: 6),
          Text(
            '可点击上方「一键获取最新数据」重试，'
            '或稍后再进入页面自动刷新。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: tg.t3, height: 1.6),
          ),
        ],
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
    final items = <(String, String)>[
      ('在售样本', '${s.count} 条'),
      ('价格区间', s.rangeText),
      ('中位价', s.medianText),
      ('均价', s.meanText),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 600 ? 2 : 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: (c.maxWidth - 12 * (cols - 1)) / cols,
                child: _StatCell(label: items[i].$1, value: items[i].$2),
              ),
          ],
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

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

/* ============================== 通用区块卡 ============================== */

/// 区块标题（`pm-sec h4`：金条 + serif 标题）。
class _SecHead extends StatelessWidget {
  const _SecHead({
    required this.title,
    this.trailing,
    this.titleExpanded = true,
  });

  final String title;
  final Widget? trailing;

  /// 标题是否占满整行；false 时标题按自然宽度排布，
  /// 使 [trailing]（如「共 N 条」小字）紧跟标题文字（原型 h4 + 行内小字）。
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

/// 卡片外壳。
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

/* ============================== 价位分布 ============================== */

class _DistCard extends StatelessWidget {
  const _DistCard({required this.filtered});

  final List<PetListing> filtered;

  @override
  Widget build(BuildContext context) {
    final segs = pmDistSegs(filtered);
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecHead(title: '价位分布 · 在售数量'),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const _EmptyTip('当前筛选无数据')
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              seg.label,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: tg.t2, letterSpacing: .5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 6,
                color: tg.inset,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: width.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC9995A), Color(0xFFF2D49B)],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text.rich(
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
          ),
        ],
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
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecHead(title: '价位段画像'),
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
    return Column(
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
                Text(r.label, style: TextStyle(fontSize: 12, color: tg.t2)),
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
                Text(r.lvTop, style: TextStyle(fontSize: 12, color: tg.t2)),
              ),
            ),
            Expanded(
              flex: 5,
              child: cell(
                r.features.isEmpty
                    ? Text('—', style: TextStyle(fontSize: 12, color: tg.t2))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final f in r.features)
                            _PmTag(text: f, gold: false),
                        ],
                      ),
              ),
            ),
          ]),
      ],
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

/* ============================== 性价比推荐 ============================== */

class _BestCard extends StatelessWidget {
  const _BestCard({required this.filtered, required this.onDetail});

  final List<PetListing> filtered;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecHead(title: '性价比推荐 · 资质 / 千元价（资质 ≥3800）'),
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
      return const _EmptyTip('当前筛选无高资质样本');
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
    Widget goBtn() => _BestGoBtn(
      label: '详情',
      onTap: () => onDetail(t),
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
                    _PmTag(text: '资质 ${t.apt}', gold: true),
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
              _PmTag(text: '资质 ${t.apt}', gold: true),
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

/// 性价比行的小按钮（描边小药丸，避免与明细「详情」文案撞车）。
class _BestGoBtn extends StatefulWidget {
  const _BestGoBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_BestGoBtn> createState() => _BestGoBtnState();
}

class _BestGoBtnState extends State<_BestGoBtn> {
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
        borderRadius: BorderRadius.circular(7),
        hoverColor: Colors.transparent,
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
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
              fontSize: 11,
              color: _hover ? tg.gold2 : tg.t2,
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== 空态 ============================== */

class _EmptyTip extends StatelessWidget {
  const _EmptyTip(this.text);

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

/* ============================== 在售明细 ============================== */

class _ListCard extends StatelessWidget {
  const _ListCard({
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
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecHead(
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
          if (rows.isEmpty)
            const _EmptyTip('当前筛选无数据')
          else
            _DetailTable(rows: rows, onDetail: onDetail),
        ],
      ),
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

/// 明细表（`pm-table`）：图 / 价格 / 携带 / 灵·悟 / 特征 / 区服 / 标题 / 操作。
class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.rows, required this.onDetail});

  final List<PetListing> rows;
  final ValueChanged<PetListing> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
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
    Widget tr({required List<Widget> cells, bool last = false}) => Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: tg.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: cells,
      ),
    );
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 560;
        // 列宽：紧凑隐藏 灵/悟 与 区服 列（hide-m）。
        final thumbW = 44.0;
        final priceW = 76.0;
        final carryW = 78.0; // 携带档位文本（如“其他等级”）
        final lingW = 70.0;
        final areaW = 116.0; // 区服两行
        final titleW = compact ? 148.0 : 248.0;
        final opW = 84.0;
        // 最小表宽：紧凑仍需容纳特征列少量标签；桌面留足剩余给特征。
        final minTable = compact ? 640.0 : 860.0;
        final tableW = math.max(c.maxWidth, minTable);

        final header = tr(
          cells: [
            SizedBox(width: thumbW, child: th('图')),
            SizedBox(width: priceW, child: th('价格')),
            SizedBox(width: carryW, child: th('携带')),
            if (!compact) ...[
              SizedBox(width: lingW, child: th('灵/悟')),
              SizedBox(width: areaW, child: th('区服')),
            ],
            Expanded(child: th('特征')),
            SizedBox(width: titleW, child: th('标题')),
            SizedBox(width: opW, child: th('操作')),
          ],
        );
        // 明细行直接铺在整页滚动里（不做区内独立滚动）：明细与页面其余内容
        // 属于同一条滚动，滚动惯性 / 缓动 / 回弹均由系统整页物理统一提供，
        // 不存在「明细滚到边界再切换给整页」的手感断层。
        // 行内图片均已 cacheWidth 降采样解码，行数几百时构建与滚动仍流畅。
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableW,
            child: Column(
              children: [
                header,
                for (var i = 0; i < rows.length; i++)
                  tr(
                    last: i == rows.length - 1,
                    cells: _rowCells(
                      context,
                      rows[i],
                      compact: compact,
                      cell: cell,
                      thumbW: thumbW,
                      priceW: priceW,
                      carryW: carryW,
                      lingW: lingW,
                      areaW: areaW,
                      titleW: titleW,
                      opW: opW,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _rowCells(
    BuildContext context,
    PetListing t, {
    required bool compact,
    required Widget Function(Widget) cell,
    required double thumbW,
    required double priceW,
    required double carryW,
    required double lingW,
    required double areaW,
    required double titleW,
    required double opW,
  }) {
    final tg = context.tg;
    return [
      SizedBox(
        width: thumbW,
        child: cell(_Thumb(pet: t)),
      ),
      SizedBox(
        width: priceW,
        child: cell(
          Text(
            _p(t.price),
            style: TextStyle(
              fontSize: 12,
              color: tg.gold2,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
      SizedBox(
        width: carryW,
        child: cell(
          Text(t.carryText, style: TextStyle(fontSize: 12, color: tg.t2)),
        ),
      ),
      if (!compact) ...[
        SizedBox(
          width: lingW,
          child: cell(
            Text(
              '${t.ling != '0' ? t.ling : '—'} / ${t.wu != '0' ? t.wu : '—'}',
              style: TextStyle(fontSize: 12, color: tg.t2),
            ),
          ),
        ),
        SizedBox(
          width: areaW,
          child: cell(
            Text(
              t.area.isEmpty ? '—' : '${t.area}-${t.server}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tg.t2, height: 1.35),
            ),
          ),
        ),
      ],
      Expanded(child: cell(_FeatureCell(pet: t))),
      SizedBox(
        width: titleW,
        child: cell(
          Text(
            t.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: tg.t1),
          ),
        ),
      ),
      SizedBox(
        width: opW,
        child: cell(Center(child: _DetailBtn(onTap: () => onDetail(t)))),
      ),
    ];
  }
}

/// 缩略图：方形裁切（42×42，对应 `.pm-thumb`）；有图时可点击预览大图。
class _Thumb extends StatefulWidget {
  const _Thumb({required this.pet});

  final PetListing pet;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.pet.img;
    final hasImg = url != null && url.isNotEmpty;
    final hot = _hover && hasImg; // 无可点图时不进入可点 hover 态
    Widget inner() {
      if (!hasImg) {
        return TgIcon('paw', size: 20, color: hot ? tg.gold2 : tg.t3);
      }
      return Image.network(
        url,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        cacheWidth: 128, // 42×42 显示，解码上限到 @3x，避免原图全尺寸解码
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            TgIcon('paw', size: 20, color: hot ? tg.gold2 : tg.t3),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : TgIcon('paw', size: 20, color: tg.t3),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: hasImg ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: hasImg
            ? () => _showLightbox(
                  context,
                  imageUrl: url,
                  caption: widget.pet.title,
                )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 42,
            height: 42,
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

/// 特征 tag 组合（对应 `pmTag(t)`）。
class _FeatureCell extends StatelessWidget {
  const _FeatureCell({required this.pet});

  final PetListing pet;

  @override
  Widget build(BuildContext context) {
    final t = pet;
    final tags = <(String, bool)>[
      if (t.ding) ('顶变', true),
      if (t.ss) ('双十', true),
      if (t.ch != null) (t.ch!, false),
      if (t.skill != null && t.skill! > 0) ('技能全${t.skill}', false),
      if (t.pet.isNotEmpty && t.pet != '其他') (t.pet, true),
      if (t.ling != '0') ('灵${t.ling}', false),
    ];
    if (tags.isEmpty) {
      return Text('—', style: TextStyle(fontSize: 12, color: tgOf(context).t2));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (text, gold) in tags) _PmTag(text: text, gold: gold),
      ],
    );
  }
}

/// 「详情」小按钮（`.pm-detail-btn`）。
class _DetailBtn extends StatefulWidget {
  const _DetailBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DetailBtn> createState() => _DetailBtnState();
}

class _DetailBtnState extends State<_DetailBtn> {
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
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hover ? tg.goldTint(.45) : tg.borderHi,
              width: 1,
            ),
            color: _hover ? tg.goldTint(.06) : Colors.transparent,
          ),
          child: Text(
            '详情',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: _hover ? tg.gold2 : tg.t2),
          ),
        ),
      ),
    );
  }
}

/* ============================== 详情子视图 ============================== */

class _DetailHead extends StatelessWidget {
  const _DetailHead({
    required this.pet,
    required this.onHub,
    required this.onBack,
  });

  final PetListing pet;
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
                ' / 珍兽行情 / 商品详情',
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
                  '珍兽详情',
                  style: TgType.pageH1.copyWith(color: tg.t1),
                ),
              ),
            ],
          ),
          const SizedBox(height: TgSpacing.s10),
          Text(
            '${pet.area.isEmpty ? '' : '${pet.area} · ${pet.server}'}'
            ' · 编号 ${pet.sn}',
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

/// 详情主体（`pd-wrap`）。
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.pet, required this.onBack});

  final PetListing pet;
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
                    SizedBox(width: 320, child: _DetailImg(pet: pet)),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _DetailInfo(pet: pet, onBack: onBack),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 紧凑布局：限制到约 320 方形（居中），避免撑满整行过高。
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _DetailImg(pet: pet),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailInfo(pet: pet, onBack: onBack),
                  ],
                ),
        );
      },
    );
  }
}

/// 详情大图（真实远程商品图，加载失败回退 paw 占位；点击放大）。
class _DetailImg extends StatefulWidget {
  const _DetailImg({required this.pet});

  final PetListing pet;

  @override
  State<_DetailImg> createState() => _DetailImgState();
}

class _DetailImgState extends State<_DetailImg> {
  bool _hover = false;

  Widget _placeholder(double size, Color color) {
    return TgIcon('paw', size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.pet.img;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showLightbox(
          context,
          imageUrl: url,
          caption: url != null ? widget.pet.title : null,
        ),
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

/// 图片预览弹窗（复用「卡回归计算器 · 添加账号」的 TgModal 卡片样式）：
/// 居中 `.modal` 卡片（r20 · 描边 · 大阴影）· 头部 icon 块 + 标题 + 关闭按钮，
/// 下方为方形商品图预览；点击遮罩或关闭按钮关闭。
Future<void> _showLightbox(
  BuildContext context, {
  String? imageUrl,
  String? caption,
}) {
  final imgUrl = imageUrl;
  return showTgModal(
    context: context,
    maxWidth: 720,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // modal-head：与「添加账号」同款（icon 块 + 标题 + 关闭）
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.tg.goldTint(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.tg.goldTint(.28), width: 1),
              ),
              child: TgIcon('paw', size: 21, color: context.tg.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '商品图片预览',
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.tg.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption ?? '珍兽行情 · 在售商品图',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TgType.tag.copyWith(color: context.tg.t3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 弹窗在 root navigator（showTgModal 默认 useRootNavigator:true），
            // 必须 pop root navigator；直接 Navigator.of(context) 会解析到 shell
            // 子 navigator 而回退页面路由。
            TgModalCloseButton(
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 方形商品图：随弹窗可用宽度自适应（约 ≤ 316）。
        SizedBox(
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.tg.inset,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.tg.border, width: 1),
              ),
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: 1600, // 弹窗宽 720 时解码上限到 @2x
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TgIcon('paw', size: 64, color: context.tg.t3),
                            const SizedBox(height: 8),
                            Text(
                              '图片加载失败',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.tg.t3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.tg.gold2,
                                  backgroundColor: context.tg.goldTint(.15),
                                ),
                              ),
                            ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TgIcon('paw', size: 64, color: context.tg.t3),
                          const SizedBox(height: 8),
                          Text(
                            '暂无图片',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.tg.t3,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PdCell(label: '资质', value: t.apt?.toString() ?? '未标注', gold: true),
            _PdCell(label: '可携带等级', value: t.carryText),
            _PdCell(
              label: '灵性 / 悟性',
              value:
                  '${t.ling != '0' ? t.ling : '—'} / ${t.wu != '0' ? t.wu : '—'}',
            ),
            _PdCell(label: '上架时间', value: '—'),
            _PdCell(label: '浏览量', value: _thousands(t.views)),
            _PdCell(
              label: '大区 · 服务器',
              value: t.area.isEmpty ? '—' : '${t.area}-${t.server}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (t.ding) const _PmTag(text: '顶变', gold: true),
            if (t.ss) const _PmTag(text: '双十', gold: true),
            if (t.ch != null) _PmTag(text: t.ch!, gold: false),
            if (t.skill != null && t.skill! > 0)
              _PmTag(text: '技能全${t.skill}', gold: false),
            if (t.pet.isNotEmpty && t.pet != '其他')
              _PmTag(text: t.pet, gold: true),
            if (t.ling != '0') _PmTag(text: '灵${t.ling}', gold: false),
            if (t.ding == false &&
                t.ss == false &&
                t.ch == null &&
                t.skill == null &&
                (t.pet.isEmpty || t.pet == '其他') &&
                t.ling == '0')
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
          '行情数据仅供交易参考 · 天工阁与神仙代售平台无隶属关系',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
      ],
    );
  }
}

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
            _DetailMissing(onBack: () => context.pop())
          else ...[
            _DetailHead(
              pet: p,
              onHub: () => context.go(
                ToolCatalog.miscMarket.group.hubLocation,
              ),
              onBack: () => context.pop(),
            ),
            _DetailBody(pet: p, onBack: () => context.pop()),
            const SizedBox(height: TgSpacing.s34),
            const _DetailFoot(),
          ],
        ];
        // 与行情列表一致的内边距 / 限宽 1180 居中换算。
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

/// 直接深链且无 extra 商品数据时的兜底提示。
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
          TgIcon('paw', size: 26, color: tg.t3),
          const SizedBox(height: 12),
          Text('商品数据缺失', style: TextStyle(fontSize: 14, color: tg.t2)),
          const SizedBox(height: 6),
          Text(
            '未获取到该商品的行情数据，请从行情列表重新进入。',
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
