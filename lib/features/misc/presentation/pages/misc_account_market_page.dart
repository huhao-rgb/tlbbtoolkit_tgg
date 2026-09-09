import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/chainable_scroll_physics.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_image_gallery.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../../../shared/widgets/tg_select.dart';
import '../../data/account_market_fetcher.dart';
import '../../data/pet_market_fetcher.dart'
    show SxdsRegion, SxdsServer, fetchSxdsRegions;
import '../../domain/account_market.dart';
import '../../domain/account_market_stats.dart';

/// 账号行情分析（对应原型 `v-acc-market`）。
///
/// - 数据完全来自神仙代售平台真实接口（`fetchSxdsAccountMarket`），无静态快照；
/// - 首次进入自动拉取；顶部筛选（大区 / 服务器 / 角色等级）联动统计；
/// - 统计卡、价位分布、价位段画像、区服在售分布、性价比推荐、在售明细；
/// - 「一键获取」可手动重新拉取；Web 端被 CORS 拦截时显示
///   「浏览器跨域拦截」提示与空态，桌面/移动端可直连。
class MiscAccountMarketPage extends StatefulWidget {
  const MiscAccountMarketPage({super.key, this.fetchAccounts, this.fetchRegions});

  /// 抓取函数（测试注入用）；默认走 `fetchSxdsAccountMarket` 真实接口。
  final Future<AccountMarketFetchResult> Function()? fetchAccounts;

  /// 区服目录抓取（测试注入用）；默认走 `fetchSxdsRegions` 真实接口。
  final Future<List<SxdsRegion>> Function()? fetchRegions;

  @override
  State<MiscAccountMarketPage> createState() => _MiscAccountMarketPageState();
}

class _MiscAccountMarketPageState extends State<MiscAccountMarketPage> {
  String _area = '';
  String _server = '';
  AccountLevelBand _band = AccountLevelBand.all;

  // 数据源：初始为空，进入页面后自动从接口拉取。
  List<AccountListing> _items = const [];

  // 区服目录候选（下拉选项来源）：从平台 gamefilter 加载，避免聚焦后缩水。
  List<SxdsRegion> _regions = const [];

  // 加载状态：none 隐藏 / loading / ok（绿）/ warn（琥珀）。
  _FetchState _fetch = _FetchState.loading;
  String _fetchMsg = '';

  AccountMarketFilter get _filter =>
      AccountMarketFilter(area: _area, server: _server, band: _band);

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

  void _onArea(String v) {
    setState(() {
      _area = v;
      _server = ''; // 大区变化重置服务器
    });
  }

