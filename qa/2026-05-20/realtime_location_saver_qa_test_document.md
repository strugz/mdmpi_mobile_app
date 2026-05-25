# Realtime Location Saver – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Realtime Location Saver |
| Feature Description | Validate the Settings-based Realtime Location Saver toggle, including enable/disable behavior, location-service and permission handling, persistence across app restarts, success/error feedback, and cross-platform stability. |
| Application Stack | Flutter, Dart, GetStorage, Location Services, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Realtime Location Saver | Settings toggle for local realtime location capture | Positive testing – toggle is visible and accessible in Settings | `RLS-001` | User is authenticated and can open the Settings screen. | 1. Open Settings.<br>2. Locate the **Realtime Location Saver** tile and switch.<br>3. Review subtitle and current toggle state. | Tile and switch are visible, readable, and tappable; UI is aligned correctly and responds to input. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline visibility and accessibility case. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Positive testing – enable saver when location services and permission are available | `RLS-002` | Location services are enabled and app location permission can be granted. | 1. Open Settings.<br>2. Toggle Realtime Location Saver on.<br>3. Observe immediate feedback and toggle state.<br>4. Move the device if needed to generate location updates. | Toggle turns on successfully and remains enabled; no crash occurs; feature starts without repeated prompts once permission is granted. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Note any success feedback or lack thereof. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Permission testing – location permission denied on first request | `RLS-003` | App permission can be denied from the OS prompt or settings. | 1. Turn the saver on when location permission has not been granted.<br>2. Deny the permission request.<br>3. Observe the resulting toggle state and messaging. | A clear warning is shown; the toggle returns to disabled state; feature does not appear enabled when permission is denied. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important permission-handling case. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Permission testing – location permission denied forever | `RLS-004` | Permission can be set to denied forever / permanently denied in OS settings. | 1. Configure location permission as permanently denied.<br>2. Attempt to turn the saver on.<br>3. Observe warning message and toggle behavior. | User receives clear guidance to enable permission in Settings; saver remains disabled and app stays stable. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Note differences between Android and iOS permission wording. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Service-state testing – location services disabled | `RLS-005` | Device location services can be turned off. | 1. Disable device location services.<br>2. Open Settings and toggle the saver on.<br>3. Observe messaging and resulting switch state. | Warning indicates location services are disabled; saver does not remain enabled; no crash or inconsistent state occurs. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers service-availability failure handling. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Positive testing – disable saver after it is enabled | `RLS-006` | Saver is currently enabled. | 1. Toggle Realtime Location Saver off.<br>2. Observe feedback and final switch state.<br>3. Leave and re-open Settings. | Saver turns off successfully, success feedback is shown, and the disabled state remains consistent after revisiting Settings. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms stop-tracking behavior from a user perspective. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Persistence testing – toggle state survives app backgrounding and restart | `RLS-007` | Saver can be enabled and app can be backgrounded/restarted. | 1. Enable the saver.<br>2. Background and reopen the app.<br>3. Close and relaunch the app if feasible.<br>4. Recheck the toggle state in Settings. | Toggle state persists according to saved preference, and the UI reflects the actual enabled/disabled state after relaunch. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for GetStorage-backed persistence. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Navigation/UI testing – tile tap and switch tap behave consistently | `RLS-008` | Settings screen is open. | 1. Toggle using the switch directly.<br>2. Toggle again by tapping the tile row if supported.<br>3. Repeat several times.<br>4. Observe any duplicate or contradictory state updates. | Row tap and switch tap keep the state synchronized correctly; no double-toggle or flicker occurs. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Useful for UI interaction regression. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Error-handling testing – unexpected start failure | `RLS-009` | Failure can be simulated via service disruption or test environment. | 1. Attempt to enable the saver under a condition that causes startup failure.<br>2. Observe the error message and final toggle state.<br>3. Retry after recovery if possible. | An error message is shown, saver is not left in a false enabled state, and retry is possible after the issue is resolved. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers unexpected runtime failures. |
| Realtime Location Saver | Settings toggle for local realtime location capture | Regression testing – repeated toggle cycles and cross-platform stability | `RLS-010` | Settings screen is accessible on Android and iOS. | 1. Toggle the saver on and off repeatedly over several cycles.<br>2. Navigate away from and back to Settings.<br>3. Compare behavior across Android and iOS. | Repeated toggle cycles remain stable; UI stays responsive; no stuck states, crashes, or platform-specific blocking issues appear. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Endurance regression case. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

