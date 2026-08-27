# Hotline Direct Request – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Hotline Direct Request |
| Feature Description | Validate Hotline Direct request creation, including client and document reference input, shipping method and delivery terms selection, delivery date handling, priority and requester selection, submission behavior, and error recovery. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hotline Direct Request | Hotline Direct logistics request creation | Positive testing – open Hotline Direct form from Request screen | `HDR-001` | User is authenticated; Hotline Direct category is available from the Request screen. | 1. Open the Request screen.<br>2. Select the Hotline Direct category.<br>3. Tap the add/new request action.<br>4. Review the loaded form. | Hotline Direct Request form opens successfully with the expected request-form title and visible client/document reference sections. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-flow smoke case. |
| Hotline Direct Request | Hotline Direct logistics request creation | Validation testing – missing client selection or document reference | `HDR-002` | Hotline Direct form is open. | 1. Leave client unselected and attempt submission.<br>2. Select a client but leave document reference values invalid or empty if required.<br>3. Tap **Create Request**. | Submission is blocked and clear validation is shown for missing client and/or required document reference values. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers common request-form dependencies. |
| Hotline Direct Request | Hotline Direct logistics request creation | Functional testing – Shipping Method dropdown | `HDR-003` | Hotline Direct form is open. | 1. Open the **Shipping Method** dropdown.<br>2. Verify options such as Land, Air, and Sea.<br>3. Select each option in turn and observe displayed value. | Dropdown opens correctly, available options are readable, and the selected shipping method is displayed correctly. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm no duplicate or malformed dropdown entries. |
| Hotline Direct Request | Hotline Direct logistics request creation | Functional testing – Delivery Terms and Priority dropdowns | `HDR-004` | Hotline Direct form is open. | 1. Open **Delivery Terms** and select Partial then Full.<br>2. Open **Priority** and select High, Medium, and Low across repeated runs.<br>3. Observe field values. | Both dropdowns populate correctly, selections persist visually, and no UI break occurs during repeated changes. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers common logistics option selectors. |
| Hotline Direct Request | Hotline Direct logistics request creation | Validation testing – Delivery Date picker behavior | `HDR-005` | Hotline Direct form is open and date picker is available. | 1. Tap the **Delivery Date** field.<br>2. Select a valid date.<br>3. Reopen and cancel the picker.<br>4. Attempt submission without a delivery date if possible. | Date picker opens correctly; selected value is displayed in the expected format; cancel preserves prior state; missing date triggers clear validation if required. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Check Android/iOS picker consistency. |
| Hotline Direct Request | Hotline Direct logistics request creation | Functional testing – Requested By dropdown and user-list quality | `HDR-006` | User/requester list is loaded in QA. | 1. Open **Requested By** dropdown.<br>2. Review available user names.<br>3. Select a valid requester.<br>4. Repeat with search/long list scrolling if applicable. | User list displays readable, non-placeholder entries; selected requester appears correctly in the field. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms local requester data readiness. |
| Hotline Direct Request | Hotline Direct logistics request creation | Positive/API testing – successful request creation | `HDR-007` | Valid client, document reference, dropdown selections, date, and requester are available; API is online. | 1. Fill the form with valid data.<br>2. Tap **Create Request**.<br>3. Observe progress state and success feedback.<br>4. Return to the relevant list or refresh the module. | Request is created successfully, success feedback is shown, and the new Hotline Direct request appears in the expected list/context. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture created request reference if visible. |
| Hotline Direct Request | Hotline Direct logistics request creation | Error handling – offline mode, timeout, or API rejection | `HDR-008` | Device can be switched offline or API failures can be simulated. | 1. Fill required values with valid data.<br>2. Submit while offline or during simulated API failure.<br>3. Observe messaging and form state.<br>4. Retry after recovery. | The app shows clear, user-friendly error messaging, stays on the form, and supports retry after the failure condition is resolved. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Ensure raw backend exceptions are not exposed. |
| Hotline Direct Request | Hotline Direct logistics request creation | Negative testing – duplicate prevention during repeated submission | `HDR-009` | Form is completed with valid data. | 1. Tap **Create Request** rapidly multiple times.<br>2. Observe button behavior and resulting request count.<br>3. Repeat after a failed attempt. | Duplicate requests are prevented and the submit action is guarded while processing or retrying. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Race-condition regression case. |
| Hotline Direct Request | Hotline Direct logistics request creation | UI/regression testing – scrolling, keyboard, orientation, and background recovery | `HDR-010` | Hotline Direct form is accessible on Android and iOS. | 1. Focus text inputs to open the keyboard.<br>2. Scroll through the form while keyboard is visible.<br>3. Rotate the device if supported.<br>4. Background and reopen the app while the form is open. | Layout remains stable and readable; no overlap, clipping, or corrupted state occurs after lifecycle changes. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Covers real-world interruption handling. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

