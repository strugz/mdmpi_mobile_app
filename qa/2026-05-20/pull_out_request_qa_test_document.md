# Pull Out Request – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Pull Out Request |
| Feature Description | Validate Pull Out request creation including client and item selection, IRRF number/date handling, reason-for-return input, date pickers, requester selection, API submission, and failure recovery. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Pull Out Request | Pull Out / Return request creation flow | Positive testing – open Pull Out form and verify initial state | `POR-001` | User is authenticated; Pull Out category is available from the Request screen. | 1. Open Request screen.<br>2. Select Pull Out category.<br>3. Tap add/new request.<br>4. Review the loaded form. | Pull Out form opens successfully with expected sections including client, document reference, item category, IRRF fields, reason, dates, requester, and create action. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm read-only/pre-selected form category behavior if present. |
| Pull Out Request | Pull Out / Return request creation flow | Validation testing – missing mandatory fields | `POR-002` | Pull Out form is open. | 1. Leave required fields empty.<br>2. Tap **Create Request**.<br>3. Repeat by omitting one required field at a time. | Submission is blocked and clear validation appears for all mandatory inputs. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include client, item category, pull out date, and requester. |
| Pull Out Request | Pull Out / Return request creation flow | Functional testing – item category selection and empty list handling | `POR-003` | Item categories are available or can be unavailable in QA. | 1. Open item category dropdown.<br>2. Select a valid category.<br>3. Repeat where categories are unavailable.<br>4. Observe stability. | Valid categories can be selected and rendered correctly; empty-category state does not crash the form. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers dependency on reference data sync. |
| Pull Out Request | Pull Out / Return request creation flow | Validation testing – IRRF number numeric and boundary rules | `POR-004` | Pull Out form is open. | 1. Enter valid numeric IRRF values.<br>2. Enter letters, special characters, blank values, and long values.<br>3. Attempt submission. | Numeric expectations are enforced where applicable; invalid values are rejected with user-friendly messaging. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include pasted input and long numeric strings. |
| Pull Out Request | Pull Out / Return request creation flow | Functional/validation testing – IRRF Date and Pull Out Date pickers | `POR-005` | Date pickers are available. | 1. Open IRRF Date and Pull Out Date pickers.<br>2. Select valid dates.<br>3. Cancel selection.<br>4. Attempt submission with missing dates if required. | Date pickers open correctly; chosen values display in proper format; cancel preserves previous state; missing required dates show clear validation. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate future/past date rules if specified. |
| Pull Out Request | Pull Out / Return request creation flow | Validation/UI testing – reason for return, contact person, and requester | `POR-006` | Pull Out form is open. | 1. Enter valid reason for return and contact person.<br>2. Select a requester.<br>3. Test blank, whitespace-only, and long values where allowed. | Text fields accept valid content, remain readable, and validate required or malformed input correctly. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Use multi-line text where supported. |
| Pull Out Request | Pull Out / Return request creation flow | Positive/API testing – successful Pull Out request creation | `POR-007` | Valid test data exists; API is reachable. | 1. Fill required fields with valid values.<br>2. Tap **Create Request**.<br>3. Observe loader/success feedback.<br>4. Return to related list or module. | Pull Out request is created successfully, feedback is shown, and the new record appears in the expected context. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture created request reference if visible. |
| Pull Out Request | Pull Out / Return request creation flow | Error handling – offline mode, API failure, and retry | `POR-008` | Device can be offline or API errors can be simulated. | 1. Fill form with valid data.<br>2. Submit while offline or during API failure.<br>3. Restore connectivity and retry. | Clear error messaging is shown; data is not lost unexpectedly; retry succeeds after failure condition is resolved. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm no duplicate creation after retry. |
| Pull Out Request | Pull Out / Return request creation flow | Regression testing – rapid taps, backgrounding, and re-entry | `POR-009` | Completed Pull Out form is ready for submission. | 1. Tap **Create Request** multiple times quickly.<br>2. Background the app during or after attempt.<br>3. Return to app and reopen form if needed. | Duplicate submissions are prevented; app resumes without crash; state retention/reset matches requirements. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Real-world interruption case. |
| Pull Out Request | Pull Out / Return request creation flow | UI/performance testing – long-form usability and platform consistency | `POR-010` | Form is accessible on Android and iOS. | 1. Review the form on different screen sizes.<br>2. Use keyboard on top and bottom fields.<br>3. Scroll through the form repeatedly.<br>4. Rotate device if supported. | UI remains readable and responsive; no clipped labels, overlap, or platform-specific layout break occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Screenshot evidence recommended. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

