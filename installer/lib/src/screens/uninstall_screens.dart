import 'package:flutter/material.dart';
import 'package:tiangongge_installer/src/design/effects.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';
import 'package:tiangongge_installer/src/design/widgets.dart';
import 'package:tiangongge_installer/src/flow.dart';
import 'package:tiangongge_installer/src/screens/common.dart';

class UninstallConfirmPage extends StatelessWidget {
  const UninstallConfirmPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedRing(warning: true),
          const SizedBox(height: 22),
          Text(
            '确定要卸载 天工阁 吗？',
            style: T.sans(
              size: 21,
              weight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '卸载将从计算机移除主程序及其组件\n'
            '版本 v${controller.version} · ${controller.installDir}',
            textAlign: TextAlign.center,
            style: T.sans(size: 12, color: T.t3, height: 1.8),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: CheckCard(
              checked: controller.keepUserData,
              onTap: controller.toggleKeepUserData,
              title: '保留用户数据（推荐）',
              description: '收藏、行情记录与配置保留在 %AppData%\\TiangongGe，重装后自动恢复',
            ),
          ),
        ],
      ),
    );
  }
}

class UninstallProgressPage extends StatelessWidget {
  const UninstallProgressPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) => ProgressView(controller: controller);
}

class UninstallFinishPage extends StatelessWidget {
  const UninstallFinishPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    return FinishHero(
      title: '卸载完成',
      quote: '天下无不散之筵席，江湖再见',
      hint: controller.keepUserData
          ? '已保留你的收藏与配置\n位置：%AppData%\\TiangongGe（重装后自动恢复）'
          : '已连同本地数据一并清除',
    );
  }
}
