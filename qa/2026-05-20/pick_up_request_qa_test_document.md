# Pick Up Request – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Pick Up Request |
| Feature Description | Validate creation of a Pick Up request including client selection, document reference entry, item category selection, pick-up date handling, successful submission, error recovery, and cross-platform usability. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Pick Up Request | Pick Up logistics request creation | Positive testing – open Pick Up form from Request screen | `PUR-001` | User is authenticated; Pick Up category is available from the Request screen. | 1. Open the Request screen.<br>2. Select the Pick Up category.<br>3. Tap the add/new request action.<br>4. Review the loaded form. | Pick Up Request form opens successfully with the expected title/context and required sections. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-flow smoke case. |
| Pick Up Request | Pick Up logistics request creation | Validation testing – missing client selection | `PUR-002` | Pick Up form is open. | 1. Leave client unselected.<br>2. Enter or omit other values as needed.<br>3. Tap **Create Request**. | Submission is blocked and the user receives a clear validation message indicating a client must be selected. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms client validation in the shared request flow. |
| Pick Up Request | Pick Up logistics request creation | Validation testing – empty document reference | `PUR-003` | Pick Up form is open and document reference area is visible. | 1. Select a valid client.<br>2. Leave all document reference fields blank.<br>3. Fill or select other required values.<br>4. Tap **Create Request**. | Submission is blocked and a clear validation message indicates at least one document reference is required. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include multiple blank document reference rows if supported. |
| Pick Up Request | Pick Up logistics request creation | Functional/validation testing – item category selection and empty-state handling | `PUR-004` | Item categories are loaded in QA or can be simulated as missing. | 1. Open the Item Category dropdown.<br>2. Select a valid item category.<br>3. Repeat with no categories available or local data unavailable.<br>4. Observe field behavior. | Valid categories can be selected and displayed correctly; empty-state handling is graceful and does not crash the form. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers reference-data dependency gaps. |
| Pick Up Request | Pick Up logistics request creation | Validation testing – Pick-Up Date picker behavior | `PUR-005` | Pick Up form is open and date picker is available. | 1. Tap the **Pick-Up Date** field.<br>2. Select a valid date.<br>3. Reopen and cancel the picker.<br>4. Try submission with the field empty if possible. | Date picker opens correctly; selected date is displayed in the correct format; cancel preserves prior state; missing date triggers clear validation. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify Android and iOS date picker behavior separately. |
| Pick Up Request | Pick Up logistics request creation | Positive/API testing – successful request creation | `PUR-006` | Valid client, document reference, item category, and pick-up date are available; API is online. | 1. Fill all required values with valid data.<br>2. Tap **Create Request**.<br>3. Observe loading state and success feedback.<br>4. Return to the related list or refresh the module. | Request is created successfully; a success message is shown; the new Pick Up request appears in the expected list/context. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture created request reference if visible. |
| Pick Up Request | Pick Up logistics request creation | Error handling – offline mode, timeout, or API rejection | `PUR-007` | Device can be switched offline or API errors can be simulated. | 1. Fill required values with valid data.<br>2. Submit while offline or during simulated API failure.<br>3. Observe the error state.<br>4. Retry after recovery. | The app shows clear, user-friendly error feedback, remains on the form, and allows retry after the failure condition is removed. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm raw exception text is not shown. |
| Pick Up Request | Pick Up logistics request creation | Negative testing – duplicate prevention during repeated submission | `PUR-008` | Form is completed with valid data. | 1. Tap **Create Request** rapidly multiple times.<br>2. Observe button/loading behavior.<br>3. Check resulting record count or list state. | Duplicate requests are prevented and the submit action is guarded while the request is processing. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Race-condition regression case. |
| Pick Up Request | Pick Up logistics request creation | UI testing – scrolling, keyboard handling, and orientation | `PUR-009` | Form is accessible on multiple devices. | 1. Open the form on Android and iOS.<br>2. Focus input fields to show the keyboard.<br>3. Scroll through the form while the keyboard is visible.<br>4. Rotate the device if supported. | Layout remains readable and usable; keyboard does not block critical fields or actions; no overlap or clipping occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Capture screenshots if platform layouts differ. |
| Pick Up Request | Pick Up logistics request creation | Regression testing – repeated creation, re-entry, and background recovery | `PUR-010` | Valid test data exists and the form can be reopened multiple times. | 1. Create multiple Pick Up requests in succession.<br>2. Reopen the form after each submission.<br>3. Background and resume the app while the form is open.<br>4. Observe state behavior. | The form remains stable across repeated use; no stale data leaks unexpectedly; background/foreground transitions do not corrupt the UI or submission flow. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers repeat-use and interruption handling. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

