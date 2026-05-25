# Air/Sea List – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Air/Sea List |
| Feature Description | Validate the Air/Sea request listing flow, including loading and empty states, pull-to-refresh, request-card interactions, status-based modal behavior, role-dependent actions, remarks access, and list stability. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Air/Sea List | Air/Sea request listing and status interaction | Loading-state testing – shimmer placeholder on initial load | `ASL-001` | User is authenticated; Air/Sea list can be opened from the Request screen; network is available or loading can be observed. | 1. Navigate to the Air/Sea category.<br>2. Observe the screen while data is still loading.<br>3. Wait for loading to complete. | A loading placeholder/shimmer appears instead of a blank screen; it disappears cleanly when the list or empty state loads. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture timing and any shimmer/list overlap if seen. |
| Air/Sea List | Air/Sea request listing and status interaction | Empty-state testing – no Air/Sea requests found | `ASL-002` | Air/Sea category is accessible; test account or filters can produce zero results. | 1. Open Air/Sea list with no matching requests.<br>2. Observe icon, text, and layout.<br>3. Pull down to refresh from the empty state. | Empty state shows clear messaging, remains readable in current theme, and still supports pull-to-refresh without crash. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify wording and theme contrast. |
| Air/Sea List | Air/Sea request listing and status interaction | Functional testing – non-empty list rendering and scroll behavior | `ASL-003` | At least one Air/Sea request exists. | 1. Open Air/Sea list with several requests.<br>2. Review card spacing, text readability, and status visibility.<br>3. Scroll up and down through the list. | Cards render consistently, list scrolls smoothly, and key request information is readable with no clipping or overlap. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Good baseline visual-regression case. |
| Air/Sea List | Air/Sea request listing and status interaction | Refresh testing – pull-to-refresh updates list content | `ASL-004` | Air/Sea list is open and can be refreshed. | 1. Pull down from the top of the list.<br>2. Observe the refresh indicator.<br>3. Wait for refresh completion.<br>4. Compare visible data before and after refresh. | Refresh indicator appears and disappears correctly; updated data is shown if available; list remains stable if no changes occur. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Repeat from empty state and populated state. |
| Air/Sea List | Air/Sea request listing and status interaction | Tap interaction – status-based modal opens correctly | `ASL-005` | At least one Air/Sea request exists in a non-final status. | 1. Tap an Air/Sea request card.<br>2. Observe the opened bottom sheet/modal.<br>3. Review visible request details and status-specific controls. | Tapping a card opens a modal bottom sheet without crash; request details are readable; modal content matches the current request status. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Use multiple statuses if available. |
| Air/Sea List | Air/Sea request listing and status interaction | Role-based action testing – status advancement controls by account type | `ASL-006` | Test accounts exist for Request, Release, Courier, and Viewer-style roles; requests exist in relevant statuses. | 1. Log in with each role type.<br>2. Open the same or comparable Air/Sea request statuses.<br>3. Tap request cards and compare available actions.<br>4. Attempt permitted status changes. | Each role sees only the actions appropriate to its permission level and the request status; unauthorized actions are not exposed. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important permission-regression case. |
| Air/Sea List | Air/Sea request listing and status interaction | Long-press testing – remarks dialog behavior | `ASL-007` | Non-final Air/Sea requests exist; final-status requests also exist if possible. | 1. Long-press a non-final request card.<br>2. Observe the remarks dialog.<br>3. Repeat on a final-status request. | Non-final requests open remarks/add-view dialog correctly; final-status requests do not expose inappropriate remarks editing behavior. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate clear save/cancel behavior if editable. |
| Air/Sea List | Air/Sea request listing and status interaction | Final-state testing – received/cancelled/drop-off requests are view-only | `ASL-008` | Final-status Air/Sea requests are available. | 1. Open requests in final statuses such as Received, Drop Off, or Cancelled.<br>2. Tap each card and review the modal.<br>3. Check for proof or remarks visibility where applicable. | Final-status requests open read-only views with no mutating actions; displayed proof/remarks metadata is readable and stable. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Useful for sign-off on completed lifecycle states. |
| Air/Sea List | Air/Sea request listing and status interaction | Error-handling testing – network failure or stale-state retry behavior | `ASL-009` | Device can be switched offline or the API can be made unstable. | 1. Open or refresh the Air/Sea list while offline or during API failure.<br>2. Attempt tap interactions if cached data exists.<br>3. Restore connectivity and retry refresh. | Screen does not crash; user sees graceful fallback/error behavior; refresh works again after connectivity is restored. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Note whether cached data remains visible. |
| Air/Sea List | Air/Sea request listing and status interaction | Regression testing – repeated taps, refreshes, and background recovery | `ASL-010` | Air/Sea list is accessible with data available. | 1. Tap and close several request modals in succession.<br>2. Refresh multiple times.<br>3. Background and reopen the app while on the list.<br>4. Observe performance and UI stability. | List remains stable, responsive, and visually correct; no duplicated rows, stale dialogs, or loading glitches accumulate. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Endurance regression case. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

