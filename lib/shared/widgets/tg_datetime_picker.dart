import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

/// 可选时间的方向。
enum TgDateTimeDirection {
  /// 只能选过去（如「最后上线时刻」）。
  past,

  /// 只能选将来（如「回归触发时刻」）。
  future,
}

/// 天工阁日期时间字段（设计稿：322 宽两段式面板）。
///
/// 只读字段 + 点按弹出面板：先选日期，0.22s 后自动滑入时间页，面包屑可回跳；
/// 面板优先在字段上方弹出（空间不足时落到下方），点面板外 / Esc 关闭。
///
/// - [direction] 决定可选的日期区间：`past` 禁选今天之后的日期，`future`
///   禁选今天之前的日期；时间滚轮同时按当前时刻做整点 / 分钟级禁用。
/// - 未完整选择时「确定」禁用；点面板外关闭不回填。
class TgDateTimeField extends StatefulWidget {
  const TgDateTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.direction = TgDateTimeDirection.future,
    this.timeCaption = '触发时刻',
    this.onCleared,
    this.panelWidth = 322,
  });

  /// 当前值（必填；面板打开时以此为初值）。
  final DateTime value;

  /// 点「确定」或快捷时刻后回填。
  final ValueChanged<DateTime> onChanged;

  final TgDateTimeDirection direction;

  /// 时间页大数字右侧的小字说明。
  final String timeCaption;

  /// 提供后显示「清除」：点按时回调并关闭面板，字段值由调用方决定。
  final VoidCallback? onCleared;

  /// 面板宽度（设计稿 322）。
  final double panelWidth;

  @override
  State<TgDateTimeField> createState() => _TgDateTimeFieldState();
}

class _TgDateTimeFieldState extends State<TgDateTimeField> {
  /// 面板高度估算（头 + 310 主体 + 两行页脚），用于判断向上 / 向下弹出。
  static const double _panelHeightEstimate = 456;

  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _hover = false;
  bool _openUp = true;
  double _panelDx = 0;
  double _panelDy = 0;
  double _panelWidth = 322;

