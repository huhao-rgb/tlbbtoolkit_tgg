#!/usr/bin/env bash
# 数据目录 —— 部署验收脚本（对着真实云端接口跑一遍契约）
#
#   ./server/cloudbase/scripts/verify-catalog.sh https://<envId>.service.tcloudbase.com
#   ./server/cloudbase/scripts/verify-catalog.sh https://<envId>.service.tcloudbase.com '<TGG_CATALOG_SECRET>'
#
# 不带密钥时只跑只读用例（manifest / 分片 / 304 / CORS / 404 / 鉴权）；
# 带密钥时额外跑「发布 → 读取 → 304 → 下线」全链路，并自行清理测试分片。

set -uo pipefail

BASE="${1:-}"
SECRET="${2:-}"
PATH_PART="/catalog"
KIND="verify.smoke"

if [[ -z "$BASE" ]]; then
  echo "用法: $0 https://<envId>.service.tcloudbase.com [TGG_CATALOG_SECRET]" >&2
  exit 2
fi

URL="${BASE%/}${PATH_PART}"
BODY_FILE="$(mktemp)"
HDR_FILE="$(mktemp)"
DATA_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE" "$HDR_FILE" "$DATA_FILE"' EXIT

printf '{"schemaVersion":1,"dataVersion":"verify","items":{"smoke":true}}' > "$DATA_FILE"

pass=0
fail=0
USE_TOKEN=1

expect_status() { # <描述> <期望> <实际>
  if [[ "$2" == "$3" ]]; then
    printf '  ✅ %s（HTTP %s）\n' "$1" "$3"; pass=$((pass + 1))
  else
    printf '  ❌ %s：期望 HTTP %s，实际 %s\n' "$1" "$2" "$3"; fail=$((fail + 1))
  fi
}

expect_contains() { # <描述> <子串> <文本>
  if [[ "$3" == *"$2"* ]]; then
    printf '  ✅ %s\n' "$1"; pass=$((pass + 1))
  else
    printf '  ❌ %s：未找到 %s\n      实际：%s\n' "$1" "$2" "${3:0:200}"; fail=$((fail + 1))
  fi
}

# 发请求，状态码走 stdout，响应体/头落到临时文件
req() { # <方法> <url> [data 文件]
  local method="$1" url="$2" data="${3-}"
  local args=(-s -o "$BODY_FILE" -D "$HDR_FILE" -w '%{http_code}' -X "$method" "$url")
  if [[ -n "$data" ]]; then
    args+=(-H 'content-type: application/json' --data-binary "@$data")
  fi
  if [[ "$USE_TOKEN" -eq 1 && -n "$SECRET" ]]; then
    args+=(-H "x-catalog-token: $SECRET")
  fi
  curl "${args[@]}"
}

body() { cat "$BODY_FILE" 2>/dev/null || true; }
hdr() { grep -i "^$1:" "$HDR_FILE" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r'; }

cleanup_remote() {
  if [[ -n "$SECRET" ]]; then
    curl -s -o /dev/null -X DELETE -H "x-catalog-token: $SECRET" "$URL/$KIND.json" || true
  fi
}
trap 'cleanup_remote; rm -f "$BODY_FILE" "$HDR_FILE" "$DATA_FILE"' EXIT

echo "目标：$URL"
[[ -n "$SECRET" ]] && echo "模式：读 + 写（含测试分片 ${KIND}，结束后自动删除）" || echo "模式：只读（未提供密钥）"
echo

echo "1) manifest"
status=$(req GET "$URL/manifest.json")
expect_status "GET manifest.json → 200" 200 "$status"
expect_contains "返回 files 数组" '"files"' "$(body)"
expect_contains "返回 schemaVersion" '"schemaVersion"' "$(body)"

echo "2) CORS 预检"
status=$(req OPTIONS "$URL/manifest.json")
expect_status "OPTIONS → 204（Web 端必需）" 204 "$status"
expect_contains "允许任意来源" '*' "$(hdr access-control-allow-origin)"
expect_contains "暴露 ETag（否则 Web 读不到）" 'etag' "$(hdr access-control-expose-headers)"

echo "3) 不存在的分片"
status=$(req GET "$URL/verify.missing.json")
expect_status "GET 未发布分片 → 404" 404 "$status"
expect_contains "返回 not_found" 'not_found' "$(body)"

echo "4) 鉴权"
USE_TOKEN=0
status=$(req PUT "$URL/$KIND.json" "$DATA_FILE")
USE_TOKEN=1
expect_status "PUT 无密钥 → 401" 401 "$status"

if [[ -z "$SECRET" ]]; then
  echo
  printf '结果：%d 通过 / %d 失败（只读模式）\n' "$pass" "$fail"
  [[ "$fail" -eq 0 ]] && echo "只读契约验收通过 ✅" || exit 1
  exit 0
fi

echo "5) 发布测试分片"
status=$(req PUT "$URL/$KIND.json" "$DATA_FILE")
expect_status "PUT → 204" 204 "$status"
etag="$(hdr etag)"
expect_contains "返回 ETag" '"' "$etag"

echo "6) 读取与完整性"
status=$(req GET "$URL/$KIND.json")
expect_status "GET → 200" 200 "$status"
expect_contains "原文返回" '"smoke":true' "$(body)"
if command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$BODY_FILE" | cut -d' ' -f1)"
  if [[ "\"$actual\"" == "$etag" ]]; then
    printf '  ✅ body 的 sha256 与 ETag 一致\n'; pass=$((pass + 1))
  else
    printf '  ❌ sha256 与 ETag 不一致：body %s / etag %s\n' "$actual" "$etag"; fail=$((fail + 1))
  fi
fi

echo "7) 条件请求"
status=$(curl -s -o /dev/null -w '%{http_code}' -H "If-None-Match: $etag" "$URL/$KIND.json")
expect_status "If-None-Match 命中 → 304" 304 "$status"

echo "8) manifest 已收录"
status=$(req GET "$URL/manifest.json")
expect_contains "manifest 含测试分片" "\"$KIND\"" "$(body)"
expect_contains "manifest 的 sha256 与分片 ETag 一致" "${etag//\"/}" "$(body)"

echo "9) 下线"
status=$(req DELETE "$URL/$KIND.json")
expect_status "DELETE → 204" 204 "$status"
status=$(req GET "$URL/$KIND.json")
expect_status "下线后 GET → 404" 404 "$status"

echo
printf '结果：%d 通过 / %d 失败\n' "$pass" "$fail"
if [[ "$fail" -ne 0 ]]; then
  echo "未通过 ❌ —— 按响应体里的 error 定位：" >&2
  echo "  · not_configured              → 云函数缺 TGG_CATALOG_SECRET" >&2
  echo "  · unauthorized                → 请求头 x-catalog-token 与服务端不一致" >&2
  echo "  · db_unreachable              → 数据通道网络层不通（超时/DNS/网关）" >&2
  echo "  · db_error (DATABASE_42501)   → RLS 写策略没建/密钥不一致（跑 set-catalog-secret.sh）" >&2
  echo "  · 写成功但读不到 → 检查 tgg_catalog_read 策略与 GRANT 是否已执行" >&2
  exit 1
fi
echo "契约验收通过 ✅"
