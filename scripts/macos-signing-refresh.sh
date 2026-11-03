#!/usr/bin/env bash
# 刷新 macOS 开发签名用的 provisioning profile。
#
# 为什么需要这个脚本：
#   Flutter 的 macOS 构建路径（flutter run / flutter build macos）调用 xcodebuild 时
#   **不会**传 -allowProvisioningUpdates，而免费个人团队签发的
#   "Mac Team Provisioning Profile" 只有 7 天有效期。一旦本地 profile 过期或缺失，
#   构建就会硬失败：
#     error: No profiles for '<bundle-id>' were found ...
#     Automatic signing is disabled and unable to generate a profile.
#   手动跑一次带该参数的 xcodebuild 即可让 Xcode 重新签发，之后 Flutter 构建恢复正常。
#
# 幂等：本地已有有效 profile 时直接秒过（~0.1s），只有失效时才真正调用 Xcode。
#
# 用法：
#   ./scripts/macos-signing-refresh.sh            # profile 有效则跳过，失效才刷新
#   ./scripts/macos-signing-refresh.sh --force    # 无条件刷新
#
# 前提：Xcode → Settings → Accounts 里已登录开发者账号（免费个人团队即可）。
#
# 环境变量：
#   FLUTTER_BIN    flutter 命令，默认 "fvm flutter"（CI 里设为 flutter）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FORCE=0
case "${1:-}" in
  --force) FORCE=1 ;;
  -h|--help)
    sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  "") ;;
  *)
    echo "未知参数：$1（可用：--force）" >&2
    exit 2
    ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

# 没有本地签名配置时走 ad-hoc 兜底（CODE_SIGN_IDENTITY = -），不需要 profile。
SIGNING_XCCONFIG="macos/Runner/Configs/Signing.xcconfig"
if [ ! -f "${SIGNING_XCCONFIG}" ]; then
  echo "==> 未配置本地签名（无 ${SIGNING_XCCONFIG}），ad-hoc 构建无需 profile，跳过。"
  exit 0
fi

TEAM="$(grep -E '^DEVELOPMENT_TEAM' "${SIGNING_XCCONFIG}" | head -1 | sed 's/.*= *//' | tr -d '\r')"
if [ -z "${TEAM}" ]; then
  echo "==> ${SIGNING_XCCONFIG} 里 DEVELOPMENT_TEAM 为空，ad-hoc 构建无需 profile，跳过。"
  exit 0
fi

BUNDLE_ID="$(grep -E '^PRODUCT_BUNDLE_IDENTIFIER' macos/Runner/Configs/AppInfo.xcconfig | head -1 | sed 's/.*= *//' | tr -d '\r')"
PROFILE_DIR="${HOME}/Library/Developer/Xcode/UserData/Provisioning Profiles"

# 有效 profile 判定：名字匹配 + 未过期（提前 1 天视为失效，免得构建到一半才过期）。
profile_state() {
  python3 - "$1" "$2" "${PROFILE_DIR}" <<'PY'
import glob, os, plistlib, subprocess, sys
from datetime import datetime, timedelta, timezone

want_name, team, profile_dir = sys.argv[1], sys.argv[2], sys.argv[3]
# plistlib 解析出的日期是 naive（UTC），这里统一按 naive UTC 比较。
now = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(days=1)

for path in glob.glob(os.path.join(profile_dir, '*.provisionprofile')):
    try:
        raw = subprocess.run(
            ['security', 'cms', '-D', '-i', path],
            capture_output=True, check=True,
        ).stdout
        plist = plistlib.loads(raw)
    except Exception:
        continue
    if plist.get('Name') != want_name:
        continue
    if team not in (plist.get('TeamIdentifier') or []):
        continue
    if plist.get('ExpirationDate', now) <= now:
        continue
    print(path)
    sys.exit(0)

sys.exit(1)
PY
}

PROFILE_NAME="Mac Team Provisioning Profile: ${BUNDLE_ID}"

if [ "${FORCE}" -eq 0 ] && profile_state "${PROFILE_NAME}" "${TEAM}" >/dev/null; then
  echo "==> macOS 开发 profile 有效，无需刷新。"
  exit 0
fi

echo "==> 刷新 macOS 开发 profile（team ${TEAM}）…"

# xcodebuild 的 Run Script 阶段会调用 flutter assemble，需要 ephemeral 配置指向
# 真实的入口文件（否则会残留上次 flutter test 的临时 target 而失败）。
FLUTTER_BIN="${FLUTTER_BIN:-fvm flutter}"
# shellcheck disable=SC2086 # FLUTTER_BIN 允许是 "fvm flutter" 两个词
${FLUTTER_BIN} build macos --debug --config-only >/dev/null

LOG="$(mktemp -t tgg-macos-signing)"
trap 'rm -f "${LOG}"' EXIT

# 复用 Flutter 的 derivedDataPath，让随后的 flutter run 走增量构建。
if ! xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/macos \
  -allowProvisioningUpdates \
  -quiet \
  build >"${LOG}" 2>&1; then
  echo "❌ 刷新失败，xcodebuild 输出：" >&2
  grep -E "error:|Verify|provisioning|Team|team" "${LOG}" >&2 || cat "${LOG}" >&2
  cat >&2 <<'EOF'

排查建议：
  1) Xcode → Settings → Accounts 确认已登录开发者账号（免费个人团队即可）；
  2) 打开 macos/Runner.xcworkspace，Runner → Signing & Capabilities，
     确认 Team 已选中且 Bundle Identifier 与 AppInfo.xcconfig 一致；
  3) 仍失败时手动执行一次：
       xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug \
         -destination 'platform=macOS' -allowProvisioningUpdates build
EOF
  exit 1
fi

if profile_state "${PROFILE_NAME}" "${TEAM}" >/dev/null; then
  echo "✅ 已刷新：${PROFILE_NAME}"
else
  echo "⚠️  xcodebuild 成功但未找到匹配的新 profile；若接下来构建仍报 No profiles，请按上面的排查建议检查账号。" >&2
fi
