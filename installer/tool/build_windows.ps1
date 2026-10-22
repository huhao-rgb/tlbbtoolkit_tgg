param(
  [switch]$SkipApp,
  [switch]$SkipInstaller,
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
  Write-Host "[1/3] 构建主程序…" -ForegroundColor Cyan
  Invoke-Checked { fvm flutter build windows --release } "主程序构建失败"
}

Write-Host "[2/3] 打包 payload.zip…" -ForegroundColor Cyan
Invoke-Checked {
  fvm dart run tool/package_payload.dart --input $AppBuildDir --output assets\payload\payload.zip
} "payload 打包失败"

if (-not $SkipInstaller) {
  Write-Host "[3/3] 构建安装器（APP_VERSION=$version）…" -ForegroundColor Cyan
  Invoke-Checked {
    fvm flutter build windows --release --dart-define=APP_VERSION=$version
  } "安装器构建失败"
}

$installer = "build\windows\x64\runner\Release\tiangongge_installer.exe"
if (Test-Path $installer) {
  $size = (Get-Item $installer).Length / 1MB
  Write-Host "完成：$installer（$([math]::Round($size,1)) MB）" -ForegroundColor Green
  Write-Host "提示：正式分发前需用 signtool 对 exe 做 Authenticode 签名。" -ForegroundColor Yellow
}
