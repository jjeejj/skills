# [Bug]: Application crashes with SIGSEGV when toggling Dark Mode in Profile Settings

## Symptoms
On macOS 15.0, rapidly toggling between Light and Dark appearance modes in Control Center causes the profile view controller to crash with a segmentation fault.

- **OS**: macOS Sequoia 15.0 (24A335)
- **Architecture**: Apple Silicon (M2 Max)
- **Crash Signature**: `EXC_BAD_ACCESS (SIGSEGV)` at `ThemeManager.swift:84`

## Steps to Reproduce
1. Open the application and navigate to the "Profile" screen;
2. Open macOS System Settings -> Appearance;
3. Toggle between Light and Dark appearance 2-3 times in quick succession;
4. The main application window disappears and the console outputs Segmentation Fault.

## Crash Evidence
![Crash Log](https://github.com/user-attachments/assets/7a8e91b4-4567-48de-b567-c23456789abc)

## Related Issues
- **Preceding Feature**: #12 (Add dynamic system theme observation)

## Impact
All macOS 15+ users with dynamic/auto appearance enabled experience frequent crashes when visiting the Profile view.

## Preliminary Investigation & Suspected Root Cause
- `ThemeObserver` may be deallocated before unregistering notification observers, leading to dangling pointer callbacks.
- Background notification handler might be updating UI elements without dispatching to the main thread.

## Acceptance Criteria
- Toggling appearance 20+ times consecutively does not trigger crashes or UI glitches.
- Unit test suite `ThemeManagerTests` adds high-concurrency observer deregistration test and passes cleanly.
