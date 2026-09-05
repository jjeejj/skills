## 结案：根因分析 (RCA) 与修复报告

### 现象与证据链
在 `macOS 15` 环境下快速切换系统外观时触发 `EXC_BAD_ACCESS`。

通过抓取崩溃转储堆栈定位到调用链：
```text
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_ACCESS (code=1, address=0x20)
    frame #0: 0x0000000100012f4c App`ThemeObserver.updateColors(self=0x0000600000214000) at ThemeManager.swift:84:18
    frame #1: 0x00007ff810234a10 CoreFoundation`__CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 137
```
排查发现：`DistributedNotificationCenter` 在派发系统主题变更通知时，`ThemeObserver` 的闭包强持有了已释放的 View 控制器弱引用指针，但未进行空指针保护。

### 根因分析
1. **多重监听未清理**：页面重载时重复调用了 `registerThemeObserver()`，但反注册逻辑仅在 `deinit` 中处理，由于逃逸闭包形成了隐式强引用循环，导致析构函数未被调用。
2. **生命周期不一致**：系统通知通过全局队列广播，触发回调时原视图层级可能已脱离 Window，访问解引用属性引发野指针崩溃。

### 修复细节与改动
- **改动文件**：
  - `Sources/App/Managers/ThemeManager.swift`：重构观察者注册机制，采用弱引用包装器（Weak Box Pattern），并在 `viewWillDisappear` 中显式反注册。
  - `Tests/AppTests/ThemeManagerTests.swift`：补充并发与连续通知派发的单元测试。
- **关联 Commit**：`3a9f2e4` (`fix(theme): prevent dangling pointer access during rapid theme transitions (Fixes #52)`)

### 验证情况
- **自动化测试**：`swift test --filter ThemeManagerTests` 12 项测试全部通过（包含 100 次高频模拟通知切换）。
- **手工验证**：在 macOS 15.0 实机上执行 50 次连续快速切换外观模式，页面渲染平滑，无内存泄漏与崩溃。

### 验收步骤
1. 拉取分支 `git checkout fix/theme-crash`；
2. 运行应用并进入“个人中心”；
3. 打开系统设置连续切换浅色/暗色外观，确认页面表现正常。
