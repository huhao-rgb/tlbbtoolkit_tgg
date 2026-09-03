import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // —— 启动不闪原生标题栏、不丢红绿灯 ——
    // 不要在这里提前改 styleMask/.fullSizeContentView（会丢失系统红绿灯）。
    // 改为先隐藏窗口，等 Flutter 首帧由 window_manager 应用
    // TitleBarStyle.hidden（保留红绿灯）后再由 Dart 侧 show() 显示。
    self.orderOut(nil)

    super.awakeFromNib()
  }
}

