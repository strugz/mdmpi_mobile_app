# Standard Delivery Request – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Standard Delivery Request |
| Feature Description | Validate creation of a Standard Delivery request including reference-data selection, required-field validation, API submission, duplicate protection, UI behavior, and cross-platform consistency. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Standard Delivery Request | Standard logistics request creation | Positive testing – open Standard Delivery form from Request screen | `SDR-001` | User is authenticated; Standard Delivery entry path is available from the Request screen. | 1. Open Request screen.<br>2. Select Standard Delivery category.<br>3. Tap add/new request.<br>4. Review loaded screen. | Standard Delivery Request form opens successfully with correct context, expected sections, and no duplicate route issues. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-path smoke case. |
| Standard Delivery Request | Standard logistics request creation | Validation testing – missing required fields | `SDR-002` | Standard Delivery form is open. | 1. Leave mandatory fields blank.<br>2. Tap **Create Request**.<br>3. Repeat by omitting one required field at a time. | Submission is blocked and clear field-level validation is displayed for each required input. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Cover client, date, requester, and category dependencies. |
| Standard Delivery Request | Standard logistics request creation | Functional testing – client, document reference, and category selection | `SDR-003` | Client list and categories are available in QA. | 1. Select a client.<br>2. Fill document reference details.<br>3. Choose item category and form category.<br>4. Review displayed selections. | Selections are rendered correctly, remain stable, and reflect chosen reference data. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate pre-selected form category if launched from category context. |
| Standard Delivery Request | Standard logistics request creation | Validation testing – shipping method, delivery terms, date, priority, requester | `SDR-004` | Standard Delivery form is open. | 1. Omit shipping method, delivery terms, delivery date, priority, and requested-by one at a time.<br>2. Attempt submission after each omission. | Each required field shows clear validation; form remains editable and stable. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include date-picker cancel behavior. |
| Standard Delivery Request | Standard logistics request creation | Positive/API testing – successful request creation | `SDR-005` | Valid data exists; API is online. | 1. Fill all required fields with valid data.<br>2. Tap **Create Request**.<br>3. Observe loading and success feedback.<br>4. Refresh or reopen the relevant list. | Request is created successfully, success feedback is shown, and created data is visible after refresh/re-entry. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture request identifier if visible. |
| Standard Delivery Request | Standard logistics request creation | Error handling – API rejection or server-side validation failure | `SDR-006` | API failure or invalid server-side payload can be simulated. | 1. Submit with intentionally problematic data or simulated 4xx/5xx response.<br>2. Observe resulting error state.<br>3. Correct data and retry. | Failure is surfaced with clear, non-technical messaging; data remains recoverable; retry works without reopening the form. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify raw REST exceptions are not shown. |
| Standard Delivery Request | Standard logistics request creation | Negative testing – duplicate prevention on rapid taps | `SDR-007` | Form is completed with valid data. | 1. Tap **Create Request** rapidly multiple times.<br>2. Observe button state and created records. | Duplicate requests are prevented; submit action is disabled or guarded while processing. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Race-condition regression case. |
| Standard Delivery Request | Standard logistics request creation | Negative/UI testing – empty dropdown source data | `SDR-008` | Environment can simulate empty/missing reference lists. | 1. Open the form when one or more dropdown lists are unavailable.<br>2. Interact with affected fields.<br>3. Observe screen stability. | Empty states are handled gracefully with no crash; controls show disabled or informative states as appropriate. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers client/user/category sync gaps. |
| Standard Delivery Request | Standard logistics request creation | UI testing – scrolling, keyboard handling, and orientation | `SDR-009` | Form is accessible on multiple devices. | 1. Open the form on Android and iOS.<br>2. Focus top and bottom fields.<br>3. Scroll while keyboard is visible.<br>4. Rotate the device if supported. | All fields remain reachable; no overlap, clipping, or unusable keyboard state occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Long-form usability validation. |
| Standard Delivery Request | Standard logistics request creation | Performance/regression testing – response time and persistence | `SDR-010` | Valid test data exists and API is reachable. | 1. Measure approximate time from tapping **Create Request** to success.<br>2. Reopen list or module.<br>3. Search for created record.<br>4. Repeat on Android and iOS. | Submission completes within acceptable time and created data persists correctly without corruption or duplication. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Record slow-device timings if observed. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

