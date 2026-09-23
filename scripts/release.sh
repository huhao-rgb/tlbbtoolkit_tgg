#!/usr/bin/env bash
#
# release.sh —— 天工阁发版脚本
# 一条命令完成：改版本号 → 更新 CHANGELOG → 提交 → 打 tag → 推送
#
# 用法：
#   ./scripts/release.sh 1.0.4            # 交互式：预览草稿，确认后执行
#   ./scripts/release.sh 1.0.4+5 --yes    # 跳过所有确认（CI / 信任流程）
#   ./scripts/release.sh 1.0.4 --dry-run  # 只预览，不修改任何文件
#
# 规则：
#   - 版本号格式：主.次.修订[+构建号]，如 1.0.4 或 1.0.4+5
#   - tag 名 = v + 主.次.修订（去掉 +构建号，避免 + 在部分工具 / URL 中出问题）
#   - CHANGELOG 新条目由自上一个 tag 以来的提交自动生成草稿，确认前可手动整理
#   - 提交信息沿用仓库惯例：chore: 修改版本号<版本号>
#
# 注意：脚本只改 pubspec.yaml 与 CHANGELOG.md，不跑 fvm / build_runner
#       （版本号变更不影响代码生成产物）。

set -euo pipefail

# ---------- 颜色输出 ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { printf "${GREEN}%s${NC}\n" "$*"; }
warn()  { printf "${YELLOW}%s${NC}\n" "$*"; }
error() { printf "${RED}%s${NC}\n" "$*" >&2; }

# ---------- 参数解析 ----------
VERSION=""
YES=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --yes)     YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -*)        error "未知参数: $arg"; exit 1 ;;
    *)         VERSION="$arg" ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "用法: ./scripts/release.sh <版本号> [--yes] [--dry-run]"
  echo "示例: ./scripts/release.sh 1.0.4+5"
  exit 1
fi

# ---------- 版本号校验 ----------
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$ ]]; then
  error "版本号格式错误: $VERSION（应为 主.次.修订[+构建号]，如 1.0.4 或 1.0.4+5）"
  exit 1
fi

# tag 名：v + 主.次.修订（去掉 +构建号）
TAG="v${VERSION%%+*}"

