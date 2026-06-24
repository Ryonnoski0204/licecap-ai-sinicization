# 重做:窄窗口控制按钮 + 菜单(Windows)— 设计文档

- 日期:2026-06-24
- 分支:`right-click-menu`(原分支 `main`;在上一版"右键标题栏菜单"基础上重做)
- 目标平台:仅 Windows

## 1. 背景与目标

上一版实现是"右键标题栏/取景框任意处弹菜单",用户反馈方向不对。重新定位为:

**窗口宽度过小、常规底部按钮放不下时,只显示一个 ☰ 控制按钮;左键点击或右键它弹出操作菜单。** 解决窄窗口下没有可见操作入口的问题。

- **正常宽度**:显示常规底部按钮(现状不变),隐藏 ☰
- **窄窗口**:隐藏所有常规底部控件(帧率/尺寸/录制到剪贴板/录制/停止/插入/状态栏),只在右下角显示 ☰
- **☰ 控制按钮**:左键点击 **或** 右键 → 弹出动态菜单(录制/录制到剪贴板/暂停/继续/停止/退出)
- **去掉**上一版"右键窗口任意处弹菜单"(`WM_NCRBUTTONUP`)

## 2. 实现方案(改 `resource.h` + `licecap.rc` + `licecap_ui.cpp`)

### 2.1 新控件
- `resource.h`:`IDC_CTRL` = 1026
- `licecap.rc`:`IDD_DIALOG1` 右下角新增 `PUSHBUTTON "☰",IDC_CTRL,519,320,28,12`(与"停止"按钮同区,互斥显示)

### 2.2 窄窗口判断 + 统一显隐(重写 `UpdateDimBoxes`)
判断窄:中间的"录制到剪贴板"按钮右边超过"录制"按钮左边即为窄
```
narrow = recClip->last.right > recRec->last.left - 4
```
按 `narrow` 与 `g_cap_state` 统一设置各控件可见性(成为底部布局唯一显隐控制点):
| 控件 | 显示条件 |
|---|---|
| `IDC_CTRL` (☰) | `narrow` |
| `IDC_STATUS` | 录制中(state1) 且 非窄 |
| 帧率/尺寸标签与输入框 + `IDC_REC_CLIP` | 停止(state0) 且 非窄 |
| `IDC_REC` / `IDC_STOP` | 非窄 |
| `IDC_INSERT` | 暂停(state2) 且 非窄 |

### 2.3 控制按钮初始化与触发
- `init_item(IDC_CTRL,1,1,1,1)`(锚定右下)
- 左键:`WM_COMMAND` 的 `IDC_CTRL` → 取按钮屏幕矩形左下角作坐标 → `ShowRecordContextMenu`
- 右键:`WM_CONTEXTMENU`,若 `wParam == GetDlgItem(IDC_CTRL)` → `ShowRecordContextMenu`
- 复用现有 `ShowRecordContextMenu`(动态菜单)

### 2.4 删除与补调
- 删除 `WM_NCRBUTTONUP` 处理(上一版右键窗口弹菜单)
- 暂停 / 继续分支末尾补调 `UpdateDimBoxes`,使状态切换时窄窗口显隐正确(原有分散的 `ShowWindow(INSERT/STATUS)` 保留,会被 `UpdateDimBoxes` 覆盖,无害)

## 3. 验证与限制
- **成功标准:** CI 编译通过;本机:正常宽度显示常规按钮、无 ☰;拖窄到按钮放不下 → 只剩 ☰;左键/右键 ☰ 弹出菜单(中文);拖宽恢复。
- 本机可程序化 resize + 查询 `IDC_CTRL`/常规按钮可见性 + 发命令验证;实际拖拽手感建议用户确认。

## 4. 不做的事(YAGNI)
- 不保留右键窗口任意处弹菜单。
- 窄窗口下不显示状态栏/录制信息(用户明确"只显示一个控制按钮")。
- 不做 macOS 端。
