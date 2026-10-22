import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:tiangongge_installer/src/design/effects.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';
import 'package:tiangongge_installer/src/design/widgets.dart';
import 'package:tiangongge_installer/src/flow.dart';
import 'package:tiangongge_installer/src/screens/common.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Seal(character: '工', size: 96),
          const SizedBox(height: 22),
          Text(
            '天 工 阁',
            style: T.sans(size: 26, weight: FontWeight.w600, letterSpacing: 3),
          ),
          const SizedBox(height: 6),
          Text(
            '天龙怀旧工具箱 · v${controller.version} · Windows 64 位',
            style: T.sans(size: 12, color: T.t3),
          ),
          const SizedBox(height: 22),
          Text('「 工欲善其事，必先利其器 」', style: T.serif(size: 15)),
          const SizedBox(height: 12),
          Text(
            '为《天龙八部·怀旧服》玩家打造的桌面工具箱\n'
            '账号行情 · 珍兽兽魂 · 兽灵图鉴 · 数据速查\n\n'
            '建议关闭其他程序后继续',
            textAlign: TextAlign.center,
            style: T.sans(size: 12, color: T.t3, height: 1.8),
          ),
        ],
      ),
    );
  }
}

class LicenseAgreementPage extends StatelessWidget {
  const LicenseAgreementPage({required this.controller, super.key});

  final InstallerController controller;

  static const _sections = <(String, String)>[
    (
      '一、授权范围',
      '本软件为免费桌面工具，授予你在个人电脑上安装、使用的非独占、不可转让许可。'
          '你可以自由使用，但不得反向编译、篡改程序签名或用于商业转售。',
    ),
    (
      '二、数据来源声明',
      '软件内的行情、兽灵图鉴等数据由社区协作维护，仅供参考，不构成任何交易担保。'
          '游戏中相关内容（天龙八部等）的著作权归原著权利方与游戏运营方所有，本工具与官方无隶属关系。',
    ),
    (
      '三、本地数据',
      '你的收藏、行情记录与个性化配置仅保存在本机（%AppData%\\TiangongGe）。'
          '卸载时你可选择保留或一并删除，软件不会上传任何个人数据。',
    ),
    (
      '四、免责条款',
      '本软件按“现状”提供。对于因使用本软件造成的游戏账号风险、数据偏差或任何间接损失，'
          '作者不承担责任。请遵守游戏用户协议，合理使用第三方工具。',
    ),
    ('五、更新与支持', '软件可能在启动时检查更新，你可以在设置中关闭自动检查。'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: '用户许可协议',
          subtitle: '请在继续安装之前阅读以下条款。勾选底部复选框表示你已阅读并接受本协议。',
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0x40000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in _sections) ...[
                      Text(
                        section.$1,
                        style: T.sans(
                          size: 14,
                          color: T.gold2,
                          weight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.$2,
                        style: T.sans(size: 12.5, color: T.t2, height: 2),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      '—— 天工阁开发组 · v${controller.version}',
                      style: T.sans(size: 11, color: T.t3, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CheckLine(
          checked: controller.agreed,
          label: '我已阅读并同意上述协议条款',
          onTap: controller.toggleAgreed,
        ),
      ],
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.installDir,
  );
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _focus.addListener(() => setState(() {}));
  }

  void _sync() {
    if (!_focus.hasFocus && _text.text != widget.controller.installDir) {
      _text.text = widget.controller.installDir;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    final selected = await getDirectoryPath(
      initialDirectory: widget.controller.installDir,
      confirmButtonText: '选择文件夹',
    );
    if (selected != null && selected.isNotEmpty) {
      widget.controller.browseInstallDir(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final disk = controller.disk;
    final required = controller.engine.payload.requiredBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '选择安装位置',
          subtitle: '天工阁将安装到以下文件夹（至少需要 ${formatBytes(required)} 可用空间）。',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  onChanged: controller.setInstallDir,
                  style: T.sans(size: 13, color: T.t1),
                  cursorColor: T.gold,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0x33000000),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: T.gold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AppButton(label: '浏览…', onPressed: _browse),
          ],
        ),
        const SizedBox(height: 26),
        _DiskBar(
          label: _diskLabel(controller.installDir),
          available: disk == null ? null : formatBytes(disk.available),
          required: formatBytes(required),
          usedFraction: disk?.usedFraction ?? 0,
          requiredFraction: disk == null || disk.total == 0
              ? 0
              : required / disk.total,
        ),
        const SizedBox(height: 22),
        Text(
          '※ 也可以安装到其他磁盘；数据与缓存始终保存在用户目录下，不会写入安装文件夹。',
          style: T.sans(size: 12.5, color: T.t3, height: 1.7),
        ),
      ],
    );
  }

