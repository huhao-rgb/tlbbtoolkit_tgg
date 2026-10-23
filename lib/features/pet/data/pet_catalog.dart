/// pet 相关分片的解析与提供者。
///
/// 页面用 `ref.watch(xxxProvider).value ?? 常量` 取数：
/// 首帧立刻拿到内置常量，分片读好后自动重建，不出现 loading 空档。
library;

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';
import 'package:tlbbtoolkit/features/pet/domain/beast_soul.dart';
import 'package:tlbbtoolkit/features/pet/domain/beast_spirit.dart';
import 'package:tlbbtoolkit/features/pet/domain/pet_prob.dart';
import 'package:tlbbtoolkit/features/pet/domain/pet_suit.dart';

part 'pet_catalog.g.dart';

const String beastSpiritsKind = 'pet.beast_spirits';
const String beastSoulsKind = 'pet.beast_souls';
const String petSuitsKind = 'pet.suits';
const String petSkillsKind = 'pet.skills';

/// 兽灵图鉴：阶位结构 + 技能列表 + 首尾脚注。
typedef BeastSpiritCatalog = ({
  List<BeastTierStep> tierSteps,
  List<BeastSpirit> spirits,
  String introNote,
  String footNote,
});

/// 珍兽套装：系列 + 部位 + 材料消耗 + 档位键。
typedef PetSuitCatalog = ({
  List<PetSuitSeries> series,
  List<PetSuitSlot> slots,
  Map<String, SuitMatCost> matCost,
  String matName,
  List<String> lvKeys,
});

/// 宝宝技能概率：技能库 + 性格系数。
typedef PetSkillCatalog = ({List<PetSkill> skills, List<PetChar> chars});

/// 同步兜底值：widget 里用 `ref.watch(...).value ?? petSuitFallback`。
final PetSuitCatalog petSuitFallback = (
  series: kPetSuitSeries,
  slots: kPetSuitSlots,
  matCost: kSuitMatCost,
  matName: kSuitMatName,
  lvKeys: kSuitLvKeys,
);

Future<String?> _loadShard(Ref ref, String kind) async {
  final repository = await ref.watch(catalogRepositoryProvider.future);
  return repository.loadShard(kind);
}

@riverpod
Future<BeastSpiritCatalog> beastSpiritCatalog(Ref ref) async {
  final fallback = (
    tierSteps: kBeastTierSteps,
    spirits: kBeastSpirits,
    introNote: kBeastIndexIntroNote,
    footNote: kBeastIndexFootNote,
  );
  final raw = await _loadShard(ref, beastSpiritsKind);
  if (raw == null) return fallback;
  try {
    final parsed = _parseBeastSpirits(raw);
    return parsed.spirits.isEmpty ? fallback : parsed;
  } catch (e, s) {
    Logger.instance.error('Pet', '$beastSpiritsKind 解析失败，回退常量: $e', s);
    return fallback;
  }
}

@riverpod
Future<List<BeastSoul>> beastSoulCatalog(Ref ref) async {
  final raw = await _loadShard(ref, beastSoulsKind);
  if (raw == null) return kBeastSouls;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return kBeastSouls;
    final items = decoded['items'];
    if (items is! List) return kBeastSouls;
    final parsed = [for (final item in items) ?_beastSoulOf(item)];
    return parsed.isEmpty ? kBeastSouls : parsed;
  } catch (e, s) {
    Logger.instance.error('Pet', '$beastSoulsKind 解析失败，回退常量: $e', s);
    return kBeastSouls;
  }
}

@riverpod
Future<PetSuitCatalog> petSuitCatalog(Ref ref) async {
  final raw = await _loadShard(ref, petSuitsKind);
  if (raw == null) return petSuitFallback;
  try {
    final parsed = _parsePetSuits(raw);
    return parsed.series.isEmpty ? petSuitFallback : parsed;
  } catch (e, s) {
    Logger.instance.error('Pet', '$petSuitsKind 解析失败，回退常量: $e', s);
    return petSuitFallback;
  }
}

