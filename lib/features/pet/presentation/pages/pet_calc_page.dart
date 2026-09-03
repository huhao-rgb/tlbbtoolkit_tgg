import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/pet_calc.dart';

/// 宝宝资质计算（对应原型 `v-pet-calc`）。
///
/// 布局：页头 + split（左：表单卡，右：结果卡 380px，sticky）。
/// - 表单卡：超灵品种开关 + 当前资质输入 + 当前/目标悟灵步进器 + 开始计算按钮；
/// - 结果卡：初始隐藏，点击「开始计算」后展示预估成品资质、评级、裸资与培养建议；
/// - 计算逻辑见 `pet_calc.dart`（与原型「资质公式 v4」一致）。
///
/// 页面不含 Scaffold/AppBar（信息条与返回按钮由 shell 框架提供）。
class PetCalcPage extends StatefulWidget {
  const PetCalcPage({super.key});

  @override
  State<PetCalcPage> createState() => _PetCalcPageState();
}

class _PetCalcPageState extends State<PetCalcPage> {
  final _baseController = TextEditingController(text: '2200');

  bool _isChaoling = false;

  // 当前悟性 / 当前灵性 / 目标悟性 / 目标灵性（0~10）。
  int _curWu = 0;
  int _curLing = 0;
  int _wu = 8;
  int _ling = 5;

  /// 结果；null 表示尚未计算（结果卡隐藏）。
  PetCalcResult? _result;

  @override
  void dispose() {
    _baseController.dispose();
    super.dispose();
  }

