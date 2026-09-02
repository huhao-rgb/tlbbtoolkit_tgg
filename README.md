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

# 静态检查
fvm flutter analyze

# 测试
fvm flutter test
```

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
│   ├── settings/              # 示例：本地持久化 + 设置（/settings tab）
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
- 一级页面 = tab 分支（home `/home`、settings `/settings`），切换保留各分支导航状态；
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