  String _diskLabel(String dir) {
    if (!Platform.isWindows) return '磁盘';
    final root = p.rootPrefix(p.absolute(dir));
    if (root.isEmpty) return '磁盘';
    return '${root.replaceAll(RegExp(r'[\\/]'), '')}: 盘（系统）';
  }
}

class _DiskBar extends StatelessWidget {
  const _DiskBar({
    required this.label,
    required this.available,
    required this.required,
    required this.usedFraction,
    required this.requiredFraction,
  });

  final String label;
  final String? available;
  final String required;
  final double usedFraction;
  final double requiredFraction;

  @override
  Widget build(BuildContext context) {
    final used = (usedFraction <= 0 ? 0.003 : usedFraction.clamp(0.003, 1))
        .toDouble();
    final need =
        (requiredFraction <= 0 ? 0.003 : requiredFraction.clamp(0.003, 1))
            .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: T.sans(size: 12, color: T.t3)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: available == null ? '可用空间读取中…' : '可用 $available',
                    style: const TextStyle(
                      color: T.t2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' / 安装需 $required'),
                ],
              ),
              style: T.sans(size: 12, color: T.t3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x12FFFFFF)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: used,
                    heightFactor: 1,
                    child: const ColoredBox(color: Color(0x38FFFFFF)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: need,
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [T.gold, T.deep]),
                        boxShadow: [
                          BoxShadow(color: Color(0x66D9B96C), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ComponentsPage extends StatelessWidget {
  const ComponentsPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '选择附加组件', subtitle: '以下组件可选；核心程序始终安装。'),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const CheckCard(
                  checked: true,
                  locked: true,
                  title: '天工阁主程序',
                  tag: '必装',
                  description: '工具箱核心：账号行情、珍兽兽魂、兽灵图鉴、宠物估价',
                ),
                const SizedBox(height: 12),
                CheckCard(
                  checked: controller.desktopShortcut,
                  onTap: controller.toggleDesktopShortcut,
                  title: '桌面快捷方式',
                  description: '在桌面创建「天工阁」图标，双击即达',
                ),
                const SizedBox(height: 12),
                CheckCard(
                  checked: controller.autostart,
                  onTap: controller.toggleAutostart,
                  title: '开机自启动',
                  description: '登录 Windows 后在后台启动，随时唤起（可稍后在设置中更改）',
                ),
                const SizedBox(height: 12),
                CheckCard(
                  checked: controller.offlineData,
                  onTap: controller.toggleOfflineData,
                  title: '行情离线数据包 · 约 120 MB',
                  description: '预置近 90 天行情快照，离线也能查询；不选则首次启动联网拉取',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class InstallProgressPage extends StatelessWidget {
  const InstallProgressPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) => ProgressView(controller: controller);
}

class InstallFinishPage extends StatelessWidget {
  const InstallFinishPage({required this.controller, super.key});

  final InstallerController controller;

  @override
  Widget build(BuildContext context) {
    return FinishHero(
      title: '安装完成',
      quote: '工具已备，山河可期',
      hint: '安装位置：${controller.installDir}',
      children: [
        CheckLine(
          checked: controller.runAfter,
          label: '立即运行 天工阁',
          onTap: controller.toggleRunAfter,
        ),
        const SizedBox(height: 10),
        CheckLine(
          checked: controller.desktopShortcut,
          label: '创建桌面快捷方式',
          onTap: controller.toggleDesktopShortcut,
        ),
      ],
    );
  }
}
