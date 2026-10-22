import 'package:flutter/material.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';

/// 金色渐变进度条 + 流光（对应设计稿 .prog>i::after）。
class GradientProgressBar extends StatefulWidget {
  const GradientProgressBar({required this.value, this.height = 10, super.key});

  final double value;
  final double height;

  @override
  State<GradientProgressBar> createState() => _GradientProgressBarState();
}

class _GradientProgressBarState extends State<GradientProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.value.clamp(0, 1)),
          duration: const Duration(milliseconds: 220),
          builder: (context, value, _) => Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0x14FFFFFF)),
              if (value > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    heightFactor: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [T.gold, T.deep]),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66D9B96C),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) {
                            final t = _shine.value * 6 - 3;
                            return Align(
                              alignment: Alignment(t, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.4,
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 完成 / 警告环形图标：描边动画（对应设计稿 .done-ring / .warn-ring）。
class AnimatedRing extends StatefulWidget {
  const AnimatedRing({this.warning = false, this.size = 92, super.key});

  final bool warning;
  final double size;

  @override
  State<AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<AnimatedRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            progress: _controller.value,
            warning: widget.warning,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.warning});

  final double progress;
  final bool warning;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    final center = Offset(size.width / 2, size.height / 2);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 30 * scale));

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..color = T.gold
      ..strokeCap = StrokeCap.round;

    final circleMetric = circle.computeMetrics().first;
    final circleT = (progress / 0.6).clamp(0.0, 1.0);
    canvas.drawPath(
      circleMetric.extractPath(0, circleMetric.length * circleT),
      circlePaint,
    );

    final shapeT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
    if (shapeT == 0) return;

    final shape = Path();
    if (warning) {
      shape
        ..moveTo(32 * scale, 18 * scale)
        ..lineTo(32 * scale, 38 * scale);
    } else {
      shape
        ..moveTo(20 * scale, 33 * scale)
        ..lineTo(29 * scale, 42 * scale)
        ..lineTo(45 * scale, 23 * scale);
    }

    final shapeMetric = shape.computeMetrics().first;
    canvas.drawPath(
      shapeMetric.extractPath(0, shapeMetric.length * shapeT),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scale
        ..color = T.gold2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (warning) {
      canvas.drawCircle(
        Offset(32 * scale, 46 * scale),
        2.4 * scale,
        Paint()..color = T.gold2,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.warning != warning;
}

/// 页面切换：淡入 + 轻微上移（对应设计稿 fadeUp）。
class FadeSlideSwitcher extends StatelessWidget {
  const FadeSlideSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// 供进度页使用的等宽小字。
TextStyle monoStyle(double size, Color color) => TextStyle(
  fontFamily: 'NotoSansSC',
  fontFamilyFallback: const ['Consolas', 'Menlo', 'monospace'],
  fontSize: size,
  color: color,
  height: 1.7,
);

String formatPercent(double value) => '${(value.clamp(0, 1) * 100).floor()}%';

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0.0 MB/s';
  final mb = bytesPerSecond / 1024 / 1024;
  return '${mb.toStringAsFixed(1)} MB/s';
}

String formatEta(Duration? eta) {
  if (eta == null) return '剩余 --';
  final seconds = eta.inSeconds;
  if (seconds <= 0) return '剩余 0 秒';
  return '剩余 $seconds 秒';
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
