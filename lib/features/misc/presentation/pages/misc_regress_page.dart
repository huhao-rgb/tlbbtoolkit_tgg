import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../../../shared/widgets/tg_text_field.dart';
import '../../data/reg_repository.dart';
import '../../domain/reg_account.dart';

/// 卡回归计算器（对应原型 `v-regression`）。
///
/// - 「我的账号」卡片：账号网格（门派字徽 + 名称/Lv + 门派定位 + 状态点），
///   点选账号后于下方面板查看与操作；支持添加/编辑/删除账号；
/// - 选中账号面板三态：空闲可开始回归计时、计时中倒计时、已达成可领奖；
/// - 底部面板同时展示该账号的回归历史记录；
/// - 账号与计时状态持久化到本地（原型 `localStorage[tgg-reg-v1]`）。
class MiscRegressPage extends ConsumerStatefulWidget {
  const MiscRegressPage({super.key});

  @override
  ConsumerState<MiscRegressPage> createState() => _MiscRegressPageState();
}

class _MiscRegressPageState extends ConsumerState<MiscRegressPage> {
  late RegRepository _repo;
  List<RegAccount> _accts = const [];
  String? _selId;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _repo = RegRepository(ref.read(localStorageProvider));
    final loaded = _repo.load();
    _accts = loaded.accts;
    _selId = loaded.sel;
    // 选中 id 失效（如被删）则置空。
    if (_selId != null && !_accts.any((a) => a.id == _selId)) _selId = null;
    _startTickerIfNeeded();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTickerIfNeeded() {
    final hasRun = _accts.any((a) => a.curMs != null);
    if (hasRun && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    }
  }

  Future<void> _persist() async {
    await _repo.save(_accts, _selId);
    if (mounted) _startTickerIfNeeded();
  }

  void _addOrEdit({RegAccount? edit}) {
    showTgModal(
      context: context,
      child: _AccountModal(
        account: edit,
        sectKey: edit?.sectKey ?? 'xiaoyao',
        onSubmit: (name, lv, sectKey) {
          if (edit != null) {
            setState(() {
              _accts = [
                for (final a in _accts)
                  if (a.id == edit.id)
                    a.copyWith(name: name, lv: lv, sectKey: sectKey)
                  else
                    a,
              ];
            });
          } else {
            final a = RegAccount(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              lv: lv,
              sectKey: sectKey,
            );
            setState(() {
              _accts = [..._accts, a];
              _selId = a.id;
            });
          }
          _persist();
        },
      ),
    );
  }

  void _delete(RegAccount a) {
    setState(() {
      _accts = _accts.where((x) => x.id != a.id).toList(growable: false);
      if (_selId == a.id) _selId = null;
    });
    _persist();
  }

  void _select(String id) {
    if (_selId == id) return;
    setState(() => _selId = id);
    _persist();
  }

  void _start(RegAccount a, DateTime start) {
    final st = start.millisecondsSinceEpoch;
    if (st > DateTime.now().millisecondsSinceEpoch + 60000) return;
    setState(() {
      _accts = [
        for (final x in _accts)
          if (x.id == a.id) x.copyWith(curMs: st) else x,
      ];
    });
    _persist();
  }

  void _quit(RegAccount a) {
    setState(() {
      _accts = [
        for (final x in _accts)
          if (x.id == a.id) x.copyWith(clearCur: true) else x,
      ];
    });
    _persist();
  }

  void _claim(RegAccount a) {
    final end = regEndOf(a.curMs!);
    setState(() {
      _accts = [
        for (final x in _accts)
          if (x.id == a.id)
            x.copyWith(
              runs: [...x.runs, RegRun(startMs: a.curMs!, endMs: end)],
              clearCur: true,
            )
          else
            x,
      ];
    });
    _persist();
  }

