import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

/// 均衡器跳动条（对应原型 `.bgm-eq`）：
/// 3 根金色小柱（宽 2.5 · 圆角 1 · 间距 1.5 · 容器 14×12），
/// 高度按 `.9s` 周期循环，各柱依次延迟 `.25s`。
///
/// 仅在播放中才挂载（原型靠 `.on .eq-on{display:flex}` 控制显隐），
/// 停止播放时随 widget 一起销毁，动画自然停下。
class MusicEqBars extends StatefulWidget {
  const MusicEqBars({super.key});

  /// 容器宽（原型 `width:14px`）。
  static const double width = 14;

  /// 容器高（原型 `height:12px`）。
  static const double height = 12;

  @override
  State<MusicEqBars> createState() => _MusicEqBarsState();
}

class _MusicEqBarsState extends State<MusicEqBars>
    with SingleTickerProviderStateMixin {
  /// 动画周期（原型 `animation:bgmEq .9s ease-in-out infinite`）。
  static const Duration _period = Duration(milliseconds: 900);

  /// 相邻柱子的相位差（原型 `animation-delay:.25s` → 250/900 个周期）。
  static const double _phaseStep = 250 / 900;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 关键帧高度比例（原型 `0%→30% / 45%→100% / 70%→55% / 100%→30%`）。
  static double _heightFactor(double t) {
    if (t < .45) return .3 + .7 * (t / .45);
    if (t < .7) return 1 - .45 * ((t - .45) / .25);
    return .55 - .25 * ((t - .7) / .3);
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return SizedBox(
      width: MusicEqBars.width,
      height: MusicEqBars.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 1.5),
              Container(
                width: 2.5,
                height:
                    MusicEqBars.height *
                    _heightFactor((_controller.value + i * _phaseStep) % 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: tg.gradGold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
