param(
  [switch]$SkipApp,
  [switch]$SkipInstaller,
  [switch]$SkipSfx,
  [string]$AppBuildDir = "..\build\windows\x64\runner\Release"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Checked {
  param([scriptblock]$Command, [string]$Message)
  & $Command
  if ($LASTEXITCODE -ne 0) { throw $Message }
}

# 版本号以主工程 pubspec.yaml 为准，避免安装器与主程序版本漂移
$pubspec = Get-Content "..\pubspec.yaml" -Raw
if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
  throw "无法从 pubspec.yaml 读取版本号"
}
$version = $Matches[1]
Write-Host "天工阁版本：$version" -ForegroundColor Cyan

if (-not $SkipApp) {
  Write-Host "[1/4] 构建主程序…" -ForegroundColor Cyan
  Invoke-Checked { fvm flutter build windows --release } "主程序构建失败"
}

Write-Host "[2/4] 打包 payload.zip…" -ForegroundColor Cyan
Invoke-Checked {
  fvm dart run tool/package_payload.dart --input $AppBuildDir --output assets\payload\payload.zip
} "payload 打包失败"

if (-not $SkipInstaller) {
  Write-Host "[3/4] 构建安装器（APP_VERSION=$version）…" -ForegroundColor Cyan
  Invoke-Checked {
    fvm flutter build windows --release --dart-define=APP_VERSION=$version
  } "安装器构建失败"
}

$installer = "build\windows\x64\runner\Release\tiangongge_installer.exe"
if (Test-Path $installer) {
  $size = (Get-Item $installer).Length / 1MB
  Write-Host "完成：$installer（$([math]::Round($size,1)) MB）" -ForegroundColor Green
}

# 单文件外壳：静默解压安装器目录后启动自绘向导（需要 NSIS）
if (-not $SkipSfx) {
  if (-not (Get-Command makensis -ErrorAction SilentlyContinue)) {
    Write-Host "未找到 makensis，跳过单文件封装（安装：choco install nsis）" -ForegroundColor Yellow
  } else {
    Write-Host "[4/4] 封装单文件 Setup.exe…" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force dist | Out-Null
    $source = (Resolve-Path "build\windows\x64\runner\Release").Path
    $icon = (Resolve-Path "windows\runner\resources\app_icon.ico").Path
    $outFile = Join-Path (Get-Location) "dist\TiangongGe-Setup-$version-win64.exe"
    Invoke-Checked {
      makensis "/DAPP_VERSION=$version" "/DSOURCE_DIR=$source" "/DOUTPUT_FILE=$outFile" "/DICON_FILE=$icon" tool\setup_sfx.nsi
    } "单文件封装失败"
    $sfxSize = (Get-Item $outFile).Length / 1MB
    Write-Host "完成：$outFile（$([math]::Round($sfxSize,1)) MB）" -ForegroundColor Green
  }
}

Write-Host "提示：正式分发前需用 signtool 对 exe 做 Authenticode 签名。" -ForegroundColor Yellow
