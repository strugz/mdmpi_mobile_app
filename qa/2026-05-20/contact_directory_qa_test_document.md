# Contact Directory – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Contact Directory |
| Feature Description | Validate the Contact Directory screen, including contact list loading, empty state behavior, add-contact flow, directory search, field validation, local persistence, delete confirmation, and general UI stability across Android and iOS. |
| Application Stack | Flutter, Dart, Local Database / Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Contact Directory | Local contact directory management | Positive testing – open Contact Directory from Settings | `CD-001` | User is authenticated; Settings screen is reachable. | 1. Open the Settings screen.<br>2. Tap **Contact Directory**.<br>3. Review the opened screen and app bar. | Contact Directory opens successfully with the correct title, visible back navigation, and no crashes or blank states. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-flow smoke case. |
| Contact Directory | Local contact directory management | UI/loading testing – loading state and empty-state behavior | `CD-002` | Contact Directory is accessible; test environment can include no saved contacts. | 1. Open Contact Directory with an empty or newly reset local contact list.<br>2. Observe initial loading behavior.<br>3. Wait for the list area to settle. | A loading indicator appears while data is loading if needed; if no contacts exist, a clear empty state such as “No contacts yet. Tap + to add one.” is shown. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validates baseline experience for first-time use. |
| Contact Directory | Local contact directory management | Positive testing – add contact using directory search and auto-fill | `CD-003` | Directory options are available in the environment. | 1. Tap the **+** floating action button.<br>2. In the bottom sheet, search for a known directory entry.<br>3. Select a result.<br>4. Review auto-filled Initial, Department, and Contact Number values.<br>5. Tap **Save Contact**. | Bottom sheet opens correctly; search results filter as expected; selecting a result auto-fills fields; saving creates the contact successfully and shows success feedback. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers search-to-save happy path. |
| Contact Directory | Local contact directory management | Validation testing – required fields in add-contact form | `CD-004` | Add Contact bottom sheet is open. | 1. Leave Initial, Department, and Contact Number blank.<br>2. Tap **Save Contact**.<br>3. Repeat with one field blank at a time. | Required-field validation is shown clearly for each missing field and save is blocked until valid values are provided. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms form-level validation. |
| Contact Directory | Local contact directory management | Negative testing – directory search no-results behavior | `CD-005` | Add Contact bottom sheet is open; directory search is available. | 1. Enter a search query that should not match any directory contact.<br>2. Observe the results list.<br>3. Clear the query and search again with a valid term. | The sheet shows a clear **No results** state for unmatched queries and recovers correctly when the query is cleared or changed. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers search UX edge cases. |
| Contact Directory | Local contact directory management | Positive testing – manual contact creation without directory selection | `CD-006` | Add Contact bottom sheet is open. | 1. Open the add-contact sheet.<br>2. Do not select a directory result.<br>3. Manually enter Initial, Department, and Contact Number.<br>4. Tap **Save Contact**. | Manual entry is accepted when valid; the contact is added successfully and appears in the contact list with correct values. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms the feature works without directory prefill. |
| Contact Directory | Local contact directory management | UI/data testing – saved contact card rendering and persistence | `CD-007` | At least one contact has been added. | 1. Review the contact list after saving.<br>2. Verify avatar initial, contact name, department, and phone number rendering.<br>3. Leave and reopen Contact Directory. | Contact cards render correctly and persist after leaving and reopening the screen. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for local persistence validation. |
| Contact Directory | Local contact directory management | Delete-flow testing – confirmation dialog cancel and confirm | `CD-008` | At least one saved contact exists. | 1. Tap the delete icon for a saved contact.<br>2. Review the confirmation dialog.<br>3. Tap **Cancel**.<br>4. Reopen the dialog and tap **Delete**. | Cancel keeps the contact unchanged; confirm removes the contact, updates the list, and shows success feedback. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify deleted contact no longer appears after re-entry. |
| Contact Directory | Local contact directory management | Error-handling testing – invalid delete path or failed local operation | `CD-009` | Contact data exists; failure simulation or edge-case data can be prepared if possible. | 1. Attempt add/delete flows under low-storage, DB-lock, or unusual local-state conditions if reproducible.<br>2. Observe app messaging and stability.<br>3. Retry after recovery. | The app remains stable, surfaces user-friendly feedback where possible, and does not corrupt the visible contact list state. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | If failure simulation is unavailable, mark Blocked with reason. |
| Contact Directory | Local contact directory management | UI/performance testing – scrolling, keyboard handling, repeated add/delete cycles | `CD-010` | Contact Directory is accessible; multiple contacts can be created. | 1. Add several contacts.<br>2. Scroll through the list on Android and iOS.<br>3. Open the add sheet with the keyboard visible.<br>4. Delete multiple contacts one by one.<br>5. Observe responsiveness and layout stability. | The list remains responsive, keyboard/inset handling is correct, and repeated add/delete operations do not cause lag, crashes, or layout issues. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Good candidate for regression after local DB changes. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

