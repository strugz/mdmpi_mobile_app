# Request Screen – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Request Screen |
| Feature Description | Validate the logistics Request screen, including initial loading and error states, category tabs, swipe/carousel synchronization, per-category filters, local/server switching, category list rendering, and floating action button behavior. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Request Screen | Logistics category hub and request entry screen | Positive testing – open Request screen from main navigation | `REQ-001` | User is authenticated and can access the Request tab. | 1. Open the Request screen from the main app shell.<br>2. Observe initial load and overall layout.<br>3. Review app bar and content areas. | Request screen opens successfully without crash, blank screen, or visible layout corruption. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline entry smoke case. |
| Request Screen | Logistics category hub and request entry screen | Loading/error testing – initial loader, empty categories, and retry behavior | `REQ-002` | Environment can simulate slow load, no categories, or load error. | 1. Open Request screen while categories are loading.<br>2. Observe loading indicator.<br>3. Test no-category or error state if reproducible.<br>4. Tap **Retry** where applicable. | Loading state is clear; empty/error state is user-friendly; retry reattempts loading and updates the UI correctly. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for startup reliability. |
| Request Screen | Logistics category hub and request entry screen | Functional testing – category tabs visibility and selection behavior | `REQ-003` | One or more request categories are available. | 1. Review visible category tabs.<br>2. Tap several tabs.<br>3. Observe active-tab highlight and content changes. | Tabs are readable, selectable, and the highlighted tab always matches the displayed content. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Check horizontal scrolling if many categories exist. |
| Request Screen | Logistics category hub and request entry screen | Swipe/carousel testing – horizontal content and tab synchronization | `REQ-004` | Multiple categories are available. | 1. Swipe left/right across the content area.<br>2. Observe the visible category and selected tab.<br>3. Repeat after tapping tabs. | Swiping changes the active category correctly, and tab selection stays synchronized with the visible content. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Good navigation-consistency case. |
| Request Screen | Logistics category hub and request entry screen | Functional testing – per-category filter area updates correctly | `REQ-005` | Categories with filters are available. | 1. Observe the filter area for one category.<br>2. Change filters and review list results.<br>3. Switch categories and observe filter UI changes.<br>4. Return to the original category. | Filter area matches the selected category, updates appropriately, and does not show stale controls from another category. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Document whether filters persist or reset between categories. |
| Request Screen | Logistics category hub and request entry screen | Storage-mode testing – Local/Server switch behavior | `REQ-006` | Categories are loaded and support storage mode switching. | 1. Observe the Local/Server switch in the app bar.<br>2. Toggle the switch for one category.<br>3. Review visible data/behavior changes.<br>4. Change categories and return. | Switch label and state update correctly; visible behavior reflects the chosen mode; per-category mode does not incorrectly override other categories. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for data-source behavior. |
| Request Screen | Logistics category hub and request entry screen | Functional testing – category list rendering and item interaction | `REQ-007` | At least one category contains requests. | 1. Open a category with list data.<br>2. Scroll through items.<br>3. Tap a list item to open its detail or action flow.<br>4. Return to the Request screen. | Category content renders correctly, scrolls smoothly, and tapping an item opens the expected downstream screen or modal without losing context on return. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify category and scroll-position retention if applicable. |
| Request Screen | Logistics category hub and request entry screen | Floating action button testing – role-based visibility and correct form routing | `REQ-008` | Test accounts exist with and without request-creation permission. | 1. Log in with a user allowed to create requests and verify FAB visibility.<br>2. Tap the FAB under multiple categories.<br>3. Repeat with a user who should not see the FAB. | FAB appears only for permitted users, opens the correct request form for the active category, and remains hidden for unauthorized users. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Release-signoff case for permission-sensitive request creation. |
| Request Screen | Logistics category hub and request entry screen | Error-handling testing – network failure, rapid category changes, and data refresh | `REQ-009` | Device can be switched offline or network can be destabilized. | 1. Open or refresh Request screen while offline or during API failure.<br>2. Rapidly switch categories via taps and swipes.<br>3. Observe state recovery after network is restored. | Screen fails gracefully without infinite spinner or crash; rapid tab switching does not corrupt the UI; data can be refreshed successfully afterward. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for real-world mobile instability. |
| Request Screen | Logistics category hub and request entry screen | Regression testing – orientation, background/foreground, and repeated navigation | `REQ-010` | Request screen is accessible and categories are loaded. | 1. Rotate the device if supported.<br>2. Background and reopen the app while on Request screen.<br>3. Re-enter the screen multiple times from the navigation shell.<br>4. Observe retained state and UI behavior. | Current category and layout remain stable; no duplicate Request screens, broken tabs, or blank content appear after repeated use. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Endurance/regression case. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

