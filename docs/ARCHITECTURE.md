# 架构约定（Feature-first）

本工程采用 **Feature-first 架构**：业务按 feature 垂直切分，每个 feature 内部再按
`domain / data / presentation` 三层组织，横向的基础设施集中在 `core`，跨 feature 复用的组件集中在 `shared`。

## 分层总览

```
┌─────────────────────────────────────────────┐
│  app（组合根：路由、主题、根组件）             │
├─────────────────────────────────────────────┤
│  features/<name>                            │
│   ├── presentation/  页面 / 组件 / 状态      │
│   ├── domain/        实体 + 仓储抽象（纯 Dart）│
│   └── data/          DTO + 数据源 + 仓储实现  │
├─────────────────────────────────────────────┤
│  shared/  跨 feature 复用的通用组件/工具       │
│  core/    跨 feature 的基础设施（不依赖业务）   │
└─────────────────────────────────────────────┘
```

依赖方向**永远单向向内**：

```
presentation ──► domain ◄── data
      │              │
      └──► core / shared（被任意层使用）
```

- `domain` **不依赖** Flutter 和任何外部库（纯 Dart），只定义实体与抽象接口。
- `data` 实现 `domain` 中定义的抽象，负责 DTO 转换、网络、本地存储。
- `presentation` 通过 Riverpod 消费 `data` 层注入的能力，不直接触碰网络/存储。
- `core` 提供基础设施（网络、存储、常量），不包含业务逻辑。
- 新增 feature 之间**不允许互相 import**；需要共享时提升到 `shared` 或 `core`。

## 每个 feature 的模板

以 `features/home` 为例：

```
features/home/
├── domain/
│   ├── entities/home_item.dart          # freezed 不可变实体
│   └── repositories/home_repository.dart # 仓储抽象接口
├── data/
│   ├── models/home_item_dto.dart        # DTO + toEntity 转换
│   ├── datasources/                     # 数据源（本地/远程可互换）
│   │   ├── home_data_source.dart        # 抽象
│   │   ├── local_home_data_source.dart  # 本地模拟实现
│   │   └── remote_home_data_source.dart # dio 实现
│   └── repositories/home_repository_impl.dart # 实现 + @riverpod 注入
├── presentation/
│   ├── pages/home_page.dart             # 一级 tab 页面（无 Scaffold/AppBar）
│   ├── pages/home_detail_page.dart      # 二级详情页（无 Scaffold/AppBar）
│   ├── widgets/home_item_card.dart      # 业务组件
│   └── providers/home_providers.dart    # @riverpod 状态类
└── home_routes.dart                     # @TypedGoRoute（/home + detail/:id）
```

## 状态管理约定（Riverpod 3.4 + 代码生成）

所有 provider 一律使用 `@riverpod` 注解，由 **riverpod_generator** 在 build_runner 时生成，
**不手写 provider 定义**。

- **数据层注入**：`@riverpod` 函数，与实现类放在同一文件（`xxx_repository_impl.dart`）。
- **页面状态**：`@riverpod class X extends _$X`（同步 `Notifier`）或返回
  `Future` 的异步状态类（自动生成 `AsyncNotifierProvider`）。
- **派生状态**：`@riverpod` 函数基于已有 provider 计算，如 `themeModeProvider`。
- **命名规则**：函数 `foo(Ref ref)` → `fooProvider`；类 `Foo extends _$Foo` → `fooProvider`。
- **UI 订阅**：页面使用 `ConsumerWidget` + `ref.watch`；事件处理用 `ref.read(...notifier)`。
- **统一异步视图**：使用 `shared/widgets/app_async_view.dart` 的 `AppAsyncView`
  统一渲染 loading / error / data，页面不再各自写状态分支。

```dart
// 数据层注入：@riverpod 函数
@riverpod
HomeRepository homeRepository(Ref ref) {
  final dataSource = AppConstants.useLocalDataSource
      ? const LocalHomeDataSource()
      : RemoteHomeDataSource(ref.watch(dioProvider));
  return HomeRepositoryImpl(dataSource);
}
```

```dart
// 页面状态：@riverpod 类（异步，自动生成 homeItemsProvider）
@riverpod
class HomeItems extends _$HomeItems {
  @override
  Future<List<HomeItem>> build() =>
      ref.watch(homeRepositoryProvider).fetchHomeItems();

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).fetchHomeItems(),
    );
  }
}
```

