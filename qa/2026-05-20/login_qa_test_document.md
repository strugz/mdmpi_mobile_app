# Login – QA Test Document

## Module Overview

| Field | Details |
|---|---|
| Module Name | Login |
| Feature Description | Validate email/password and social authentication, client-side validation, API/error handling, and correct post-login navigation to onboarding or the authenticated app shell. |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Target Platforms | Android, iOS |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Default Execution Status | Not Tested |
| Document Date | 2026-05-20 |

## Recommended Test Environment

| Device/Platform | OS Version | Build Type | Network |
|---|---|---|---|
| Android phone | Android 13+ | QA / Staging | Wi-Fi |
| Android phone | Android 12+ | QA / Staging | Mobile data / unstable |
| iPhone | iOS 17+ | QA / Staging | Wi-Fi |
| iPhone | iOS 16+ | QA / Staging | Mobile data / unstable |

## Detailed Test Cases

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Login | Email/password authentication and post-login routing | Positive testing – valid returning-user login | `LOGIN-001` | Valid returning-user credentials exist; app is installed; network is stable. | 1. Launch the app.<br>2. Open the Login screen.<br>3. Enter valid email and password.<br>4. Tap **Login**.<br>5. Observe resulting navigation. | User logs in successfully and is routed to the authenticated shell with the bottom navigation visible. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline smoke case. |
| Login | Email/password authentication and post-login routing | Positive testing – first-time login routes to onboarding | `LOGIN-002` | Valid first-time user account exists and onboarding is not yet completed. | 1. Launch app.<br>2. Enter first-time user credentials.<br>3. Tap **Login**.<br>4. Observe next screen. | Login succeeds and user is routed to onboarding instead of directly to the main shell. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate onboarding completion flow. |
| Login | Form validation | Validation testing – empty required fields | `LOGIN-003` | Login screen is open. | 1. Leave email and password blank.<br>2. Tap **Login**.<br>3. Repeat with one field blank at a time. | Required-field validation appears clearly; submission is blocked until valid values are provided. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm no silent API attempt occurs. |
| Login | Form validation | Negative testing – invalid email format and malformed input | `LOGIN-004` | Login screen is open. | 1. Enter malformed email values such as `user`, `user@`, or whitespace.<br>2. Enter invalid password formats if restricted.<br>3. Tap **Login**. | Invalid input is rejected gracefully with clear, user-friendly validation messaging. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include paste, leading spaces, and emoji edge cases. |
| Login | Authentication failures | Negative testing – wrong credentials | `LOGIN-005` | Invalid credentials are available. | 1. Enter a valid email with the wrong password.<br>2. Tap **Login**.<br>3. Retry using an unknown account. | Authentication fails gracefully with a clear error; user can retry immediately without app restart. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Ensure raw backend errors are not exposed. |
| Login | Alternate authentication | API/UI testing – Google sign-in success, cancel, and failure | `LOGIN-006` | Google sign-in is enabled in the QA build. | 1. Tap **Google Sign-In**.<br>2. Complete a successful sign-in.<br>3. Repeat and cancel the picker flow.<br>4. Repeat under a simulated failure. | Success authenticates the user; cancel returns safely to Login; failure displays a clear error without corrupting UI state. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Mark Blocked if social sign-in is not enabled in the build. |
| Login | Recovery navigation | Navigation testing – forgot password flow | `LOGIN-007` | Forgot-password entry point is enabled. | 1. Tap **Forgot Password**.<br>2. Verify navigation to the recovery flow.<br>3. Return to Login.<br>4. Review form state behavior. | Recovery screen opens correctly; returning to Login does not create duplicate back-stack entries or broken state. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | If absent in the build, mark Blocked with reason. |
| Login | Network resilience | Error handling – offline, timeout, and slow network | `LOGIN-008` | Device can be switched offline or throttled. | 1. Attempt login while offline.<br>2. Attempt login on slow/intermittent network.<br>3. Observe loading and retry behavior. | Login fails gracefully with actionable messaging; no infinite loading or blank screen occurs; retry works after network restoration. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important mobile reliability case. |
| Login | UI and usability | UI testing – layout, keyboard behavior, and orientation | `LOGIN-009` | Login screen is accessible on multiple devices. | 1. Open Login on Android and iOS.<br>2. Review spacing, alignment, contrast, and button visibility.<br>3. Open keyboard for each field.<br>4. Rotate device if supported. | Layout remains readable and aligned; keyboard does not hide critical actions; no clipping or overlap occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Capture screenshots for regression comparison. |
| Login | Session and back-stack control | Performance/navigation testing – repeated login/logout cycles | `LOGIN-010` | Valid credentials are available; logout path works. | 1. Log in successfully.<br>2. Use system back from the authenticated shell.<br>3. Log out and log back in multiple times.<br>4. Observe responsiveness and navigation stack behavior. | User cannot return to Login from the authenticated shell via back navigation; repeated login cycles remain stable and responsive. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Suitable for smoke and future automation. |

## Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