  void _toggle() {
    if (_portal.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final screen = MediaQuery.sizeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    final rect = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final width = math.min(
      widget.panelWidth,
      math.max(240.0, screen.width - 24),
    );
    var dx = 0.0;
    var up = true;
    var dy = -8.0;
    if (rect != null) {
      final spaceAbove = rect.top;
      final spaceBelow = screen.height - rect.bottom;
      up = spaceAbove >= _panelHeightEstimate || spaceAbove >= spaceBelow;
      dy = up ? -8.0 : 8.0;
      final maxLeft = screen.width - 12 - width;
      if (rect.left > maxLeft) dx = maxLeft - rect.left;
      if (rect.left + dx < 12) dx = 12 - rect.left;
      // 上下空间都不足时，把面板推回屏幕内（允许轻微压住字段）。
      if (up) {
        final overflow = _panelHeightEstimate + 20 - rect.top;
        if (overflow > 0) dy += overflow;
      } else {
        final overflow =
            rect.bottom + dy + _panelHeightEstimate + 12 - screen.height;
        if (overflow > 0) dy -= overflow;
      }
    }
    setState(() {
      _openUp = up;
      _panelDx = dx;
      _panelDy = dy;
      _panelWidth = width;
    });
    _portal.show();
  }

  void _close() {
    if (!_portal.isShowing) return;
    _portal.hide();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final open = _portal.isShowing;
    final borderColor = open
        ? tg.gold
        : (_hover ? tg.goldTint(.45) : tg.goldTint(.2));

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.ease,
              height: 44,
              decoration: BoxDecoration(
                color: open || _hover ? tg.goldTint(.04) : tg.inset,
                borderRadius: BorderRadius.circular(TgRadius.md),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: open ? TgShadows.focusRing : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 13),
                  TgIcon('calendar', size: 16, color: open ? tg.gold : tg.t3),
                  const SizedBox(width: 9),
                  Expanded(child: _valueText(context)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? -.25 : .25,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    child: TgIcon(
                      'chev',
                      size: 12,
                      color: open ? tg.gold : tg.t3,
                    ),
                  ),
                  const SizedBox(width: 13),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueText(BuildContext context) {
    final tg = context.tg;
    final v = widget.value;
    const base = TextStyle(
      fontSize: 14,
      letterSpacing: .5,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${v.year}-${_p2(v.month)}-${_p2(v.day)}',
            style: base.copyWith(color: tg.gold2, fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: '（周${_weekdayLabel(v)}）',
            style: base.copyWith(color: tg.t2),
          ),
          TextSpan(
            text: ' ${_p2(v.hour)}:${_p2(v.minute)}',
            style: base.copyWith(color: tg.gold2, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // 全屏透明遮罩：点面板外关闭（不回填）。
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: _openUp ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor: _openUp
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: Offset(_panelDx, _panelDy),
              child: Align(
                alignment: _openUp ? Alignment.bottomLeft : Alignment.topLeft,
                child: _PanelEntrance(
                  alignment: _openUp ? Alignment.bottomLeft : Alignment.topLeft,
                  child: _DateTimePickerPanel(
                    width: _panelWidth,
                    initial: widget.value,
                    direction: widget.direction,
                    timeCaption: widget.timeCaption,
                    onClear: widget.onCleared == null
                        ? null
                        : () {
                            widget.onCleared!();
                            _close();
                          },
                    onConfirm: (v) {
                      widget.onChanged(v);
                      _close();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 面板入场：opacity 0→1 · translateY 6→0 · scale .98→1（180ms）。
class _PanelEntrance extends StatelessWidget {
  const _PanelEntrance({required this.child, required this.alignment});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - v)),
          child: Transform.scale(
            scale: .98 + .02 * v,
            alignment: alignment,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

enum _Stage { date, time }

/// 选择器面板本体（头 · 310 主体 · 页脚）。
class _DateTimePickerPanel extends StatefulWidget {
  const _DateTimePickerPanel({
    required this.width,
    required this.initial,
    required this.direction,
    required this.timeCaption,
    required this.onConfirm,
    this.onClear,
  });

  final double width;
  final DateTime initial;
  final TgDateTimeDirection direction;
  final String timeCaption;
  final ValueChanged<DateTime> onConfirm;
  final VoidCallback? onClear;

  @override
  State<_DateTimePickerPanel> createState() => _DateTimePickerPanelState();
}

class _DateTimePickerPanelState extends State<_DateTimePickerPanel> {
  static const double _bodyHeight = 310;
  static const double _cellHeight = 35;
  static const double _rowGap = 3;

  late final DateTime _now;
  late final DateTime _today;
  late final DateTime _futureMin;

  late DateTime _selected;
  late int _hour;
  late int _minute;
  late int _viewYear;
  late int _viewMonth;
  _Stage _stage = _Stage.date;
  Timer? _stageTimer;
  int _stageToken = 0;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _today = DateTime(_now.year, _now.month, _now.day);
    // 未来方向最小可选时刻 = 下一分钟（所选时刻需晚于当前时间）。
    _futureMin = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _now.hour,
      _now.minute,
    ).add(const Duration(minutes: 1));

    _selected = DateTime(
      widget.initial.year,
      widget.initial.month,
      widget.initial.day,
    );
    if (widget.direction == TgDateTimeDirection.past) {
      if (_selected.isAfter(_today)) _selected = _today;
    } else {
      final minDay = _dateOnly(_futureMin);
      if (_selected.isBefore(minDay)) _selected = minDay;
    }
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _clampTime();

    _viewYear = _selected.year;
    _viewMonth = _selected.month;
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }

  bool get _isPast => widget.direction == TgDateTimeDirection.past;

  bool get _canPrev => !(!_isPast && _isViewingCurrentMonth);

  bool get _canNext => !(_isPast && _isViewingCurrentMonth);

  bool get _isViewingCurrentMonth =>
      _viewYear == _now.year && _viewMonth == _now.month;

  bool get _canConfirm => _isValid(_hour, _minute);

  void _clampTime() {
    if (_isValid(_hour, _minute)) return;
    final ref = _isPast ? _now : _futureMin;
    _hour = ref.hour;
    _minute = ref.minute;
  }

  bool _isValid(int hour, int minute) {
    final t = DateTime(
      _selected.year,
      _selected.month,
      _selected.day,
      hour,
      minute,
    );
    return _isPast ? !t.isAfter(_now) : !t.isBefore(_futureMin);
  }

  bool _dayEnabled(DateTime day) {
    final d = _dateOnly(day);
    return _isPast ? !d.isAfter(_today) : !d.isBefore(_dateOnly(_futureMin));
  }

  bool _hourEnabled(int hour) {
    if (_isPast) {
      return !_sameDay(_selected, _today) || hour <= _now.hour;
    }
    return !_sameDay(_selected, _dateOnly(_futureMin)) ||
        hour >= _futureMin.hour;
  }

  bool _minuteEnabled(int minute) {
    if (_isPast) {
      if (!_sameDay(_selected, _today)) return true;
      if (_hour < _now.hour) return true;
      if (_hour > _now.hour) return false;
      return minute <= _now.minute;
    }
    if (!_sameDay(_selected, _dateOnly(_futureMin))) return true;
    if (_hour > _futureMin.hour) return true;
    if (_hour < _futureMin.hour) return false;
    return minute >= _futureMin.minute;
  }

  void _setStage(_Stage stage) {
    if (_stage == stage) return;
    _stageTimer?.cancel();
    _stageToken++;
    setState(() {
      if (stage == _Stage.time) _clampTime();
      _stage = stage;
    });
  }

  void _shiftMonth(int delta) {
    final target = DateTime(_viewYear, _viewMonth + delta, 1);
    final thisMonth = DateTime(_now.year, _now.month, 1);
    if (_isPast && target.isAfter(thisMonth)) return;
    if (!_isPast && target.isBefore(thisMonth)) return;
    setState(() {
      _viewYear = target.year;
      _viewMonth = target.month;
    });
  }

  void _pickDate(DateTime day) {
    if (!_dayEnabled(day)) return;
    setState(() {
      _selected = _dateOnly(day);
      _clampTime();
    });
    // 点选日期后 0.22s 自动滑入时间页。
    final token = ++_stageToken;
    _stageTimer?.cancel();
    _stageTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || token != _stageToken || _stage == _Stage.time) return;
      setState(() => _stage = _Stage.time);
    });
  }

  void _onHourChanged(int hour) {
    setState(() {
      _hour = hour;
      _clampTime();
    });
  }

  void _onMinuteChanged(int minute) {
    setState(() {
      _minute = minute;
      _clampTime();
    });
  }

  /// 快捷时刻（整组回填，贴合卡回归的整点习惯）。
  List<(String label, DateTime value, bool enabled)> _quickOptions() {
    final t = _today;
    final List<(String, DateTime)> raw = _isPast
        ? [
            ('今天 08:00', DateTime(t.year, t.month, t.day, 8)),
            ('昨天 20:00', DateTime(t.year, t.month, t.day - 1, 20)),
            ('三天前 20:00', DateTime(t.year, t.month, t.day - 3, 20)),
          ]
        : [
            ('今天 18:00', DateTime(t.year, t.month, t.day, 18)),
            ('明天 09:00', DateTime(t.year, t.month, t.day + 1, 9)),
            ('三天后 20:00', DateTime(t.year, t.month, t.day + 3, 20)),
          ];
    return [
      for (final (label, value) in raw)
        (
          label,
          value,
          _isPast ? !value.isAfter(_now) : !value.isBefore(_futureMin),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      key: const Key('tg-dtp-panel'),
      width: widget.width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tg.card2,
        borderRadius: BorderRadius.circular(TgRadius.r14),
        border: Border.all(color: tg.goldTint(.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .55),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
          BoxShadow(color: Colors.black.withValues(alpha: .4), spreadRadius: 1),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildBody(context),
            _buildFoot(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tg.border)),
      ),
      child: Row(
        children: [
          _Crumb(
            label: '① 选择日期',
            current: _stage == _Stage.date,
            enabled: true,
            onTap: () => _setStage(_Stage.date),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TgIcon('chev', size: 9, color: tg.t3),
          ),
          _Crumb(
            label: '② 选择时间',
            current: _stage == _Stage.time,
            enabled: true,
            onTap: () => _setStage(_Stage.time),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SizedBox(
      height: _bodyHeight,
      child: ClipRect(
        child: Stack(
          children: [
            _buildPane(
              visible: _stage == _Stage.date,
              fromLeft: true,
              child: _buildDatePane(context),
            ),
            _buildPane(
              visible: _stage == _Stage.time,
              fromLeft: false,
              child: _buildTimePane(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 两段式滑入 / 滑出（隐藏页向外平移 60px 并淡出）。
  Widget _buildPane({
    required bool visible,
    required bool fromLeft,
    required Widget child,
  }) {
    final dx = 60 / math.max(widget.width, 1);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : Offset(fromLeft ? -dx : dx, 0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.ease,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePane(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                _NavButton(
                  icon: 'chev-l',
                  enabled: _canPrev,
                  onTap: () => _shiftMonth(-1),
                ),
                Expanded(child: Center(child: _monthTitle(context))),
                _TodayLink(
                  onTap: () => setState(() {
                    _viewYear = _now.year;
                    _viewMonth = _now.month;
                  }),
                ),
                const SizedBox(width: 2),
                _NavButton(
                  icon: 'chev',
                  enabled: _canNext,
                  onTap: () => _shiftMonth(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      _weekLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: i == 0 || i == 6 ? tg.goldDp : tg.t3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < 6; row++) ...[
            if (row > 0) const SizedBox(height: _rowGap),
            SizedBox(
              height: _cellHeight,
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _buildDayCell(context, _cellDate(row * 7 + col)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthTitle(BuildContext context) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$_viewYear',
            style: TextStyle(color: tg.gold),
          ),
          TextSpan(
            text: ' 年 ',
            style: TextStyle(color: tg.t1),
          ),
          TextSpan(
            text: _p2(_viewMonth),
            style: TextStyle(color: tg.gold),
          ),
          TextSpan(
            text: ' 月',
            style: TextStyle(color: tg.t1),
          ),
        ],
      ),
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  DateTime _cellDate(int index) {
    final first = DateTime(_viewYear, _viewMonth, 1);
    final leading = first.weekday % 7;
    return DateTime(_viewYear, _viewMonth, 1 - leading + index);
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final tg = context.tg;
    final enabled = _dayEnabled(day);
    final inMonth = day.month == _viewMonth && day.year == _viewYear;
    final isToday = _sameDay(day, _today);
    final selected = _sameDay(day, _selected);

    Color color;
    FontWeight weight = FontWeight.w400;
    if (!enabled) {
      color = tg.t3.withValues(alpha: .7);
    } else if (!inMonth) {
      color = tg.t3.withValues(alpha: .55);
    } else {
      color = tg.t1;
    }
    if (isToday && !selected) {
      color = tg.gold2;
      weight = FontWeight.w600;
    }
    if (selected) {
      color = TgTokens.btnInk;
      weight = FontWeight.w700;
    }

    return _Hoverable(
      key: ValueKey('tg-dtp-day-${day.year}-${day.month}-${day.day}'),
      onTap: enabled ? () => _pickDate(day) : null,
      child: (context, hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TgTokens.gradGoldStart, TgTokens.gradGoldEnd],
                )
              : null,
          color: !selected && enabled && hover ? tg.goldTint(.12) : null,
          borderRadius: BorderRadius.circular(TgRadius.s9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tg.goldDp.withValues(alpha: .35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: weight,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (isToday && !selected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tg.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePane(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        children: [
          _buildTimeDisplay(context),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TimeColumn(
                    label: '时',
                    count: 24,
                    value: _hour,
                    isEnabled: _hourEnabled,
                    onChanged: _onHourChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeColumn(
                    label: '分',
                    count: 60,
                    value: _minute,
                    isEnabled: _minuteEnabled,
                    onChanged: _onMinuteChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    final tg = context.tg;
    final digit = TextStyle(
      fontFamily: TgFonts.serif,
      fontSize: 34,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 2,
      color: tg.gold,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [Shadow(color: tg.gold.withValues(alpha: .35), blurRadius: 18)],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(_p2(_hour), style: digit),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
          child: Text(
            ':',
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w400,
              color: tg.t3,
            ),
          ),
        ),
        Text(_p2(_minute), style: digit),
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 9),
          child: Text(
            widget.timeCaption,
            style: TextStyle(fontSize: 12, color: tg.t3),
          ),
        ),
      ],
    );
  }

  Widget _buildFoot(BuildContext context) {
    final tg = context.tg;
    final options = _quickOptions();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tg.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, value, enabled) in options)
                _QuickChip(
                  label: label,
                  enabled: enabled,
                  onTap: () => widget.onConfirm(value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onClear != null) ...[
                _FootTextButton(label: '清除', onTap: widget.onClear!),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _OkButton(enabled: _canConfirm, onTap: _confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm() {
    if (!_canConfirm) return;
    widget.onConfirm(
      DateTime(_selected.year, _selected.month, _selected.day, _hour, _minute),
    );
  }
}

/// 时间滚轮列：选中行居中吸附，行高 44，可视 5 行。
class _TimeColumn extends StatefulWidget {
  const _TimeColumn({
    required this.label,
    required this.count,
    required this.value,
    required this.isEnabled,
    required this.onChanged,
  });

  final String label;
  final int count;
  final int value;
  final bool Function(int index) isEnabled;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeColumn> createState() => _TimeColumnState();
}

class _TimeColumnState extends State<_TimeColumn> {
  static const double _itemExtent = 44;

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: widget.value * _itemExtent,
  );

  @override
  void didUpdateWidget(_TimeColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value || !_controller.hasClients) return;
    _animateTo(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    final target = index * _itemExtent;
    if ((_controller.offset - target).abs() < .5) return;
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
  }

  int _nearestEnabled(int index) {
    if (widget.isEnabled(index)) return index;
    for (var d = 1; d < widget.count; d++) {
      final lo = index - d;
      if (lo >= 0 && widget.isEnabled(lo)) return lo;
      final hi = index + d;
      if (hi < widget.count && widget.isEnabled(hi)) return hi;
    }
    return index;
  }

  void _snap() {
    if (!_controller.hasClients) return;
    var index = (_controller.offset / _itemExtent).round().clamp(
      0,
      widget.count - 1,
    );
    index = _nearestEnabled(index);
    if (index != widget.value) widget.onChanged(index);
    _animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = math.max(0.0, (constraints.maxHeight - _itemExtent) / 2);
        return Stack(
          children: [
            // 选中带在滚轮之下，文字压在上面。
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    height: _itemExtent,
                    decoration: BoxDecoration(
                      color: tg.goldTint(.07),
                      borderRadius: BorderRadius.circular(TgRadius.md),
                      border: Border.all(color: tg.goldTint(.2)),
                    ),
                  ),
                ),
              ),
            ),
            NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _snap();
                return false;
              },
              child: ListView.builder(
                controller: _controller,
                padding: EdgeInsets.symmetric(vertical: pad),
                itemExtent: _itemExtent,
                physics: const ClampingScrollPhysics(),
                itemCount: widget.count,
                itemBuilder: (context, index) => _buildRow(context, index),
              ),
            ),
            Positioned(
              left: 10,
              top: 0,
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 11, color: tg.t3),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final tg = context.tg;
    final selected = index == widget.value;
    final enabled = widget.isEnabled(index);
    return _Hoverable(
      onTap: enabled
          ? () {
              widget.onChanged(index);
              _animateTo(index);
            }
          : null,
      child: (context, hover) => Center(
        child: Text(
          _p2(index),
          style: TextStyle(
            fontSize: selected ? 19 : 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? tg.gold
                : (enabled
                      ? (hover ? tg.gold2 : tg.t2)
                      : tg.t3.withValues(alpha: .45)),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// hover 态构建器（统一手势与鼠标指针）。
class _Hoverable extends StatefulWidget {
  const _Hoverable({super.key, required this.child, this.onTap});

  final Widget Function(BuildContext context, bool hover) child;
  final VoidCallback? onTap;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child(context, _hover),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool current;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: enabled ? onTap : null,
      child: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: current ? tg.goldTint(.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(TgRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: current ? FontWeight.w600 : FontWeight.w400,
            color: current
                ? tg.gold
                : (enabled ? (hover ? tg.gold2 : tg.t2) : tg.t3),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: enabled ? onTap : null,
      child: (context, hover) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: hover && enabled ? tg.goldTint(.2) : tg.borderHi,
          ),
        ),
        child: Center(
          child: TgIcon(
            icon,
            size: 13,
            color: !enabled
                ? tg.t3.withValues(alpha: .35)
                : (hover ? tg.gold : tg.t2),
          ),
        ),
      ),
    );
  }
}

class _TodayLink extends StatelessWidget {
  const _TodayLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: onTap,
      child: (context, hover) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          '今天',
          style: TextStyle(fontSize: 12, color: hover ? tg.gold : tg.t3),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: enabled ? onTap : null,
      child: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: TgRadius.pillShape,
          border: Border.all(
            color: hover && enabled ? tg.goldTint(.2) : tg.borderHi,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: !enabled
                ? tg.t3.withValues(alpha: .55)
                : (hover ? tg.gold : tg.t2),
          ),
        ),
      ),
    );
  }
}

class _FootTextButton extends StatelessWidget {
  const _FootTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: onTap,
      child: (context, hover) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, color: hover ? tg.t2 : tg.t3),
        ),
      ),
    );
  }
}

class _OkButton extends StatelessWidget {
  const _OkButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return _Hoverable(
      onTap: enabled ? onTap : null,
      child: (context, hover) => AnimatedContainer(
        key: const Key('tg-dtp-ok'),
        duration: const Duration(milliseconds: 140),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hover
                      ? [TgTokens.gradGoldStart, TgTokens.dGold]
                      : [TgTokens.gradGoldStart, TgTokens.gradGoldEnd],
                )
              : null,
          color: enabled ? null : tg.inset2,
          borderRadius: BorderRadius.circular(TgRadius.s8),
        ),
        child: Text(
          '确定',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: enabled ? TgTokens.btnInk : tg.t3,
          ),
        ),
      ),
    );
  }
}

const List<String> _weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

String _p2(int v) => v.toString().padLeft(2, '0');

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayLabel(DateTime d) => _weekLabels[d.weekday % 7];
