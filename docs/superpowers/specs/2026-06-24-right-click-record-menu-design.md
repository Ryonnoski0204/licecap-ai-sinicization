# 新功能:右键菜单控制录制(Windows)— 设计文档

- 日期:2026-06-24
- 分支:`right-click-menu`(原分支 `main`)
- 目标平台:仅 Windows

## 1. 目标

右键点击 LiceCap 窗口(标题栏或取景框)弹出上下文菜单,提供录制相关操作,免去必须点底部按钮。

## 2. 关键技术点

LiceCap 的 `WM_NCHITTEST`(licecap_ui.cpp:1968)把**整个客户区(含取景框)都返回 `HTCAPTION`**(为支持拖动取景框移动窗口)。因此右键窗口任意位置,系统都视为右键标题栏,发送 `WM_NCRBUTTONUP`(wParam=`HTCAPTION`)。一个处理点即可覆盖"标题栏 + 取景框"右键。

`win32_utf8` 已 hook `InsertMenu`→`InsertMenuUTF8`,菜单文字用 UTF-8 中文可正常显示;分隔符用原生 `InsertMenuW` 添加(避免 UTF-8 包装处理 NULL 文本)。

## 3. 菜单内容(随录制状态动态生成)

| 状态 (`g_cap_state`) | 菜单项 |
|---|---|
| 停止 (0) | `录制...` / `录制到剪贴板` / 分隔符 / `退出 LICEcap` |
| 录制中 (1) | `暂停` / `停止` |
| 暂停中 (2) | `继续` / `停止` |

菜单项映射到现有命令(行为与点按钮完全一致):
- `录制...` / `暂停` / `继续` → `IDC_REC`(该按钮本身随状态多功能:停止时录制、录制中暂停、暂停中继续)
- `录制到剪贴板` → `IDC_REC_CLIP`
- `停止` → `IDC_STOP`
- `退出 LICEcap` → 自定义命令 `CTXCMD_EXIT`,触发 `WM_CLOSE`(停止状态下关闭程序)

## 4. 实现方案

只改 `licecap_ui.cpp`:

### 4.1 新增函数(放在 `liceCapMainProc` 之前,`#ifdef _WIN32`)
```
static void ShowRecordContextMenu(HWND hwnd, int x, int y);
```
- `CreatePopupMenu` → 按 `g_cap_state` 用 `InsertMenu`(UTF-8 文字)添加项,分隔符用 `InsertMenuW`
- `TrackPopupMenu(TPM_RETURNCMD|TPM_RIGHTBUTTON, x, y, ...)` 取返回命令
- `DestroyMenu`
- 返回命令:`CTXCMD_EXIT` → `PostMessage(WM_CLOSE)`;其余 → `SendMessage(WM_COMMAND, MAKEWPARAM(cmd, BN_CLICKED))`
- `CTXCMD_EXIT` 取 `0xE001`(不与 1001–1025 的 `IDC_*` 冲突)

### 4.2 消息处理(`liceCapMainProc` 内,`#ifdef _WIN32`)
```
case WM_NCRBUTTONUP:
  if (wParam == HTCAPTION) {
    ShowRecordContextMenu(hwndDlg, (short)LOWORD(lParam), (short)HIWORD(lParam)); // lParam 为屏幕坐标
    return 1; // 已处理, 阻止默认系统菜单
  }
  break;
```

## 5. 影响文件
- `licecap/licecap_ui.cpp`

## 6. 验证与限制
- **成功标准:** CI 编译通过;本机运行:右键窗口弹出菜单,文字为中文;各状态菜单项正确;点菜单项能触发对应录制/停止/退出。
- 本机可用程序化 `WM_NCRBUTTONUP` 或读菜单内容验证;实际右键交互建议用户手动确认一次。

## 7. 不做的事(YAGNI)
- 不加"插入文本帧"等用户未要求的项(本次仅录制/剪贴板录制/暂停/继续/停止/退出)。
- 不做 macOS 端(SWELL 菜单机制不同)。
- 不改动底部按钮(右键菜单是补充入口)。