  void _onCalc() {
    final base = int.tryParse(_baseController.text.trim()) ?? 0;
    setState(() {
      _result = computePetCalc(
        PetCalcInput(
          base: base,
          currentWu: _curWu,
          currentLing: _curLing,
          targetWu: _wu,
          targetLing: _ling,
          isSuperLing: _isChaoling,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // compact：极窄屏（页面内边距/大数字缩放）；wide：并排 split 布局。
        final compact = constraints.maxWidth < 640;
        final wide = constraints.maxWidth >= 860;
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
                      crumbLeft: ToolCatalog.petCalc.crumbRoot,
                      crumbTail: ToolCatalog.petCalc.crumb
                          .substring(ToolCatalog.petCalc.crumbRoot.length),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.petCalc.group.hubLocation),
                      title: ToolCatalog.petCalc.title,
                      subtitle: ToolCatalog.petCalc.pageSubtitle,
                    ),
                    // split：宽屏左表单右结果；窄屏上下堆叠。
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FormCard(
                              compact: compact,
                              isChaoling: _isChaoling,
                              baseController: _baseController,
                              curWu: _curWu,
                              curLing: _curLing,
                              wu: _wu,
                              ling: _ling,
                              onChaolingChanged: (v) =>
                                  setState(() => _isChaoling = v),
                              onCurWuMinus: () =>
                                  setState(() => _curWu = _bump(_curWu, -1)),
                              onCurWuPlus: () =>
                                  setState(() => _curWu = _bump(_curWu, 1)),
                              onCurLingMinus: () =>
                                  setState(() => _curLing = _bump(_curLing, -1)),
                              onCurLingPlus: () =>
                                  setState(() => _curLing = _bump(_curLing, 1)),
                              onWuMinus: () =>
                                  setState(() => _wu = _bump(_wu, -1)),
                              onWuPlus: () => setState(() => _wu = _bump(_wu, 1)),
                              onLingMinus: () =>
                                  setState(() => _ling = _bump(_ling, -1)),
                              onLingPlus: () =>
                                  setState(() => _ling = _bump(_ling, 1)),
                              onCalc: _onCalc,
                            ),
                          ),
                          const SizedBox(width: TgSpacing.s18),
                          if (_result != null)
                            SizedBox(
                              width: 380,
                              child: _ResultCard(
                                result: _result!,
                                compact: compact,
                              ),
                            ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FormCard(
                            compact: compact,
                            isChaoling: _isChaoling,
                            baseController: _baseController,
                            curWu: _curWu,
                            curLing: _curLing,
                            wu: _wu,
                            ling: _ling,
                            onChaolingChanged: (v) =>
                                setState(() => _isChaoling = v),
                            onCurWuMinus: () =>
                                setState(() => _curWu = _bump(_curWu, -1)),
                            onCurWuPlus: () =>
                                setState(() => _curWu = _bump(_curWu, 1)),
                            onCurLingMinus: () =>
                                setState(() => _curLing = _bump(_curLing, -1)),
                            onCurLingPlus: () =>
                                setState(() => _curLing = _bump(_curLing, 1)),
                            onWuMinus: () => setState(() => _wu = _bump(_wu, -1)),
                            onWuPlus: () => setState(() => _wu = _bump(_wu, 1)),
                            onLingMinus: () =>
                                setState(() => _ling = _bump(_ling, -1)),
                            onLingPlus: () =>
                                setState(() => _ling = _bump(_ling, 1)),
                            onCalc: _onCalc,
                          ),
                          if (_result != null) ...[
                            const SizedBox(height: TgSpacing.s18),
                            _ResultCard(result: _result!, compact: compact),
                          ],
                        ],
                      ),
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

  int _bump(int v, int delta) =>
      (v + delta).clamp(kWuLingMin, kWuLingMax);
}

/// 表单卡（`.form-card`）：超灵开关 + 当前资质 + 当前/目标悟灵 + 开始计算。
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.compact,
    required this.isChaoling,
    required this.baseController,
    required this.curWu,
    required this.curLing,
    required this.wu,
    required this.ling,
    required this.onChaolingChanged,
    required this.onCurWuMinus,
    required this.onCurWuPlus,
    required this.onCurLingMinus,
    required this.onCurLingPlus,
    required this.onWuMinus,
    required this.onWuPlus,
    required this.onLingMinus,
    required this.onLingPlus,
    required this.onCalc,
  });

  final bool compact;
  final bool isChaoling;
  final TextEditingController baseController;
  final int curWu;
  final int curLing;
  final int wu;
  final int ling;
  final ValueChanged<bool> onChaolingChanged;
  final VoidCallback onCurWuMinus;
  final VoidCallback onCurWuPlus;
  final VoidCallback onCurLingMinus;
  final VoidCallback onCurLingPlus;
  final VoidCallback onWuMinus;
  final VoidCallback onWuPlus;
  final VoidCallback onLingMinus;
  final VoidCallback onLingPlus;
  final VoidCallback onCalc;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: TgSpacing.cardPadding,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // frow 1：宝宝品种（超灵开关）
          _TgSwitchRow(
            label: '宝宝品种',
            hint: '（超灵品种：灵性10 加成 34%，普通 31%）',
            switchLabel: '超灵品种',
            value: isChaoling,
            showSwitchLabel: !compact,
            onChanged: onChaolingChanged,
          ),
          const SizedBox(height: TgSpacing.lg),
          // frow 2：当前资质
          _Label('当前资质', '（攻击 / 属性资质，按当前悟灵状态填写）'),
          const SizedBox(height: TgSpacing.sm),
          TextField(
            controller: baseController,
            keyboardType: TextInputType.number,
            style: TgType.body14.copyWith(color: tg.t1),
            cursorColor: tg.gold,
            decoration: const InputDecoration(hintText: '如 2200'),
          ),
          const SizedBox(height: TgSpacing.lg),
          // frow 3：当前悟性 / 当前灵性
          _StepperPair(
            left: _StepperField(
              label: '当前悟性',
              hint: '（反推裸资质）',
              value: curWu,
              onMinus: onCurWuMinus,
              onPlus: onCurWuPlus,
            ),
            right: _StepperField(
              label: '当前灵性',
              hint: '（反推裸资质）',
              value: curLing,
              onMinus: onCurLingMinus,
              onPlus: onCurLingPlus,
            ),
          ),
          const SizedBox(height: TgSpacing.lg),
          // frow 4：目标悟性 / 目标灵性
          _StepperPair(
            left: _StepperField(
              label: '目标悟性',
              hint: '（10级 +39.3%）',
              value: wu,
              onMinus: onWuMinus,
              onPlus: onWuPlus,
            ),
            right: _StepperField(
              label: '目标灵性',
              hint: '（10级 +31%，超灵+34%）',
              value: ling,
              onMinus: onLingMinus,
              onPlus: onLingPlus,
            ),
          ),
          const SizedBox(height: TgSpacing.lg),
          // 开始计算（主按钮 · 全宽）
          _PrimaryButton(label: '开始计算', onTap: onCalc),
        ],
      ),
    );
  }
}

