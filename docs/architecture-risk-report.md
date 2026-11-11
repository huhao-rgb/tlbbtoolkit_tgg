# 架构风险排查报告

> 排查日期：2026-11-11　范围：`lib/`、`test/`、`server/`、`.github/`、Android/iOS/macOS 工程配置
>
> 本文记录排查结论与处理状态。**风险不是一次性的**，新增功能时请对照「待排期」一节。

## 0. 基线（排查时实测）

| 检查项 | 结果 |
| --- | --- |
| `fvm flutter analyze` | 0 issue |
| `fvm flutter test` | 475 passed / 9 skipped |
| feature 之间互相 import | 0 处 |
| `domain` 反向依赖 `data` / `presentation` | 0 处 |
| `core` / `shared` 反向依赖 `features` | 0 处 |
| 非生成代码规模 | 44,319 行（`features` 32,414 行） |

结论：**分层骨架健康**，风险集中在自动化防线、少数可靠性/安全点、依赖治理与可维护性债。

---

## 1. 本次已修复

| # | 风险 | 处理 | 验证 |
| --- | --- | --- | --- |
| 1 | CI 只有发布流水线，PR / main 无质量门禁 | 新增 `.github/workflows/ci.yml`：`--enforce-lockfile` → 生成代码并校验生成物入库 → 格式 → analyze → 架构边界 → test | 工作流文件已入库，本地等价命令全绿 |
| 2 | `LocalStorage.getJson` 只捕 `FormatException`，合法非对象 JSON 会抛 `TypeError`，设置页首帧可能白屏 | 先判类型再返回；补 6 个坏数据用例 | `test/core/storage/local_storage_test.dart` |
| 3 | 无全局错误边界，release 异常完全静默 | `core/utils/error_log.dart`（内存 + SharedPreferences 环形缓冲，最多 20 条，不联网）+ `error_handlers.dart`（`FlutterError.onError` / `PlatformDispatcher.onError`）+ `main()` 的 `runZonedGuarded`；设置页「关于 → 诊断日志」可复制 | `test/core/utils/error_log_test.dart` |
| 4 | Android 默认备份会把卡回归账号名单、音乐列表带进云备份 / 换机迁移 | `allowBackup=false` + `fullBackupContent=false` + `dataExtractionRules`（12+） | `xmllint` + debug APK 构建 |
| 5 | iOS/macOS 音乐列表存绝对路径，容器 UUID 变化后全部失效 | `MusicFileStore.repair` 按文件名找回；控制器启动时异步修复并落盘 | `music_file_store_test.dart` / `music_player_controller_test.dart` |
| 6 | 死代码：未被使用的 `dioProvider`（`baseUrl=api.example.com` + release 也打印请求体的 `LogInterceptor`）、`AppConstants.apiBaseUrl` / `useLocalDataSource` | 删除；`ApiClient` 只保留按用途的工厂；同步更新架构文档 | analyze 0 issue |
| 7 | 「禁止跨 feature import」纯靠自觉 | 新增 `scripts/check_feature_boundaries.py`，已接入 CI | 脚本本地通过 |
| 8 | 生成物与源码漂移（排查时 `assets/wudao_icons` 的昆仑图标未生成） | 重跑 `build_runner` 补入 `lib/gen/assets.gen.dart`；CI 增加 `git diff --exit-code` 护栏 | `flutter analyze` / `test` |

---

## 2. 待排期

### 中

| # | 风险 | 位置 | 建议 |
| --- | --- | --- | --- |
| 9 | 第三方签名密钥硬编码 | `lib/features/misc/data/sxds_api.dart:17` | 编译进 APK 可被提取；站方轮换即三处行情同时失效。记录轮换预案，长期改为云端代理转发。 |
| 10 | `domain` 依赖 `package:flutter/foundation.dart`（19 个文件） | `lib/features/*/domain/` | 改用 `package:meta` 的 `@immutable` + `dart:typed_data`；恢复后导出脚本可回归 `dart run`。 |
| 11 | 三个巨型页面 + `setState` 业务逻辑 | `misc_regress_page.dart`（2,633 行）/ `misc_market_page.dart`（1,865）/ `misc_account_market_page.dart`（1,584） | 筛选/解析/统计下沉到 `domain` 纯函数（参考 `account_market_stats.dart`）。 |
| 12 | 静态数据双份：domain 常量 vs `assets/catalog/*.json` | `lib/features/*/domain/` · `assets/catalog/` | CI 增加「导出后 `git diff --exit-code`」，覆盖全部 10 个分片。 |
| 13 | 依赖漂移与撤回版本 | `pubspec.lock` | `objective_c 9.6.1` 已被 pub 撤回；`share_plus` 10→13、`flutter_secure_storage` 10→11、`package_info_plus` 9→10、`window_manager` 0.5→0.6。先解撤回版本，再按季度评估 major（`go_router 17` 仍被 `material_ui` 卡住，见架构文档）。 |
| 14 | 服务端无 CI、RLS 策略手工注入 | `server/cloudbase/functions/` · `scripts/set-*-secret.sh` | 给云函数加 `npm test` CI；部署前后跑 `verify-deployment.sh` 作为发布检查项。 |
| 15 | 行情抓取无重试/退避，且每次进页面实时抓取 | `lib/features/misc/data/*_fetcher.dart` | 增加有限重试 + 短 TTL 缓存，避免被限流时整页报错。 |

### 低 / 卫生

| # | 风险 | 位置 | 建议 |
| --- | --- | --- | --- |
| 16 | 手写 provider 违反约定，且 router 未 dispose | `lib/app/router/app_router.dart:27` | 改为 `@riverpod` + `ref.onDispose(router.dispose)`。 |
| 17 | catalog 完整性只有 sha256（与 manifest 同源），无签名 | `lib/core/content/` | 当前仅展示数据，可接受；若将来承载规则/脚本必须加签名。 |
| 18 | Web 缓存介质是 localStorage（约 5 MB） | `catalog_storage_factory` | 当前 588 KB 可用；分片继续增长时换 IndexedDB 或按需加载。 |
| 19 | 仓库体积：`tools/fonts/` 全量字体约 49 MB 入库，`.git` 约 54 MB | `tools/fonts/` | 移到 release assets 或 Git LFS。 |
| 20 | `.vscode/launch.json` 写死真实 CloudBase 环境域名 | `.vscode/launch.json` | 与 README「不写死环境地址」保持一致，改为占位或本机配置。 |

---

## 3. 新增功能时的检查清单

- [ ] 生成物（`*.g.dart` / `*.freezed.dart` / `lib/gen/`）与源码同提交 —— CI 会拦。
- [ ] `domain` 不引入 Flutter / 外部运行时依赖。
- [ ] 新 provider 一律 `@riverpod`，异步状态用 `AppAsyncView`。
- [ ] 新增静态数据同时跑 `tools/catalog/export_catalog.dart`。
- [ ] 跨 feature 复用先考虑上提 `shared/`，不要互相 import。
- [ ] 改动依赖前确认 `pubspec.lock` 的来源仍是 `https://pub.dev`。