  RegAccount? get _selected {
    for (final a in _accts) {
      if (a.id == _selId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return TgPageEntrance(
          child: SingleChildScrollView(
            padding: compact
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
                  ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TgPageHead(
                      crumbLeft: ToolCatalog.miscRegress.crumbRoot,
                      crumbTail: ToolCatalog.miscRegress.crumb.substring(
                        ToolCatalog.miscRegress.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.miscRegress.group.hubLocation),
                      title: ToolCatalog.miscRegress.title,
                      subtitle: ToolCatalog.miscRegress.pageSubtitle,
                    ),
                    // 规则 note
                    _RegRuleNote(),
                    const SizedBox(height: 16),
                    // 我的账号卡
                    _buildAccountsCard(),
                    const SizedBox(height: 16),
                    // 选中账号面板
                    _buildPanel(),
                    const SizedBox(height: TgSpacing.s34),
                    const _PageFoot(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- 「我的账号」卡 ----
  Widget _buildAccountsCard() {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '我的账号',
                style: TextStyle(
                  fontFamily: TgFonts.serif,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: tg.t1,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tg.goldTint(.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tg.goldTint(.35), width: 1),
                ),
                child: Text(
                  '${_accts.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tg.gold2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              _AddButton(
                onTap: () => _addOrEdit(),
                compact: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 账号网格（原型 auto-fill minmax(238px,1fr)，gap 12）
          LayoutBuilder(
            builder: (context, c) {
              const minTile = 238.0;
              const gap = 12.0;
              final cols =
                  (((c.maxWidth + gap) / (minTile + gap)).floor()).clamp(1, 8);
              final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
              if (_accts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  alignment: Alignment.center,
                  child: Text(
                    '暂无账号 · 点击右上角「添加账号」开始记录回归',
                    style: TgType.row13.copyWith(color: tg.t3),
                  ),
                );
              }
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in _accts)
                    SizedBox(
                      width: tileW,
                      child: _AccountCard(
                        account: a,
                        selected: a.id == _selId,
                        onTap: () => _select(a.id),
                        onEdit: () => _addOrEdit(edit: a),
                        onDelete: () => _delete(a),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---- 选中账号面板 ----
  Widget _buildPanel() {
    final tg = context.tg;
    final a = _selected;
    if (a == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: tg.card,
          borderRadius: TgRadius.card,
          border: Border.all(color: tg.border, width: 1),
        ),
        child: Text(
          '在上方选择一个账号，开始回归计时',
          textAlign: TextAlign.center,
          style: TgType.body14.copyWith(color: tg.t3),
        ),
      );
    }
    final state = regStateOf(a, _now.millisecondsSinceEpoch);
    switch (state) {
      case RegState.idle:
        return _IdlePanel(
          key: ValueKey('reg-idle-${a.id}'),
          account: a,
          onStart: (st) => _start(a, st),
        );
      case RegState.run:
        return _RunPanel(
          key: ValueKey('reg-run-${a.id}'),
          account: a,
          nowMs: _now.millisecondsSinceEpoch,
          onQuit: () => _quit(a),
        );
      case RegState.done:
        return _DonePanel(
          key: ValueKey('reg-done-${a.id}'),
          account: a,
          nowMs: _now.millisecondsSinceEpoch,
          onClaim: () => _claim(a),
        );
    }
  }
}

/// 规则 note（`.note`：info 图标 + 文本；7 天金色加粗）。
class _RegRuleNote extends StatelessWidget {
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
                style: TgType.row13.copyWith(
                  color: tg.t2,
                  fontSize: 12.5,
                  height: 1.7,
                ),
                children: [
                  const TextSpan(text: '规则：账号连续 '),
                  TextSpan(
                    text: '7 天',
                    style: TextStyle(
                      color: tg.gold2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' 不登录，第 '),
                  TextSpan(
                    text: '7 天',
                    style: TextStyle(
                      color: tg.gold2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: ' 开启回归任务。例：周一 10:00 下线后不再登录，'
                        '到下周一 10:01 再上线即完成一个回归周期'
                        '（工具按「起点 + 7天1分」计算达成时刻）。',
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

/// 「+ 添加账号」主按钮。
class _AddButton extends StatefulWidget {
  const _AddButton({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
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
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: widget.compact || _hover ? tg.gradGold : null,
              color: widget.compact || _hover ? null : tg.goldTint(.12),
              borderRadius: BorderRadius.circular(9),
              border: widget.compact || _hover
                  ? null
                  : Border.all(color: tg.goldTint(.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TgIcon(
                  'plus',
                  size: 13,
                  color: widget.compact || _hover ? TgTokens.btnInk : tg.gold2,
                ),
                const SizedBox(width: 5),
                Text(
                  '添加账号',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: widget.compact || _hover
                        ? TgTokens.btnInk
                        : tg.gold2,
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

/// 单个账号卡（`.acct`）。
class _AccountCard extends StatefulWidget {
  const _AccountCard({
    required this.account,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RegAccount account;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _hover = false;
  bool _arm = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = widget.account;
    final sect = regSectOf(a.sectKey);
    final markC = Color(sect.colorValue);
    final state = regStateOf(a, DateTime.now().millisecondsSinceEpoch);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) {
        setState(() {
          _hover = false;
          _arm = false;
        });
      },
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: widget.selected ? tg.card2 : tg.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.selected
                    ? tg.goldTint(.55)
                    : (_hover ? tg.borderHi : tg.border),
                width: 1,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: tg.goldTint(.18),
                        spreadRadius: 0,
                        blurRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 门派字 tile（44 · 门派色 10% 底 / 28% 描边）
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: markC.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: markC.withValues(alpha: .28),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    sect.mark,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: markC,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: TgFonts.serif,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tg.t1,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '· Lv.${a.lv}',
                            style: TgType.tag.copyWith(color: tg.t3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${sect.name} · ${sect.type}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tg.t3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _StatusDot(state: state, nowMs: DateTime.now().millisecondsSinceEpoch),
                    ],
                  ),
                ),
                // 操作：编辑 / 删除
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniIcon(
                      icon: 'pen',
                      tooltip: '编辑',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(height: 2),
                    _MiniIcon(
                      icon: 'trash',
                      tooltip: '删除',
                      danger: true,
                      arm: _arm,
                      onTap: () {
                        if (_arm) {
                          widget.onDelete();
                        } else {
                          setState(() => _arm = true);
                          Future.delayed(const Duration(milliseconds: 2600), () {
                            if (mounted) setState(() => _arm = false);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 账号操作小图标（26×26 · r8 · hover 底色）。
class _MiniIcon extends StatefulWidget {
  const _MiniIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.danger = false,
    this.arm = false,
  });

  final String icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool danger;
  final bool arm;

  @override
  State<_MiniIcon> createState() => _MiniIconState();
}

class _MiniIconState extends State<_MiniIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final Color color;
    if (widget.arm) {
      color = tg.red;
    } else if (_hover) {
      color = widget.danger ? tg.red : tg.gold2;
    } else {
      color = tg.t3;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.arm ? '确认删除？' : (widget.tooltip ?? ''),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Ink(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _hover ? tg.inset2 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: widget.arm
                    ? Text(
                        '确认?',
                        style: TextStyle(fontSize: 10, color: tg.red),
                      )
                    : TgIcon(widget.icon, size: 13, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态点（空闲/计时中/已达成）。
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.state, required this.nowMs});

  final RegState state;
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final (String text, Color dot, Color? glow) = switch (state) {
      RegState.idle => ('空闲', tg.t3, null),
      RegState.run => ('计时中', tg.blue, tg.blue),
      RegState.done => ('已达成', tg.gold2, tg.gold2),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot,
            boxShadow: glow == null
                ? null
                : [
                    BoxShadow(color: glow.withValues(alpha: .6), blurRadius: 5),
                  ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1,
            color: state == RegState.done ? tg.gold2 : tg.t3,
          ),
        ),
      ],
    );
  }
}

/// 面板头部（账号名 serif + 门派 tag + 状态）。
class _PanelHead extends StatelessWidget {
  const _PanelHead({required this.account});

  final RegAccount account;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final sect = regSectOf(account.sectKey);
    final c = Color(sect.colorValue);
    final state = regStateOf(account, DateTime.now().millisecondsSinceEpoch);
    final stText = switch (state) {
      RegState.idle => '空闲',
      RegState.run => '计时中',
      RegState.done => '已达成',
    };
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          account.name,
          style: TextStyle(
            fontFamily: TgFonts.serif,
            fontSize: 18.5,
            fontWeight: FontWeight.w600,
            color: tg.t1,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: c.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withValues(alpha: .4), width: 1),
          ),
          child: Text(
            'Lv.${account.lv} · ${sect.name}',
            style: TextStyle(
              fontSize: 11,
              color: c,
              height: 1.6,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state == RegState.done
                    ? tg.gold2
                    : (state == RegState.run ? tg.blue : tg.t3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              stText,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1,
                color: state == RegState.done ? tg.gold2 : tg.t3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 空闲态：开始回归计时。
class _IdlePanel extends StatefulWidget {
  const _IdlePanel({
    super.key,
    required this.account,
    required this.onStart,
  });

  final RegAccount account;
  final ValueChanged<DateTime> onStart;

  @override
  State<_IdlePanel> createState() => _IdlePanelState();
}

class _IdlePanelState extends State<_IdlePanel> {
  /// 默认起点：当前时刻（原型 dft = 当前）。
  DateTime _start = DateTime.now();

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = widget.account;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHead(account: a),
          const SizedBox(height: 14),
          Text(
            '开始回归计时',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: tg.t3,
            ),
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: tg.borderHi),
          const SizedBox(height: 12),
          // 起点输入
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最后上线时刻（即卡回归起点）',
                style: TgType.label.copyWith(color: tg.t3),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: 350,
                child: _DateTimeField(
                  value: _start,
                  onTap: _pick,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '按「起点 + 7天1分」计算达成时刻；若角色早已下线，请调整为实际下线时间。',
            style: TgType.tag.copyWith(
              color: tg.t3,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: '开始回归计时',
            icon: 'clock',
            onTap: () => widget.onStart(_start),
          ),
          _RunHistory(account: a),
        ],
      ),
    );
  }
}

/// 计时中：倒计时 4 宫格 + 周期进度条 + 达成时刻 + 警示。
class _RunPanel extends StatefulWidget {
  const _RunPanel({
    super.key,
    required this.account,
    required this.nowMs,
    required this.onQuit,
  });

  final RegAccount account;
  final int nowMs;
  final VoidCallback onQuit;

  @override
  State<_RunPanel> createState() => _RunPanelState();
}

class _RunPanelState extends State<_RunPanel> {
  bool _armQuit = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = widget.account;
    final end = regEndOf(a.curMs!);
    final leftMs = end - widget.nowMs;
    final t = leftMs <= 0 ? 0 : leftMs ~/ 1000;
    final d = t ~/ 86400;
    final h = (t % 86400) ~/ 3600;
    final m = (t % 3600) ~/ 60;
    final s = t % 60;
    final total = kRegDurMs;
    final elapsed = widget.nowMs - a.curMs!;
    final pct = (elapsed / total * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHead(account: a),
          const SizedBox(height: 16),
          Text(
            '距回归任务开启还剩',
            style: TextStyle(
              fontSize: 12,
              color: tg.t3,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // 倒计时 4 宫格
          LayoutBuilder(
            builder: (context, c) {
              const gap = 10.0;
              final w = (c.maxWidth - gap * 3) / 4;
              return Row(
                children: [
                  _CdCell(width: w, num: '$d', label: '天'),
                  const SizedBox(width: gap),
                  _CdCell(width: w, num: _pad2(h), label: '时'),
                  const SizedBox(width: gap),
                  _CdCell(width: w, num: _pad2(m), label: '分'),
                  const SizedBox(width: gap),
                  _CdCell(width: w, num: _pad2(s), label: '秒'),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          // 周期进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: tg.goldTint(.13)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (pct / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: tg.gradGold,
                        boxShadow: [
                          BoxShadow(
                            color: tg.gold2.withValues(alpha: .5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '周期进度 ${pct.toStringAsFixed(1)}%',
                style: TgType.tag.copyWith(color: tg.t3),
              ),
              Text(
                '达成时刻 ${regFmt(end)}',
                style: TgType.tag.copyWith(color: tg.t3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 警示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: tg.tintOf(tg.red, .08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: tg.tintOf(tg.red, .3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TgIcon('info', size: 15, color: tg.red),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.7,
                        color: tg.tintOf(tg.t1, .95),
                      ),
                      children: [
                        const TextSpan(text: '计时期间'),
                        TextSpan(
                          text: '请勿登录该账号',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tg.tagRed,
                          ),
                        ),
                        const TextSpan(
                          text: '——一旦上线，回归周期将重新计算，前功尽弃。',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 放弃（二次确认）
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_armQuit) {
                  widget.onQuit();
                } else {
                  setState(() => _armQuit = true);
                  Future.delayed(const Duration(milliseconds: 2800), () {
                    if (mounted) setState(() => _armQuit = false);
                  });
                }
              },
              borderRadius: BorderRadius.circular(9),
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Ink(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: tg.borderHi, width: 1),
                ),
                child: Center(
                  child: Text(
                    _armQuit ? '确认放弃？（本轮进度将清零）' : '放弃本轮计时',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _armQuit ? tg.red : tg.t2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _RunHistory(account: a),
        ],
      ),
    );
  }
}

/// 倒计时单元格。
class _CdCell extends StatelessWidget {
  const _CdCell({
    required this.width,
    required this.num,
    required this.label,
  });

  final double width;
  final String num;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(6, 15, 6, 11),
      decoration: BoxDecoration(
        color: tg.inset2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            num,
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 31,
              fontWeight: FontWeight.w600,
              color: tg.gold2,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: tg.t3,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 已达成态：金色达成卡。
class _DonePanel extends StatelessWidget {
  const _DonePanel({
    super.key,
    required this.account,
    required this.nowMs,
    required this.onClaim,
  });

  final RegAccount account;
  final int nowMs;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = account;
    final end = regEndOf(a.curMs!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHead(account: a),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tg.goldTint(.5), width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tg.goldTint(.12), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                Text(
                  '回归任务已开启',
                  style: TextStyle(
                    fontFamily: TgFonts.serif,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: tg.gold2,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '达成时刻 ${regFmt(end)} · 现在上号即可领取回归奖励',
                  textAlign: TextAlign.center,
                  style: TgType.body14.copyWith(color: tg.t2),
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: '确认上线领奖 · 开启下一轮',
                  onTap: onClaim,
                ),
                const SizedBox(height: 12),
                Text(
                  '若暂不上线可继续挂机，状态保持「已达成」。',
                  style: TgType.tag.copyWith(color: tg.t3),
                ),
              ],
            ),
          ),
          _RunHistory(account: a),
        ],
      ),
    );
  }
}

/// 回归记录列表（已完成 N 轮）。
class _RunHistory extends StatelessWidget {
  const _RunHistory({required this.account});

  final RegAccount account;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final runs = account.runs;
    if (runs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '回归记录 · 已完成 ${runs.length} 轮',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: tg.t3,
          ),
        ),
        const SizedBox(height: 2),
        Container(height: 1, color: tg.borderHi),
        const SizedBox(height: 4),
        for (var i = 0; i < runs.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('第 ${i + 1} 轮', style: TgType.body14.copyWith(color: tg.t1)),
                Text(
                  '${regFmt(runs[i].startMs)} → ${regFmt(runs[i].endMs)}',
                  style: TgType.body14.copyWith(color: tg.t3),
                ),
              ],
            ),
          ),
          if (i != runs.length - 1)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tg.border, width: 1)),
              ),
            ),
        ],
      ],
    );
  }
}

/// 金渐变主按钮（开始回归计时 / 确认领奖）。
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: tg.gradGold,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hover ? TgShadows.primaryButton : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    TgIcon(widget.icon!, size: 14, color: TgTokens.btnInk),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
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
      ),
    );
  }
}

/// 日期时间字段（只读 · 点击弹出选择）。
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  String get _label {
    return '${value.year}-${_pad2(value.month)}-${_pad2(value.day)} '
        '${_pad2(value.hour)}:${_pad2(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tg.inset,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tg.border, width: 1),
          ),
          child: Row(
            children: [
              TgIcon('clock', size: 15, color: tg.t3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: tg.t1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              TgIcon('chev', size: 14, color: tg.t3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账号维护弹窗（添加 / 编辑）。
class _AccountModal extends StatefulWidget {
  const _AccountModal({
    this.account,
    this.sectKey = 'xiaoyao',
    required this.onSubmit,
  });

  final RegAccount? account;
  final String sectKey;
  final void Function(String name, int lv, String sectKey) onSubmit;

  @override
  State<_AccountModal> createState() => _AccountModalState();
}

class _AccountModalState extends State<_AccountModal> {
  late final TextEditingController _name;
  late final TextEditingController _lv;
  late String _sect;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.name ?? '');
    _lv = TextEditingController(
      text: (widget.account?.lv ?? 89).toString(),
    );
    _sect = widget.sectKey;
  }

  @override
  void dispose() {
    _name.dispose();
    _lv.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final lv = int.tryParse(_lv.text.trim())?.clamp(10, 119) ?? 89;
    widget.onSubmit(name, lv, _sect);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final editing = widget.account != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // modal-head
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tg.goldTint(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tg.goldTint(.28), width: 1),
              ),
              child: TgIcon('user', size: 21, color: tg.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editing ? '编辑账号' : '添加账号',
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: tg.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '回归计时 · 账号维护',
                    style: TgType.tag.copyWith(color: tg.t3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TgModalCloseButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 角色名称
        _FieldLabel('角色名称'),
        const SizedBox(height: 6),
        TgTextField(
          controller: _name,
          hintText: '如：逍遥生',
          maxLength: 12,
          height: 40,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 13),
        // 角色等级
        _FieldLabel('角色等级（10 - 119）'),
        const SizedBox(height: 6),
        TgTextField(
          controller: _lv,
          hintText: '89',
          height: 40,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 13),
        // 门派（胶囊网格）
        _FieldLabel('角色门派'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final s in kRegSects)
              _SectPill(
                sect: s,
                active: _sect == s.key,
                onTap: () => setState(() => _sect = s.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        // 保存
        SizedBox(
          width: double.infinity,
          child: _PrimaryButton(
            label: '保存账号',
            onTap: _save,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text(
      text,
      style: TgType.label.copyWith(
        color: tg.t3,
        letterSpacing: 1,
      ),
    );
  }
}

/// 门派胶囊（弹窗内选择）。
class _SectPill extends StatelessWidget {
  const _SectPill({
    required this.sect,
    required this.active,
    required this.onTap,
  });

  final RegSect sect;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final active = this.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? tg.goldTint(.1) : tg.inset2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? tg.goldTint(.5) : tg.borderHi,
                width: 1,
              ),
            ),
            child: Text(
              sect.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? tg.gold2 : tg.t2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 页脚（对应原型 `.page-foot`）。
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
          '天工阁 · 玩家自制工具集合，与畅游官方无关',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
        const SizedBox(height: 2),
        Text(
          '回归周期与奖励为玩家经验整理，正式版接入实战数据',
          textAlign: TextAlign.center,
          style: TgType.tag.copyWith(color: tg.t3),
        ),
      ],
    );
  }
}

/// 两位补零（用于时间 / 倒计时文本）。
String _pad2(int n) => n.toString().padLeft(2, '0');