/// 双栏步进器（`.frow` grid 1fr 1fr · gap 16）。
///
/// 两列并排需要每列 ≥ 步进器横向宽度（32+10+30+10+32=114）+ 间距，
/// 即整行需 ≥ 约 244px；极窄屏下自动改为上下堆叠，避免溢出。
class _StepperPair extends StatelessWidget {
  const _StepperPair({required this.left, required this.right});

  /// 两列并排所需最小整行宽度。
  static const double _minTwoCol = 260;

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _minTwoCol) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: TgSpacing.md),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(height: TgSpacing.lg),
            right,
          ],
        );
      },
    );
  }
}

/// 单个步进器域：label（含 hint）+ stepper。
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String hint;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, hint),
        const SizedBox(height: TgSpacing.sm),
        _Stepper(value: value, onMinus: onMinus, onPlus: onPlus),
      ],
    );
  }
}

/// 步进器（`.stepper`）：− [值] ＋，32px 圆角按钮。
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        _StepperButton(label: '−', enabled: value > kWuLingMin, onTap: onMinus),
        const SizedBox(width: TgSpacing.s10),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TgType.cell16.copyWith(
              color: tg.t1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: TgSpacing.s10),
        _StepperButton(
          label: '＋',
          enabled: value < kWuLingMax,
          onTap: onPlus,
        ),
      ],
    );
  }
}

/// 步进器按钮：32×32 · r9 · 加强描边 · hover 泛金 · disabled 30% 透明。
class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final usable = widget.enabled;
    final color = usable
        ? (_hover ? tg.gold2 : tg.t2)
        : tg.t2;
    final border = usable && _hover ? tg.goldTint(.4) : tg.borderHi;
    return Opacity(
      opacity: usable ? 1 : .3,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: usable ? widget.onTap : null,
            borderRadius: BorderRadius.circular(TgRadius.s9),
            child: Ink(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TgRadius.s9),
                border: Border.all(color: border, width: 1),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TgType.control15.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表单 label：主文 t2 · hint t3（对应 `.label` 内嵌 span）。
class _Label extends StatelessWidget {
  const _Label(this.text, this.hint);

  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        text: text,
        style: TgType.label.copyWith(color: tg.t2),
        children: [
          TextSpan(text: hint, style: TgType.label.copyWith(color: tg.t3)),
        ],
      ),
    );
  }
}