@riverpod
Future<PetSkillCatalog> petSkillCatalog(Ref ref) async {
  final fallback = (skills: kPetSkills, chars: kPetChars);
  final raw = await _loadShard(ref, petSkillsKind);
  if (raw == null) return fallback;
  try {
    final parsed = _parsePetSkills(raw);
    return parsed.skills.isEmpty ? fallback : parsed;
  } catch (e, s) {
    Logger.instance.error('Pet', '$petSkillsKind 解析失败，回退常量: $e', s);
    return fallback;
  }
}

// ---------------------------------------------------------------------------
// 解析
// ---------------------------------------------------------------------------

Map<String, dynamic> _items(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('分片顶层必须是对象');
  }
  final items = decoded['items'];
  if (items is! Map) throw const FormatException('items 必须是对象');
  return items.cast<String, dynamic>();
}

/// 枚举按 `.name` 还原；未知值走兜底，不让整条数据失效。
T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

BeastSpiritCatalog _parseBeastSpirits(String raw) {
  final items = _items(raw);

  final spirits = <BeastSpirit>[];
  for (final item in (items['spirits'] as List? ?? const [])) {
    final spirit = _beastSpiritOf(item);
    if (spirit != null) spirits.add(spirit);
  }

  return (
    tierSteps: [
      for (final item in (items['tierSteps'] as List? ?? const []))
        if (item is Map && item['name'] is String && item['lv'] is String)
          BeastTierStep(item['name'] as String, item['lv'] as String),
    ],
    spirits: spirits,
    introNote: items['introNote'] is String
        ? items['introNote'] as String
        : kBeastIndexIntroNote,
    footNote: items['footNote'] is String
        ? items['footNote'] as String
        : kBeastIndexFootNote,
  );
}

BeastSpirit? _beastSpiritOf(Object? json) {
  if (json is! Map) return null;
  final id = json['id'];
  final name = json['name'];
  final sub = json['sub'];
  if (id is! String || name is! String || sub is! String) return null;

  final tiers = [
    for (final item in (json['tiers'] as List? ?? const []))
      if (item is Map &&
          item['name'] is String &&
          item['lv'] is String &&
          item['dec'] is String)
        BeastSpiritTier(
          name: item['name'] as String,
          lv: item['lv'] as String,
          dec: item['dec'] as String,
          effect1: item['effect1'] is String ? item['effect1'] as String : '',
          effect2: item['effect2'] is String ? item['effect2'] as String : '',
        ),
  ];
  if (tiers.isEmpty) return null;

  return BeastSpirit(
    id: id,
    name: name,
    sub: sub,
    kind: _enumByName(
      BeastSpiritKind.values,
      json['kind'],
      BeastSpiritKind.passive,
    ),
    tiers: tiers,
  );
}

BeastSoul? _beastSoulOf(Object? json) {
  if (json is! Map) return null;
  final name = json['name'];
  final cs = json['cs'];
  final rh = json['rh'];
  if (name is! String || cs is! Map || rh is! Map) return null;
  if (cs['name'] is! String || cs['description'] is! String) return null;
  if (rh['name'] is! String) return null;

  return BeastSoul(
    name: name,
    type: _enumByName(BeastSoulType.values, json['type'], BeastSoulType.shen),
    cs: BeastSoulSkill(
      name: cs['name'] as String,
      description: cs['description'] as String,
      iconPath: cs['iconPath'] is String ? cs['iconPath'] as String : null,
    ),
    rh: BeastSoulRh(
      name: rh['name'] as String,
      iconPath: rh['iconPath'] is String ? rh['iconPath'] as String : null,
      tiers: [
        for (final tier in (rh['tiers'] as List? ?? const []))
          if (tier is Map && tier['lv'] is int)
            BeastSoulRhTier(
              lv: tier['lv'] as int,
              description: tier['description'] is String
                  ? tier['description'] as String
                  : null,
            ),
      ],
    ),
  );
}

