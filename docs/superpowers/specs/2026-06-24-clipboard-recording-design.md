# 新功能:录制到剪贴板(Windows)— 设计文档

- 日期:2026-06-24
- 分支:`clipboard-recording`(原分支 `main`)
- 目标平台:仅 Windows

## 1. 目标

在 LiceCap 主界面新增一个 **[录制到剪贴板]** 按钮。点击后直接框选录制(不弹保存对话框),停止后把录好的 GIF 以「文件」形式放入剪贴板,使用户可直接在 QQ / 微信聊天框等位置 `Ctrl+V` 粘贴发送,**动画保留**。

## 2. 关键技术决策

### 2.1 剪贴板格式 = CF_HDROP(复制文件)
GIF 动图没有标准的"动画位图"剪贴板格式。要让 QQ/微信粘贴后保留动画,唯一可靠方式是把 `.gif` **文件**放入剪贴板(`CF_HDROP`,等同于在资源管理器里复制该文件)。聊天软件粘贴文件型图片时按图片消息处理,动画保留。若改放位图(`CF_DIB`)只能得到静态一帧,不满足需求。

- 使用 Unicode 形式的 `DROPFILES`(`fWide = TRUE`),路径由 `g_last_fn`(UTF-8)经 `WDL_UTF8ToWC` 转 UTF-16,兼容中文用户名/路径。

### 2.2 临时文件
- 路径:`%TEMP%\LICEcap\clip_<timeGetTime>.gif`,录制前 `CreateDirectory` 确保目录存在。
- 录制完成后**不删除**:剪贴板的 `CF_HDROP` 只是引用磁盘文件,用户粘贴时系统才去读该文件,删了会导致粘贴失败。旧文件留在临时目录,由系统/用户后续清理。
- 时间戳文件名避免连续录制时覆盖正在被引用的文件。

### 2.3 录制设置
剪贴板模式跳过保存对话框,沿用已持久化的设置(`g_prefs` 标题帧/透明位、`g_titlems`、`g_gif_loopcount` 等),与上一次普通录制一致。强制 `.gif` 格式。

## 3. 实现方案

### 3.1 代码重构(避免重复)
当前 `IDC_REC` 分支里"创建编码器 + 窗口置顶 + 开始录制"是一大段内联代码(约 `licecap_ui.cpp:1574-1724`)。提取为共享函数:

```
static bool StartCaptureToCurrentFile(HWND hwndDlg);
```

- 输入:`g_last_fn` 已设好(扩展名决定 gif/webm/lcf)。
- 行为:注册热键、创建位图、按扩展名创建对应编码器、写标题帧、窗口置顶、`g_cap_state=1`、刷新界面。返回是否成功开始。
- `IDC_REC`:`WDL_ChooseFileForSave` 成功 + 写 `lastfn` 后调用它。
- `IDC_REC_CLIP`:生成临时 `g_last_fn` + 置 `g_clipboard_mode=true` 后调用它(不写 `lastfn`)。

### 3.2 新增控件与状态
- `resource.h`:新增 `IDC_REC_CLIP`(取未使用的 ID)。
- `licecap.rc`:`IDD_DIALOG1` 底部中间空白处新增 `PUSHBUTTON "录制到剪贴板",IDC_REC_CLIP`(约 `x=160,y=320,w=95,h=12`,与帧率/尺寸输入框同排)。
- 全局:`bool g_clipboard_mode=false;`

### 3.3 录制结束处理
在 `Capture_Finish` 末尾(`g_cap_gif` 已 delete、gif 文件已写完整之后):
- 若 `g_clipboard_mode`:调用 `CopyGifToClipboard(hwndDlg, g_last_fn)`,在状态栏/标题提示"已复制到剪贴板",然后 `g_clipboard_mode=false`。

```
static bool CopyGifToClipboard(HWND hwnd, const char *utf8path);
// OpenClipboard -> EmptyClipboard -> 构造 Unicode DROPFILES -> SetClipboardData(CF_HDROP) -> CloseClipboard
```

### 3.4 录制时按钮显隐
`IDC_REC_CLIP` 在录制开始时隐藏、停止时显示,跟随现有帧率/尺寸输入框的显隐逻辑处理(实现时定位该切换点统一处理;若主界面靠 `IDC_STATUS` 覆盖显示,则录制时隐藏该按钮避免与状态文字重叠)。

### 3.5 顺带修复汉化遗漏
`licecap_ui.cpp` 中录制时按钮文字 `[pause]` → `[暂停]`、`[unpause]` → `[继续]`(此前漏译)。

## 4. 影响文件
- `licecap/resource.h`
- `licecap/licecap.rc`
- `licecap/licecap_ui.cpp`

## 5. 验证与限制
- **成功标准:** CI 编译通过;本机实跑:点 [录制到剪贴板] → 框选 → 录一段 → 停止 → 状态栏提示已复制 → 在资源管理器/聊天框 `Ctrl+V` 得到 gif 文件(动图)。
- **本机可验证:** 这台是 Windows,可下载 CI 产物实跑并用脚本检查剪贴板是否含 `CF_HDROP` 且指向 .gif。
- 中文显示/布局沿用上次汉化方案(UTF-8 + win32_utf8 + `/utf-8`)。

## 6. 不做的事(YAGNI)
- 不做 CF_DIB 静态位图后备(会让部分目标程序退化为静态图,与"保动画"目标冲突)。
- 不自动清理历史临时文件。
- 不做 macOS 端。
- 不新增录制设置项,沿用现有。
