# tlbbtoolkit

天龙八部（TLBB）工具箱 —— 基于 **Feature-first 架构**的 Flutter 应用脚手架。

## 技术栈

| 能力 | 方案 |
| --- | --- |
| 语言 | Dart 3.13 / Flutter 3.47（通过 [FVM](https://fvm.app) 管理版本） |
| 状态管理 / DI | [Riverpod 3.4](https://riverpod.dev)（`@riverpod` 代码生成） |
| 路由 | [go_router 18](https://pub.dev/packages/go_router) + go_router_builder（类型安全路由生成） |
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
│   ├── router/app_router.dart # 路由表（聚合各 feature 生成的路由）
│   └── theme/                 # 主题（明/暗）
├── core/                      # 跨 feature 的基础设施
│   ├── constants/             # 全局常量 / 接口路径
│   ├── di/providers.dart      # 全局 provider（dio / storage，@riverpod）
│   ├── network/               # dio 封装 + 统一异常
│   ├── storage/               # LocalStorage 封装
│   ├── utils/                 # 工具（日志等）
│   └── widgets/               # （预留）
├── features/                  # 业务 feature（核心）
│   ├── home/                  # 示例：网络/异步数据流
│   │   ├── domain/            # 实体 + 仓储抽象（纯 Dart，不依赖 Flutter）
│   │   ├── data/              # DTO + 数据源 + 仓储实现 + 注入
│   │   ├── presentation/      # 页面 + 组件 + 状态 provider
│   │   └── home_routes.dart   # 类型安全路由（@TypedGoRoute）
│   ├── settings/              # 示例：本地持久化 + 设置
│   └── ...                    # 新 feature 参照 home 的目录模板
└── shared/                    # 跨 feature 共享的组件/工具
    └── widgets/               # AppAsyncView 等通用组件
```

完整的架构约定见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 新增一个 Feature

1. 在 `lib/features/<name>/` 下创建 `domain / data / presentation` 三目录；
2. `domain`：定义实体（freezed）与仓储抽象接口；
3. `data`：实现数据源与仓储，用 `@riverpod` 函数完成注入；
4. `presentation`：编写页面、组件与 `@riverpod` 状态类；
5. 在 feature 根部创建 `<name>_routes.dart` 用 `@TypedGoRoute` 定义路由；
6. 到 `lib/app/router/app_router.dart` 把该 feature 生成的 `$appRoutes` 追加进 `routes`；
7. 运行 `fvm dart run build_runner build` 生成全部代码。
