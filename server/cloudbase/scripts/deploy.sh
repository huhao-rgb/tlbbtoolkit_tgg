#!/usr/bin/env bash
# 部署 reg-sync 云函数，并**逐字节校验**部署结果。
#
# 为什么需要校验：实测遇到过 `tcb fn deploy` 打印「deployed successfully」，
# 但云端代码并未更新（下载回来仍是旧文件，还带着旧的 pg 依赖）。措辞不可信，
# 字节可信，所以本脚本会在部署后把云端产物拉回来比对 md5，不一致直接失败。
#
# 用法：
#   ./cloudbase/scripts/deploy.sh              # 测试 + 部署 + 校验 + 契约验收
#   ./cloudbase/scripts/deploy.sh --skip-tests # 跳过单测（仅本地快速迭代）
set -euo pipefail

cd "$(dirname "$0")/../.."   # 到 server/（cloudbaserc.json 所在目录）

FUNC="reg-sync"
ROUTE_PATH="/reg"
SRC_DIR="cloudbase/functions/${FUNC}"
VERIFY_FILES=(index.js handler.js package.json)
SKIP_TESTS=0
[ "${1:-}" = "--skip-tests" ] && SKIP_TESTS=1

ENV_ID="$(node -e "process.stdout.write(require('./cloudbaserc.json').envId)")"
BASE_URL="https://${ENV_ID}.service.tcloudbase.com"

md5_of() { md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1; }

if [ "$SKIP_TESTS" -eq 0 ]; then
  echo "▶ 1/4 本地单测"
  (cd "$SRC_DIR" && node --test 2>&1 | grep -E "^# (tests|pass|fail)")
fi

echo "▶ 2/4 部署 $FUNC → $ENV_ID"
tcb fn deploy "$FUNC" --path "$ROUTE_PATH" --force 2>&1 | grep -E "successfully|error|失败" || true

echo "▶ 3/4 校验云端代码与本地一致"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
tcb fn code download "$FUNC" "$TMP" >/dev/null 2>&1

MISMATCH=0
for f in "${VERIFY_FILES[@]}"; do
  local_md5="$(md5_of "${SRC_DIR}/${f}")"
  cloud_md5="$(md5_of "${TMP}/${f}")"
  if [ "${local_md5}" = "${cloud_md5}" ]; then
    echo "   ✅ ${f} 一致（${local_md5}）"
  else
    echo "   ❌ ${f} 不一致：本地 ${local_md5} / 云端 ${cloud_md5:-缺失}" >&2
    MISMATCH=1
  fi
done
if [ "$MISMATCH" -ne 0 ]; then
  echo "❌ 云端代码与本地不一致 —— 部署未生效，不要以为已经上线。" >&2
  echo "   排查方向：确认 tcb 工作目录是 server/、无多余 cloudbaserc.json、" >&2
  echo "   并检查函数环境变量是否仍在（配置更新偶尔会覆盖/漏掉代码上传）。" >&2
  exit 1
fi

echo "▶ 4/4 契约验收"
./cloudbase/scripts/verify-deployment.sh "$BASE_URL" | tail -3

echo
echo "✅ 部署完成且已校验：${BASE_URL}${ROUTE_PATH}"
