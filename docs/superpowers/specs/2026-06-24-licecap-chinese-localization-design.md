# LiceCap 汉化并重新打包(Windows)— 设计文档

- 日期:2026-06-24
- 分支:`chinese-localization`(原分支 `main`)
- 目标平台:仅 Windows
- 打包方式:GitHub Actions 云端自动构建(本机无 MSVC/Windows SDK/NSIS)

## 1. 目标

把 LiceCap(屏幕录制生成 GIF/LCF 的工具)的 Windows 版**全部用户可见文本汉化为简体中文**,并通过 GitHub Actions 在云端自动编译、用 NSIS 打包成中文安装程序。

"全部中文"范围:
- 程序界面(对话框、按钮、标签、运行时状态栏与标题栏)
- 安装程序界面(NSIS 向导、组件名、快捷方式名)
- 安装包名称标注"汉化版"

**例外:** `license.txt` 是 GNU GPL v2 法律文本,GPL 条款本身规定 "changing it is not allowed"(禁止修改该许可证文件),翻译它会违反许可证,故**保留英文原文**;但安装界面中指向它的快捷方式名称可中文化。`whatsnew.txt`(历史变更日志)保留英文原文。

## 2. 中文编码方案(技术核心,决定成败)

项目在 Windows 上字符集为 `MultiByte`,并链接了 `WDL/win32_utf8.c`,后者通过宏把 `SetWindowText` / `SetDlgItemText` / `GetDlgItemText` / `MessageBox` / `GetOpenFileName` / `GetSaveFileName` 等重定向为 UTF-8 版本。因此:

- **`.cpp` 源码字符串**:直接写 UTF-8 中文字面量即可经 `win32_utf8` 正确显示。**但必须给编译器加 `/utf-8` 开关**,否则 MSVC 在英文 CI 环境(执行字符集为系统 ANSI 代码页)下会把窄字符串里的中文错误转码并丢失。
  - 实现:在 `licecap/licecap/licecap.vcxproj` 的各 `ClCompile` 段加 `<AdditionalOptions>/utf-8 %(AdditionalOptions)</AdditionalOptions>`。该开关对纯 ASCII 的 WDL 源无副作用。
- **`.rc` 对话框资源**:对话框模板里的字符串在资源中以 UTF-16 存储,由 `rc.exe` 按 `#pragma code_page` 指定的代码页从源字节解码。
  - 实现:把 `licecap/licecap.rc` 的 `#pragma code_page(1252)` 改为 `#pragma code_page(65001)`,并将该文件以 **UTF-8** 保存,字符串改为中文。
- **NSIS 脚本**:含中文的 `installer.nsi` 以 UTF-8 保存,并在脚本顶部加 `Unicode true`,使用简体中文语言包。

## 3. 汉化字符串清单

### 3.1 `licecap/licecap.rc`(对话框资源)

主窗口 `IDD_DIALOG1`:
| 控件 | 原文 | 译文 |
|---|---|---|
| IDC_INSERT | Insert... | 插入... |
| IDC_REC | Record... | 录制... |
| IDC_STOP | Stop | 停止 |
| IDC_MAXFPS_LBL | Max FPS: | 最大帧率: |
| IDC_DIMLBL_1 | Size: | 尺寸: |
| IDC_DIMLBL | x | x(保留) |
| IDC_STATUS | Status (i.e. ...) | 运行时被覆盖,可保留占位 |

保存选项面板 `IDD_SAVEOPTS`:
| 原文 | 译文 |
|---|---|
| Display in animation | 在动画中显示 |
| title frame: | 标题帧: |
| sec | 秒 |
| elapsed time | 已用时间 |
| mouse button press | 鼠标点击 |
| Big font | 大字体 |
| WEBM options... | WEBM 选项... |
| Control+Alt+P pauses recording | Control+Alt+P 暂停录制 |
| .GIF repeat count (0=infinite): | .GIF 循环次数 (0=无限): |
| Use .GIF transparency for smaller files | 使用 .GIF 透明以减小文件 |
| Automatically stop after | 自动停止于 |
| seconds | 秒 |

插入文本帧 `IDD_INSERT`:
| 原文 | 译文 |
|---|---|
| Insert text frame (CAPTION) | 插入文本帧 |
| Duration: | 时长: |
| Alpha: | 透明度: |
| Insert (0) | 插入 (0) |
| Close | 关闭 |

WEBM 选项 `IDD_OPTIONS`:
| 原文 | 译文 |
|---|---|
| WEBM options (CAPTION + GROUPBOX) | WEBM 选项 |
| Video bitrate: | 视频码率: |
| Audio bitrate: | 音频码率: |
| kbps | kbps(保留单位) |
| Ok | 确定 |

### 3.2 `licecap/licecap_ui.cpp`(运行时字符串)

