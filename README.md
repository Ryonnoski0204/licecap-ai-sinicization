# LICEcap 简体中文汉化版

[![构建 Windows 汉化版](https://github.com/Ryonnoski0204/licecap-ai-sinicization/actions/workflows/build.yml/badge.svg)](https://github.com/Ryonnoski0204/licecap-ai-sinicization/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/Ryonnoski0204/licecap-ai-sinicization)](https://github.com/Ryonnoski0204/licecap-ai-sinicization/releases/latest)
[![License](https://img.shields.io/badge/license-GPL%20v2-blue)](license.txt)

[LICEcap](https://www.cockos.com/licecap/) 是 Cockos 出品的轻量级屏幕录制工具,可把屏幕区域录制为 **GIF** 动图或 **LCF** 文件。本仓库在其官方 **v1.32** 源码基础上做了**简体中文汉化**,并增加了若干实用功能,通过 GitHub Actions 自动构建出汉化版安装包。

## ✨ 功能特性

- **全面汉化** —— 程序界面、所有对话框、安装程序向导、开始菜单/桌面快捷方式名称均为简体中文(GPL 许可证文本按协议要求保留英文原文)。
- **录制到剪贴板** —— 主界面新增「录制到剪贴板」按钮:一键框选录制,停止后 GIF 自动以文件形式进入剪贴板,可直接在 **QQ / 微信** 等聊天框 `Ctrl+V` 粘贴发送,**动画保留**。
- **窄窗口渐进布局 + ☰ 控制菜单** —— 窗口拖窄时底部按钮按顺序逐个隐藏,一旦放不下就在右下角出现 **☰** 控制按钮;左键点击或右键它即可弹出录制控制菜单(录制 / 录制到剪贴板 / 暂停 / 继续 / 停止 / 退出),最窄时只剩 ☰,操作不丢失。
- **自动构建** —— 推送到任意分支即由 GitHub Actions 在 Windows 上编译并用 NSIS 打包,产物可在 Actions 的 Artifacts 或 Releases 下载。

## 📥 下载安装

前往 [**Releases 页面**](https://github.com/Ryonnoski0204/licecap-ai-sinicization/releases/latest) 下载:

| 文件 | 说明 |
|---|---|
| `licecap132-install.exe` | 安装版(推荐) |
| `LICEcap.exe` | 免安装,直接运行 |

> 仅提供 Windows 版本。

## 🔨 从源码构建

### 方式一:GitHub Actions(无需本地环境)

仓库已内置工作流 [`.github/workflows/build.yml`](.github/workflows/build.yml)。向任意分支 `push`,或在 Actions 页面手动触发 `workflow_dispatch`,即可在云端 `windows-latest` 上自动完成编译与打包,产物在该次运行的 **Artifacts** 中。

### 方式二:本地 Visual Studio

需要 **Visual Studio 2022**(含 C++ 桌面开发组件)与 **NSIS 3**。

```sh
# 编译(Release / Win32)
msbuild licecap\licecap\licecap.sln /p:Configuration=Release /p:Platform=Win32 /p:PlatformToolset=v143

# 拷贝产物到安装脚本期望的位置
copy licecap\licecap\Release_new\licecap.exe licecap\release\LICEcap.exe

# 打包安装程序(在 licecap 目录下)
cd licecap
makensis installer.nsi   # 产出 licecap132-install.exe
```

## 🌏 汉化技术说明

- **对话框资源**(`licecap.rc`):使用 `#pragma code_page(65001)` + UTF-8(含 BOM)保存,字体统一为 `MS Shell Dlg` 以正确显示中文;并用 `<windows.h>` 替代未随精简版 VS 安装的 `afxres.h`。
- **运行时字符串**(`licecap_ui.cpp`):引入 WDL 的 `win32_utf8.h`,使 `SetWindowText` / `SetDlgItemText` 等按 UTF-8 处理中文;工程开启 `/utf-8` 编译开关,保证中文窄字符串字面量被正确编码。
- 详细设计记录见 [`docs/superpowers/specs/`](docs/superpowers/specs/)。

## 🙏 致谢

- 原作:[Cockos Incorporated — LICEcap](https://www.cockos.com/licecap/),源码基于其官方仓库与 [WDL](https://www.cockos.com/wdl/)。
- 本项目仅做汉化与功能增强,所有版权归原作者所有。

## 📄 许可证

与上游一致,采用 **GNU GPL v2**,详见 [`license.txt`](license.txt)。按 GPL 条款要求,许可证文件本身保留英文原文,不作翻译。
