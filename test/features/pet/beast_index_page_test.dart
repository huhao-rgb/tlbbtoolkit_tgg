import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/beast_index_page.dart';

/// 以完整主题（含 TgColors extension）泵入兽灵图鉴页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 2000),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: BeastIndexPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// 富文本（`Text.rich`）内容匹配。
Finder richContaining(String text) =>
    find.textContaining(text, findRichText: true);

/// 只匹配 `Text`（排除搜索框里的 `EditableText`，避免搜「冰精」时命中输入框）。
Finder textOnly(String text) =>
    find.byWidgetPredicate((w) => w is Text && w.data == text);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

const _sevenChips = [
  '一阶 · 1-3 级',
  '二阶 · 4-6 级',
  '三阶 · 7-9 级',
  '四阶 · 10-12 级',
  '五阶 · 13-15 级',
  '六阶 · 16-19 级',
  '七阶 · 20 级',
];

/// 图鉴内 68 只兽灵（被动 39 + 手动 29，全部完整数据，顺序 = 手风琴顺序）。
const _allNames = [
  '破御',
  '破胆',
  '冰精',
  '火灵',
  '毒蛊',
  '玄兽',
  '迟钝',
  '狡猾',
  '憨厚',
  '拼命',
  '痛击',
  '连击',
  '灵动',
  '法魂',
  '蛮力',
  '借力',
  '移魂',
  '瞬影',
  '强身',
  '凝神',
  '寒冰咒',
  '烈火咒',
  '血毒咒',
  '玄雷咒',
  '反击',
  '反震',
  '吸气',
  '打怒',
  '忠心',
  '灵气',
  '猛击',
  '识破',
  '虚弱',
  '破绽',
  '摔绊',
  '冰魂',
  '火魂',
  '毒魂',
  '玄魂',
  // 手动技能（29）
  '灵狐之息',
  '同护',
  '极冰凝杀',
  '劫火焚杀',
  '腐毒蚀杀',
  '玄雷击杀',
  '血爆',
  '冰爆',
  '净化',
  '重生',
  '共生',
  '治疗',
  '肉墙',
  '神佑',
  '嗜血',
  '血祭',
  '伪装',
  '附身',
  '解穴',
  '清醒',
  '明目',
  '轻灵',
  '固元',
  '洒脱',
  '冰天雪地',
  '烈火燎原',
  '血毒万里',
  '五雷轰顶',
  '咆哮',
];

