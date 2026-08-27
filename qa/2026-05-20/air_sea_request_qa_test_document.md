# Air/Sea Request – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Air/Sea Request |
| Feature Description | Validate creation of an Air/Sea request, including client and document reference entry, item category selection, pick-up date handling, submission behavior, API integration, and error recovery on Android and iOS. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Air/Sea Request | Air/Sea logistics request creation | Positive testing – open Air/Sea form from Request screen | `ASR-001` | User is authenticated; Air/Sea category is available from the Request screen. | 1. Open Request screen.<br>2. Select Air/Sea category.<br>3. Tap add/new request.<br>4. Review the opened form. | Air/Sea Request form opens successfully with correct title/context and expected sections. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-flow smoke case. |
| Air/Sea Request | Air/Sea logistics request creation | Validation testing – missing required client and document reference | `ASR-002` | Air/Sea form is open. | 1. Leave client and required document reference values empty.<br>2. Tap **Create Request**. | Submission is blocked and clear validation messages identify missing mandatory fields. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate messages are human-readable and field-specific. |
| Air/Sea Request | Air/Sea logistics request creation | Functional testing – client selection behavior | `ASR-003` | Client list is available in QA. | 1. Open client selector/search.<br>2. Select a valid client.<br>3. Change to another client.<br>4. Review displayed details. | Selected client details are shown correctly and update immediately when the client changes. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers reference-data rendering. |
| Air/Sea Request | Air/Sea logistics request creation | Validation/UI testing – item category dropdown and empty-state handling | `ASR-004` | Item category list is available or can be simulated as empty. | 1. Open Item Category dropdown.<br>2. Select a valid option.<br>3. Re-test with no categories available.<br>4. Observe field behavior. | Valid categories can be selected; empty state is handled gracefully without crash or broken layout. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers missing reference data risk. |
| Air/Sea Request | Air/Sea logistics request creation | Validation testing – Pick-Up Date picker behavior | `ASR-005` | Air/Sea form is open and date picker is available. | 1. Tap Pick-Up Date field.<br>2. Select a valid date.<br>3. Cancel selection on a second attempt.<br>4. Try submitting without a date if required. | Date picker opens correctly; chosen date is displayed in correct format; cancel preserves prior state; missing date triggers clear validation. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate platform-native date picker behavior on both Android and iOS. |
| Air/Sea Request | Air/Sea logistics request creation | Positive/API testing – successful Air/Sea request creation | `ASR-006` | Valid test data exists and API is online. | 1. Fill all required values with valid data.<br>2. Tap **Create Request**.<br>3. Observe loading state and success feedback.<br>4. Refresh or reopen the relevant list. | Request is created successfully, success feedback is shown, and created record is visible after refresh or re-entry. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture request identifier if visible. |
| Air/Sea Request | Air/Sea logistics request creation | Error handling – offline mode, timeout, or API rejection | `ASR-007` | Device can be switched offline or API errors can be simulated. | 1. Fill required data.<br>2. Submit while offline or during API failure.<br>3. Observe error message and form state.<br>4. Retry after recovery. | Failure is shown with clear, user-friendly messaging; data remains recoverable; retry works after connectivity or API recovery. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Ensure raw server or exception text is not exposed. |
| Air/Sea Request | Air/Sea logistics request creation | Negative testing – duplicate prevention during repeated submission | `ASR-008` | Air/Sea form is completed with valid data. | 1. Tap **Create Request** rapidly multiple times.<br>2. Observe loading state and resulting record count. | Duplicate requests are prevented and the submit action is guarded while processing. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Race-condition regression case. |
| Air/Sea Request | Air/Sea logistics request creation | UI testing – scrolling, keyboard handling, and orientation | `ASR-009` | Form is accessible on multiple devices. | 1. Open form on Android and iOS.<br>2. Focus text inputs and open keyboard.<br>3. Scroll through the form.<br>4. Rotate device if supported. | Layout remains readable and usable; keyboard does not block critical fields or actions; no clipping or overlap occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Capture screenshots if layout differs across platforms. |
| Air/Sea Request | Air/Sea logistics request creation | Performance/regression testing – repeated creation and background recovery | `ASR-010` | Valid test data exists; form can be reopened multiple times. | 1. Create multiple Air/Sea requests in succession.<br>2. Background and resume the app while the form is open.<br>3. Reopen the form and continue testing. | Sequential requests remain stable, no stale data leaks between attempts, and background/foreground transitions do not corrupt form state. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers mobile interruption and repeat-use behavior. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

