/// 账号行情 —— 统计 / 分布 / 排行计算层（对应原型 JS 逻辑的 Dart 翻译）。
///
/// 全部为纯函数：输入 `List<AccountListing>` + 筛选状态，输出展示用统计模型，
/// 便于 widget 页直接渲染与单元测试。不依赖 Flutter UI。
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'account_market.dart';
import 'pet_market_stats.dart' show pmMedian, pmThousands;

/// 金额格式化（原型 `amFmt`）：≥10000 → `x.x 万`（去尾 .0），否则千分位四舍五入整数。
String amFmt(num n) {
  if (n >= 10000) {
    var s = (n / 10000).toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return '$s 万';
  }
  return pmThousands(n.round());
}

/// 金额 fmt + 前缀 ￥。
String amP(num n) => '￥${amFmt(n)}';

/// 千分位（浏览量等）。
String amThousands(int n) => pmThousands(n);

/// 大区候选（原型 `amAreas`：按大区内服务器数降序，服务器名排序）。
@immutable
class AmAreaOption {
  const AmAreaOption({required this.name, required this.servers});

  final String name;
  final List<String> servers;
}

/// 从数据推导大区候选（原型 `amAreas`）。
List<AmAreaOption> amAreas(List<AccountListing> data) {
  final m = <String, Set<String>>{};
  for (final x in data) {
    if (x.area.isEmpty) continue;
    (m[x.area] ??= <String>{}).add(x.server.isEmpty ? '' : x.server);
  }
  final opts = <AmAreaOption>[];
  for (final e in m.entries) {
    final servers = e.value.where((s) => s.isNotEmpty).toList()..sort();
    opts.add(AmAreaOption(name: e.key, servers: servers));
  }
  opts.sort((a, b) => b.servers.length.compareTo(a.servers.length));
  return opts;
}

/// 某大区（或全部）下的服务器名列表（原型 `amFillServers`）。
List<String> amServersOf(List<AmAreaOption> areas, String area) {
  if (area.isNotEmpty) {
    for (final o in areas) {
      if (o.name == area) return o.servers;
    }
    return const [];
  }
  final all = <String>{};
  for (final o in areas) {
    all.addAll(o.servers);
  }
  final out = all.toList()..sort();
  return out;
}

/// 按筛选状态过滤（原型 `amFilterData`）。
///
/// 等级段为 `min-max`：min 闭区间、max 开区间（如 '60-70' → 60 ≤ lv < 70）。
List<AccountListing> amFiltered(
  List<AccountListing> data,
  AccountMarketFilter f,
) {
  int? lo;
  int? hi;
  if (f.band != AccountLevelBand.all && f.band.limit != null) {
    final parts = f.band.limit!.split('-');
    lo = int.tryParse(parts[0]);
    hi = int.tryParse(parts[1]);
  }
  return data
      .where((x) {
        if (f.area.isNotEmpty && x.area != f.area) return false;
        if (f.server.isNotEmpty && x.server != f.server) return false;
        if (lo != null && x.lv < lo) return false;
        if (hi != null && x.lv >= hi) return false;
        return true;
      })
      .toList(growable: false);
}

/// 顶部统计卡（原型 `amStats`）。
@immutable
class AmStatCards {
  const AmStatCards({
    required this.count,
    required this.loPrice,
    required this.hiPrice,
    required this.median,
    required this.mean,
  });

  final int count;
  final int? loPrice;
  final int? hiPrice;
  final double median;
  final double mean;

  bool get empty => count == 0;

  String get rangeText {
    final lo = loPrice;
    if (lo == null) return '—';
    return '${amFmt(lo)} ~ ${amFmt(hiPrice!)}';
  }
  String get medianText => empty ? '—' : '￥${amFmt(median)}';
  String get meanText => empty ? '—' : '￥${amFmt(mean)}';
}

AmStatCards amComputeStats(List<AccountListing> d) {
  if (d.isEmpty) {
    return const AmStatCards(
      count: 0,
      loPrice: null,
      hiPrice: null,
      median: 0,
      mean: 0,
    );
  }
  final ps = d.map((x) => x.price).toList()..sort((a, b) => a - b);
  final sum = ps.reduce((a, b) => a + b);
  return AmStatCards(
    count: d.length,
    loPrice: ps.first,
    hiPrice: ps.last,
    median: pmMedian(ps),
    mean: sum / d.length,
  );
}

/// 价位分布段（原型 `amDist` 的 5 段）。
@immutable
class AmDistSeg {
  const AmDistSeg({
    required this.label,
    required this.lo,
    required this.hi,
    required this.list,
    required this.maxCount,
  });

  final String label;
  final int lo;
  final int hi;
  final List<AccountListing> list;
  final int maxCount; // 全局最大段数量（用于 bar 归一）

  int get count => list.length;
  double get bar => maxCount == 0 ? 0 : count / maxCount;

  /// 段内均价（原型 avg=round(mean price)）。
  int get avg => list.isEmpty
      ? 0
      : (list.map((x) => x.price).reduce((a, b) => a + b) / list.length).round();