  /// 打开账号详情（独立嵌套子路由：push 到列表之上，返回后列表滚动位置
  /// 天然保留，不会页面跳动）。
  void _openDetail(AccountListing acc) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.push('/misc/acc-market/detail', extra: acc);
  }

  /// 由大区名称解析平台大区 id（目录优先，数据兜底）。
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
  /// 区服目录已加载时用目录映射名称→id；否则回退从已抓数据里找同名商品。
  /// 角色等级直接映射 `roleLevelLimit`。全空时返回 [AccountMarketQuery]。
  AccountMarketQuery _buildQuery() {
    return AccountMarketQuery(
      areaId: _area.isEmpty ? null : _areaIdOf(_area),
      serverId: _server.isEmpty ? null : _serverIdsOf(_server),
      levelLimit: _band == AccountLevelBand.all ? null : _band.limit,
    );
  }

  /// 当前检索条件的人类可读文案（用于成功提示）。
  String get _queryLabel {
    final parts = <String>[
      if (_area.isNotEmpty) _area,
      if (_server.isNotEmpty) _server,
      if (_band != AccountLevelBand.all) _band.label,
    ];
    return parts.isEmpty ? '全部大区' : parts.join(' · ');
  }

  /// 拉取平台真实行情（首次进入自动 + 「一键获取」手动共用）。
  ///
  /// - 自动携带当前筛选条件（大区/服务器/角色等级）；
  /// - 无筛选（全部）→ 只取前 400 条；有筛选 → 分页拉取该条件下全部数据；
  /// - 成功后**保留**当前筛选（不重置）；
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
    final fetch = widget.fetchAccounts != null
        ? widget.fetchAccounts!
        : () => fetchSxdsAccountMarket(query: query);
    try {
      final result = await fetch();
      if (!mounted) return;
      if (result.parsed.isNotEmpty) {
        setState(() {
          _items = result.parsed;
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
              '但未识别出有效账号，请稍后重试。';
        });
      }
    } on AccountMarketFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _fetch = _FetchState.warn;
        _fetchMsg = e.isWebBlocked
            ? '浏览器跨域拦截（CORS）$_webCorsText'
            : e.message;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final data = _items;
        // 页面主体（行情列表）作为垂直区块序列，交由整页 CustomScrollView
        // 统一滚动；明细表行数超出可视上限时在表体内独立滚动 + 惰性构建
        // （见 _DetailTable），避免大数据量下一次性构建全部行导致卡顿。
        final blocks = <Widget>[
          _MarketHead(
            onCrumbTap: () => context.go(
              ToolCatalog.miscAccountMarket.group.hubLocation,
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
            _StatsRow(filtered: amFiltered(data, _filter)),
            const SizedBox(height: 12),
            _DistCard(filtered: amFiltered(data, _filter)),
            const SizedBox(height: 14),
            _SegCard(filtered: amFiltered(data, _filter)),
            const SizedBox(height: 14),
            _BestCard(filtered: amFiltered(data, _filter)),
            const SizedBox(height: 14),
            _ListCard(data: data, filter: _filter, onDetail: _openDetail),
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

/// 金额 fmt + 前缀 ￥（价格列/统计）。
String _p(num n) => amP(n);

/* ============================== 主视图头 ============================== */

class _MarketHead extends StatelessWidget {
  const _MarketHead({required this.onCrumbTap});

  final VoidCallback onCrumbTap;

  @override
  Widget build(BuildContext context) {
    return TgPageHead(
      crumbLeft: ToolCatalog.miscAccountMarket.crumbRoot,
      crumbTail: ToolCatalog.miscAccountMarket.crumb.substring(
        ToolCatalog.miscAccountMarket.crumbRoot.length,
      ),
      onCrumbLeftTap: onCrumbTap,
      title: '账号行情分析',
      subtitle: ToolCatalog.miscAccountMarket.pageSubtitle,
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

  final List<AccountListing> data;
  final AccountMarketFilter filter;
  final bool fetching;
  final ValueChanged<String> onArea;
  final ValueChanged<String> onServer;
  final ValueChanged<AccountLevelBand> onBand;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    // 区服下拉候选：优先平台目录（全量）；目录未加载时回退到当前数据推导。
    final useRegions = regions.isNotEmpty;
    final areas = useRegions
        ? [for (final r in regions) r.areaName]
        : [for (final o in amAreas(data)) o.name];
    final serverPool = useRegions
        ? <SxdsServer>[
            for (final r in regions)
              if (filter.area.isEmpty || r.areaName == filter.area)
                ...r.servers,
          ]
        : null;
    final serverNames = serverPool != null
        ? [for (final s in serverPool) s.serverName]
        : amServersOf(amAreas(data), filter.area);
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
              label: '角色等级',
              value: filter.band == AccountLevelBand.all
                  ? ''
                  : filter.band.label,
              hint: AccountLevelBand.all.label,
              width: 150,
              options: [
                for (final b in AccountLevelBand.values)
                  (b.label, b.label),
              ],
              onChanged: (v) {
                final band = AccountLevelBand.values.firstWhere(
                  (b) => b.label == v,
                  orElse: () => AccountLevelBand.all,
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

/// 「一键获取最新数据」主按钮（`.btn btn-primary`）。
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

/// 获取成功提示（绿）。
class _StatusOk extends StatelessWidget {
  const _StatusOk({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatusBar(color: const Color(0xFF7FC88F), message: message);
  }
}

/// CORS / 网络失败提示（琥珀）。
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
                        ' 天龙八部怀旧服「游戏账号」类目公开在售列表'
                        '（实时接口，进入页面自动拉取最新数据）。筛选条件联动'
                        '全部统计模块，「一键获取」可手动刷新。',
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
          TgIcon('user', size: 26, color: tg.t3),
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

  final List<AccountListing> filtered;

  @override
  Widget build(BuildContext context) {
    final s = amComputeStats(filtered);
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
  const _SecHead({required this.title, this.trailing, this.titleExpanded = true});

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

  final List<AccountListing> filtered;

  @override
  Widget build(BuildContext context) {
    final segs = amDistSegs(filtered);
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

  final AmDistSeg seg;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final width = seg.bar;
    final pct = total == 0 ? 0 : (seg.count / total * 100).round();
    final hasAttr = seg.avgAttr > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 118,
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
                        '${hasAttr ? ' · 均主属性${seg.avgAttr}' : ''}',
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

/* ============================== 价位段画像 + 区服分布 ============================== */

class _SegCard extends StatelessWidget {
  const _SegCard({required this.filtered});

  final List<AccountListing> filtered;

  @override
  Widget build(BuildContext context) {
    final segs = amSegProfiles(amDistSegs(filtered));
    final sectRows = amSectRows(filtered);
    var maxCount = 0;
    for (final r in sectRows) {
      if (r.count > maxCount) maxCount = r.count;
    }
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecHead(title: '价位段画像'),
          const SizedBox(height: 12),
          _SegTable(rows: segs),
          const SizedBox(height: 18),
          const _SecHead(title: '区服在售分布'),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const _EmptyTip('当前筛选无数据')
          else
            for (final r in sectRows)
              _SectRow(row: r, total: filtered.length, maxCount: maxCount),
        ],
      ),
    );
  }
}

class _SegTable extends StatelessWidget {
  const _SegTable({required this.rows});

  final List<AmSegProfile> rows;

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
          Expanded(flex: 2, child: th('均主属性')),
          Expanded(flex: 3, child: th('主流等级')),
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
                  '${r.avgAttr ?? '—'}',
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

/// 区服在售分布行。
class _SectRow extends StatelessWidget {
  const _SectRow({required this.row, required this.total, required this.maxCount});

  final AmSectRow row;
  final int total;

  /// 全区服最大数量（bar 归一用）。
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final width = maxCount == 0 ? 0.0 : row.count / maxCount;
    final pct = total == 0 ? 0 : (row.count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              row.area,
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
                    text: '${row.count} 条',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tg.gold2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' $pct% · 中位${_p(row.median)}'),
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

TgColors tgOf(BuildContext context) => context.tg;

/* ============================== 性价比推荐 ============================== */

class _BestCard extends StatelessWidget {
  const _BestCard({required this.filtered});

  final List<AccountListing> filtered;

  @override
  Widget build(BuildContext context) {
    final best = amBestItems(filtered);
    return _BlockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecHead(title: '性价比推荐 · 主属性 / 万元价（主属性 ≥4000）'),
          const SizedBox(height: 12),
          if (best.isEmpty)
            const _EmptyTip('当前筛选无高主属性样本')
          else
            for (var i = 0; i < best.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BestRow(index: i, item: best[i]),
              ),
        ],
      ),
    );
  }
}

class _BestRow extends StatelessWidget {
  const _BestRow({required this.index, required this.item});

  final int index;
  final AmBestItem item;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final t = item.account;
    final sub = t.area.isEmpty ? '' : t.area;
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
      width: 64,
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
                    _PmTag(text: '主属性 ${t.attr}', gold: true),
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
              _PmTag(text: '主属性 ${t.attr}', gold: true),
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
            ],
          ),
        );
      },
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
  const _ListCard({required this.data, required this.filter, required this.onDetail});

  final List<AccountListing> data;
  final AccountMarketFilter filter;
  final ValueChanged<AccountListing> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final rows = amDetailRows(data, filter);
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
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _EmptyTip('当前筛选无数据')
          else
            _DetailTable(rows: rows, onDetail: onDetail),
        ],
      ),
    );
  }
}

