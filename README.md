# tlbbtoolkit

天龙八部（TLBB）工具箱 —— 基于 **Feature-first 架构**的 Flutter 应用脚手架。

## 技术栈

| 能力 | 方案 |
| --- | --- |
| 语言 | Dart 3.13 / Flutter 3.47（通过 [FVM](https://fvm.app) 管理版本） |
| 状态管理 / DI | [Riverpod 3.4](https://riverpod.dev)（`@riverpod` 代码生成） |
| 路由 | [go_router 17](https://pub.dev/packages/go_router) + go_router_builder（类型安全路由生成） |
| 网络 | [dio 5](https://pub.dev/packages/dio) |
| 本地存储 | shared_preferences（经 `LocalStorage` 封装） |
| 模型 / 序列化 | [freezed 4](https://pub.dev/packages/freezed) + json_serializable（build_runner 代码生成） |
| 代码生成 | build_runner 统一驱动（freezed / json_serializable / riverpod_generator / go_router_builder） |
| 代码规范 | flutter_lints |

> 版本：Flutter 3.47.0（Dart 3.13.0）由 `fvm_config.json` 锁定，使用 `fvm flutter ...` 运行。

## 快速开始

```sh
# 使用项目锁定的 Flutter 版本
fvm use

# 安装依赖
fvm flutter pub get

# 首次运行前生成全部代码（freezed/json/riverpod/go_router）
fvm dart run build_runner build

# 运行（默认使用本地模拟数据源）
fvm flutter run

# 接入真实后端
fvm flutter run --dart-define=API_BASE_URL=https://api.example.com \
                --dart-define=USE_LOCAL_DATA_SOURCE=false

# 启用「卡回归」云同步（地址为 CloudBase 环境，部署见 server/cloudbase/README.md）
fvm flutter run --dart-define=SYNC_BASE_URL=https://tgg-account-d8gd8q1mc16b81044.service.tcloudbase.com

# 静态检查
fvm flutter analyze

# 测试
fvm flutter test
```

> 💡 **VS Code 按 `F5` 已内置上述 define**（见 [`.vscode/launch.json`](.vscode/launch.json)）：
> *「天工阁 · macOS（云同步）」/「天工阁 · Chrome（云同步）」* 会自动带上 `SYNC_BASE_URL`，
> *「天工阁 · macOS（仅本地）」* 则不带，便于对照验证降级路径。
>
> ⚠️ `SYNC_BASE_URL` 是**编译期**注入（`String.fromEnvironment`），
> **不能**用 `export SYNC_BASE_URL=...` —— Flutter 不读操作系统环境变量。
> 同理 Release 包也要显式带上，否则发布版视为「未配置云同步」
> （降级为一次性同步码，不报错）：
>
> ```sh
> fvm flutter build apk --release \
>   --target-platform android-arm64 \
>   --dart-define=SYNC_BASE_URL=https://tgg-account-d8gd8q1mc16b81044.service.tcloudbase.com
> ```
>
> ⚠️ **必须带 `--target-platform android-arm64`**：不带时 Flutter 会把
> arm64-v8a / armeabi-v7a / x86_64 三套引擎与 AOT 产物全部打进同一个 APK
> （`.so` 合计约 60 MB，仅 arm64 约 20 MB）。32 位真机与 x86 模拟器没有实际用户。
>
> 🧪 **真实链路端到端测试**（打到真实云端，验证加密/合并/冲突在真网络上成立）：
> 默认**跳过**，只有注入 `SYNC_BASE_URL` 时才执行，CI 与离线开发不受影响。
>
> ```sh
> fvm flutter test test/features/misc/reg_sync_e2e_test.dart \
>   --dart-define=SYNC_BASE_URL=https://tgg-account-d8gd8q1mc16b81044.service.tcloudbase.com
> ```
>
> 每个用例用随机 syncId 建独立记录，结束即删除，不触碰既有数据。
>
> 发版流水线（[`release.yml`](.github/workflows/release.yml)）从仓库变量
> `vars.SYNC_BASE_URL` 读取该地址（Settings → Secrets and variables → Actions →
> Variables）。**未配置该变量时流水线只打一条 warning、照常出包**，但包里不含云同步功能。
> 地址粘贴时多一个末尾斜杠会被自动归一化（否则会拼成 `//reg` 而 404）。

## 目录结构

```
lib/
├── main.dart                  # 入口：初始化 + ProviderScope 注入
├── app/                       # 应用壳（组合根）
│   ├── app.dart               # 根组件 MaterialApp.router
│   ├── router/app_router.dart # 路由表（StatefulShellRoute 聚合各 tab 分支）
│   ├── shell_navigation/      # shell 导航框架（响应式）
│   │   ├── shell_navigation.dart  # 信息条 + 内容区 + tabbar/NavigationRail 双布局
│   │   └── shell_navigation_state.dart  # 当前路由名/是否二级页面（@riverpod）
│   └── theme/                 # 主题（明/暗）
├── core/                      # 跨 feature 的基础设施
│   ├── constants/             # 全局常量 / 接口路径
│   ├── di/providers.dart      # 全局 provider（dio / storage，@riverpod）
│   ├── network/               # dio 封装 + 统一异常
│   ├── responsive/breakpoints.dart  # 断点 + DeviceLayout + 限宽容器
│   ├── storage/               # LocalStorage 封装
│   ├── utils/                 # 工具（日志等）
│   └── widgets/               # （预留）
├── features/                  # 业务 feature（核心）
│   ├── home/                  # 示例：网络/异步数据流 + 二级详情页
│   │   ├── domain/            # 实体 + 仓储抽象（纯 Dart，不依赖 Flutter）
│   │   ├── data/              # DTO + 数据源 + 仓储实现 + 注入
│   │   ├── presentation/      # 页面 + 组件 + 状态 provider
│   │   └── home_routes.dart   # 类型安全路由（/home + detail/:id 二级路由）
│   ├── settings/              # 示例：本地持久化 + 设置（/misc/settings 二级页）
│   └── ...                    # 新 feature 参照 home 的目录模板
└── shared/                    # 跨 feature 共享的组件/工具
    └── widgets/               # AppAsyncView 等通用组件
```

### Shell 导航框架（响应式）

根路由是 `StatefulShellRoute.indexedStack`（见 [app_router.dart](lib/app/router/app_router.dart)），
`AppShellNavigation` 按窗口宽度自适应两种布局（断点 `≥900`，见 `core/responsive/breakpoints.dart`）：

```
mobile（<900）                    desktop（≥900）
┌─────────────────────────────┐  ┌───────────────────────────────┐
│ 信息条：当前路由名(+返回按钮)  │  │ 信息条：当前路由名(+返回按钮)   │
├─────────────────────────────┤  ├───────┬───────────────────────┤
│                             │  │ 工具箱 │                       │
│     内容区（当前 tab 分支）    │  │ (侧栏) │   内容区（限宽居中）     │
│                             │  │ 设置   │                       │
├─────────────────────────────┤  │       │                       │
│ [工具箱]      [设置]          │  └───────┴───────────────────────┘
└─────────────────────────────┘
```

- **mobile**（<900）：底部 `NavigationBar`；**desktop**（≥900）：左侧 `NavigationRail`；
- 一级页面 = tab 分支（`/home` 首页、`/pet` 珍兽、`/job` 职业、`/misc` 实用），
  切换保留各分支导航状态；同一分支可聚合多个 feature 的顶层路由
  （兽灵 · 兽魂一级页移除后，其工具作为 `pet` feature 的二级路由并入珍兽，
  location 仍为 `/pet/beast/*`）；
- 二级页面（如 `/home/detail/:id`）显示在分支栈内，信息条自动出现返回按钮；
- 页面本身**不写 Scaffold/AppBar**，统一由 shell 提供框架；
- 宽屏内容限宽：设置/详情页用 `DesktopContentConstraint`（≤840 居中）；首页列表用
  `LayoutBuilder` 自适应列数（宽屏网格）。

完整的架构约定见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 新增一个 Feature

1. 在 `lib/features/<name>/` 下创建 `domain / data / presentation` 三目录；
2. `domain`：定义实体（freezed）与仓储抽象接口；
3. `data`：实现数据源与仓储，用 `@riverpod` 函数完成注入；
4. `presentation`：编写页面、组件与 `@riverpod` 状态类（**一级页面不写 Scaffold/AppBar**，由 shell 提供）；
5. 在 feature 根部创建 `<name>_routes.dart` 用 `@TypedGoRoute` 定义路由（一级 tab 用根路径，二级页面用嵌套 `routes:`）；
6. 到 `lib/app/router/app_router.dart` 把该 feature 生成的 `$appRoutes` 作为一个 `StatefulShellBranch` 追加；
7. 运行 `fvm dart run build_runner build` 生成全部代码。

## 发版流程

一条命令完成：改版本号 → 写 `CHANGELOG` → 提交 → 打 tag → 推送，CI 接着构建并发布。
**发版日志默认是自动草稿，发之前建议手工过一遍**（见第 2 步）。

### 0. 前置条件

- 在 `main` 分支，且工作区干净——脚本发现未提交改动会直接退出；
- 版本号形如 `主.次.修订[+构建号]`（如 `1.1.1+7`），且**不能**与 `pubspec.yaml` 当前值相同；
- 仓库变量 `SYNC_BASE_URL` 已配置（Settings → Secrets and variables → Actions → Variables）。
  未配置时 CI 只打 warning 不失败，但打出的 APK **不含云同步功能**；
- 签名用到的 4 个 Secrets 已配置（见下节「正式签名」），缺失时 CI **直接失败**，不会产出 debug 签名的包。

### 1. 先预览草稿

```sh
./scripts/release.sh 1.1.1+7 --dry-run
```

只打印将要执行的操作和 `CHANGELOG` 草稿，**不写任何文件**。草稿取自「上一个 tag 以来的提交」，
按前缀归类：`feat:` → 新增，`fix:` → 修复，`perf:` / `refactor:` → 优化，其余 → 其他；
`chore: 修改版本号…` 与合并提交会被跳过。

### 2. 整理发版日志（三选一）

| 方式 | 命令 | 说明 |
| --- | --- | --- |
| 编辑器整理 | `./scripts/release.sh 1.1.1+7 --edit` | 预览后打开 `$VISUAL`/`$EDITOR`（未设置则 `vi`），在草稿上增删改 |
| 现成文件 | `./scripts/release.sh 1.1.1+7 --notes-file notes.md` | 用文件内容整段替换草稿；文件里没写 `## [版本] - 日期` 标题时自动补上 |
| 原样接受 | `./scripts/release.sh 1.1.1+7` | 草稿够用，直接确认 |

`--edit` 的操作顺序：在编辑器里改 → 保存退出（vi：`i` 编辑，`Esc`，`:wq` 回车）→ 脚本打印
「整理后的 CHANGELOG 条目」→ 询问 `确认无误？` → **输入完整的 `yes` 回车**。
`y`、`YES`、直接回车都会判定为取消，不改任何文件。加 `--yes` 跳过这道确认，可与 `--edit` 组合。

整理时顺手把 `## [未发布]` 里已包含在本版的内容清掉，避免和新条目重复。

> ⚠️ 不要在别的终端直接改 `CHANGELOG.md`：脚本插入的是它内存里的草稿，你的改动不会被采用。
> 想手写就用 `--notes-file`。

### 3. 脚本做了什么

1. 更新 `pubspec.yaml` 的 `version:`；
2. 把条目插到 `CHANGELOG.md` 第一个版本小节（通常是 `## [未发布]`）之前；
3. 提交 `chore: 修改版本号<版本号>`；
4. 打 tag `v<主.次.修订>`——**去掉 `+构建号`**，如 `1.1.1+7` → `v1.1.1`；
5. 推送 `main` 与 tag。

脚本只动 `pubspec.yaml` 和 `CHANGELOG.md`，不跑 `fvm` / `build_runner`（版本号变化不影响生成物）。

### 4. CI 做了什么

推送 `v*` tag 触发 [`.github/workflows/release.yml`](.github/workflows/release.yml)：
拉依赖 → `build_runner` 校验生成物 → 从 Secrets 还原 keystore → 构建 Release APK →
校验签名证书（是 debug 证书则失败）→ 从 `CHANGELOG.md` 抽取
`## [<版本>` 开头的小节作为发行说明 → 创建（已存在则更新）GitHub Release → 删除临时 keystore。
产物：`build/app/outputs/flutter-apk/app-release.apk`。

同一个 tag 还会触发 [`.github/workflows/installer-release.yml`](.github/workflows/installer-release.yml)
构建 Windows 安装包（`windows-latest`）：构建主程序 → 打包 payload → 构建安装器 →
封装单文件 Setup → **附加到同一个 GitHub Release**。Release 由本流程先创建，安装器流水线
先等它出现（最多 10 分钟）再上传；若始终没出现则自行按 `CHANGELOG` 创建。

Windows 产物（附在 Release 里）：

| 文件 | 说明 |
| --- | --- |
| `TiangongGe-Setup-<版本>-win64.exe` | 面向用户的单文件安装程序 |
| `TiangongGe-Installer-<版本>-win64.zip` | 安装器目录（含 `payload.zip`），便于排查问题 |

> ⚠️ **拉依赖用 `flutter pub get --enforce-lockfile`，且 job 级固定
> `PUB_HOSTED_URL: https://pub.dev`**（与 `pubspec.lock` 里记录的 source 一致）。
> 两者缺一不可：源不一致会让 pub 判定整个 lock 失效并**重新解析全部依赖**，
> 静默升级到刚发布的新版本 —— v1.1.2 的黑屏事故就是这么来的
> （`shared_preferences_android` 被升到 2.5.1，改用 Pigeon JNI，被 R8 混淆击穿）。
>
> 本机若设了国内镜像（`export PUB_HOSTED_URL=https://pub.flutter-io.cn`），
> **请去掉它**，否则本地 `fvm flutter pub get` 会因源不匹配改写 `pubspec.lock`，
> 又把仓库带偏。确实需要换源时，必须**连同 `pubspec.lock` 一起重新生成并提交**，
> 且同步修改 workflow 里的 `PUB_HOSTED_URL`。

### 4.1 正式签名（keystore 不入库）

签名材料**只存在两个地方**：本机 `android/key.properties` + `android/app/upload-keystore.jks`
（均被 `.gitignore` 排除），以及 GitHub 仓库的 Secrets。仓库里既没有 `.jks` 也没有口令。

配置一次即可，在 Settings → Secrets and variables → Actions → **Secrets** 里新建 4 条：

| Secret 名 | 值 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/app/upload-keystore.jks \| tr -d '\n' \| pbcopy`（macOS）的输出 |
| `ANDROID_STORE_PASSWORD` | `key.properties` 里的 `storePassword` |
| `ANDROID_KEY_ALIAS` | `key.properties` 里的 `keyAlias` |
| `ANDROID_KEY_PASSWORD` | `key.properties` 里的 `keyPassword` |

CI 侧：`base64 -d` 还原到 `$RUNNER_TEMP/release.jks`（`umask 077`，仅本次运行可见）→
以 `ANDROID_*` 环境变量传给 Gradle → 构建 → `apksigner` 校验证书 → `if: always()` 删除。
**keystore 不写进工作区、不生成 `key.properties`，也不会进日志或缓存。**

> 可选加固：再配一条仓库**变量** `ANDROID_CERT_SHA256`（证书 SHA-256 指纹，大小写/冒号不敏感）。
> 配置后 CI 会比对该指纹，防止 Secrets 里被换成别的 keystore 而静默发出不兼容的包。
> 当前证书指纹可用
> `keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | grep SHA256` 查到。

Gradle 侧（[`android/app/build.gradle.kts`](android/app/build.gradle.kts)）签名参数按优先级取：

1. `android/key.properties`（本机开发）；
2. `ANDROID_KEYSTORE_PATH` / `ANDROID_STORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` 环境变量（CI）；
3. 都缺失 → 回退 debug 签名并打 warning，只适合本地调试，**不可用于分发**。

> ⚠️ 换签名证书 = 换了 App 身份：已安装的用户必须卸载重装、商店需重新上传。
> 请把 `upload-keystore.jks` 与口令另行离线备份，**丢了就无法再发布升级包**。

### 5. 发布后自检

- Actions 里该 tag 的 workflow 全绿；
- Release 正文是你整理后的内容（CI 读的是 `CHANGELOG.md`，不是终端里的草稿）；
- 只是正文措辞要改：在 GitHub Release 页面直接编辑即可；想让仓库记录跟着对齐，
  再补一个 `docs:` 提交更新 `CHANGELOG.md`。

### 6. 打包失败 / 需要撤稿

tag 一旦推上去就会自动构建，失败时按情况处理：

```sh
# 删除已推送的 tag（GitHub 上残留的 Release 与失败 run 需到网页删除）
git push origin :refs/tags/v1.1.1
git tag -d v1.1.1
```

- **版本号已提交、包没发出去**：撤掉 `CHANGELOG.md` 里那条没发布的小节（`git revert` 或手工删除），
  别让日志留下「已发布」的假象；修好代码再发；
- **重发要换新的构建号**（如失败的是 `1.1.1+6`，重发用 `1.1.1+7`）：脚本会拒绝与
  `pubspec.yaml` 相同的版本号，同名 tag 也会冲突。

## 许可证

本仓库原创代码以 **MIT** 许可发布，见 [LICENSE](LICENSE)。

第三方字体、Dart/Flutter 依赖以及《天龙八部》相关的名称、图标与数值素材遵循各自的条款，
详见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

Windows 发行包的签名由 SignPath Foundation 提供，见
[代码签名策略](docs/code-signing-policy.md)；下载与安装说明见 [docs/download.md](docs/download.md)，
隐私说明见 [docs/privacy-policy.md](docs/privacy-policy.md)。
