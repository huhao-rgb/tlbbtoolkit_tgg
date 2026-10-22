# 天工阁 Windows 安装器

独立 Flutter 工程，实现「天工阁-Windows安装卸载界面设计稿」的自绘安装 / 卸载向导，
并内置解压、快捷方式、自启动、卸载注册表等安装引擎，不依赖 Inno Setup / NSIS。

## 目录

```
lib/
  main.dart                 入口（--uninstall 进入卸载向导）
  src/app.dart              无边框窗口、标题栏、侧栏、底部按钮条
  src/flow.dart             安装 / 卸载状态机
  src/design/               设计变量、控件、动效
  src/screens/              8 个界面
  src/engine/               安装 / 卸载引擎、路径、磁盘空间、系统集成
tool/
  package_payload.dart      把主程序 Release 目录打成 payload.zip
  build_windows.ps1         Windows 一键出包
```

## 本地预览（macOS / Windows）

```bash
cd installer
fvm flutter pub get
fvm flutter run -d macos      # Windows 用 -d windows
```

调试构建下没有 `assets/payload/payload.zip` 时会自动进入**演示模式**：界面、日志、速度、ETA 都正常，
但不会真正写文件 / 注册表（侧栏会标注“演示模式”）。Release 构建缺少 payload 会直接报错。调试构建左下角可切换安装 / 卸载向导。

## Windows 出包

```powershell
cd installer
pwsh -File tool\build_windows.ps1
```

脚本按顺序执行：

1. `fvm flutter build windows --release` 构建主程序；
2. `tool/package_payload.dart` 把 `..\build\windows\x64\runner\Release` 打成 `assets/payload/payload.zip`；
3. 用 `--dart-define=APP_VERSION=<主工程版本>` 构建安装器；
4. 如果安装了 NSIS（`choco install nsis`），再把安装器目录封装成单文件
   `dist\TiangongGe-Setup-<版本>-win64.exe`。

产物：

- 目录版：`build\windows\x64\runner\Release\`（exe + DLL + `data/` + payload）；
- 单文件版：`dist\TiangongGe-Setup-<版本>-win64.exe`（NSIS 静默解压后启动自绘向导）。

单文件外壳解压期间没有界面（约数秒），随后进入安装向导；`-SkipSfx` 可跳过封装，
`-SkipApp` / `-SkipInstaller` 用于只重跑其中一步。

## 安装行为

- 按用户安装：`%LOCALAPPDATA%\Programs\TiangongGe`，**不触发 UAC**；
- 用户数据：`%APPDATA%\TiangongGe`；
- 快捷方式：桌面（可选）与开始菜单；
- 卸载项：`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\{8F3C...}`；
- 卸载器：安装时把安装器运行时复制到 `<安装目录>\.uninstaller`，控制面板卸载指向它。

## 已知边界

- 卸载器自身目录在点击“关闭”后由隐藏的 PowerShell 延迟删除（按用户安装没有管理员权限，
  不能用 `MOVEFILE_DELAY_UNTIL_REBOOT`）；
- 安装 / 卸载前应退出天工阁主程序，被占用的文件会跳过并在日志中标注；
- 尚未接入代码签名，正式分发前需用 `signtool` 签名；
- 安装包与主程序需同版本构建，版本号由 `build_windows.ps1` 注入。
