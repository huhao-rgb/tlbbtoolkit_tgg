/// 珍兽行情 —— 统计 / 分布 / 排行计算层（对应原型 JS 逻辑的 Dart 翻译）。
///
/// 全部为纯函数：输入 `List<PetListing>` + 筛选状态，输出展示用统计模型，
/// 便于 widget 页直接渲染与单元测试。不依赖 Flutter UI。
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'pet_market.dart';

/// 千分位整数（如 1,234）。
String pmThousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

/// 金额格式化（原型 `fmt`）：≥10000 → `x.x 万`，否则千分位四舍五入整数。
String pmFmt(num n) {
  if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)} 万';
  return pmThousands(n.round());
}

/// 中位数（原型 `pmMed`）。
double pmMedian(List<int> a) {
  if (a.isEmpty) return 0;
  final s = [...a]..sort((x, y) => x - y);
  final m = s.length >> 1;
  return s.length.isOdd ? s[m].toDouble() : (s[m - 1] + s[m]) / 2;
}

/// 按筛选状态过滤（原型 `pmFiltered`，不含关键字）。
List<PetListing> pmFiltered(List<PetListing> data, PetMarketFilter f) {
  return data
      .where((x) {
        if (f.area.isNotEmpty && x.area != f.area) return false;
        if (f.server.isNotEmpty && x.server != f.server) return false;
        if (f.carryBand != PetCarryBand.all && x.band != f.carryBand) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

/// 大区列表（数据中有值的大区，去重保序）。
List<String> pmAreas(List<PetListing> data) =>
    data.map((x) => x.area).where((a) => a.isNotEmpty).toSet().toList();

/// 某大区（或全部）下的服务器列表，去重保序。
List<String> pmServers(List<PetListing> data, String area) {
  final pool = area.isEmpty
      ? data
      : data.where((x) => x.area == area).toList(growable: false);
  return pool.map((x) => x.server).where((s) => s.isNotEmpty).toSet().toList();
}

/// 顶部统计卡（原型 `pmStats`）。
@immutable
class PmStatCards {
  const PmStatCards({
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

  String get rangeText =>
      loPrice == null ? '—' : '$loPrice ~ ${pmFmt(hiPrice!)}';
  String get medianText => empty ? '—' : '￥${pmFmt(median)}';
  String get meanText => empty ? '—' : '￥${pmFmt(mean)}';
}

PmStatCards pmComputeStats(List<PetListing> d) {
  if (d.isEmpty) {
    return const PmStatCards(
      count: 0,
      loPrice: null,
      hiPrice: null,
      median: 0,
      mean: 0,
    );
  }
  final ps = d.map((x) => x.price).toList()..sort((a, b) => a - b);
  final sum = ps.reduce((a, b) => a + b);
  return PmStatCards(
    count: d.length,
    loPrice: ps.first,
    hiPrice: ps.last,
    median: pmMedian(ps),
    mean: sum / d.length,
  );
}

/// 价位分布段（原型 `pmDist` 的 5 段）。
@immutable
class PmDistSeg {
  const PmDistSeg({
    required this.label,
    required this.lo,
    required this.hi,
    required this.list,
    required this.maxCount,
  });

  final String label;
  final int lo;
  final int hi;
  final List<PetListing> list;
  final int maxCount; // 全局最大段数量（用于 bar 归一）

  int get count => list.length;
  double get pct => list.isEmpty ? 0 : count / maxCount;

  /// 段内均价（原型 avg=round(mean price)）。
  int get avg => list.isEmpty
      ? 0
      : (list.map((x) => x.price).reduce((a, b) => a + b) / list.length)
            .round();

  /// 段内均资质（仅统计有资质的样本，round；无则 0）。
  int get avgApt {
    if (list.isEmpty) return 0;
    final ap = list.where((x) => x.apt != null).toList(growable: false);
    if (ap.isEmpty) return 0;
    return (ap.map((x) => x.apt!).reduce((a, b) => a + b) / ap.length).round();
  }
}

List<PmDistSeg> pmDistSegs(List<PetListing> d) {
  const segs = <(String, int, int)>[
    ('入门 · <300 元', 0, 300),
    ('进阶 · 300-800 元', 300, 800),
    ('主流 · 800-2000 元', 800, 2000),
    ('高端 · 2000-5000 元', 2000, 5000),
    ('顶级 · ≥5000 元', 5000, 1000000000),
  ];
  final groups = <List<PetListing>>[
    for (final (_, lo, hi) in segs)
      d.where((x) => x.price >= lo && x.price < hi).toList(growable: false),
  ];
  var maxN = 0;
  for (final g in groups) {
    maxN = math.max(maxN, g.length);
  }
  return [
    for (var i = 0; i < segs.length; i++)
      PmDistSeg(
        label: segs[i].$1,
        lo: segs[i].$2,
        hi: segs[i].$3,
        list: groups[i],
        maxCount: maxN,
      ),
  ];
}

/// 价位段画像行（原型 `pmSeg` table 一行）。
@immutable
class PmSegProfile {
  const PmSegProfile({
    required this.label,
    required this.list,
    required this.avg,
    required this.avgApt,
    required this.lvTop,
    required this.features,
  });

  final String label;
  final List<PetListing> list;
  final int avg;
  final int? avgApt;
  final String lvTop; // `—` 或 `90 级`
  final List<String> features; // 空 = 高频特征 —

  int get count => list.length;
}

List<PmSegProfile> pmSegProfiles(List<PmDistSeg> segs) {
  final out = <PmSegProfile>[];
  for (final r in segs) {
    final g = r.list;
    final avg = g.isEmpty
        ? 0
        : (g.map((x) => x.price).reduce((a, b) => a + b) / g.length).round();
    final ap = g.where((x) => x.apt != null).toList(growable: false);
    final avgApt = ap.isEmpty
        ? null
        : (ap.map((x) => x.apt!).reduce((a, b) => a + b) / ap.length).round();
    // 主流携带级：该价位段内出现次数最多的档位标签（真实/快照均归档到档位）。
    final bandCnt = <PetCarryBand, int>{};
    for (final x in g) {
      final b = x.band;
      bandCnt[b] = (bandCnt[b] ?? 0) + 1;
    }
    var lvTop = '—';
    if (bandCnt.isNotEmpty) {
      final top = bandCnt.entries.reduce((a, b) => b.value > a.value ? b : a);
      lvTop = top.key.label;
    }
    final ft = <String>[];
    if (g.isNotEmpty) {
      final dd = g.where((x) => x.ding).length;
      final ssn = g.where((x) => x.ss).length;
      if (dd / g.length >= .3) ft.add('顶变 $dd');
      if (ssn / g.length >= .3) ft.add('双十 $ssn');
      final chs = <String, int>{};
      for (final x in g) {
        if (x.ch != null) chs[x.ch!] = (chs[x.ch!] ?? 0) + 1;
      }
      final tc = chs.entries.toList()..sort((a, b) => b.value - a.value);
      if (tc.isNotEmpty && tc.first.value >= 2) ft.add('${tc.first.key}为主');
      final ps2 = <String, int>{};
      for (final x in g) {
        if (x.pet != '其他') ps2[x.pet] = (ps2[x.pet] ?? 0) + 1;
      }
      final pc = ps2.entries.toList()..sort((a, b) => b.value - a.value);
      if (pc.isNotEmpty) ft.add('${pc.first.key} ${pc.first.value}');
    }
    out.add(
      PmSegProfile(
        label: r.label,
        list: g,
        avg: avg,
        avgApt: avgApt,
        lvTop: lvTop,
        features: ft,
      ),
    );
  }
  return out;
}

/// 性价比推荐项（原型 `pmBest`：资质≥3800，ix=apt/(p/1000)，top8）。
@immutable
class PmBestItem {
  const PmBestItem({required this.listing, required this.ix});

  final PetListing listing;
  final double ix;

  String get ixText => ix.round().toString();
}

List<PmBestItem> pmBestItems(List<PetListing> d) {
  final best =
      d
          .where((x) => (x.apt ?? 0) >= 3800 && x.price > 0)
          .map((x) => PmBestItem(listing: x, ix: x.apt! / (x.price / 1000)))
          .toList()
        ..sort((a, b) => b.ix.compareTo(a.ix));
  return best.take(8).toList(growable: false);
}

/// 明细过滤 + 排序（原型 `renderPmTable`：kw 匹配 标题/品种/性格/服务器/大区）。
List<PetListing> pmDetailRows(
  List<PetListing> data,
  PetMarketFilter filter,
  String kw,
) {
  var rows = pmFiltered(data, filter);
  if (kw.isNotEmpty) {
    final k = kw.toLowerCase();
    rows = rows
        .where((x) {
          final hay = '${x.title} ${x.pet} ${x.ch ?? ''} ${x.server} ${x.area}'
              .toLowerCase();
          return hay.contains(k);
        })
        .toList(growable: false);
  }
  rows = rows.toList()..sort((a, b) => a.price - b.price);
  return rows;
}
