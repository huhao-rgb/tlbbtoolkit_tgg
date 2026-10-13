#!/usr/bin/env bash
# 卡回归云同步 —— 部署验收脚本（对着真实云端接口跑一遍契约）
#
#   ./server/cloudbase/scripts/verify-deployment.sh https://<envId>.service.tcloudbase.com
#
# 覆盖：404 / 创建 / 读取 / 冲突(409) / 条件更新 / 参数校验 / CORS 预检 / 幂等删除。
# 脚本自行清理测试数据（DELETE），可重复执行。

set -uo pipefail

BASE="${1:-}"
PATH_PART="${2:-/reg}"

if [[ -z "$BASE" ]]; then
  echo "用法: $0 https://<envId>.service.tcloudbase.com [路径，默认 /reg]" >&2
  exit 2
fi

URL="${BASE%/}${PATH_PART}"
CODE="$(python3 -c 'import secrets;print(secrets.token_hex(16))' 2>/dev/null || openssl rand -hex 16)"
BODY_FILE="$(mktemp)"

pass=0
fail=0

# 断言 HTTP 状态码
expect_status() { # <描述> <期望> <实际>
  if [[ "$2" == "$3" ]]; then
    printf '  ✅ %s（HTTP %s）\n' "$1" "$3"; pass=$((pass + 1))
  else
    printf '  ❌ %s：期望 HTTP %s，实际 %s\n' "$1" "$2" "$3"; fail=$((fail + 1))
  fi
}

# 断言响应体包含子串
expect_body() { # <描述> <子串> <响应体>
  if [[ "$3" == *"$2"* ]]; then
    printf '  ✅ %s（含 %s）\n' "$1" "$2"; pass=$((pass + 1))
  else
    printf '  ❌ %s：响应体不含 %s\n      实际：%s\n' "$1" "$2" "$3"; fail=$((fail + 1))
  fi
}

# 发请求，输出状态码，响应体落到 $BODY_FILE
call() { # <方法> [JSON body]
  local method="$1" body="${2:-}"
  if [[ -n "$body" ]]; then
    curl -s -o "$BODY_FILE" -w '%{http_code}' -X "$method" "$URL?code=$CODE" \
      -H 'content-type: application/json' -d "$body"
  else
    curl -s -o "$BODY_FILE" -w '%{http_code}' -X "$method" "$URL?code=$CODE"
  fi
}
body() { cat "$BODY_FILE" 2>/dev/null || true; }

cleanup() { rm -f "$BODY_FILE"; }
trap cleanup EXIT

echo "目标：$URL"
echo "测试 code：$CODE"
echo

echo "1) 未创建的记录"
status=$(call GET)
expect_status "GET 不存在 → 404" 404 "$status"
expect_body "返回 not_found" '"error":"not_found"' "$(body)"

echo "2) 首次创建（rev=0）"
status=$(call PUT '{"rev":0,"blob":"verify-cipher-1"}')
expect_status "PUT rev=0 → 200" 200 "$status"
expect_body "返回 rev=1" '"rev":1' "$(body)"

echo "3) 读取"
status=$(call GET)
expect_status "GET → 200" 200 "$status"
expect_body "rev 正确" '"rev":1' "$(body)"
expect_body "blob 原样返回" '"blob":"verify-cipher-1"' "$(body)"

echo "4) 重复创建 → 版本冲突"
status=$(call PUT '{"rev":0,"blob":"should-not-win"}')
expect_status "PUT rev=0（已存在）→ 409" 409 "$status"
expect_body "带出当前 rev" '"rev":1' "$(body)"
call GET >/dev/null
expect_body "冲突未改动数据" '"blob":"verify-cipher-1"' "$(body)"

echo "5) 条件更新"
status=$(call PUT '{"rev":1,"blob":"verify-cipher-2"}')
expect_status "PUT rev=1 → 200" 200 "$status"
expect_body "rev 递增到 2" '"rev":2' "$(body)"

echo "6) 过期 rev 再更新 → 冲突（且不覆盖）"
status=$(call PUT '{"rev":1,"blob":"stale-write"}')
expect_status "PUT 过期 rev → 409" 409 "$status"
call GET >/dev/null
expect_body "数据未被过期写覆盖" '"blob":"verify-cipher-2"' "$(body)"

echo "7) 参数校验"
status=$(curl -s -o /dev/null -w '%{http_code}' -X GET "${BASE%/}${PATH_PART}?code=bad")
expect_status "非法 code → 400" 400 "$status"
status=$(call PUT '{"rev":-1,"blob":"x"}')
expect_status "非法 rev → 400" 400 "$status"
status=$(call PUT '{"rev":2}')
expect_status "缺 blob → 400" 400 "$status"

echo "8) CORS 预检"
status=$(curl -s -o /dev/null -w '%{http_code}' -X OPTIONS "${BASE%/}${PATH_PART}")
expect_status "OPTIONS → 204（Web 端必需）" 204 "$status"

echo "9) 删除（幂等）"
status=$(call DELETE)
expect_status "DELETE → 200" 200 "$status"
status=$(call GET)
expect_status "删除后 GET → 404" 404 "$status"
status=$(call DELETE)
expect_status "重复 DELETE → 200" 200 "$status"

echo
printf '结果：%d 通过 / %d 失败\n' "$pass" "$fail"
if [[ "$fail" -ne 0 ]]; then
  echo "未通过 ❌ —— 按响应体里的 error 定位："
  echo "  · db_not_configured  → 云函数缺 TGG_SYNC_SECRET（缺哪些会列在 missing 里）"
  echo "  · db_unreachable     → 数据通道网络层不通（超时/DNS/网关）"
  echo "  · db_error (DATABASE_*) → 通道通了但被数据库拒绝：多为 RLS 策略/授权没配好"
  echo "  · 409/数据为 0 行反而正常 → 检查 RLS 策略里的密钥是否与函数环境变量一致"
  exit 1
fi
echo "契约验收通过 ✅"
