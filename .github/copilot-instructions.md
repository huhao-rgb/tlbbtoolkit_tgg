# Copilot 项目指令

> 项目约定以根目录 [`AGENTS.md`](../AGENTS.md) 为**唯一事实源** —— 开工前先读它。
> 本文件只补充 VS Code Copilot 特有的行为要求，避免重复内容占用上下文。

## 必须遵守

1. **命令一律加 `fvm` 前缀**：`fvm flutter ...` / `fvm dart ...`。裸 `flutter` / `dart` 版本不对。
2. **不要手改生成文件**：`*.g.dart`、`*.freezed.dart`、`lib/gen/**`。改了源文件后重跑 `fvm dart run build_runner build`。
3. **不要手写 provider**：一律 `@riverpod` 注解。
4. **改动后的验证序列**：`build_runner build` → `fvm flutter analyze` → `fvm flutter test`。

## 工具使用偏好

- 编辑 Dart 文件后，用 Dart 工具链的**格式化**能力处理格式，**不要手动调缩进/换行**。
- lint 问题优先用 Dart 工具链的 **fix all**（单文件）处理，而非逐条手改。
- 定位代码优先用关键词搜索，**不要整文件通读**（`lib/` 有 100+ 文件、3.2 万行）。
- 需要理解改动影响面时，用「查找引用」而不是靠猜测。

## 沟通

- 回复使用**中文**。
- 给出改动前先用一句话说明改哪个文件、为什么，再执行编辑。
- 不确定的架构取舍先问，不要自行引入新模式或新依赖。
