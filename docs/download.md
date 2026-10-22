# 下载

天工阁（TLBB 工具箱）通过 GitHub Releases 分发。

## 下载地址

- Windows 安装程序 / macOS DMG / Android APK：<https://github.com/huhao-rgb/tlbbtoolkit_tgg/releases>
- 源码仓库：<https://github.com/huhao-rgb/tlbbtoolkit_tgg>

## Windows 安装

1. 在 Releases 页面下载 `TiangongGe-Setup-<版本>-win64.exe`；
2. 双击运行，按向导完成安装（按用户安装到 `%LOCALAPPDATA%\Programs\TiangongGe`，无需管理员权限）；
3. 安装完成后可从桌面快捷方式或开始菜单启动。

支持 Windows 10 / 11 64 位。

## Android 安装

在 Releases 页面下载 `TiangongGe-<版本>-arm64.apk`，允许“安装未知来源应用”后安装。
仅支持 arm64 设备（armeabi-v7a / x86_64 未随包分发）。

## macOS 安装

1. 在 Releases 页面下载 `TiangongGe-<版本>-macos-universal.dmg`（Intel + Apple 芯片通用，需 macOS 12+）；
2. 双击打开 DMG，在弹出的窗口里把左边的「天工阁.app」拖到右边的「Applications」，
   然后从启动台或「应用程序」中打开。

**首次打开会被系统拦截**（提示「无法验证开发者」或「Apple 无法验证…是否包含恶意软件」）。
本项目的 macOS 包**未做 Apple 公证**（没有付费开发者账号），这是正常现象，任选一种方式放行：

- **图形界面**：点弹窗的「完成」→ 打开「系统设置 → 隐私与安全性」→ 底部找到「天工阁」→
  点「仍要打开」→ 回到启动流程再点「打开」；
- **终端**：

  ```bash
  xattr -dr com.apple.quarantine "/Applications/天工阁.app"
  ```

> macOS 15（Sequoia）起，右键「打开」不再能绕过未签名应用，只能用上面两种方式。

卸载：退出应用后把「天工阁.app」拖到废纸篓；要清除全部数据，再删除
`~/Library/Containers/me.huhao.tools.tlbbtoolkit`。

## 功能

- 账号行情：按区服查询角色与商品行情，支持历史快照；
- 珍兽兽魂 / 兽灵图鉴：技能、资质与搭配查询；
- 宠物估价与套装计算；
- 数据速查：门派技能、神器、任务等离线数据表。

详细说明见 [README](../README.md)。

## 代码签名 / Code signing

本项目的 **Windows** 发行包使用 **[SignPath Foundation](https://signpath.org/) 提供的代码签名服务**，
签名由 SignPath.io 在 HSM 中完成，证书颁发给 SignPath Foundation。

**macOS 包未签名、未公证**（项目未购买 Apple Developer Program）。

> This project uses the [SignPath Foundation](https://signpath.org/) for code signing.
> The signing certificate is issued to the SignPath Foundation and the private key is
> kept in SignPath.io's HSM.

验证签名：

```powershell
signtool verify /pa /v TiangongGe-Setup-<版本>-win64.exe
```

签名策略见 [docs/code-signing-policy.md](code-signing-policy.md)。

## 已知限制

- 发行包未包含自动更新，需手动下载新版本覆盖安装；
- 首次下载时 Windows SmartScreen 可能提示“未知发布者”，这与签名信誉积累有关，
  点击“更多信息 → 仍要运行”即可。
