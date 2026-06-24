;Include Modern UI

Unicode true

!define MUI_COMPONENTSPAGE_NODESC

  !include "MUI.nsh"

;--------------------------------
;General

!searchparse /file licecap_version.h '#define LICECAP_VERSION "v' VER_MAJOR '.' VER_MINOR '"'

SetCompressor lzma



  ;Name and file
  Name "LICEcap v${VER_MAJOR}.${VER_MINOR} 汉化版"
  OutFile "licecap${VER_MAJOR}${VER_MINOR}-install.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\LICEcap"

  ;Get installation folder from registry if available
  InstallDirRegKey HKLM "Software\LICEcap" ""

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "SimpChinese"




;--------------------------------
;Installer Sections


Section "必需文件"

  SectionIn RO
  SetOutPath "$INSTDIR"


  File release\LICEcap.exe
;  File release\LICEcap_cli.exe

  ;Store installation folder
  WriteRegStr HKLM "Software\LICEcap" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  File license.txt
  File whatsnew.txt

SectionEnd

Section "桌面快捷方式"
  CreateShortcut "$DESKTOP\LICEcap.lnk" "$INSTDIR\LICEcap.exe"
SectionEnd

Section "开始菜单快捷方式"

  SetOutPath $SMPROGRAMS\LICEcap
  CreateShortcut "$OUTDIR\LICEcap.lnk" "$INSTDIR\LICEcap.exe"
  CreateShortcut "$OUTDIR\LICEcap 许可证.lnk" "$INSTDIR\license.txt"
  CreateShortcut "$OUTDIR\更新说明.lnk" "$INSTDIR\whatsnew.txt"
  CreateShortcut "$OUTDIR\卸载 LICEcap.lnk" "$INSTDIR\uninstall.exe"

  SetOutPath $INSTDIR

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  DeleteRegKey HKLM "Software\LICEcap"

  Delete "$INSTDIR\LICEcap_cli.exe"
  Delete "$INSTDIR\LICEcap.exe"

  Delete "$INSTDIR\license.txt"
  Delete "$INSTDIR\whatsnew.txt"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$SMPROGRAMS\LICEcap\*.lnk"
  RMDir $SMPROGRAMS\LICEcap
  Delete "$DESKTOP\LICEcap.lnk"

  RMDir "$INSTDIR"

SectionEnd