> ⚠️ 命名注意：`@riverpod` 状态类的类名**不能与实体同名**（会与
> `extends _$X` 生成的基类冲突）。如实体 `AppSettings`，状态类用
> `AppSettingsController`（生成 `appSettingsControllerProvider`）。

## 依赖注入

- 全局能力在 `lib/core/di/providers.dart` 定义（`dioProvider`、`sharedPreferencesProvider`、
  `localStorageProvider`，均为 `@riverpod`）。
- `sharedPreferencesProvider` 在 `main()` 中通过 `ProviderScope(overrides: [...])` 注入真实实例，
  便于测试时替换。
- feature 内部的仓储 provider 负责把 `core` 的能力组装给 `presentation`。

## 数据目录（`lib/core/content/`）

静态数据（门派神器、技能、兽灵…）支持「内置基线 + 远端热更新」，
数据与代码分离：改数据不必发版。服务端契约见
[`server/cloudbase/README.md`](../server/cloudbase/README.md)「数据目录」一节。

| 文件 | 职责 |
| --- | --- |
| `catalog_manifest.dart` | 清单模型（`kind` / `schemaVersion` / `sha256`），对外部数据容错 |
| `catalog_remote_source.dart` | `GET manifest.json` / `GET {kind}.json`，支持 `If-None-Match` → 304 |
| `catalog_storage*.dart` | 缓存介质：原生=文件，Web=SharedPreferences（条件导入） |
| `catalog_cache.dart` | `pending` / `active` 两套 key，激活前校验 sha256 |
| `catalog_repository.dart` | 优先级与降级，`refresh()` 永不抛异常 |
| `catalog_providers.dart` | `catalogRepositoryProvider` / `catalogBootstrapProvider` |

**读取优先级**：本地缓存 → 内置 `assets/catalog/` → 空（`null`，调用方兜底）。

**更新语义**：启动后后台检查一次（TTL 12h），下载校验通过后写进 `pending`，
**下次启动**由 `init()` 激活 —— 不在会话中途换数据，避免页面正在读的列表突变。

**分片约定**：

- `kind`：全小写、点分隔，如 `job.artifacts` / `pet.beast_spirits`；
- 分片顶层必须含 `schemaVersion`（结构版本）与 `dataVersion`（内容版本）；
- 内置基线路径 `assets/catalog/manifest.json` 与 `assets/catalog/<kind>.json`；
- 分级版本：`schemaVersion` 高于客户端支持值时整包忽略（等 App 升级）。

**开关**：`--dart-define=CATALOG_BASE_URL=...`，**默认复用 `SYNC_BASE_URL`**
（两者是同一个 CloudBase 环境域名，只是路径不同），因此通常只需配 `SYNC_BASE_URL`；
都不配 = 完全离线，不产生网络请求；显式传空的 `CATALOG_BASE_URL=` 可单独关掉远端数据。
接入新 feature 时，在它自己的 data 层调用：

```dart
final repo = await ref.watch(catalogRepositoryProvider.future);
final raw = await repo.loadShard('job.artifacts'); // null = 用代码兜底
```

**已接入的分片**（10 个）：

| feature | 分片 | 入口 |
| --- | --- | --- |
| job | `job.sects` / `job.artifacts` / `job.skills` / `job.sect_info` / `job.wudao` | `data/job_catalog.dart` · `data/job_artifacts_repository.dart` |
| pet | `pet.beast_spirits` / `pet.beast_souls` / `pet.suits` / `pet.skills` | `data/pet_catalog.dart` |

> `job.point`（成长系数 / 权重）也已发布到云端，但**计算器仍读常量**：
> 这些数值参与纯函数计算（`recommendPoints` / `computePreview` / `suitMatsCalc`），
> 迁移需要把参数一路透传，留待后续。

模式为三层：

1. `data/xxx_parser.dart` —— 分片 JSON → 领域实体（坏条目跳过，不整体失败）；
2. `data/xxx_repository.dart` —— `@riverpod` 读分片，读不到/解析失败回退领域常量；
3. `presentation` —— 两种取数写法，按页面骨架选：

   - **整页依赖数据**（如职业神器页）：`AppAsyncView` + `ref.watch(...)`；
   - **数据只是页面一部分**（其余 7 个页面）：`ref.watch(xxx).value ?? 常量`，
     首帧直接用常量渲染，分片读好后自动重建，**不出现 loading 空档**。

   两种写法都保留常量兜底：分片缺失 / 解析失败时页面照常可用。