  /// 段内均主属性（仅统计有主属性的样本，round；无则 0）。
  int get avgAttr {
    if (list.isEmpty) return 0;
    final at = list.where((x) => x.attr > 0).toList(growable: false);
    if (at.isEmpty) return 0;
    return (at.map((x) => x.attr).reduce((a, b) => a + b) / at.length).round();
  }
}

List<AmDistSeg> amDistSegs(List<AccountListing> d) {
  const segs = <(String, int, int)>[
    ('入门 · <1000 元', 0, 1000),
    ('进阶 · 1000-5000 元', 1000, 5000),
    ('主流 · 5000-1 万元', 5000, 10000),
    ('高端 · 1-5 万元', 10000, 50000),
    ('顶级 · ≥5 万元', 50000, 1000000000),
  ];
  final groups = <List<AccountListing>>[
    for (final (_, lo, hi) in segs)
      d.where((x) => x.price >= lo && x.price < hi).toList(growable: false),
  ];
  var maxN = 0;
  for (final g in groups) {
    maxN = math.max(maxN, g.length);
  }
  return [
    for (var i = 0; i < segs.length; i++)
      AmDistSeg(
        label: segs[i].$1,
        lo: segs[i].$2,
        hi: segs[i].$3,
        list: groups[i],
        maxCount: maxN,
      ),
  ];
}

/// 价位段画像行（原型 `amSeg` table 一行）。
@immutable
class AmSegProfile {
  const AmSegProfile({
    required this.label,
    required this.list,
    required this.avg,
    required this.avgAttr,
    required this.lvTop,
    required this.features,
  });

  final String label;
  final List<AccountListing> list;
  final int avg;
  final int? avgAttr;
  final String lvTop; // `—` 或 `90 级`
  final List<String> features; // 空 = 高频特征 —

  int get count => list.length;
}

List<AmSegProfile> amSegProfiles(List<AmDistSeg> segs) {
  final out = <AmSegProfile>[];
  for (final r in segs) {
    final g = r.list;
    final avg = g.isEmpty
        ? 0
        : (g.map((x) => x.price).reduce((a, b) => a + b) / g.length).round();
    final at = g.where((x) => x.attr > 0).toList(growable: false);
    final avgAttr = at.isEmpty
        ? null
        : (at.map((x) => x.attr).reduce((a, b) => a + b) / at.length).round();
    // 主流等级：段内中位等级（原型 lvs[mid]）。
    final lvs = g.map((x) => x.lv).where((v) => v > 0).toList()..sort((a, b) => a - b);
    final lvTop = lvs.isEmpty ? '—' : '${lvs[lvs.length >> 1]} 级';
    final ft = <String>[];
    if (g.isNotEmpty) {
      final ak = <String, int>{};
      for (final x in g) {
        if (x.atk.isNotEmpty) ak[x.atk] = (ak[x.atk] ?? 0) + 1;
      }
      final ta = ak.entries.toList()..sort((a, b) => b.value - a.value);
      if (ta.isNotEmpty && ta.first.value / g.length >= .3) {
        ft.add('${ta.first.key}为主 ${ta.first.value}');
      }
      final jb = <String, int>{};
      for (final x in g) {
        if (x.job.isNotEmpty) jb[x.job] = (jb[x.job] ?? 0) + 1;
      }
      final tj = jb.entries.toList()..sort((a, b) => b.value - a.value);
      if (tj.isNotEmpty) ft.add('${tj.first.key} ${tj.first.value}');
      final fem = g.where((x) => x.sex == '女').length;
      if (fem / g.length >= .3) ft.add('女号 $fem');
    }
    out.add(
      AmSegProfile(
        label: r.label,
        list: g,
        avg: avg,
        avgAttr: avgAttr,
        lvTop: lvTop,
        features: ft,
      ),
    );
  }
  return out;
}

/// 区服在售分布项（原型 `amSect` 一行）。
@immutable
class AmSectRow {
  const AmSectRow({
    required this.area,
    required this.count,
    required this.median,
  });

  final String area;
  final int count;
  final double median;
}

List<AmSectRow> amSectRows(List<AccountListing> d) {
  final sg = <String, List<int>>{};
  for (final x in d) {
    if (x.area.isNotEmpty) (sg[x.area] ??= <int>[]).add(x.price);
  }
  final sr = sg.entries
      .map(
        (e) => AmSectRow(area: e.key, count: e.value.length, median: pmMedian(e.value)),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return sr;
}

/// 性价比推荐项（原型 `amBest`：主属性≥4000，ix=attr/(p/10000)，top8）。
@immutable
class AmBestItem {
  const AmBestItem({required this.account, required this.ix});

  final AccountListing account;
  final double ix;

  String get ixText => ix.round().toString();
}

List<AmBestItem> amBestItems(List<AccountListing> d) {
  final best = d
      .where((x) => x.attr >= 4000 && x.price > 0)
      .map((x) => AmBestItem(account: x, ix: x.attr / (x.price / 10000)))
      .toList()
    ..sort((a, b) => b.ix.compareTo(a.ix));
  return best.take(8).toList(growable: false);
}

/// 明细：筛选 + 按价格升序（原型 `renderAmTable`）。
List<AccountListing> amDetailRows(
  List<AccountListing> data,
  AccountMarketFilter filter,
) {
  final rows = amFiltered(data, filter).toList()..sort((a, b) => a.price - b.price);
  return rows;
}
