# Git 提交规范

本仓库的提交信息遵循 **Conventional Commits + 中文主题**：`git log --oneline` 要能一眼看出
「改了什么模块、做了什么」，并可按 type / scope 过滤、供 CHANGELOG 归类使用。

> 本文由历史提交（`git log --no-merges`）的实际写法归纳而成，不是空降的新风格：
> 136 条提交里 135 条已经是这个格式，仅首条 `first commit` 与 1 处 `styles` 笔误例外。

## 1. 格式

```
<type>(<scope>): <主题>

<正文（可选）>

<footer（可选）>
```

- 主题用中文、**不加句号**，直接说清做了什么；不要写「修改」「更新」「提交」这类空话。
- 主题建议 **≤ 50 字**（历史中位数 22 字、最长 53 字）。
- `scope` 用小写；跨模块改动用逗号连接，如 `feat(job,pet): …`。
- 首行与正文之间空一行；正文用 `-` 列表，一条一个变动。
- 多人协作时在末尾加 trailer：`Co-authored-by: Name <email>`。

## 2. type

| type | 用途 |
| --- | --- |
| `feat` | 新功能 / 新数据（新增门派、神器档位、页面、命令） |
| `fix` | 修 bug、修回归 |
| `docs` | 文档、README、CHANGELOG、注释性说明 |
| `refactor` | 重构，行为不变 |
| `perf` | 性能优化 |
| `style` | 格式、缩进、命名等不影响行为的美化 |
| `build` | 构建脚本、依赖、产物打包 |
| `ci` | GitHub Actions / 流水线 |
| `chore` | 版本号、配置、杂项 |
| `revert` | 回滚既有提交 |

补充约定：

- `feat` 是主力类型（历史占比过半）：**凡是玩家能看到的新东西都用它**，包括纯数据补充。
- `test` 仅用于「只补测试」的独立提交；测试通常与对应 `feat` / `fix` 同提交。
- 禁止自造类型（历史里的 `styles` 是笔误，正确为 `style`）、禁止无 type。

## 3. scope

按目录或交付物取，常用值：

| 范围 | scope |
| --- | --- |
| 应用外壳 | `app` `theme` `router` `shell` |
| 基础设施 | `core` `network` `storage` `config` |
| 业务模块 | `home` `job` `pet` `misc` `music` `settings` |
| 跨模块复用 | `shared` |
| 数据目录 | `catalog` |
| 打包与平台 | `installer` `android` `macos` `windows` |
| 交付流程 | `ci` `release` |
| 服务端 | `server` |

横切改动（版本号、根 README、全局配置）可省略 scope，如 `chore: 修改版本号1.1.3+10`。

## 4. 示例

```
feat(job): 新增门派昆仑（主玄副冰 · 双形态）
fix(job): 神器页数据缺失时保留页头与门派切换
docs: 补充 git 提交规范
ci(installer): tag 时把 Windows 安装包附加到 GitHub Release
build(macos): 新增未签名 DMG 打包脚本与发布流水线
```

反例：

```
update                 ← 没有 type，也没说改了什么
feat: 修改              ← 信息量为零
styles: 统一缩进         ← 自造 type，应为 style
Fix: 修复问题            ← type 大写、主题是空话
```

带正文的完整写法：

```
feat(job): 新增门派昆仑（主玄副冰 · 双形态）

- 门派筛选 / 介绍 / 加点权重接入昆仑，卡回归门派列表同步补入
- 心法、技能、九档神器、武道节点官方尚未公布，页面显示占位并在 domain 注释留清单
- 重跑 catalog 导出，job.sects / job.sect_info / job.point / job.skills 分片更新
```

## 5. 一个提交一件事

- 数据、页面、文档、构建脚本尽量分开提交，review 与回滚都更省事。
- **生成物必须与源文件同提交**：
  - 改实体 / provider / 路由 / 资源 → 先跑 `fvm dart run build_runner build`；
  - 改 `domain/` 静态数据 → 先跑 `fvm flutter test tools/catalog/export_catalog.dart`。
- 提交前跑完 `AGENTS.md` 的标准验证序列（`build_runner build` → `flutter analyze` → `flutter test`），
  并确认 `dart format` 检查通过。

## 6. 版本与 CHANGELOG

- 发版提交固定为 `chore: 修改版本号<版本>`（由 `scripts/release.sh` 生成），版本号与 `CHANGELOG.md` 同提交。
- `CHANGELOG.md` 的条目是按 git log 归类整理的，**type 直接影响分类结果** —— 别把新功能塞进 `chore`。