# ---------- 前置检查 ----------
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || true)
if [ "$BRANCH" != "main" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    warn "当前分支为 $BRANCH（发版建议在 main 分支，--dry-run 仅预览不阻止）"
  else
    error "当前分支为 $BRANCH，发版应在 main 分支进行"
    exit 1
  fi
fi

if [ "$DRY_RUN" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  error "工作区有未提交的改动，请先提交或 stash："
  git status --short
  exit 1
fi

CUR_VERSION=$(sed -n 's/^version: //p' pubspec.yaml)
if [ -z "$CUR_VERSION" ]; then
  error "未能在 pubspec.yaml 中找到 version 字段"
  exit 1
fi
if [ "$VERSION" = "$CUR_VERSION" ]; then
  error "新版本与当前版本相同（$CUR_VERSION），请递增版本号"
  exit 1
fi

PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$PREV_TAG" ]; then RANGE="$PREV_TAG..HEAD"; else RANGE="HEAD"; fi
DATE=$(date +%Y-%m-%d)

# ---------- 从 git log 生成 CHANGELOG 草稿（conventional commit 前缀归类） ----------
build_draft() {
  local add=() fix=() opt=() other=()
  local line body seen=""

  while IFS= read -r line; do
    # 跳过版本号提交与合并提交
    case "$line" in
      *"修改版本号"*) continue ;;
      "Merge"*)       continue ;;
    esac
    # 去重：相同提交信息只保留一条（历史上存在重复提交）
    case "$seen" in
      *"|$line|"*) continue ;;
    esac
    seen="$seen|$line|"
    # 去掉类型前缀（feat: / fix: 等）
    case "$line" in
      feat:*)   body="${line#feat:}"  ;;
      fix:*)    body="${line#fix:}"   ;;
      perf:*)   body="${line#perf:}"  ;;
      refactor:*) body="${line#refactor:}" ;;
      style:*)  body="${line#style:}" ;;
      docs:*)   body="${line#docs:}"  ;;
      chore:*)  body="${line#chore:}" ;;
      test:*)   body="${line#test:}"  ;;
      build:*)  body="${line#build:}" ;;
      ci:*)     body="${line#ci:}"    ;;
      *)        body="$line" ;;
    esac
    # 去掉前缀后的多余空白
    body=$(printf '%s' "$body" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$body" ] || continue

    case "$line" in
      feat:*)    add+=("$body") ;;
      fix:*)     fix+=("$body") ;;
      perf:*|refactor:*) opt+=("$body") ;;
      *)         other+=("$body") ;;
    esac
  done < <(git log "$RANGE" --pretty=format:%s)

  local draft="## [$VERSION] - $DATE"
  draft+=$'\n'
  draft+=$'\n<!-- 以下条目由 git log 自动生成，请按需整理分类、增删内容 -->'
  if [ ${#add[@]} -gt 0 ]; then
    draft+=$'\n\n### 新增\n'
    for x in "${add[@]}"; do draft+="- $x"$'\n'; done
  fi
  if [ ${#fix[@]} -gt 0 ]; then
    draft+=$'\n### 修复\n'
    for x in "${fix[@]}"; do draft+="- $x"$'\n'; done
  fi
  if [ ${#opt[@]} -gt 0 ]; then
    draft+=$'\n### 优化\n'
    for x in "${opt[@]}"; do draft+="- $x"$'\n'; done
  fi
  if [ ${#other[@]} -gt 0 ]; then
    draft+=$'\n### 其他\n'
    for x in "${other[@]}"; do draft+="- $x"$'\n'; done
  fi
  if [ ${#add[@]} -eq 0 ] && [ ${#fix[@]} -eq 0 ] && [ ${#opt[@]} -eq 0 ] && [ ${#other[@]} -eq 0 ]; then
    draft+=$'\n- 待补充'
  fi
  printf '%s' "$draft"
}

DRAFT=$(build_draft)

# ---------- 预览 ----------
echo
info "========== 发版预览 =========="
echo "  当前版本 : $CUR_VERSION"
echo "  新版本   : $VERSION"
echo "  tag 名   : $TAG"
if [ -n "$PREV_TAG" ]; then
  echo "  日志范围 : $PREV_TAG..HEAD"
else
  echo "  日志范围 : 全部历史（尚无 tag）"
fi
echo "  执行步骤 :"
echo "    1) pubspec.yaml  version: $CUR_VERSION -> $VERSION"
echo "    2) CHANGELOG.md  顶部插入 [$VERSION] 条目（草稿）"
echo "    3) git commit    chore: 修改版本号$VERSION"
echo "    4) git tag -a    $TAG"
echo "    5) git push      origin main + origin $TAG"
echo
echo "----- CHANGELOG 草稿（可先在其他终端编辑 CHANGELOG.md 微调） -----"
echo "$DRAFT"
echo "----------------------------------------------------------------"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  warn "（--dry-run 模式：仅预览，未修改任何文件）"
  exit 0
fi

if [ "$YES" -eq 0 ]; then
  read -r -p "确认无误？输入 yes 继续，其他任意输入取消: " ans
  [ "$ans" = "yes" ] || { warn "已取消，未做任何修改"; exit 1; }
fi

# ---------- 执行 ----------
update_pubspec() {
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^version: .*/version: ${VERSION}/" pubspec.yaml
  else
    sed -i "s/^version: .*/version: ${VERSION}/" pubspec.yaml
  fi
}

insert_changelog() {
  local tmp_draft tmp_out n
  tmp_draft=$(mktemp)
  tmp_out=$(mktemp)
  printf '%s' "$DRAFT" > "$tmp_draft"
  # 找到第一个 "## [" 版本小节的起始行号（BSD awk 的 -v 不接受换行，改用纯 shell 实现）
  n=$(grep -n '^## \[' CHANGELOG.md | head -1 | cut -d: -f1)
  if [ -z "$n" ]; then
    # 文件里还没有版本小节：草稿追加到末尾
    { cat CHANGELOG.md; echo; cat "$tmp_draft"; } > "$tmp_out"
  else
    head -n "$((n - 1))" CHANGELOG.md > "$tmp_out"
    cat "$tmp_draft" >> "$tmp_out"
    echo >> "$tmp_out"
    tail -n "+$n" CHANGELOG.md >> "$tmp_out"
  fi
  mv "$tmp_out" CHANGELOG.md
  rm -f "$tmp_draft"
}

update_pubspec
insert_changelog

info "已更新 pubspec.yaml 与 CHANGELOG.md，开始提交……"
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: 修改版本号$VERSION"
git tag -a "$TAG" -m "$TAG 发布"

info "推送 main 与 tag $TAG ……"
git push origin main
git push origin "$TAG"

echo
info "✅ 发版完成：$TAG"
info "推送 tag 已自动触发 GitHub Actions（.github/workflows/release.yml），"
info "将自动构建 Release APK 并创建 GitHub Release，无需手动操作。"
echo "  APK 产物: build/app/outputs/flutter-apk/app-release.apk"
