# 下载

天工阁（TLBB 工具箱）通过 GitHub Releases 分发。

## 下载地址

- Windows 安装程序与 Android APK：<https://github.com/huhao-rgb/tlbbtoolkit_tgg/releases>
- 源码仓库：<https://github.com/huhao-rgb/tlbbtoolkit_tgg>

## Windows 安装

1. 在 Releases 页面下载 `TiangongGe-Setup-<版本>-win64.exe`；
2. 双击运行，按向导完成安装（按用户安装到 `%LOCALAPPDATA%\Programs\TiangongGe`，无需管理员权限）；
3. 安装完成后可从桌面快捷方式或开始菜单启动。

支持 Windows 10 / 11 64 位。

## Android 安装

在 Releases 页面下载 `app-release.apk`，允许“安装未知来源应用”后安装。仅支持 arm64 设备。

## 功能

- 账号行情：按区服查询角色与商品行情，支持历史快照；
- 珍兽兽魂 / 兽灵图鉴：技能、资质与搭配查询；
- 宠物估价与套装计算；
- 数据速查：门派技能、神器、任务等离线数据表。

详细说明见 [README](../README.md)。

## 代码签名 / Code signing

本项目的 Windows 发行包使用 **[SignPath Foundation](https://signpath.org/) 提供的代码签名服务**，
签名由 SignPath.io 在 HSM 中完成，证书颁发给 SignPath Foundation。

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
