# Navigation Menu – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Navigation Menu |
| Feature Description | Validate the bottom navigation shell, default tab behavior, cross-tab transitions, safe-area handling, role-based first-tab content, lifecycle stability, and usability across Android and iOS. |
| Application Stack | Flutter, Dart, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Positive testing – visibility after authentication | `NAV-001` | Returning-user login succeeds or onboarding is completed for first-time users. | 1. Log in as a returning user.<br>2. Verify bottom navigation appears.<br>3. Repeat for a first-time user after onboarding completion/skip. | Bottom navigation appears only after entry into the authenticated shell and is absent on login/onboarding screens. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms auth-flow integration. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Functional testing – default selected tab and content mapping | `NAV-002` | Authenticated user is on the main shell. | 1. Enter main shell after login.<br>2. Observe selected tab.<br>3. Verify content shown above the bar matches the active tab. | Default selected tab is correct and displayed screen content matches the active tab without mismatch or blank state. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | For logistics users, Home is expected by default. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Navigation testing – switch through all tabs | `NAV-003` | Main shell is visible. | 1. Tap Home, Request, Location, and Settings tabs in sequence.<br>2. Observe highlight state and content switching.<br>3. Re-tap the active tab. | Each tab opens the correct screen, active state updates properly, and re-tapping the active tab does not break the UI. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Repeated-switching smoke case. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Role-aware testing – department-specific first tab | `NAV-004` | Test accounts exist for Logistics and Collection users. | 1. Log in as Logistics user and verify first-tab screen.<br>2. Log out.<br>3. Log in as Collection user and verify first-tab screen again. | Navigation shell stays stable for both departments and loads the appropriate first-tab screen according to department rules. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important due to department-aware screen selection. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Back-stack testing – nested screen return behavior | `NAV-005` | Main shell is active and a child screen can be opened from a tab. | 1. Open a detail/child screen from Request or Settings.<br>2. Use back navigation.<br>3. Observe selected tab and returned screen. | Back navigation returns to the correct parent screen while preserving the correct selected tab. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Test in-app and system back navigation. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | UI testing – safe area, keyboard interaction, orientation | `NAV-006` | Main shell is visible on devices with different bottom inset behavior. | 1. Open a screen that shows the keyboard.<br>2. Observe bar behavior while keyboard is visible.<br>3. Rotate device if supported.<br>4. Verify devices with gesture navigation. | Bottom navigation remains usable or restores correctly, respects safe areas, and does not overlap critical content. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Include smaller-screen coverage. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Performance testing – rapid tab switching and long-session stability | `NAV-007` | Main shell is visible. | 1. Switch tabs rapidly for 1–2 minutes.<br>2. Observe for lag, crashes, flicker, or progressive slowdown. | App remains responsive with smooth transitions; no overlapping screens, freezes, or cumulative degradation occur. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Endurance regression case. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Navigation/error testing – deep link or push-entry consistency | `NAV-008` | Environment supports push or deep-link entry to a nested screen. | 1. Open app from deep link or notification to a screen under one tab.<br>2. Review highlighted tab and screen load.<br>3. Use back navigation. | User is routed cleanly with correct tab context and no orphaned or blank screens. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Mark Blocked if tool support is unavailable. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Accessibility/theme testing – icon clarity and contrast | `NAV-009` | Light/dark mode is available or system theme can be changed. | 1. Review navigation bar in light and dark modes.<br>2. Verify icon contrast and selected-state visibility.<br>3. Inspect accessibility labels if tools are available. | Icons remain visible and distinguishable across themes; selected state is clear; semantics are meaningful where supported. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include screen-reader observations if tested. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Lifecycle testing – background/foreground and state persistence | `NAV-010` | Authenticated user is on a non-default tab. | 1. Switch to a non-default tab.<br>2. Background and reopen the app.<br>3. Rotate device if supported.<br>4. Observe tab state and shell stability. | App resumes without crash; selected-tab behavior matches expectations and navigation shell remains functional. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Useful for controller lifecycle regression. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

