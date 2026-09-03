import 'package:flutter/widgets.dart';

/// 设备布局形态。
enum DeviceLayout {
  /// 移动端布局：底部 tabbar。
  mobile,

  /// 桌面端布局：左侧 NavigationRail 侧栏。
  desktop,
}

/// 响应式断点。
///
/// 按窗口宽度（而非平台）判断：桌面窗口可缩放、还有平板/折叠屏，
/// 宽度是唯一可靠的依据。本项目简化为两档：≥ [desktop] 视为桌面布局。
///
/// 断点值 1024 与 UI 原型（天工阁 · 天龙怀旧工具箱）一致：
/// 原型使用 `max-width:1023px` 隐藏侧栏、显示底部 tabbar，
/// 因此本实现以 1024 为"移动端 ↔ 桌面侧栏"的分界。
abstract final class Breakpoints {
  const Breakpoints._();

  /// 桌面布局的最小宽度（对齐 UI 原型 1024 断点）。
  static const double desktop = 1024;

  /// 根据宽度推导布局形态。
  static DeviceLayout layoutOf(double width) =>
      width >= desktop ? DeviceLayout.desktop : DeviceLayout.mobile;

  /// 内容区在桌面布局下的最大宽度（居中限宽，避免列表/表单被拉太宽）。
  static const double desktopContentMaxWidth = 840;

  /// 悬浮顶栏（毛玻璃）高度：页面滚动内容顶部需预留该高度，
  /// 使其在初始时不被悬浮栏遮挡，滚动时能滑入玻璃下方被模糊。
  static const double topbarOverlayHeight = 60;
}

/// 桌面内容区限宽容器：宽度超过 [Breakpoints.desktopContentMaxWidth] 时居中。
class DesktopContentConstraint extends StatelessWidget {
  const DesktopContentConstraint({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: Breakpoints.desktopContentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
