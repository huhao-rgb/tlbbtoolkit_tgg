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
/// 宽度是唯一可靠的依据。阈值参考 Material 3 窗口尺寸类
/// （compact <600 / medium 600~840 / expanded ≥840），
/// 本项目简化为两档：≥ [desktop] 视为桌面布局。
abstract final class Breakpoints {
  const Breakpoints._();

  /// 桌面布局的最小宽度。
  static const double desktop = 900;

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