void main() {
  testWidgets('默认渲染：页头 + 阶位结构 + 68 只兽灵手风琴（首项展开）', (tester) async {
    await pumpPage(tester);

    // 页头（副标题已随 v1.13.0 更新）
    expect(find.text('兽灵图鉴'), findsOneWidget);
    expect(
      find.text('珍兽觉醒缔约 · 兽灵附体强化存活与输出 · 依据官方公告与玩家实测整理（2025-03 上线）'),
      findsOneWidget,
    );

    // 阶位结构 · 20 级 7 阶
    expect(find.text('阶位结构 · 20 级 7 阶'), findsOneWidget);
    for (final label in [
      '一阶\n1-3 级',
      '二阶\n4-6 级',
      '三阶\n7-9 级',
      '四阶\n10-12 级',
      '五阶\n13-15 级',
      '六阶\n16-19 级',
      '七阶\n20 级',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    // 兽灵技能图鉴：68 只兽灵，全部为「完整数据」（待补已归零）
    expect(find.text('兽灵技能图鉴'), findsOneWidget);
    expect(find.text('点击展开 · 同时仅一项'), findsOneWidget);
    for (final name in _allNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('完整数据'), findsNWidgets(68));
    expect(find.text('待补'), findsNothing);

    // 类型筛选 chips（对应小程序两个页签）
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('被动技能'), findsOneWidget);
    expect(find.text('手动技能'), findsOneWidget);

    // 首项（破御）默认展开：chips + 一阶内容
    expect(find.text('一阶 · 1-3 级'), findsOneWidget);
    expect(richContaining('一阶（兽灵 1-3 级）'), findsOneWidget);
    // 其余 67 项仍收起
    expect(richContaining('珍兽对拥有破胆效果的目标'), findsNothing);
    expect(richContaining('受到冰攻伤害再次减少'), findsNothing);
    expect(richContaining('受到火攻伤害再次减少'), findsNothing);
    expect(richContaining('无视对方 4% 内防'), findsNothing);

    // 顶部 / 底部说明
    expect(richContaining('兽灵以珍兽技能为单位划分'), findsOneWidget);
    expect(find.textContaining('共 68 只兽灵（被动 39 · 手动 29）'), findsOneWidget);
  });

  testWidgets('首项默认展开：7 阶 chips + 阶位说明 + 两个效果位', (tester) async {
    await pumpPage(tester);

    for (final label in _sevenChips) {
      expect(find.text(label), findsOneWidget);
    }

    // 默认一阶：阶位说明 + 两个效果位（4 / 10 级解锁）
    expect(richContaining('一阶（兽灵 1-3 级）'), findsOneWidget);
    expect(richContaining('额外降低目标 2% 的会心防御'), findsOneWidget);
    expect(richContaining('兽灵效果一 · 4 级解锁'), findsOneWidget);
    expect(richContaining('兽灵效果二 · 10 级解锁'), findsOneWidget);
  });

  testWidgets('冰精兽灵：展开后一阶 / 七阶数值正确渲染', (tester) async {
    await pumpPage(tester);
    await tapText(tester, '冰精');

    // 一阶：减伤 / 增伤 2%，两个效果位未解锁
    expect(richContaining('一阶（兽灵 1-3 级）'), findsOneWidget);
    expect(richContaining('受到冰攻伤害再次减少 2%'), findsOneWidget);
    expect(richContaining('兽灵效果一 · 4 级解锁'), findsOneWidget);

    // 七阶：冰冻 24% / 爆炸 8% / 150% 伤害
    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('七阶（兽灵 20 级）'), findsOneWidget);
    expect(richContaining('有 24% 概率冰冻目标 0.5 秒'), findsOneWidget);
    expect(richContaining('有 8% 概率额外受到一次爆炸伤害'), findsOneWidget);
    expect(richContaining('普通攻击的 150% 伤害'), findsOneWidget);
  });

  testWidgets('毒蛊兽灵：剧毒陷阱与玄罡文案正确渲染', (tester) async {
    await pumpPage(tester);
    await tapText(tester, '毒蛊');
    await tapText(tester, '七阶 · 20 级');

    expect(richContaining('七阶（兽灵 20 级）'), findsOneWidget);
    expect(richContaining('受到毒攻伤害再次减少 15%'), findsOneWidget);
    expect(
      richContaining('有 15% 概率在目标脚底产生一个半径 3 米持续 6 秒的剧毒陷阱'),
      findsOneWidget,
    );
    expect(richContaining('获得玄罡效果'), findsOneWidget);
  });

  testWidgets('切换阶位 chips 更新说明与效果位', (tester) async {
    await pumpPage(tester);

    await tapText(tester, '四阶 · 10-12 级');
    expect(richContaining('四阶（兽灵 10-12 级）'), findsOneWidget);
    expect(richContaining('额外降低目标 16% 的会心防御'), findsOneWidget);
    expect(richContaining('主人会心攻击和会心防御 +15%'), findsOneWidget);
    expect(richContaining('免疫 1 次'), findsOneWidget);
    // 一阶内容已被替换
    expect(richContaining('额外降低目标 2% 的会心防御'), findsNothing);

    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('七阶（兽灵 20 级）'), findsOneWidget);
    expect(richContaining('免疫 5 次'), findsOneWidget);
  });

  testWidgets('手风琴同时仅一项展开，收起后阶位选择保留', (tester) async {
    await pumpPage(tester);

    // 首项默认展开，点击自身可收起
    await tapText(tester, '破御');
    expect(find.text('一阶 · 1-3 级'), findsNothing);

    // 重新展开并切到五阶
    await tapText(tester, '破御');
    expect(find.text('一阶 · 1-3 级'), findsOneWidget);
    await tapText(tester, '五阶 · 13-15 级');

    // 展开破胆 → 破御收起（chips 只剩破胆一组）
    await tapText(tester, '破胆');
    expect(richContaining('珍兽对拥有破胆效果的目标'), findsOneWidget);
    expect(find.text('一阶 · 1-3 级'), findsOneWidget);

    // 再次点击破胆 → 全部收起
    await tapText(tester, '破胆');
    expect(find.text('一阶 · 1-3 级'), findsNothing);
    expect(richContaining('珍兽对拥有破胆效果的目标'), findsNothing);

    // 重新展开破御 → 仍停留在五阶（原型 DOM 状态不重置）
    await tapText(tester, '破御');
    expect(richContaining('五阶（兽灵 13-15 级）'), findsOneWidget);
  });

  testWidgets('类型筛选：被动技能保留全部，手动技能显示空态', (tester) async {
    await pumpPage(tester);

    // 默认「全部」：68 项
    expect(find.text('破御'), findsOneWidget);
    expect(find.text('玄魂'), findsOneWidget);
    expect(find.text('灵狐之息'), findsOneWidget);
    expect(find.text('咆哮'), findsOneWidget);

    // 「被动技能」：39 项
    await tapText(tester, '被动技能');
    expect(find.text('破御'), findsOneWidget);
    expect(find.text('玄魂'), findsOneWidget);
    expect(find.text('灵狐之息'), findsNothing);
    expect(find.text('完整数据'), findsNWidgets(39));

    // 「手动技能」：29 项（首项灵狐之息默认展开）
    await tapText(tester, '手动技能');
    expect(find.text('破御'), findsNothing);
    expect(find.text('玄魂'), findsNothing);
    expect(find.text('灵狐之息'), findsOneWidget);
    expect(find.text('咆哮'), findsOneWidget);
    expect(find.text('完整数据'), findsNWidgets(29));
    expect(richContaining('珍兽造成的伤害增加 1%'), findsOneWidget);

    // 切回「全部」：恢复 68 项，并默认展开首项
    await tapText(tester, '全部');
    expect(find.text('破御'), findsOneWidget);
    expect(find.text('咆哮'), findsOneWidget);
    expect(richContaining('一阶（兽灵 1-3 级）'), findsOneWidget);
  });

  testWidgets('手动技能：灵狐之息 / 冰天雪地 展开后数值正确渲染', (tester) async {
    await pumpPage(tester);

    // 灵狐之息：七阶增伤 10%，普攻延长 4 秒
    await tapText(tester, '灵狐之息');
    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('珍兽造成的伤害增加 10%'), findsOneWidget);
    expect(richContaining('使状态增加 4 秒，最多增加 20 秒'), findsOneWidget);

    // 冰天雪地：七阶 60 点减冰抗 + 80% 主人减冰抗
    await tapText(tester, '冰天雪地');
    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('获得 60 点减冰抗'), findsOneWidget);
    expect(richContaining('能获得主人 80% 的减冰抗'), findsOneWidget);
  });

  testWidgets('本批新增技能：吸气 / 忠心 / 猛击 展开后数值正确渲染', (tester) async {
    await pumpPage(tester);

    // 吸气：吸蓝 200 → 1500，七阶气上限 4%
    await tapText(tester, '吸气');
    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('每次额外打掉目标 1500 点的气'), findsOneWidget);
    expect(richContaining('自身气上限 4% 的气量'), findsOneWidget);

    // 忠心：四阶「6% 概率由珍兽承担」
    await tapText(tester, '忠心');
    await tapText(tester, '四阶 · 10-12 级');
    expect(richContaining('有 6% 概率由珍兽承担'), findsOneWidget);

    // 猛击：无视外防 45%，内功 100% 转化外功
    await tapText(tester, '猛击');
    await tapText(tester, '七阶 · 20 级');
    expect(richContaining('无视对方 45% 外防'), findsOneWidget);
    expect(richContaining('内功攻击 100% 转化为外功攻击'), findsOneWidget);
  });

  testWidgets('搜索：按技能名 / 效果关键词过滤，可清空', (tester) async {
    await pumpPage(tester);

    // 按技能名搜：只剩冰精，且命中项默认展开
    await tester.enterText(find.byType(TextField), '冰精');
    await tester.pumpAndSettle();
    expect(textOnly('冰精'), findsOneWidget);
    expect(textOnly('破御'), findsNothing);
    expect(textOnly('玄魂'), findsNothing);
    expect(richContaining('受到冰攻伤害再次减少 2%'), findsOneWidget);

    // 按效果关键词搜：剧毒陷阱 → 毒蛊 + 玄兽
    await tester.enterText(find.byType(TextField), '剧毒陷阱');
    await tester.pumpAndSettle();
    expect(textOnly('毒蛊'), findsOneWidget);
    expect(textOnly('玄兽'), findsOneWidget);
    expect(textOnly('冰精'), findsNothing);
    expect(find.text('完整数据'), findsNWidgets(2));

    // 搜不到 → 空态提示
    await tester.enterText(find.byType(TextField), 'zzz不存在');
    await tester.pumpAndSettle();
    expect(find.textContaining('没有匹配'), findsOneWidget);
    expect(textOnly('毒蛊'), findsNothing);

    // 清空 → 恢复 68 项
    await tapText(tester, '清空');
    expect(textOnly('破御'), findsOneWidget);
    expect(textOnly('玄魂'), findsOneWidget);
    expect(find.text('完整数据'), findsNWidgets(68));
  });

  testWidgets('页脚展示', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('天工阁 · 玩家自制工具集合，与畅游官方无关'));
    await tester.pumpAndSettle();
    expect(find.text('天工阁 · 玩家自制工具集合，与畅游官方无关'), findsOneWidget);
  });

  testWidgets('移动端窄屏不溢出', (tester) async {
    // 首项默认展开
    await pumpPage(tester, size: const Size(390, 2000));
    expect(tester.takeException(), isNull);

    await tapText(tester, '七阶 · 20 级');
    expect(tester.takeException(), isNull);

    // 类型筛选 chips 在窄屏折行也不溢出
    await tapText(tester, '手动技能');
    expect(tester.takeException(), isNull);
  });
}
