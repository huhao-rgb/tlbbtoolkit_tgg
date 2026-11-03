# macOS 开发签名与 profile 刷新

面向 macOS 本机开发（`flutter run -d macos`）。发版与公证流程见
[`code-signing-policy.md`](code-signing-policy.md)，一次性配置见
[`scripts/setup-macos-signing.sh`](../scripts/setup-macos-signing.sh)。

## 症状

```
/…/macos/Runner.xcodeproj: error: No profiles for 'me.huhao.tools.tlbbtoolkit' were found:
Xcode couldn't find any Mac App Development provisioning profiles matching
'me.huhao.tools.tlbbtoolkit'. Automatic signing is disabled and unable to generate a profile.
To enable automatic signing, pass -allowProvisioningUpdates to xcodebuild.
(in target 'Runner' from project 'Runner')

** BUILD FAILED **
```

## 根因

两件事叠加：

1. **Flutter 不传 `-allowProvisioningUpdates`**。对比
   `flutter_tools/lib/src/ios/mac.dart`：iOS 路径在 `codesign` 为真时会追加
   `-allowProvisioningUpdates` 与 `-allowProvisioningDeviceRegistration`；
   macOS 路径（`macos/build_macos.dart`）的参数表里**没有**这两个 flag。
   于是 xcodebuild 被禁止访问 Apple 开发者网站，无法自动续签。
2. **免费个人团队的 profile 是临时的**。`Mac Team Provisioning Profile: <bundle-id>`
   由 Xcode 自动管理，`TimeToLive = 7`（天），过期就失效；`Automatic` 签名风格下
   Xcode 找不到有效 profile 又会因为 (1) 而无法自己续签，直接报错。

工程里的签名来源（`.gitignore` 忽略，不入库）：

| 文件 | 内容 |
| --- | --- |
| `macos/Runner/Configs/Signing.xcconfig` | `DEVELOPMENT_TEAM`、`CODE_SIGN_IDENTITY = Apple Development`、`TGG_ENTITLEMENTS_DIR = Runner/Signing` |
| `macos/Runner/Signing/*.entitlements` | 在仓库版基础上追加 `keychain-access-groups` |

`Runner` target 的 `CODE_SIGN_STYLE` 是 `Automatic`（Flutter 模板默认）。

## 修复

```sh
./scripts/macos-signing-refresh.sh          # 有效则跳过（约 0.1s），失效才续签
./scripts/macos-signing-refresh.sh --force  # 无条件续签
```

脚本做的事：

1. 读 `Signing.xcconfig`：**没有本地签名配置 / `DEVELOPMENT_TEAM` 为空时直接退出 0**
   —— 那种情况走 `CODE_SIGN_IDENTITY = -` 的 ad-hoc 兜底，本就不需要 profile；
2. 扫 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`，
   按「名字匹配 + Team 匹配 + 未过期（余量 > 1 天）」判定有效，有效即退出；
3. 失效时先跑 `fvm flutter build macos --debug --config-only` 刷新
   `macos/Flutter/ephemeral/Flutter-Generated.xcconfig`（否则 xcodebuild 的 Run Script
   阶段会用到上次 `flutter test` 残留的临时 target 而失败）；
4. 执行一次带 `-allowProvisioningUpdates` 的 `xcodebuild build`
   （`-derivedDataPath build/macos`，与 Flutter 共用增量产物）；
5. 复查 profile 是否已落盘，未落盘时给出排查清单并以非 0 退出。

Xcode 必须先登录过开发者账号（Xcode → Settings → Accounts），免费个人团队即可。

## 自动化点

| 入口 | 行为 |
| --- | --- |
| VS Code 两个 macOS 启动配置（`F5`） | `preLaunchTask` 调刷新脚本 |
| `scripts/build_macos_dmg.sh` | 构建前调刷新脚本（CI 无本地签名配置时自动跳过） |
| 任务面板「macOS: 刷新开发签名 profile」 | 手动触发 |

## 排查

| 现象 | 处理 |
| --- | --- |
| 脚本报「xcodebuild 成功但未找到匹配的新 profile」 | 检查 Xcode → Settings → Accounts 是否登录、Runner 的 Team 是否选了同一个团队 |
| 仍然 `No profiles` | 手动跑一次 `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug -destination 'platform=macOS' -allowProvisioningUpdates build` 看完整输出 |
| 构建成功但钥匙串写入抛 `-34018` | 说明当前是 ad-hoc 签名（没有生效的 `DEVELOPMENT_TEAM` / keychain-access-groups），云同步不可用；检查 `Signing.xcconfig` 与 `Runner/Signing/*.entitlements` |
| 想让 profile 长期有效 | 用付费开发者账号（Developer Program）签发，`Mac App Development` profile 有效期 1 年 |

验证签名与钥匙串：

```sh
codesign -dvvv build/macos/Build/Products/Debug/天工阁.app | grep -E "Authority|TeamIdentifier"
fvm flutter test integration_test/secure_storage_smoke_test.dart -d macos
```
