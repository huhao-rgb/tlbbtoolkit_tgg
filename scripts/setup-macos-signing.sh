#!/usr/bin/env bash
# 为 macOS（以及 iOS）配置本地签名，且**不把 Team ID 写进仓库**。
#
# 生成/更新以下被 .gitignore 忽略的文件：
#   ios/Flutter/Signing.xcconfig                  → DEVELOPMENT_TEAM
#   macos/Runner/Configs/Signing.xcconfig         → DEVELOPMENT_TEAM + 真实签名身份
#   macos/Runner/Signing/{DebugProfile,Release}.entitlements
#                                                 → 在仓库版基础上追加 keychain-access-groups
#
# 为什么 macOS 必须这么做：ad-hoc 签名无法确定 keychain access group，
# 配对凭据写入会抛 PlatformException(-34018)，云同步因此不可用。
#
# 用法：
#   ./scripts/setup-macos-signing.sh <TEAM_ID>
#   ./scripts/setup-macos-signing.sh            # 用上次生成的值（若存在）
#
# 查询自己的 Team ID：
#   security find-identity -v -p codesigning
#   或 Xcode → Settings → Accounts
set -euo pipefail

cd "$(dirname "$0")/.."   # 仓库根目录

TEAM="${1:-}"
if [ -z "${TEAM}" ]; then
  if [ -f macos/Runner/Configs/Signing.xcconfig ]; then
    TEAM="$(grep -E '^DEVELOPMENT_TEAM' macos/Runner/Configs/Signing.xcconfig | head -1 | sed 's/.*= *//')"
  fi
fi
if [ -z "${TEAM}" ]; then
  echo "用法: ./scripts/setup-macos-signing.sh <TEAM_ID>" >&2
  echo "提示: security find-identity -v -p codesigning 可查看 Team ID" >&2
  exit 1
fi
if ! printf '%s' "${TEAM}" | grep -Eq '^[A-Z0-9]{10}$'; then
  echo "Team ID 格式不对（应为 10 位大写字母数字）: ${TEAM}" >&2
  exit 1
fi

echo "▶ 使用 Team ID: ${TEAM}"

cat > ios/Flutter/Signing.xcconfig <<EOF
// 本地签名配置 —— 不入库（.gitignore 已忽略）。由 scripts/setup-macos-signing.sh 生成。
DEVELOPMENT_TEAM = ${TEAM}
EOF

cat > macos/Runner/Configs/Signing.xcconfig <<EOF
// 本地签名配置 —— 不入库（.gitignore 已忽略）。由 scripts/setup-macos-signing.sh 生成。
//
// macOS 必须使用真实团队签名：ad-hoc 签名（CODE_SIGN_IDENTITY = "-"）无法确定
// keychain access group，写入钥匙串会抛 PlatformException(-34018)。
DEVELOPMENT_TEAM = ${TEAM}

// 覆盖 Debug/Release.xcconfig 里的 ad-hoc 兜底，改用真实证书（自动签名会签发）
CODE_SIGN_IDENTITY = Apple Development

// 指向带 keychain-access-groups 的 entitlements（见下方生成逻辑）
TGG_ENTITLEMENTS_DIR = Runner/Signing
EOF

mkdir -p macos/Runner/Signing
python3 - "${TEAM}" <<'PY'
import sys
team = sys.argv[1]
block = (
    "\t<key>keychain-access-groups</key>\n"
    "\t<array>\n"
    "\t\t<string>$(DEVELOPMENT_TEAM).$(PRODUCT_BUNDLE_IDENTIFIER)</string>\n"
    "\t</array>\n"
)
for src, dst in [
    ("macos/Runner/DebugProfile.entitlements", "macos/Runner/Signing/DebugProfile.entitlements"),
    ("macos/Runner/Release.entitlements", "macos/Runner/Signing/Release.entitlements"),
]:
    s = open(src, encoding="utf-8").read()
    s = s.replace(block, "")            # 幂等：先去掉可能存在的旧块
    s = s.replace("</dict>", block + "</dict>")
    open(dst, "w", encoding="utf-8").write(s)
    print(f"  已生成 {dst}")
PY

echo "✅ 完成。接下来："
echo "   1) 打开 macos/Runner.xcworkspace，Runner → Signing & Capabilities → Team 选同一个团队"
echo "   2) 验证：fvm flutter test integration_test/secure_storage_smoke_test.dart -d macos"