> Widget 测试里 `rootBundle` 走真实文件 I/O，会被 `pumpAndSettle` 的假时钟卡住：
> 页面的 widget 测试直接覆盖数据 provider，内置资产与常量的一致性由
> `test/features/job/job_artifacts_repository_test.dart` 单独校验。

> 服务端存的是**原文**（`text` 而非 `jsonb`），客户端按 manifest 的 sha256 校验，
> 所以分片不要在下发前二次格式化。

## 路由约定（go_router + go_router_builder）

- 每个 feature 在根部定义 `<name>_routes.dart`，用 `@TypedGoRoute` 声明路由类：

  ```dart
  @TypedGoRoute<SettingsRoute>(path: '/settings')
  class SettingsRoute extends GoRouteData with $SettingsRoute {
    const SettingsRoute();

    @override
    Widget build(BuildContext context, GoRouterState state) =>
        const SettingsPage();
  }
  ```

- 生成的 `$appRoutes` 列出该文件全部路由；`lib/app/router/app_router.dart`
  把各 feature 的 `$appRoutes` 作为 **tab 分支**聚合进 shell 路由：

  ```dart
  import '../../features/home/home_routes.dart' as home;
  import '../../features/settings/settings_routes.dart' as settings;

  GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShellNavigation(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [...home.$appRoutes]),      // tab 1
          StatefulShellBranch(routes: [...settings.$appRoutes]),  // tab 2
        ],
      ),
    ],
  );
  ```

- 页面内**类型安全跳转**：`HomeDetailRoute(id).push(context)`（替代字符串路径）。

## Shell 导航框架（`lib/app/shell_navigation/`）

根路由为 `StatefulShellRoute.indexedStack`，`AppShellNavigation` 统一提供应用框架。

### 响应式布局

按窗口宽度（非平台）自适应，断点与枚举定义在 `core/responsive/breakpoints.dart`：

| 宽度 | DeviceLayout | 布局 |
| --- | --- | --- |
| `< 900` | mobile | 信息条 + 内容区 + 底部 `NavigationBar` |
| `≥ 900` | desktop | 左侧全高 `NavigationRail`，右侧 = 顶部信息条 + 底部内容区 |

- `AppShellNavigation` 内用 `LayoutBuilder` 读取宽度并分支两种布局。
- 信息条用**自绘 `_InfoBar` 容器**（非 `AppBar`）：`AppBar` 内嵌 `Column` 会与测试的
  `pumpAndSettle` 死锁，且信息条语义上用普通容器更合适。
- **内容区限宽**：设置/详情页等表单类页面用 `DesktopContentConstraint`（≤840 居中），
  避免宽屏下被拉得过宽。
- **列表自适应**：首页列表用 `LayoutBuilder` 按宽度计算 `GridView` 列数（宽屏 2~3 列）。
- 页面级细节按需用 `LayoutBuilder` / `MediaQuery.sizeOf`，不引入全局 provider。

### 关键约定

- **顶部公共信息条**：显示当前路由名（取自 `@TypedGoRoute` 的 `name:`）；
  当前为二级页面时显示返回按钮（回到该 tab 分支根页面）。
- **一级页面 = tab 分支根路由**（如 `/home`、`/pet`），**二级页面 = 分支内嵌套路由**
  （如 `/pet/calc`，通过 `@TypedGoRoute` 的 `routes:` 声明）。
- **同一分支可聚合多个 feature 的顶层路由**：分支按 URL 匹配而非「一个分支一个
  feature」，所以 `StatefulShellBranch(routes: [...misc.$appRoutes, ...settings.$appRoutes])`
  就是让 settings 的 `/misc/settings` 与本分支平级（「二级页面」按路径段数兜底，
  `segmentCount > 1` 即二级）。
- 兽灵 · 兽魂并入珍兽时采用了更彻底的方案：代码整体迁入 `features/pet/`，3 个工具
  在 `pet_routes.dart` 里作为 `/pet` 的嵌套子路由声明（location 保持 `/pet/beast/*`），
  因此不再需要跨 feature 聚合 `$appRoutes`。
- **页面自身不写 Scaffold/AppBar**（避免与 shell 信息条嵌套），只负责内容区。
- 信息条状态由 `shellNavigationProvider`（`@riverpod`，监听 `routerDelegate`）推导：
  路由匹配树中超过 2 层（shell + 分支根 + …）即判定为二级页面。

