#!/usr/bin/env bash
# 构建 macOS 应用并打成 DMG（默认不签名、不公证）。
#
# 用法：
#   bash scripts/build_macos_dmg.sh              # 构建 + 打包
#   bash scripts/build_macos_dmg.sh --skip-build # 复用已有 Release 产物，只重新打包
#
# 可选环境变量：
#   FLUTTER_BIN           flutter 命令，默认 "fvm flutter"（CI 里设为 flutter）
#   SYNC_BASE_URL         云同步地址（编译期常量，必须走 --dart-define）
#   CATALOG_BASE_URL      数据目录地址（默认复用 SYNC_BASE_URL；留空=只用内置数据）
#   MACOS_SIGN_IDENTITY   设置后会用 Developer ID 签名（含 DMG），否则用 ad-hoc
#   MACOS_NOTARY_PROFILE  设置后配合签名一起做公证（notarytool 的 keychain profile）
#
# 注：变量一律写成 ${VAR} 形式 —— macOS 自带的 bash 3.2 会把紧跟中文的 $VAR
# 误当成变量名的一部分。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FLUTTER_BIN="${FLUTTER_BIN:-fvm flutter}"
SYNC_BASE_URL="${SYNC_BASE_URL:-}"
CATALOG_BASE_URL="${CATALOG_BASE_URL:-${SYNC_BASE_URL}}"
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
BG_DIR="${ROOT}/build/macos/dmg"
OUT="${ROOT}/dist/TiangongGe-${VERSION}-macos-universal.dmg"

echo "==> 版本 ${VERSION}，应用 ${PRODUCT_NAME}"

if [ "${SKIP_BUILD}" -eq 0 ]; then
  echo "==> 构建 macOS release（universal）"
  if [ -n "${SYNC_BASE_URL}" ]; then
    echo "    云同步地址：${SYNC_BASE_URL}"
  else
    echo "    未提供 SYNC_BASE_URL —— 本次构建的包不含云同步功能"
  fi
  if [ -n "${CATALOG_BASE_URL}" ]; then
    echo "    数据目录地址：${CATALOG_BASE_URL}"
  else
    echo "    未提供 CATALOG_BASE_URL —— 本次构建只用内置数据（不热更新）"
  fi
  # SYNC_BASE_URL 是编译期常量（String.fromEnvironment），漏传不会报错，
  # 只会让云同步入口静默消失，所以必须用 --dart-define 注入。
  # shellcheck disable=SC2086 # FLUTTER_BIN 允许是 "fvm flutter" 两个词
  ${FLUTTER_BIN} build macos --release "--dart-define=SYNC_BASE_URL=${SYNC_BASE_URL}" "--dart-define=CATALOG_BASE_URL=${CATALOG_BASE_URL}"
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

if [ -n "${SYNC_BASE_URL}" ]; then
  APP_BINARY="${APP_PATH}/Contents/Frameworks/App.framework/Versions/A/App"
  if [ ! -f "${APP_BINARY}" ]; then
    echo "找不到 AOT 产物：${APP_BINARY}" >&2
    exit 1
  fi
  # AOT 快照里是明文字符串，直接按字节比对即可。
  if ! LC_ALL=C grep -qaF -- "${SYNC_BASE_URL}" "${APP_BINARY}"; then
    echo "SYNC_BASE_URL 未编入 App.framework，打出的包将无法使用云同步。" >&2
    exit 1
  fi
  echo "    校验通过：SYNC_BASE_URL 已编入 App.framework"
fi

if [ -n "${CATALOG_BASE_URL}" ]; then
  APP_BINARY="${APP_PATH}/Contents/Frameworks/App.framework/Versions/A/App"
  if [ ! -f "${APP_BINARY}" ]; then
    echo "找不到 AOT 产物：${APP_BINARY}" >&2
    exit 1
  fi
  if ! LC_ALL=C grep -qaF -- "${CATALOG_BASE_URL}" "${APP_BINARY}"; then
    echo "CATALOG_BASE_URL 未编入 App.framework，打出的包将无法热更新数据。" >&2
    exit 1
  fi
  echo "    校验通过：CATALOG_BASE_URL 已编入 App.framework"
fi

echo "==> 生成安装窗口背景"
swift scripts/macos_dmg_background.swift "${BG_DIR}"

echo "==> 准备 dmgbuild"
DMGBUILD="${DMGBUILD:-}"
if [ -z "${DMGBUILD}" ]; then
  if python3 -c "import dmgbuild" >/dev/null 2>&1; then
    DMGBUILD="python3 -m dmgbuild"
  elif [ -x "${ROOT}/.venv-dmg/bin/dmgbuild" ]; then
    DMGBUILD="${ROOT}/.venv-dmg/bin/dmgbuild"
  else
    echo "    安装 dmgbuild（只在首次需要，约 10 秒）"
    python3 -m venv "${ROOT}/.venv-dmg" >/dev/null 2>&1 \
      && "${ROOT}/.venv-dmg/bin/pip" install -q dmgbuild >/dev/null 2>&1 \
      && DMGBUILD="${ROOT}/.venv-dmg/bin/dmgbuild" \
      || true
  fi
fi

mkdir -p "${ROOT}/dist"
rm -f "${OUT}"

if [ -n "${DMGBUILD}" ]; then
  echo "==> 生成 DMG（带自定义背景与图标布局）"
  # shellcheck disable=SC2086 # DMGBUILD 允许带参数
  ${DMGBUILD} -s scripts/macos_dmg_settings.py \
    -D "app_path=${ROOT}/${APP_PATH}" \
    -D "app_name=${PRODUCT_NAME}.app" \
    -D "background=${BG_DIR}/background.png" \
    "天工阁 v${VERSION}" "${OUT}"
else
  echo "::warning::未安装 dmgbuild，退回到无背景的纯 hdiutil 打包"
  STAGE="${ROOT}/build/macos/dmg-stage"
  rm -rf "${STAGE}"
  mkdir -p "${STAGE}"
  ditto "${APP_PATH}" "${STAGE}/${PRODUCT_NAME}.app"
  ln -s /Applications "${STAGE}/Applications"
  hdiutil create -volname "天工阁 v${VERSION}" -srcfolder "${STAGE}" \
    -ov -format UDZO "${OUT}" >/dev/null
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
