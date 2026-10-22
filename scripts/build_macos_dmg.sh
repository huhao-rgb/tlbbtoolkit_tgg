#!/usr/bin/env bash
# 构建 macOS 应用并打成 DMG（默认不签名、不公证）。
#
# 用法：
#   bash scripts/build_macos_dmg.sh              # 构建 + 打包
#   bash scripts/build_macos_dmg.sh --skip-build # 复用已有 Release 产物，只重新打包
#
# 可选环境变量：
#   FLUTTER_BIN           flutter 命令，默认 "fvm flutter"（CI 里设为 flutter）
#   MACOS_SIGN_IDENTITY   设置后会用 Developer ID 签名（含 DMG），否则用 ad-hoc
#   MACOS_NOTARY_PROFILE  设置后配合签名一起做公证（notarytool 的 keychain profile）
#
# 注：变量一律写成 ${VAR} 形式 —— macOS 自带的 bash 3.2 会把紧跟中文的 $VAR
# 误当成变量名的一部分。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FLUTTER_BIN="${FLUTTER_BIN:-fvm flutter}"
SKIP_BUILD=0

for arg in "$@"; do
  case "${arg}" in
    --skip-build) SKIP_BUILD=1 ;;
    -h|--help)
      sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知参数：${arg}（可用：--skip-build）" >&2
      exit 2
      ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "打包 DMG 只能在 macOS 上执行。" >&2
  exit 1
fi

VERSION_FULL="$(sed -n 's/^version: //p' pubspec.yaml | head -1)"
VERSION="${VERSION_FULL%%+*}"
if [ -z "${VERSION}" ]; then
  echo "无法从 pubspec.yaml 读取版本号。" >&2
  exit 1
fi

PRODUCT_NAME="$(sed -n 's/^PRODUCT_NAME = //p' macos/Runner/Configs/AppInfo.xcconfig | head -1 | tr -d '\r')"
if [ -z "${PRODUCT_NAME}" ]; then
  PRODUCT_NAME="天工阁"
fi

APP_PATH="build/macos/Build/Products/Release/${PRODUCT_NAME}.app"
STAGE="${ROOT}/build/macos/dmg-stage"
OUT="${ROOT}/dist/TiangongGe-${VERSION}-macos-universal.dmg"

echo "==> 版本 ${VERSION}，应用 ${PRODUCT_NAME}"

if [ "${SKIP_BUILD}" -eq 0 ]; then
  echo "==> 构建 macOS release（universal）"
  # shellcheck disable=SC2086 # FLUTTER_BIN 允许是 "fvm flutter" 两个词
  ${FLUTTER_BIN} build macos --release
fi

if [ ! -d "${APP_PATH}" ]; then
  echo "找不到构建产物：${APP_PATH}" >&2
  exit 1
fi

if [ -n "${MACOS_SIGN_IDENTITY:-}" ]; then
  echo "==> 使用 ${MACOS_SIGN_IDENTITY} 签名应用"
  codesign --force --deep --options runtime --timestamp \
    --entitlements macos/Runner/Release.entitlements \
    --sign "${MACOS_SIGN_IDENTITY}" "${APP_PATH}"
  codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
else
  echo "==> 未设置 MACOS_SIGN_IDENTITY：沿用 Flutter 的 ad-hoc 签名（用户首次打开需手动放行）"
fi

echo "==> 准备 DMG 内容"
rm -rf "${STAGE}"
mkdir -p "${STAGE}"
# 用 ditto 而非 cp -R：保留扩展属性与资源分叉，避免签名信息丢失。
ditto "${APP_PATH}" "${STAGE}/${PRODUCT_NAME}.app"
ln -s /Applications "${STAGE}/Applications"
cp scripts/macos_dmg_readme.txt "${STAGE}/安装说明.txt"

echo "==> 生成 DMG"
mkdir -p dist
rm -f "${OUT}"
if ! diskutil image create from --format UDZO --volumeName "${PRODUCT_NAME}" "${STAGE}" "${OUT}" >/dev/null 2>&1; then
  # macOS 26 之前没有 diskutil image create from，退回 hdiutil。
  hdiutil create -volname "${PRODUCT_NAME}" -srcfolder "${STAGE}" -ov -format UDZO "${OUT}" >/dev/null
fi
hdiutil verify "${OUT}" >/dev/null
echo "    DMG 校验通过"

if [ -n "${MACOS_SIGN_IDENTITY:-}" ]; then
  echo "==> 签名 DMG"
  codesign --force --timestamp --sign "${MACOS_SIGN_IDENTITY}" "${OUT}"
  if [ -n "${MACOS_NOTARY_PROFILE:-}" ]; then
    echo "==> 提交公证（profile: ${MACOS_NOTARY_PROFILE}）"
    xcrun notarytool submit "${OUT}" --keychain-profile "${MACOS_NOTARY_PROFILE}" --wait
    xcrun stapler staple "${OUT}"
    xcrun stapler validate "${OUT}"
  else
    echo "    未设置 MACOS_NOTARY_PROFILE，跳过公证"
  fi
fi

SIZE="$(du -h "${OUT}" | cut -f1 | tr -d ' ')"
SHA="$(shasum -a 256 "${OUT}" | awk '{print $1}')"
echo
echo "完成：${OUT}"
echo "  体积：${SIZE}"
echo "  SHA256：${SHA}"
