# 代码签名策略

本项目的 Windows 发行包使用 [SignPath.io](https://signpath.io/) 提供的签名服务，
证书由 [SignPath Foundation](https://signpath.org/) 颁发。

## 签名范围

以下产物在发布流水线中签名：

| 产物 | 说明 |
| --- | --- |
| `TiangongGe-Setup-<版本>-win64.exe` | 面向用户的单文件安装程序 |
| `tiangongge_installer.exe`（含其运行时目录） | 自绘安装 / 卸载向导，安装后复制为 `<安装目录>\.uninstaller` |
| `tlbbtoolkit.exe` 及打包进 `payload.zip` 的 PE 文件 | 主程序本体 |

`payload.zip` 内的文件在打包前签名；安装器只做解压，不修改签名。

## 构建与签名流程

1. GitHub Actions（`.github/workflows/installer-release.yml`）在 `windows-latest` 上构建；
2. 主程序与安装器均以 `flutter build windows --release` 产出；
3. 由 SignPath.io 的签名步骤对上述产物签名，并附加 RFC 3161 时间戳；
4. 签名后的产物作为 GitHub Actions Artifact 上传，随后附加到 GitHub Release。

私钥由 SignPath.io 在 HSM 中生成与保管，本仓库不保存任何私钥或证书文件。

## 验证方式

```powershell
signtool verify /pa /v TiangongGe-Setup-<版本>-win64.exe
```

或在文件属性 → 数字签名中查看签名者应为 **SignPath Foundation**。

## 责任与限制

- 本项目不包含恶意代码，也不包含与项目功能无关的捆绑软件；
- 只有本仓库的维护者可以为本项目申请签名，且只对由本仓库源码构建的产物签名；
- 如发现签名产物与源码不一致，请提交 Issue 说明情况。

参考：[SignPath Foundation 条款](https://signpath.org/terms)