/// 超灵品种开关行（`.switch-row`）：左 label，右 switch。
class _TgSwitchRow extends StatelessWidget {
  const _TgSwitchRow({
    required this.label,
    required this.hint,
    required this.switchLabel,
    required this.value,
    required this.showSwitchLabel,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String switchLabel;
  final bool value;
  final bool showSwitchLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              style: TgType.label.copyWith(color: tg.t2),
              children: [
                TextSpan(
                  text: hint,
                  style: TgType.label.copyWith(color: tg.t3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: TgSpacing.s12),
        _TgSwitch(
          label: switchLabel,
          value: value,
          showLabel: showSwitchLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// 自定义开关（对应原型 `.switch`）：46×26 轨道 · 20 圆钮 · 金渐变选中。
class _TgSwitch extends StatelessWidget {
  const _TgSwitch({
    required this.label,
    required this.value,
    required this.showLabel,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool showLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 轨道：46×26 · 内边距2（+边框1 各侧）· 圆钮 20
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 46,
            height: 26,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? tg.goldTint(.14) : tg.inset2,
              borderRadius: TgRadius.pillShape,
              border: Border.all(
                color: value ? tg.gold : tg.borderHi,
                width: 1,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: value
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: value ? tg.gradGold : null,
                  color: value ? null : tg.t3,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: TgSpacing.s10),
            Text(
              label,
              style: TgType.label.copyWith(
                color: value ? tg.gold2 : tg.t3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 主按钮（`.btn-primary`）：金渐变 · 墨字 · 徽章投影 · hover 上浮提亮。
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -1 : 0, 0),
        decoration: BoxDecoration(
          gradient: tg.gradGold,
          borderRadius: TgRadius.btn,
          boxShadow: TgShadows.primaryButton,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: TgRadius.btn,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: TgRadius.btn,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Ink(
              height: 41,
              decoration: BoxDecoration(
                borderRadius: TgRadius.btn,
                // hover 提亮（brightness 1.08）
                gradient: _hover
                    ? tg.gradGold
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TgType.button.copyWith(
                    color: TgTokens.btnInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 结果卡（`.result-card`）：预估成品资质 + 评级 + 明细行 + 公式注。
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.compact});

  final PetCalcResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final r = result;
    return Container(
      width: double.infinity,
      padding: TgSpacing.cardPadding,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // res-label
          Text(
            '预估成品资质',
            style: TgType.note.copyWith(
              color: tg.t3,
              letterSpacing: 2,
            ),
          ),
          // res-main：大数字 + 评级徽章
          const SizedBox(height: TgSpacing.s14),
          Row(
            children: [
              Expanded(
                child: Text(
                  r.resultLocale,
                  style: TgType.numResult(tg.gold2).copyWith(
                    fontSize: compact ? 36 : 42,
                  ),
                ),
              ),
              const SizedBox(width: TgSpacing.s18),
              _GradeBox(grade: r.grade, blue: r.blueGrade),
            ],
          ),
          const SizedBox(height: TgSpacing.xs),
          // res-sub：评级文案 · 相对当前资质
          Text.rich(
            TextSpan(
              style: TgType.caption.copyWith(color: tg.t3),
              children: [
                TextSpan(text: r.gradeText),
                const TextSpan(text: ' · 相对当前资质 '),
                TextSpan(
                  text: r.pctText,
                  style: TgType.caption.copyWith(
                    color: tg.gold2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // res-rows：明细
          const SizedBox(height: TgSpacing.s18),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tg.border, width: 1)),
            ),
            child: Column(
              children: [
                _ResultRow(label: '推算裸资质', value: r.nakedLocale),
                _ResultRow(label: '当前悟性 / 灵性', value: r.currentWlText),
                _ResultRow(
                  label: '目标悟性 / 灵性',
                  value: r.targetWlText,
                  highlight: true,
                ),
                _ResultRow(
                  label: '超灵加成',
                  value: r.clText,
                  highlight: true,
                ),
                _ResultRow(
                  label: '满悟满灵估算',
                  value: r.maxEstLocale,
                  highlight: true,
                ),
                _ResultRow(label: '建议培养方向', value: r.tip, last: true),
              ],
            ),
          ),
          // note：公式说明
          const SizedBox(height: TgSpacing.md),
          _FormulaNote(),
        ],
      ),
    );
  }
}

/// 评级徽章（`.grade`）：52×52 · r14 · 金描边金底 · serif 26 评级字。
class _GradeBox extends StatelessWidget {
  const _GradeBox({required this.grade, required this.blue});

  final String grade;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tg.goldTint(.10),
        borderRadius: BorderRadius.circular(TgRadius.r14),
        border: Border.all(color: tg.goldTint(.45), width: 1),
      ),
      child: Text(
        grade,
        style: TgType.display26.copyWith(
          color: blue ? tg.tagBlue : tg.gold2,
        ),
      ),
    );
  }
}

/// 结果明细行（`.res-row`）：label t2 · value t1（高亮 gold2）。
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.last = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TgSpacing.s10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TgType.row13.copyWith(
              color: tg.t2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: TgSpacing.s12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TgType.row13.copyWith(
                color: highlight ? tg.gold2 : tg.t1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 公式说明（`.note`）：info 图标 + 文案，inset 底。
class _FormulaNote extends StatelessWidget {
  const _FormulaNote();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TgSpacing.s13,
        vertical: TgSpacing.s11,
      ),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(TgRadius.lg),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TgIcon('info', size: 15, color: tg.goldDp),
          const SizedBox(width: TgSpacing.s9),
          Expanded(
            child: Text(
              '官方系数表公式（17173 等资料站）：裸资 = 当前资质÷(1+当前悟性%)÷(1+当前灵性%)；'
              '目标资质 = 裸资×(1+目标悟性%)×(1+目标灵性%)。'
              '悟性：4级+3%、5级+8%、8级+23.5%、10级+39.3%；'
              '灵性：5级+11%、8级+22%、10级+31%（超灵品种+34%）。'
              '成长率与资质相互独立，不影响本计算。',
              style: TgType.note.copyWith(color: tg.t3, letterSpacing: 0),
            ),
          ),
        ],
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
    return Center(
      child: Column(
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
            '界面数据均为演示样例，正式版接入实战回归数值',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
        ],
      ),
    );
  }
}
