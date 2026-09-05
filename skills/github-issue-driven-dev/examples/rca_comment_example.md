## Resolution: Root Cause Analysis (RCA) & Fix Summary

### Symptoms & Evidence Chain
Observed `EXC_BAD_ACCESS` when rapidly toggling macOS appearance on Sequoia 15.0.

Crash stack trace extracted from diagnostic log:
```text
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_BAD_ACCESS (code=1, address=0x20)
    frame #0: 0x0000000100012f4c App`ThemeObserver.updateColors(self=0x0000600000214000) at ThemeManager.swift:84:18
    frame #1: 0x00007ff810234a10 CoreFoundation`__CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 137
```
Investigation revealed that when `DistributedNotificationCenter` dispatched theme change notifications, `ThemeObserver` closures held strong references to already-deallocated controller weak wrappers without null checks.

### Root Cause Analysis (RCA)
1. **Uncleaned Listeners**: Refreshing the view re-invoked `registerThemeObserver()`, but unregistration only occurred in `deinit`. Escaped closures created an implicit retain cycle that prevented deinit invocation.
2. **Lifecycle Mismatch**: Notifications broadcast on a global queue while the view hierarchy was already detached from the active window, triggering dangling pointer dereference.

### Fix Details
- **Modified Files**:
  - `Sources/App/Managers/ThemeManager.swift`: Refactored observer registration to use a Weak Box pattern; explicitly deregister in `viewWillDisappear`.
  - `Tests/AppTests/ThemeManagerTests.swift`: Added high-frequency concurrent observer stress tests.
- **Related Commit**: `3a9f2e4` (`fix(theme): prevent dangling pointer access during rapid theme transitions (Fixes #52)`)

### Verification
- **Automated Tests**: Ran `swift test --filter ThemeManagerTests` — all 12 tests passed (including 100 rapid simulated notification dispatches).
- **Manual QA**: Ran 50 rapid appearance toggles on physical macOS 15.0 machine with zero crashes or leaks observed.

### Acceptance Steps
1. Checkout branch `git checkout fix/theme-crash`;
2. Run application and open Profile view;
3. Toggle Light/Dark mode in System Settings repeatedly to confirm smooth rendering without errors.
