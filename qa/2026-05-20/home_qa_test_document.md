# Home – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Home |
| Feature Description | Validate the Home screen, including default entry behavior, request form shortcuts, activity dashboard statistics, refresh behavior, scrolling/layout stability, and presentation across Android and iOS. |
| Application Stack | Flutter, Dart, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Home | Home landing screen with request shortcuts and dashboard | Positive testing – default entry after authentication | `HOME-001` | User can log in successfully; onboarding is completed or skippable. | 1. Log in as a returning user.<br>2. Observe the first screen shown after authentication.<br>3. Repeat after leaving and returning to the app shell. | Home screen appears as the expected default landing screen for the authenticated shell without crash or blank state. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline post-login smoke case. |
| Home | Home landing screen with request shortcuts and dashboard | Navigation testing – Home tab selection and return from other tabs | `HOME-002` | User is on the authenticated shell with bottom navigation visible. | 1. Move to Request, Location, or Settings.<br>2. Tap the Home tab.<br>3. Observe selected-tab highlight and loaded content. | Home tab becomes selected and the Home screen loads correctly with no duplicate-screen behavior. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms integration with the bottom navigation shell. |
| Home | Home landing screen with request shortcuts and dashboard | UI testing – header, app bar, and primary layout consistency | `HOME-003` | Home screen is open. | 1. Review the top header area.<br>2. Check the app bar, greeting/logo, colors, and padding.<br>3. Compare layout consistency with other main screens. | Header is visible, aligned, and visually consistent; no overlap with status bar or top system UI occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture screenshots for regression review. |
| Home | Home landing screen with request shortcuts and dashboard | Functional testing – request form shortcuts render and navigate correctly | `HOME-004` | Home screen is open and request-form shortcuts are visible. | 1. Review visible request shortcuts.<br>2. Tap multiple shortcuts such as Standard Delivery, Air/Sea, or Pick Up.<br>3. Return to Home after each. | Shortcut items are clearly visible, navigable, and route to the correct request form screens without crash or layout corruption on return. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm no duplicate or missing shortcut items. |
| Home | Home landing screen with request shortcuts and dashboard | UI/data testing – dashboard section headings, current year, and metric visibility | `HOME-005` | Home screen is open and dashboard is visible. | 1. Scroll to the Activity Dashboard.<br>2. Verify heading text and current year display.<br>3. Review visible metrics such as total requests and status counts. | Dashboard heading and year are displayed correctly, and all configured metrics are visible and readable. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Current year should reflect the present year. |
| Home | Home landing screen with request shortcuts and dashboard | Data refresh testing – dashboard values update after request activity | `HOME-006` | User can create or modify request data elsewhere in the app. | 1. Note the current dashboard values.<br>2. Create a new request or change a request status in another module.<br>3. Return to Home.<br>4. Observe updated counts. | Dashboard values refresh appropriately and reflect recent request activity without requiring a full app restart. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important integration case across logistics modules. |
| Home | Home landing screen with request shortcuts and dashboard | Error-handling testing – no data, zero-state, or offline loading | `HOME-007` | Test account with little/no request data is available, or network can be disabled. | 1. Open Home for a low-data/new user and review dashboard values.<br>2. Reopen Home while offline or with unstable network.<br>3. Observe message/state handling. | Zero-value metrics render without crash; offline or stale-data scenarios are handled gracefully without blank or broken UI. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | If app uses cached data, note whether counts remain stale or refresh later. |
| Home | Home landing screen with request shortcuts and dashboard | UI testing – scrolling, bottom padding, and orientation behavior | `HOME-008` | Home screen is accessible on multiple devices. | 1. Scroll through the full Home screen on small and large devices.<br>2. Ensure the last dashboard item is visible above the bottom navigation bar.<br>3. Rotate device if supported. | Scrolling remains smooth; all content stays reachable; bottom navigation does not cover content; orientation does not break the layout. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Particularly important for smaller screens. |
| Home | Home landing screen with request shortcuts and dashboard | Accessibility/theme testing – text readability, contrast, and theme switching | `HOME-009` | Theme switching or system theme changes are available. | 1. Review Home in light mode.<br>2. Switch to dark mode if supported.<br>3. Increase system text size if possible.<br>4. Recheck headings, labels, and values. | Text remains readable, contrast is acceptable, and theme changes do not leave visual artifacts or unreadable states. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Add screen-reader notes if accessibility tools are used. |
| Home | Home landing screen with request shortcuts and dashboard | Performance/regression testing – repeated visits and long-session stability | `HOME-010` | Home screen can be revisited multiple times. | 1. Navigate away from Home and return repeatedly.<br>2. Open several shortcut screens and return.<br>3. Repeat over an extended session.<br>4. Observe responsiveness and rendering. | Home remains responsive and stable; no increasing lag, duplicate widgets, or visual glitches appear after repeated use. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Endurance/regression case for daily-use flow. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

