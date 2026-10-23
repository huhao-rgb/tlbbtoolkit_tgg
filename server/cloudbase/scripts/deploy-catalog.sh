#!/usr/bin/env bash
# 部署 catalog 云函数，并**逐字节校验**部署结果。
#
# 与 reg-sync 的 deploy.sh 同构：`tcb fn deploy` 打印成功不代表云端真的更新了，
# 所以部署后把云端产物拉回来比对 md5，不一致直接失败。
#
# 环境变量：
#   TGG_CATALOG_SECRET  写密钥。**提供时会随本次部署写入云函数环境变量**
#                       （经由临时目录里的 cloudbaserc.json，密钥不落仓库）；
#                       不提供时只部署代码，接口可读不可写。
#
# 用法：
#   ./cloudbase/scripts/deploy-catalog.sh
#   TGG_CATALOG_SECRET=xxx ./cloudbase/scripts/deploy-catalog.sh
#   ./cloudbase/scripts/deploy-catalog.sh --skip-tests
set -euo pipefail

cd "$(dirname "$0")/../.."   # 到 server/（cloudbaserc.json 所在目录）

FUNC="catalog"
ROUTE_PATH="/catalog"
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

echo "▶ 2/4 部署 ${FUNC} → ${ENV_ID}（路由 ${ROUTE_PATH}）"

# 为什么要绕一层临时目录：
#   1) 密钥不能写进仓库里的 cloudbaserc.json；
#   2) 不想依赖 `tcb fn deploy` 对 envVariables 的合并行为细节
#      （实测未列出的变量会保留，但这属于平台实现细节）。
# 这里把函数代码复制到临时目录、生成一份带 envVariables 的 cloudbaserc.json 再部署。
STAGE="$(mktemp -d)"
DL=""
cleanup() { rm -rf "$STAGE" ${DL:+"$DL"}; }
trap cleanup EXIT

mkdir -p "${STAGE}/cloudbase/functions"
cp -R "$SRC_DIR" "${STAGE}/cloudbase/functions/${FUNC}"

node -e '
  const fs = require("fs");
  const [rcPath, name, outPath] = process.argv.slice(1);
  const rc = JSON.parse(fs.readFileSync(rcPath, "utf8"));
  const fn = rc.functions.find((f) => f.name === name);
  const secret = process.env.TGG_CATALOG_SECRET;
  if (secret) fn.envVariables = Object.assign({}, fn.envVariables, { TGG_CATALOG_SECRET: secret });
  fs.writeFileSync(outPath, JSON.stringify(Object.assign({}, rc, {
    functionRoot: "./cloudbase/functions",
    functions: [fn],
  }), null, 2));
' "$PWD/cloudbaserc.json" "$FUNC" "${STAGE}/cloudbaserc.json"

chmod 600 "${STAGE}/cloudbaserc.json"
if [ -n "${TGG_CATALOG_SECRET:-}" ]; then
  echo "   已附带环境变量 TGG_CATALOG_SECRET（不落仓库）"
else
  echo "   ⚠ 未提供 TGG_CATALOG_SECRET：本次部署不写密钥（接口可读不可写）"
fi

(cd "$STAGE" && tcb fn deploy "$FUNC" --path "$ROUTE_PATH" --force 2>&1 | grep -E "successfully|error|失败" || true)

echo "▶ 3/4 校验云端代码与本地一致"
DL="$(mktemp -d)"
tcb fn code download "$FUNC" "$DL" >/dev/null 2>&1

MISMATCH=0
for f in "${VERIFY_FILES[@]}"; do
  local_md5="$(md5_of "${SRC_DIR}/${f}")"
  cloud_md5="$(md5_of "${DL}/${f}")"
  if [ "${local_md5}" = "${cloud_md5}" ]; then
    echo "   ✅ ${f} 一致（${local_md5}）"
  else
    echo "   ❌ ${f} 不一致：本地 ${local_md5} / 云端 ${cloud_md5:-缺失}" >&2
    MISMATCH=1
  fi
done
if [ "${MISMATCH}" -ne 0 ]; then
  echo "❌ 云端代码与本地不一致 —— 部署未生效，不要以为已经上线。" >&2
  echo "   排查方向：确认 tcb 工作目录是 server/、无多余 cloudbaserc.json、" >&2
  echo "   并检查函数环境变量是否仍在（配置更新偶尔会覆盖/漏掉代码上传）。" >&2
  exit 1
fi

echo "▶ 4/4 契约验收"
if [ -n "${TGG_CATALOG_SECRET:-}" ]; then
  ./cloudbase/scripts/verify-catalog.sh "$BASE_URL" "$TGG_CATALOG_SECRET" | tail -3
else
  echo "   （未设置 TGG_CATALOG_SECRET，只跑只读验收；写入/删除请带密钥重跑本脚本）"
  ./cloudbase/scripts/verify-catalog.sh "$BASE_URL" | tail -3
fi