PetSuitCatalog _parsePetSuits(String raw) {
  final items = _items(raw);

  final series = [
    for (final item in (items['series'] as List? ?? const []))
      if (item is Map &&
          item['name'] is String &&
          item['lv'] is String &&
          item['type'] is String &&
          item['icon'] is String &&
          item['personality'] is String &&
          item['fullEffect'] is String)
        PetSuitSeries(
          name: item['name'] as String,
          lv: item['lv'] as String,
          type: item['type'] as String,
          typeColor: _enumByName(
            PetSuitCatColor.values,
            item['typeColor'],
            PetSuitCatColor.gold,
          ),
          icon: item['icon'] as String,
          personality: item['personality'] as String,
          fullEffect: item['fullEffect'] as String,
          stats: _strings(item['stats']),
          collar: item['collar'] is String ? item['collar'] as String : null,
        ),
  ];

  final slots = [
    for (final item in (items['slots'] as List? ?? const []))
      if (item is Map &&
          item['name'] is String &&
          item['slot'] is String &&
          item['icon'] is String &&
          item['note'] is String)
        PetSuitSlot(
          name: item['name'] as String,
          slot: item['slot'] as String,
          icon: item['icon'] as String,
          note: item['note'] as String,
        ),
  ];

  final matCost = <String, SuitMatCost>{};
  final rawCost = items['matCost'];
  if (rawCost is Map) {
    for (final entry in rawCost.entries) {
      final value = entry.value;
      if (entry.key is! String || value is! Map) continue;
      final exchange = value['exchange'];
      if (exchange is! int) continue;
      matCost[entry.key as String] = SuitMatCost(
        exchange: exchange,
        starUp: _ints(value['starUp']),
        salvage: _ints(value['salvage']),
      );
    }
  }

  return (
    series: series,
    slots: slots.isEmpty ? kPetSuitSlots : slots,
    matCost: matCost.isEmpty ? kSuitMatCost : matCost,
    matName: items['matName'] is String
        ? items['matName'] as String
        : kSuitMatName,
    lvKeys: _strings(items['lvKeys']).isEmpty
        ? kSuitLvKeys
        : _strings(items['lvKeys']),
  );
}

PetSkillCatalog _parsePetSkills(String raw) {
  final items = _items(raw);

  final skills = [
    for (final item in (items['skills'] as List? ?? const []))
      if (item is Map &&
          item['name'] is String &&
          item['desc'] is String &&
          item['tag'] is String &&
          item['base'] is int &&
          item['judge'] is String &&
          item['icon'] is String &&
          item['fx'] is String)
        PetSkill(
          name: item['name'] as String,
          desc: item['desc'] as String,
          cat: _enumByName(PetSkillCat.values, item['cat'], PetSkillCat.atk),
          tag: item['tag'] as String,
          tagColor: _enumByName(
            PetTagColor.values,
            item['tagColor'],
            PetTagColor.gold,
          ),
          base: item['base'] as int,
          judge: item['judge'] as String,
          icon: item['icon'] as String,
          fx: item['fx'] as String,
        ),
  ];

  final chars = [
    for (final item in (items['chars'] as List? ?? const []))
      if (item is Map &&
          item['key'] is String &&
          item['name'] is String &&
          item['atk'] is num &&
          item['st'] is num &&
          item['sup'] is num)
        PetChar(
          key: item['key'] as String,
          name: item['name'] as String,
          atk: (item['atk'] as num).toDouble(),
          st: (item['st'] as num).toDouble(),
          sup: (item['sup'] as num).toDouble(),
        ),
  ];

  return (skills: skills, chars: chars.isEmpty ? kPetChars : chars);
}

List<String> _strings(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is String) item,
];

List<int> _ints(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is int) item,
];
