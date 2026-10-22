import 'package:flutter/material.dart';
import 'package:tiangongge_installer/src/design/effects.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';
import 'package:tiangongge_installer/src/flow.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.progress;
    final log = progress.log.length > 5
        ? progress.log.sublist(progress.log.length - 5)
        : progress.log;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  progress.phase.isEmpty ? '正在准备…' : progress.phase,
                  style: T.sans(size: 14, color: T.t2),
                ),
              ),
              Text(
                formatPercent(progress.fraction),
                style: T.sans(
                  size: 30,
                  color: T.gold2,
                  weight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientProgressBar(value: progress.fraction),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatSpeed(progress.bytesPerSecond),
                style: T.sans(size: 11.5, color: T.t3),
              ),
              Text(
                formatEta(progress.eta),
                style: T.sans(size: 11.5, color: T.t3),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            height: 118,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x40000000),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomLeft,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < log.length; i++)
                      Text(
                        log[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: monoStyle(
                          11,
                          i == log.length - 1 ? T.gold2 : T.t3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 14),
            Text(
              '${controller.error}',
              style: T.sans(size: 12, color: const Color(0xFFE08C8C)),
            ),
          ],
        ],
      ),
    );
  }
}

class FinishHero extends StatelessWidget {
  const FinishHero({
    required this.title,
    required this.quote,
    required this.hint,
    this.children = const [],
    this.warning = false,
    super.key,
  });

  final String title;
  final String quote;
  final String hint;
  final List<Widget> children;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedRing(warning: warning),
          const SizedBox(height: 22),
          Text(
            title,
            style: T.sans(size: 22, weight: FontWeight.w600, letterSpacing: 3),
          ),
          const SizedBox(height: 14),
          Text(quote, style: T.serif(size: 15)),
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: T.sans(size: 12, color: T.t3, height: 1.8),
          ),
          if (children.isNotEmpty) ...[const SizedBox(height: 20), ...children],
        ],
      ),
    );
  }
}

class LogoSidebarTip extends StatelessWidget {
  const LogoSidebarTip({
    required this.leading,
    required this.highlight,
    required this.trailing,
    this.extra,
    super.key,
  });

  final String leading;
  final String highlight;
  final String trailing;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: leading),
              TextSpan(
                text: highlight,
                style: const TextStyle(
                  color: T.gold2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: trailing),
            ],
          ),
          style: T.sans(size: 11, color: T.t3, height: 1.7),
        ),
        if (extra != null) ...[
          const SizedBox(height: 6),
          Text(
            extra!,
            style: T.sans(
              size: 10.5,
              color: T.gold.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
