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
│   ├── pages/home_page.dart             # 页面（ConsumerWidget）
│   ├── widgets/home_item_card.dart      # 业务组件
│   └── providers/home_providers.dart    # @riverpod 状态类
└── home_routes.dart                     # @TypedGoRoute 类型安全路由
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
  用**前缀导入**聚合各 feature 的路由（避免 `$appRoutes` 同名冲突）：

  ```dart
  import '../../features/home/home_routes.dart' as home;
  import '../../features/settings/settings_routes.dart' as settings;

  GoRouter(routes: [...home.$appRoutes, ...settings.$appRoutes]);
  ```

- 页面内**类型安全跳转**：`const SettingsRoute().push(context)`（替代字符串路径）。

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

- `test/app_test.dart`：widget 级冒烟测试（构建、导航、设置持久化）。
- `test/features/<name>/`：对应 feature 的单元测试，如设置仓储的读写往返。
- 测试需先运行 `fvm dart run build_runner build` 生成代码。

## 新增 Feature 清单

1. `lib/features/<name>/domain`：实体 + 仓储抽象；
2. `lib/features/<name>/data`：DTO、数据源、仓储实现 + `@riverpod` 注入；
3. `lib/features/<name>/presentation`：页面、组件、`@riverpod` 状态类；
4. `lib/features/<name>/<name>_routes.dart`：`@TypedGoRoute` 定义路由；
5. 在 `lib/app/router/app_router.dart` 前缀导入并聚合该 feature 的 `$appRoutes`；
6. 运行 `fvm dart run build_runner build` 生成全部代码；
7. 补充 `test/features/<name>/` 单元测试。