/// 明细表（`amTable`）：图 / 价格 / 等级 / 职业 / 区服 / 主属性·攻 / 标题 / 操作。
class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.rows, required this.onDetail});

  final List<AccountListing> rows;
  final ValueChanged<AccountListing> onDetail;

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
          bottom: last ? BorderSide.none : BorderSide(color: tg.border, width: 1),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: cells),
    );
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 640;
        // 图列：64×64 方形缩略图 + 两侧 10px 单元格内距 = 84 列宽。
        final thumbW = 84.0;
        final priceW = 92.0;
        final lvW = 56.0;
        final jobW = 84.0;
        final areaW = 116.0;
        final attrW = 128.0;
        final titleW = compact ? 180.0 : 300.0;
        final opW = 76.0;
        final minTable = compact ? 660.0 : 900.0;
        final tableW = math.max(c.maxWidth, minTable);
        final header = tr(
          cells: [
            SizedBox(width: thumbW, child: th('图')),
            Expanded(child: th('标题')),
            SizedBox(width: priceW, child: th('价格')),
            SizedBox(width: lvW, child: th('等级')),
            if (!compact) ...[
              SizedBox(width: jobW, child: th('职业')),
              SizedBox(width: areaW, child: th('区服')),
            ],
            SizedBox(width: attrW, child: th('主属性·攻')),
            SizedBox(width: opW, child: th('操作')),
          ],
        );
        // 大数据量虚拟化：明细行不再一次性全部铺进 Column，而是放进固定行高的
        // ListView（SliverFixedExtentList）按需惰性构建。行数超过可视高度上限时
        // 表体改为区内滚动，缩略图随之按需加载，避免上千行 widget + 上千个
        // Image.network 同时创建导致的卡顿；未超限时禁用内滚，保持「随页滚动」。
        // 行高取 84：64 缩略图 + 上下 9px 单元格内距，可容纳标题/区服两行文案。
        final rowExtent = 84.0;
        final maxTableH = math.min(
          560.0,
          MediaQuery.sizeOf(context).height * .75,
        );
        final overflow = rows.length * rowExtent > maxTableH;
        final bodyH = math.min(rows.length * rowExtent, maxTableH);
        // 整行可点击：点击行内任意位置直接进入该条详情。行内自带的交互
        // （缩略图预览大图、「详情」按钮）在命中区优先，互不冲突。
        Widget rowItem(int i) {
          final t = rows[i];
          return _TappableRow(
            onTap: () => onDetail(t),
            child: tr(
              last: i == rows.length - 1,
              cells: _rowCells(
                context,
                t,
                compact: compact,
                cell: cell,
                thumbW: thumbW,
                priceW: priceW,
                lvW: lvW,
                jobW: jobW,
                areaW: areaW,
                attrW: attrW,
                titleW: titleW,
                opW: opW,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(
                  height: bodyH,
                  child: ListView.builder(
                    key: const ValueKey('acc-detail-list'),
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    itemExtent: rowExtent,
                    // 表体未超出可视上限时禁用内滚，避免遮蔽外层整页滚动；
                    // 超出后启用惰性构建 + 区内滚动，且滚到顶/底时把越界位移
                    // 转交外层整页，使页面能继续滚动（见 ChainableScrollPhysics）。
                    physics: overflow
                        ? ChainableScrollPhysics(
                            outer:
                                Scrollable.maybeOf(
                                  context,
                                )?.position
                                    as ScrollPositionWithSingleContext?,
                          )
                        : const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) => rowItem(i),
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
    AccountListing t, {
    required bool compact,
    required Widget Function(Widget) cell,
    required double thumbW,
    required double priceW,
    required double lvW,
    required double jobW,
    required double areaW,
    required double attrW,
    required double titleW,
    required double opW,
  }) {
    final tg = context.tg;
    return [
      SizedBox(
        width: thumbW,
        child: cell(_Thumb(account: t)),
      ),
      Expanded(
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
        width: lvW,
        child: cell(
          Text(
            t.lv > 0 ? '${t.lv}' : '—',
            style: TextStyle(fontSize: 12, color: tg.t2),
          ),
        ),
      ),
      if (!compact) ...[
        SizedBox(
          width: jobW,
          child: cell(
            Text(
              t.job.isEmpty ? '—' : t.job,
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
      SizedBox(
        width: attrW,
        child: cell(
          Text(
            t.attr > 0
                ? '${amFmt(t.attr)}${t.atk.isNotEmpty ? ' · ${t.atkShort}' : ''}'
                : '—',
            style: TextStyle(fontSize: 12, color: tg.t2),
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

/// 明细行可点击外壳：整行点击进入详情；hover 显示点击光标 + 金色高亮底。
///
/// 行内子控件（缩略图预览、「详情」按钮）自身注册的点击在命中区优先，
/// 外层整行点击只负责其余空白区域的跳转。
class _TappableRow extends StatefulWidget {
  const _TappableRow({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TappableRow> createState() => _TappableRowState();
}

class _TappableRowState extends State<_TappableRow> {
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

/// 缩略图：方形裁切（42×42）；有图时可点击预览大图。
class _Thumb extends StatefulWidget {
  const _Thumb({required this.account});

  final AccountListing account;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final url = widget.account.img;
    final hasImg = url != null && url.isNotEmpty;
    final hot = _hover && hasImg; // 无可点图时不进入可点 hover 态
    Widget inner() {
      if (!hasImg) {
        return TgIcon('user', size: 28, color: hot ? tg.gold2 : tg.t3);
      }
      return Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        cacheWidth: 192, // 64×64 显示，解码上限到 @3x，避免原图全尺寸解码
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            TgIcon('user', size: 28, color: hot ? tg.gold2 : tg.t3),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : TgIcon('user', size: 28, color: tg.t3),
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
                      caption: widget.account.title,
                      errorIcon: 'user',
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

/// 计算调用方小图在全局坐标系中的矩形（供画廊 Hero 动画定位）。
Rect? _widgetRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
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
