# AGENTS.md

> 给 AI coding agent 的项目操作手册。**动手前先读完本文件**，可省掉大量探索成本。
> 架构细节见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)，技术栈见 [`README.md`](README.md)。

---

## 1. 项目定位

天龙八部（TLBB）工具箱 —— **Feature-first 架构**的 Flutter 应用（Android / iOS / macOS / Windows / Linux / Web 多端）。

技术栈：Flutter 3.47.0 (Dart 3.13.0) · Riverpod 3.4（`@riverpod` 代码生成）· go_router 17 + go_router_builder · freezed 4 + json_serializable · dio 5 · shared_preferences · flutter_gen。

---

## 2. 命令（**必须用 `fvm` 前缀**）

本项目 SDK 由 FVM 锁定在 `3.47.0`（`fvm_config.json`），**裸 `flutter` / `dart` 不在正确版本上，不要使用**。

| 目的 | 命令 |
| --- | --- |
| 拉依赖 | `fvm flutter pub get` |
| 代码生成（一次性） | `fvm dart run build_runner build` |
| 代码生成（监听，推荐边改边生成） | `fvm dart run build_runner watch` |
| 静态检查 | `fvm flutter analyze` |
| 格式检查（不改文件，不适则非 0 退出） | `fvm dart format --output=none --set-exit-if-changed lib test` |
| 格式化写回 | `fvm dart format lib test` |
| 全量测试 | `fvm flutter test` |
| 单文件测试 | `fvm flutter test test/features/job/job_wudao_page_test.dart` |
| 运行 App | `fvm flutter run` |
| Release APK | `fvm flutter build apk --release`（约 60s） |

**改完代码的标准验证序列**：`fvm dart run build_runner build` → `fvm flutter analyze` → `fvm flutter test`。

VS Code 里已预置同名 task：「Dart: 格式检查（不改文件）」/「Dart: 格式化写回」。

---

## 3. 关键约定

### 分层（单向依赖，feature 之间禁止互相 import）

```
presentation ──► domain ◄── data
      └──► core / shared
```

- `domain/`：纯 Dart 实体 + 仓储抽象，**不依赖 Flutter 和任何外部库**。
- `data/`：DTO + 数据源 + 仓储实现，负责网络/存储与实体转换。
- `presentation/`：页面与业务组件，经 Riverpod 消费 `data`，**不直接触碰网络/存储**。
- 跨 feature 复用提升到 `shared/`，基础设施放 `core/`。

### 导入

- `lib/` 内**一律用 `package:tlbbtoolkit/...` 绝对导入**，禁止 `../../` 相对路径
  （已由 lint `always_use_package_imports` 强制）。
- 例外：`part` / `part of` 指令按 Dart 语法必须相对路径；`lib/gen/`、
  `*.g.dart`、`*.freezed.dart` 是生成文件，不手改。
- 好处：深层路径一眼可读、文件移动不失效；import 里能直接看出跨 feature 引用，
  便于守住「feature 之间禁止互相 import」。

### Riverpod 3.4

- **所有 provider 一律用 `@riverpod` 注解 + 代码生成，禁止手写 provider 定义。**
- 页面状态用 `@riverpod class X extends _$X`（同步 `Notifier`）或返回 `Future` 的异步类。
- UI 订阅用 `ConsumerWidget` + `ref.watch`；事件处理用 `ref.read(...notifier)`。
- ⚠️ **`@riverpod` 状态类名不能与实体同名**（会与 `extends _$X` 生成的基类冲突）。如实体 `AppSettings` → 状态类 `AppSettingsController`。
- 异步 loading/error/data 统一用 `shared/widgets/app_async_view.dart` 的 `AppAsyncView`，页面不要各写分支。

### 路由

- 每个 feature 根部有 `<name>_routes.dart`，用 `@TypedGoRoute` 声明，`app/router/app_router.dart` 聚合。
- 一级 tab 页与二级详情页**都不写 `Scaffold` / `AppBar`**，外壳由 `app/shell_navigation/` 提供。

### 代码生成产物

- `*.g.dart` / `*.freezed.dart` / `lib/gen/` **是生成文件，永远不要手改**。
- 改了实体、provider、路由或 assets 后**必须重跑 build_runner**，否则编译报错。
- 新增 SVG 图标资产后：重跑 build_runner 生成 `lib/gen/assets.gen.dart`，并注册到 `TgIcon._paths`。

---

## 4. 已知坑（踩过的，别重复踩）

| 坑 | 说明与对策 |
| --- | --- |
| **FVM 启动锁卡死** | Dart 插件停在 "Initializing the Flutter SDK"：残留 flutter 进程占着 `bin/cache/lockfile`。用 `lsof /Users/hu/fvm/versions/3.47.0/bin/cache/lockfile` 找出并 `kill`。 |
| **Gradle APK 重命名** | Flutter Gradle 插件会强制把产物复制并重命名到 `build/app/outputs/flutter-apk/`，Code 里的 `variant.outputs` 对它无效。交付名修改点集中在 `android/app/build.gradle.kts` 末尾的 `finalizedBy` 任务，**不要动 Flutter 插件行为**。 |
| **ABI 名自带 `-`** | `armeabi-v7a` / `arm64-v8a` 不能用 `split("-")` 解析，要用已知前缀匹配。 |
| **`PopupMenuButton` 无界宽** | 作非弹性 `Row` 子项时会收到无界宽度，其 child `Row` 内不能再放 `Expanded` → 下拉容器须设 `maxWidth`；标题列用 `Expanded` 换行。 |
| **紧凑断点 560** | 大量表格在 `< 560` 宽度隐藏次要列（如 灵/悟、区服），改表格时注意保持无溢出。 |
| **清理 `build` / `.dart_tool` 后** | 必须重新 `fvm flutter pub get`。 |
| **`.fvmrc` 是 YAML 陷阱** | FVM 4.x 只读 `fvm_config.json`（JSON）。`.fvmrc` 若存在会被当 JSON 解析导致 `FormatException`。 |
| **数据表靠 `dart format off` 保命** | `job_skill` / `job_wudao` / `job_artifact` / `job_sect_info` 四个 domain 文件的人工紧凑数据表（一行一个门派 / 一条记录，最长单行 3000+ 字符）由 `// dart format off` … `// dart format on` 豁免。**不要删这两行注释**，否则一跑格式化会被展开成上千行（实测 1024 行 → 5418 行）。 |

---

## 5. 测试约定

- `test/` 目录与 `lib/` **镜像对应**，页面测试放 `test/features/<feature>/`。
- 纯计算逻辑优先拆到 `domain/` 下的纯函数并单独测试（如 `pet_market_stats_test.dart`）。
- widget 测试通过构造参数注入 mock 数据源（页面构造器提供可注入的 fetch 函数），网络层用 mock Dio adapter。
- 涉及 `Timer` 的测试（如倒计时）需在末尾 `pump` 足够时长消化，否则报 pending timer。

---

## 6. 边界（不要做）

- 不要提交 `build/`、`.dart_tool/`、`.fvm/flutter_sdk/`。
- 不要手改生成文件；不要在 `domain/` 引入 Flutter 依赖。
- 不要新增第三方依赖前不打招呼 —— 先说明理由。
- **任何 API Key / 密钥不要写进源码或提交到仓库**。
- 不要改动 `android/app/build.gradle.kts` 中的 APK 交付命名逻辑（见坑表），除非明确要求。
