; 天工阁安装器的单文件外壳：静默解压 + 启动自绘安装向导。
; 由 tool/build_windows.ps1 调用，路径通过 /D 传入：
;   makensis /DAPP_VERSION=1.1.2 /DSOURCE_DIR=... /DOUTPUT_FILE=... /DICON_FILE=... tool\setup_sfx.nsi
Unicode true
RequestExecutionLevel user
SilentInstall silent
SetCompressor /SOLID lzma
SetCompressorDictSize 64
CRCCheck on

!ifndef APP_VERSION
  !define APP_VERSION "0.0.0"
!endif
!ifndef SOURCE_DIR
  !error "SOURCE_DIR is required"
!endif
!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE is required"
!endif

Name "天工阁 安装程序"
OutFile "${OUTPUT_FILE}"
!ifdef ICON_FILE
  Icon "${ICON_FILE}"
!endif

InstallDir "$TEMP\TiangongGeSetup-${APP_VERSION}"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_DIR}\*.*"

  ExecWait '"$INSTDIR\tiangongge_installer.exe"'

  ; 安装向导退出后再清理临时目录（稍等，避免文件句柄未释放）
  Sleep 500
  SetOutPath "$TEMP"
  RMDir /r "$INSTDIR"
SectionEnd