| 行(约) | 原文 | 译文 |
|---|---|---|
| 565 / 623 | `PREROLL: %d - ` | `准备中: %d - ` |
| 569 | `Paused - ` | `已暂停 - ` |
| 591 | ` @ %.1ffps` | ` @ %.1f 帧/秒` |
| 607 | `REAPER_LICEcap ... [stopped]` | `... [已停止]` |
| 609 | `LICEcap ... [stopped]` | `LICEcap ... [已停止]` |
| 627 | ` [recording]` / ` [paused]` | ` [录制中]` / ` [已暂停]` |
| 658 | `Record...`(按钮复位) | `录制...` |
| 791 / 820 | `Title`(占位符,显示与比较两处需同步改) | `标题` |
| 993 / 1029 | `Insert (%d)` | `插入 (%d)` |
| 1510 | `GIF files (*.gif)` | `GIF 文件 (*.gif)` |
| 1512 | `LiceCap files (*.lcf)` | `LiceCap 文件 (*.lcf)` |
| 1515 | `WEBM files (*.webm)` | `WEBM 文件 (*.webm)` |
| 1556 | `Choose file for recording` | `选择录制保存位置` |

> 品牌名 **LICEcap / LiceCap** 保留;格式标识 ` LCF` / ` GIF` / 视频扩展名、尺寸 `%dx%d`、时间 `%d:%02d`、INI 键名等不属于用户可读文案,保留不动。
> 实现时会再完整扫描一遍 `licecap_ui.cpp` 全部窄字符串字面量,确保无遗漏(以上为已确认清单)。

### 3.3 `licecap/installer.nsi`(NSIS 安装程序)

- 顶部加 `Unicode true`;`!insertmacro MUI_LANGUAGE "English"` → `"SimpChinese"`。
- `Name "LICEcap v${VER_MAJOR}.${VER_MINOR}"` → `Name "LICEcap v${VER_MAJOR}.${VER_MINOR} 汉化版"`。
- 组件 Section 名:`Required files`→`必需文件`、`Desktop Icon`→`桌面快捷方式`、`Start Menu Shortcuts`→`开始菜单快捷方式`。
- 快捷方式名:`LICEcap License`→`LICEcap 许可证`、`Whatsnew.txt`→`更新说明`、`Uninstall LICEcap`→`卸载 LICEcap`。
- 安装目录、注册表键、文件名等保持英文不变(避免破坏安装/卸载逻辑)。

## 4. GitHub Actions 自动构建

新增 `.github/workflows/build.yml`:

- 触发:`push`(到 `main` / `chinese-localization`)+ 手动 `workflow_dispatch`。
- runner:`windows-latest`(自带 VS2022 + Windows 10 SDK)。
- 步骤:
  1. `actions/checkout`
  2. `microsoft/setup-msbuild`
  3. 编译:`msbuild licecap\licecap\licecap.sln /p:Configuration=Release /p:Platform=Win32 /p:PlatformToolset=v143`
     - 原工程为 `v120`(VS2013),runner 无此工具集,故命令行覆盖为 `v143`。
     - 输出位于 `licecap\licecap\Release_new\licecap.exe`。
  4. 拷贝产物到 `installer.nsi` 期望路径:`licecap\release\LICEcap.exe`。
  5. 安装 NSIS:`choco install nsis -y`(或 `makensis` 已内置)。
  6. 打包:在 `licecap\` 目录运行 `makensis installer.nsi` → 产出 `licecap\licecap132-install.exe`。
  7. `actions/upload-artifact` 上传安装包(及独立 `LICEcap.exe`)。

不永久修改工程的 `PlatformToolset`(命令行覆盖),保持源工程对本地 VS2013 用户的兼容性;`/utf-8` 则写入工程(现代 VS 与汉化均需要)。

## 5. 验证与限制

- **成功标准:** GitHub Actions 工作流全绿;Artifacts 中可下载到 `licecap132-install.exe` 与 `LICEcap.exe`。
- **本地限制:** 本机无 Windows 构建环境,无法在本地编译运行验证中文实际显示效果。代码层面会做静态核对(字符串、编码、工程开关、CI 脚本);最终中文显示效果需由 CI 产出的安装包在 Windows 上实测确认。
- 建议交付后下载安装包安装一次,核对:主界面按钮/标签、保存选项面板、插入文本帧与 WEBM 选项对话框、录制时状态栏与标题栏、文件保存对话框、安装/卸载向导,均为中文。

## 6. 不做的事(YAGNI)

- 不做 macOS 端打包(本机非 mac;用户只要 Windows)。
- 不翻译 GPL `license.txt` 与 `whatsnew.txt`。
- 不重构既有代码逻辑,仅做汉化所需的最小改动 + CI + 编码开关。
- 不引入多语言切换框架(目标是单一中文版)。