> ⚠️ 版本注意：`go_router` 固定在 **17.x**（配合 go_router_builder 4.4.1）。
> `go_router 18` 引入了 `material_ui` 传递依赖，其 1.1.0 在 Flutter 3.47 下编译失败
> 会导致 `flutter test` 挂起。升级 Flutter 到能编译 `material_ui` 的版本后再升 go_router。

## UI 组件分层（widgets）

组件分三层放置，**新增组件前先确认是否已有同层实现**（避免同一形态在多个页面各写一份）：

| 层 | 位置 | 放什么 |
| --- | --- | --- |
| 全局共享 | `lib/shared/widgets/` | 与业务无关、跨 feature 复用的原子组件：`TgCard` / `TgCardPadding`（响应式卡片壳，`decoration` 可省 = 通用卡片外观）、`TgPageFoot`（页脚：64×1 分隔线 + 居中说明文案，可两行）、`TgNoteBar`（说明条：`gold` / `plain` / `danger` 三配色，纯文本或富文本）、`TgBarRow`（占比条行：label + 6px 轨道 + 金渐变 + 尾部值）、`TgPageHead` / `TgSelect` / `TgTextField` / `TgSwitch` / `TgSegmented` / `TgIcon` / `TgModalShell` / `TgImageGallery` / `TgScrollTopButton` / `SliverTopbarSpacer`（吸顶内容的顶栏遮挡占位）/ `PinnedSearchHeaderDelegate` + `TgSearchBox`（行情页「在售明细」吸顶搜索框）/ `AppAsyncView` |
| 模块内共享 | `lib/features/<feature>/presentation/widgets/` | 只在本 feature 多个页面成型、且带业务语义的组件（job 的 `job_common.dart` / `job_mini_button.dart`；misc 的 `misc_common.dart` / `misc_detail_widgets.dart`） |
| 页面私有 | 页面文件内 `_Xxx` | 绑定该页数据模型、只此一处使用的组件 |

判断口径：**能被 ≥2 个 feature 用上**（或已在多处重复）→ 上提 `shared/`；
只在本 feature 内多个页面成型 → 放本 feature `presentation/widgets/`；
只服务单页 → 留在页面文件内。

## 代码生成

build_runner 统一驱动四类生成器：

- `freezed` → `.freezed.dart`（不可变模型）
- `json_serializable` → `.g.dart`（JSON 序列化）
- `riverpod_generator` → `.g.dart`（provider）
- `go_router_builder` → `.g.dart`（类型安全路由）

修改模型 / provider / 路由后运行：

```sh
fvm dart run build_runner build
```

- 需要在 freezed 类里定义自定义方法时，**必须添加私有空构造函数**
  `const X._();`，否则生成代码 `implements` 本类、自定义方法不会被继承
  （参见 freezed 官方文档 "Adding getters and methods to our models"）。

## 错误处理

- 网络错误统一转为 `core/network/api_exception.dart` 的 `ApiException`。
- 仓储/数据源向上抛出领域友好异常，`presentation` 层只做展示与重试。

## 测试

- `test/app_test.dart`：widget 级冒烟测试（构建、tabbar 切换、二级页面返回按钮、设置持久化）。
- `test/features/<name>/`：对应 feature 的单元测试，如设置仓储的读写往返。
- 测试需先运行 `fvm dart run build_runner build` 生成代码。

## 新增 Feature 清单

1. `lib/features/<name>/domain`：实体 + 仓储抽象；
2. `lib/features/<name>/data`：DTO、数据源、仓储实现 + `@riverpod` 注入；
3. `lib/features/<name>/presentation`：页面（一级页面**不写 Scaffold/AppBar**）、组件、`@riverpod` 状态类；
4. `lib/features/<name>/<name>_routes.dart`：`@TypedGoRoute` 定义路由
   （一级 tab 用根路径 + `name:`，二级页面用嵌套 `routes:`）；
5. 在 `lib/app/router/app_router.dart` 前缀导入，把 `$appRoutes` 作为一个
   `StatefulShellBranch` 追加，并在 `AppShellNavigation._tabs` 中补一个 tab 项；
   若只是并入既有分类（而非新开一级 tab），则把 `$appRoutes` 追加进该分类的
   分支，并在 `shared/tools/tool_catalog.dart` 里把工具的 `category` 指向该分类，
   `_tabs` 不变；
6. 运行 `fvm dart run build_runner build` 生成全部代码；
7. 补充 `test/features/<name>/` 单元测试。
