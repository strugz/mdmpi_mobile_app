# Feature-Specific QA Test Document

## Checklist
- [x] Converted the generic QA template into a real, feature-specific QA document
- [x] Covered five real app modules: Login, Standard Delivery Request, Pull Out Request, Navigation Menu, and Settings
- [x] Included positive, negative, UI, validation, API, navigation, performance, and error-handling coverage
- [x] Added Android and iOS compatibility considerations
- [x] Kept the format suitable for manual execution and future automation mapping
- [x] Added module-level and overall execution summaries

## 1. Test Document Overview

| Field | Details |
|---|---|
| Application | MDMPI Mobile App |
| Application Stack | Flutter, Dart, REST API, Mobile Application |
| Test Document Type | Manual QA Test Specification with automation-ready IDs |
| Covered Modules | Login, Standard Delivery Request, Pull Out Request, Navigation Menu, Settings |
| Target Platforms | Android, iOS |
| Test Execution Status | Ready for QA execution |
| Default Row Status | `Not Tested` until manually executed |
| Document Date | 2026-05-20 |

## 2. Recommended Execution Environment

| Device/Platform | OS Version | Build Type | Network Condition | Usage |
|---|---|---|---|---|
| Android phone | Android 13+ | QA / Staging | Wi-Fi | Core functional coverage |
| Android mid-tier phone | Android 12+ | QA / Staging | 4G / unstable network | Performance and recovery testing |
| iPhone | iOS 17+ | QA / Staging | Wi-Fi | Core iOS validation |
| iPhone | iOS 16+ | QA / Staging | Mobile Data / intermittent network | Error-handling and retry testing |

---

# Module 1 – Login

## Feature Description
Verify that users can authenticate successfully using supported login paths, receive clear validation and error messages, and are routed correctly to onboarding or the main application shell.

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Login | Email/password authentication and post-login routing | Positive testing – valid returning-user login | `LOGIN-001` | App is installed; valid returning-user credentials are available; network is stable. | 1. Launch the app.<br>2. Open the Login screen.<br>3. Enter valid email and password.<br>4. Tap **Login**.<br>5. Observe loading and navigation result. | User is authenticated successfully, receives progress feedback if needed, and is routed to the main app with the bottom navigation menu visible. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline happy-path case for future automation. |
| Login | Email/password authentication and post-login routing | Positive testing – first-time user login redirects to onboarding | `LOGIN-002` | App is installed; valid first-time user account exists; onboarding is not yet completed for the user. | 1. Launch the app.<br>2. Enter valid first-time user credentials.<br>3. Tap **Login**.<br>4. Observe the next screen. | Login succeeds and the user is redirected to onboarding instead of the main navigation shell; onboarding can be completed or skipped without crash. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate onboarding completion flag behavior after first run. |
| Login | Input validation and form guarding | Validation testing – empty required fields | `LOGIN-003` | Login screen is visible. | 1. Leave email and password empty.<br>2. Tap **Login**.<br>3. Repeat with only one field populated. | Required-field validation is shown clearly, submission is blocked, and no silent authentication request is sent. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm messages are human-readable and consistently placed. |
| Login | Input validation and form guarding | Negative testing – invalid email format or malformed input | `LOGIN-004` | Login screen is visible. | 1. Enter malformed email values such as `user`, `user@`, or whitespace-only input.<br>2. Enter a short or invalid password format if client-side rules exist.<br>3. Tap **Login**. | Invalid input is rejected gracefully with clear validation feedback; the app remains editable and stable. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include copy-paste, leading/trailing spaces, and emoji edge cases. |
| Login | Authentication error handling | Negative testing – wrong credentials | `LOGIN-005` | Invalid or non-matching credentials are available. | 1. Enter an existing email with the wrong password.<br>2. Tap **Login**.<br>3. Retry with an unknown account. | Authentication fails gracefully with a user-friendly error message; no crash, stuck spinner, or blank screen occurs; user can retry immediately. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Verify raw backend error text is not exposed. |
| Login | Alternate authentication path | API/UI testing – Google sign-in success, cancel, and failure handling | `LOGIN-006` | Google sign-in is configured in the QA environment. | 1. Tap **Google Sign-In**.<br>2. Complete sign-in with a valid account.<br>3. Repeat and cancel the consent/account picker flow.<br>4. Repeat under a simulated sign-in failure. | Success path authenticates the user correctly; cancel returns cleanly to Login; failure displays a clear error without corrupting screen state. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Applicable only when Google sign-in is enabled in the build. |
| Login | Recovery and supporting navigation | Navigation testing – forgot password and return flow | `LOGIN-007` | Forgot-password entry point is enabled. | 1. Tap **Forgot Password**.<br>2. Verify navigation to the recovery flow.<br>3. Return to Login.<br>4. Check whether previous form state behaves as designed. | Recovery screen opens correctly; returning to Login does not create broken state or duplicate back-stack entries. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | If disabled in the build, mark as Blocked with reason. |
| Login | Network and API resilience | Error handling – offline, timeout, and server delay scenarios | `LOGIN-008` | Device can be switched offline or throttled; QA API can be delayed if needed. | 1. Attempt login while offline.<br>2. Attempt login under slow or unstable network.<br>3. Observe loading indicator, error state, and retry behavior. | Login request times out or fails gracefully with actionable messaging; no infinite loading occurs; retry works after connectivity is restored. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for mobile connectivity regression. |
| Login | UI and usability | UI testing – layout, keyboard behavior, and orientation | `LOGIN-009` | Login screen is accessible on small and large devices. | 1. Open Login on Android and iOS.<br>2. Check header, spacing, field alignment, contrast, and button visibility.<br>3. Focus each field and open the keyboard.<br>4. Rotate the device if supported. | Layout remains readable and aligned; keyboard does not hide critical actions; no overlap, clipping, or broken orientation state occurs. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Capture screenshots for regression reference. |
| Login | Session and performance behavior | Performance/navigation testing – repeated login attempts and post-login back-stack control | `LOGIN-010` | Valid credentials are available; logout path is working. | 1. Log in successfully.<br>2. Use system back navigation from the main app shell.<br>3. Log out and log in again multiple times.<br>4. Observe responsiveness and stack behavior. | User cannot navigate back to Login from the authenticated shell; repeated login/logout cycles remain stable and responsive. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Good candidate for smoke automation. |

### Login Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

---

# Module 2 – Standard Delivery Request

## Feature Description
Verify that users can create a Standard Delivery request by completing required fields, selecting valid reference data, and submitting the request successfully through the mobile form with proper validation, server handling, and UI responsiveness.

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Standard Delivery Request | Request form creation flow for logistics users | Positive testing – open Standard Delivery form from Request screen | `SDR-001` | User is authenticated; Request screen is reachable; Standard Delivery category is available. | 1. Go to the Request screen.<br>2. Select the Standard Delivery category.<br>3. Tap the add/new request entry point.<br>4. Observe the opened form. | Standard Delivery Request form opens successfully with correct title/context, expected sections, and no duplicate navigation entries. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Entry-path smoke case. |
| Standard Delivery Request | Request form creation flow for logistics users | Validation testing – required fields left empty | `SDR-002` | Standard Delivery form is open. | 1. Leave required fields blank, including client, date, and other mandatory selectors.<br>2. Tap **Create Request**. | Submission is blocked and clear validation messages are displayed for each mandatory field. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate field-level and summary-level messaging if both exist. |
| Standard Delivery Request | Request form creation flow for logistics users | Functional testing – client, document reference, and category selection | `SDR-003` | Reference lists are loaded in the environment. | 1. Select a client.<br>2. Enter or select document reference values.<br>3. Choose item category and form category values.<br>4. Review displayed selections. | Selected client and category data render correctly, stay selected, and update the form without instability. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate that pre-selected form category reflects the originating Request category when applicable. |
| Standard Delivery Request | Request form creation flow for logistics users | Validation testing – shipping method, delivery terms, date, priority, and requester | `SDR-004` | Standard Delivery form is open. | 1. Attempt submission while omitting shipping method, delivery terms, delivery date, priority, and requested-by fields one at a time.<br>2. Observe form feedback. | Each required field shows clear validation and the form remains usable for correction. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include invalid date selection or cancellation behavior where possible. |
| Standard Delivery Request | Request form creation flow for logistics users | Positive/API testing – successful request creation | `SDR-005` | Valid client, category, date, priority, and requester data are available; API is online. | 1. Fill all required fields with valid data.<br>2. Tap **Create Request**.<br>3. Observe progress state and resulting success behavior.<br>4. Refresh or revisit the request listing. | Request is created successfully, a success message or navigation confirmation is shown, and the created record is visible after refresh/re-entry. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture created request identifier if shown. |
| Standard Delivery Request | Request form creation flow for logistics users | Error handling – server-side validation failure or API rejection | `SDR-006` | Ability to submit an invalid payload or simulate API failure. | 1. Submit the form using intentionally problematic or incomplete data that bypasses local checks, or simulate a 4xx/5xx response.<br>2. Observe the error state.<br>3. Correct data and retry. | Server failure is surfaced with clear, non-technical messaging; form data remains recoverable; retry is possible without reopening the form. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Ensure the app does not expose raw REST exception details. |
| Standard Delivery Request | Request form creation flow for logistics users | Negative testing – duplicate prevention during rapid taps | `SDR-007` | Form is completed with valid data. | 1. Tap **Create Request** rapidly multiple times.<br>2. Observe button state, loading indicator, and resulting request records. | Multiple taps do not create duplicate requests; button is disabled or guarded while submission is in progress. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for race-condition regression. |
| Standard Delivery Request | Request form creation flow for logistics users | Negative/UI testing – empty dropdown source data and fallback handling | `SDR-008` | QA environment can simulate missing reference data or empty local cache. | 1. Open the form when one or more dropdown lists are empty or unavailable.<br>2. Attempt to interact with the affected fields.<br>3. Observe stability and messaging. | Empty-state handling is graceful; fields show disabled/empty state or helpful guidance; no crash occurs. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers category/user/client sync gaps. |
| Standard Delivery Request | Request form creation flow for logistics users | UI testing – scrolling, keyboard behavior, and orientation | `SDR-009` | Form is accessible on multiple devices. | 1. Open the form on Android and iOS.<br>2. Focus fields near the top and bottom.<br>3. Scroll while the keyboard is visible.<br>4. Rotate the device if supported. | All fields remain reachable; no overlap or cutoff occurs; entered values persist according to platform behavior requirements. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Particularly important for long forms. |
| Standard Delivery Request | Request form creation flow for logistics users | Performance/regression testing – response time and persisted visibility | `SDR-010` | API is available; valid test data exists. | 1. Measure approximate time from tapping **Create Request** to success state.<br>2. Reopen the Request list or related module.<br>3. Search for the created record.<br>4. Repeat on Android and iOS. | Submission time is within acceptable limits, and created data remains visible after refresh without corruption or duplication. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Record slow-device timing for release comparison. |

### Standard Delivery Request Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

---

# Module 3 – Pull Out Request

## Feature Description
Verify that users can create a Pull Out request with correct Pull Out-specific data such as IRRF details, reason for return, date fields, and requester selection while maintaining stable form behavior, clear validation, and reliable API integration.

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Pull Out Request | Pull Out / Return request creation flow | Positive testing – open Pull Out form and verify initial state | `POR-001` | User is authenticated; Pull Out category can be selected from the Request screen. | 1. Open the Request screen.<br>2. Choose the Pull Out category.<br>3. Tap the add/new request action.<br>4. Review the loaded form. | Pull Out form opens successfully with expected sections including client, document reference, item category, IRRF fields, reason, dates, requester, and create action. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm form category is appropriately pre-selected/read-only if designed that way. |
| Pull Out Request | Pull Out / Return request creation flow | Validation testing – missing mandatory fields | `POR-002` | Pull Out form is open. | 1. Leave required fields empty.<br>2. Tap **Create Request**.<br>3. Repeat by omitting one required field at a time. | Required-field errors are shown clearly and submission is blocked until valid values are provided. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include client, item category, pull out date, and requested-by coverage. |
| Pull Out Request | Pull Out / Return request creation flow | Functional testing – item category selection and empty list handling | `POR-003` | Item categories are available or can be made unavailable in QA. | 1. Open the item category dropdown.<br>2. Select a valid category.<br>3. Re-test in an environment with no categories or cleared cache. | Valid categories can be selected and rendered correctly; empty-category state does not crash the form. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Covers reference-data dependency risk. |
| Pull Out Request | Pull Out / Return request creation flow | Validation testing – IRRF number numeric and boundary rules | `POR-004` | Pull Out form is open. | 1. Enter valid numeric IRRF values.<br>2. Enter alphabetic, special-character, blank, and over-length values.<br>3. Attempt submission. | Numeric-only expectations are enforced where applicable; invalid IRRF values are rejected with user-friendly messaging. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include pasted input and very long numeric strings. |
| Pull Out Request | Pull Out / Return request creation flow | Functional/validation testing – IRRF date and Pull Out date pickers | `POR-005` | Date pickers are available. | 1. Open IRRF Date and Pull Out Date pickers.<br>2. Select valid dates.<br>3. Cancel selection.<br>4. Attempt submission with missing dates if required. | Date picker opens correctly, selected dates display in correct format, cancel keeps prior state, and missing required dates trigger clear errors. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate future/past date rules if specified by business requirements. |
| Pull Out Request | Pull Out / Return request creation flow | Validation/UI testing – reason for return, contact person, and requester fields | `POR-006` | Pull Out form is open. | 1. Enter a valid reason for return and client contact person.<br>2. Select a requester.<br>3. Test blank, whitespace-only, and unusually long text values where allowed. | Text fields accept valid content, remain readable, and validate required or malformed inputs correctly; requester selection behaves as expected. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Use multi-line text for reason field when supported. |
| Pull Out Request | Pull Out / Return request creation flow | Positive/API testing – successful Pull Out request creation | `POR-007` | Valid test data is available; QA API is online. | 1. Fill all required fields with valid values.<br>2. Tap **Create Request**.<br>3. Observe loader/success feedback.<br>4. Return to the relevant list or module. | Pull Out request is created successfully, feedback is shown, and the new record is visible in the appropriate list or detail context. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Capture the created request reference for evidence. |
| Pull Out Request | Pull Out / Return request creation flow | Error handling – offline mode, API failure, and retry | `POR-008` | Device can be taken offline or API errors can be simulated. | 1. Fill the form with valid data.<br>2. Submit while offline or while the API returns an error.<br>3. Restore connectivity and retry. | Clear error messaging is displayed; data is not lost unexpectedly; retry succeeds after the failure condition is resolved. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm duplicate records are not created after retry. |
| Pull Out Request | Pull Out / Return request creation flow | Regression testing – rapid taps, backgrounding, and re-entry | `POR-009` | Completed Pull Out form is ready for submission. | 1. Tap **Create Request** multiple times quickly.<br>2. Background the app during or after the attempt.<br>3. Return to the app and re-open the form if needed. | Duplicate submissions are prevented; the app resumes without crash; state retention or reset behavior matches requirements. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important for real-world mobile interruption handling. |
| Pull Out Request | Pull Out / Return request creation flow | UI/performance testing – long-form usability and cross-platform consistency | `POR-010` | Form is accessible on Android and iOS. | 1. Review the form on different screen sizes.<br>2. Use the keyboard on top and bottom fields.<br>3. Scroll through the form repeatedly.<br>4. Rotate the device if supported. | UI remains readable and responsive; touch targets are usable; no clipped labels, jitter, or layout breaks appear across platforms. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Screenshot evidence recommended for field alignment checks. |

### Pull Out Request Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

---

# Module 4 – Navigation Menu

## Feature Description
Verify that the bottom navigation menu renders correctly, supports smooth switching among main app sections, preserves selection state appropriately, and behaves consistently across devices, themes, lifecycle changes, and role-based entry conditions.

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Positive testing – navigation menu visibility after authentication | `NAV-001` | Returning-user login succeeds or onboarding is completed for first-time users. | 1. Log in as a returning user.<br>2. Verify bottom navigation appears.<br>3. Repeat using a first-time user after completing/skipping onboarding. | Bottom navigation becomes visible only after the user reaches the authenticated shell and is not shown on login or onboarding screens. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirms integration with auth routing. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Functional testing – default selected tab and content mapping | `NAV-002` | Authenticated user is on the main shell. | 1. Enter the app shell after login.<br>2. Observe the selected tab.<br>3. Verify the content shown above the bar matches the selected tab. | Default selected tab is correct and screen content matches the active tab without mismatch or blank state. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | For logistics users, default is expected to land on the Home flow. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Navigation testing – switch through all tabs | `NAV-003` | Main shell is visible. | 1. Tap Home, Request, Location, and Settings tabs in sequence.<br>2. Observe tab highlight, content switching, and responsiveness.<br>3. Re-tap the currently active tab. | Each tab opens the correct screen, selection highlight updates correctly, and re-tapping the active tab does not cause crashes or broken state. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include repeated switching loops for smoke coverage. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Role-aware testing – department-specific home screen behavior | `NAV-004` | Test accounts exist for Logistics and Collection departments. | 1. Log in as a Logistics user and verify the first tab content.<br>2. Log out.<br>3. Log in as a Collection user and verify first-tab content again. | Navigation shell remains stable for both departments and loads the appropriate first-tab screen per department rules without affecting shared tabs. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Important because first-tab content differs by department logic. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Navigation/back-stack testing – nested screen return behavior | `NAV-005` | Main shell is active; a deeper screen can be opened from at least one tab. | 1. Open a detail or child screen from Request or Settings.<br>2. Use back navigation.<br>3. Observe selected tab and returned screen. | Back navigation returns to the correct parent screen and preserves the correct selected bottom tab without routing to the wrong section. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate both in-app back button and system back gesture/button. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | UI testing – safe area, keyboard interaction, and orientation | `NAV-006` | Main shell is visible on devices with different screen configurations. | 1. Open forms or inputs that bring up the keyboard.<br>2. Observe bottom bar behavior with the keyboard shown.<br>3. Rotate the device if supported.<br>4. Check devices with gesture navigation or bottom insets. | Bottom navigation remains usable or restores properly after keyboard dismissal, respects safe areas, and does not overlap critical content. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Include small-screen device coverage. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Performance testing – rapid tab switching and long-session stability | `NAV-007` | Main shell is visible. | 1. Switch tabs rapidly for 1–2 minutes.<br>2. Observe for lag, crashes, screen flicker, or memory-related degradation. | App remains responsive; transitions stay smooth; no overlapping screens, freezes, or cumulative slowdown occur. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Good endurance regression case. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Navigation/error testing – deep link or push-entry consistency | `NAV-008` | Build/environment supports notification or deep-link entry into a nested screen. | 1. Open the app from a deep link or notification targeting a screen under one of the tabs.<br>2. Observe active tab highlighting and screen load.<br>3. Use back navigation. | The correct tab is highlighted or the user is returned cleanly to the correct tab context; no orphaned or blank screens appear. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Mark Blocked if deep-link test tooling is unavailable. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Accessibility/theme testing – icon clarity, contrast, and semantics | `NAV-009` | Light and dark themes are available, or system theme can be changed. | 1. Review the navigation bar in light and dark mode.<br>2. Verify icon contrast and selection visibility.<br>3. If accessibility tools are available, inspect announced labels. | Icons remain visible and distinguishable across themes, selected state is apparent, and accessibility labels are meaningful where supported. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Include screen-reader notes if tested manually. |
| Navigation Menu | Bottom tab shell with Home, Request, Location, and Settings access | Lifecycle testing – rotation, background/foreground, and state persistence | `NAV-010` | Authenticated user is on a non-default tab. | 1. Switch to a non-default tab.<br>2. Background the app and reopen it.<br>3. Rotate the device if supported.<br>4. Observe whether tab state and shell stability remain correct. | App resumes without crash, selected-tab behavior matches product expectations, and the navigation shell remains functional. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Useful for controller lifecycle regression. |

### Navigation Menu Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

---

# Module 5 – Settings

## Feature Description
Verify that the Settings screen exposes account, data-management, developer-tool, and logout actions correctly, displays appropriate confirmation dialogs and status feedback, and remains stable across repeated operations, network failures, and platform variations.

| Module Name | Feature Description | Test Scenario | Test Case ID | Preconditions | Testing Steps | Expected Result | Actual Result | Status (Pass/Fail) | Severity Level | Priority | Device/Platform Tested | Tester Name | Test Date | Remarks/Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Settings | Account settings, data tools, developer tools, and logout | Positive/UI testing – open Settings and verify header/profile tile | `SET-001` | User is authenticated and can access the Settings tab. | 1. Open the Settings tab from the navigation menu.<br>2. Review the Account header, styling, and profile tile.<br>3. Tap the profile tile and return. | Settings screen loads without issue; header is readable; profile tile opens the profile screen and returns cleanly to Settings. | `TBD during execution` | Not Tested | Major | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Baseline navigation and layout case. |
| Settings | Account settings, data tools, developer tools, and logout | UI testing – data settings section and tile visibility | `SET-002` | Settings screen is open. | 1. Review the Data Settings section.<br>2. Verify visibility of Upload Data, Hard Reset Refresh, Realtime Location Saver, and Contact Directory options.<br>3. Verify labels and subtitles are readable. | All expected settings tiles render correctly, are tappable, and use clear labels/subtitles without clipping or overlap. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Developer tools may be absent outside debug builds. |
| Settings | Account settings, data tools, developer tools, and logout | Functional/API testing – Upload Data confirmation and success behavior | `SET-003` | There is uploadable local data; QA API/network is available. | 1. Tap **Upload Data**.<br>2. Verify the confirmation dialog contents.<br>3. Tap **Cancel**.<br>4. Repeat and tap **Upload**.<br>5. Observe feedback and app stability. | Confirmation dialog is clear; cancel closes safely; upload action starts correctly and completes without crash or freeze; user receives visible feedback. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Pair with server-side verification if available. |
| Settings | Account settings, data tools, developer tools, and logout | Functional testing – Hard Reset Refresh expandable section | `SET-004` | Settings screen is open; reference and request data exist locally. | 1. Expand **Hard Reset Refresh**.<br>2. Review request-data and reference-data options.<br>3. Trigger one request-data reset and one reference-data reset.<br>4. Confirm dialogs and resulting behavior. | Expansion section opens correctly; confirmation dialogs are descriptive; refresh actions complete without crash and refresh the selected dataset as intended. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Validate at least one request cache and one reference cache flow. |
| Settings | Account settings, data tools, developer tools, and logout | Functional testing – Realtime Location Saver toggle behavior | `SET-005` | Settings screen is open; required location permissions are granted or testable. | 1. Observe the current Realtime Location Saver switch state.<br>2. Toggle it on and off.<br>3. Leave and re-enter Settings.<br>4. Observe whether the state persists as designed. | Toggle responds immediately, reflects the current state accurately, and does not cause layout, permission, or stability issues. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Note any permission prompts or denied-permission handling. |
| Settings | Account settings, data tools, developer tools, and logout | Navigation testing – Contact Directory and return flow | `SET-006` | Settings screen is open. | 1. Tap **Contact Directory**.<br>2. Verify navigation to the contact-management screen.<br>3. Use back navigation to return. | Contact Directory screen opens correctly and returning to Settings preserves expected state without duplicate routes. | `TBD during execution` | Not Tested | Medium | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | If local contact data is empty, verify empty-state stability. |
| Settings | Account settings, data tools, developer tools, and logout | Debug/navigation testing – developer tools visibility and access | `SET-007` | Debug build is installed for developer-tool checks. | 1. Open Settings in a debug build.<br>2. Verify **Local Storage Viewer** and **Signature Outbox** tiles are visible.<br>3. Open each tool and return to Settings. | Developer tools appear only in the appropriate build context, open successfully, and return to Settings without broken navigation. | `TBD during execution` | Not Tested | Major | Medium | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Mark Blocked for release builds where debug-only tools are intentionally hidden. |
| Settings | Account settings, data tools, developer tools, and logout | Error handling – offline or failed data-management actions | `SET-008` | Device can be taken offline or API failures can be simulated. | 1. Attempt Upload Data or a Hard Reset action while offline or during API failure.<br>2. Observe dialogs, loaders, and result messaging.<br>3. Retry once network is restored. | Action fails gracefully with clear messaging; app does not hang or crash; retry is possible after recovery. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Confirm no silent failure for destructive or sync actions. |
| Settings | Account settings, data tools, developer tools, and logout | Security/navigation testing – logout behavior and protected-route access | `SET-009` | User is logged in. | 1. Tap **Logout**.<br>2. Confirm the user is returned to the authentication flow.<br>3. Attempt back navigation into protected screens.<br>4. Log in again. | User is logged out successfully, cannot access authenticated screens via back navigation, and can re-authenticate normally afterward. | `TBD during execution` | Not Tested | Critical | High | Android 13+, iOS 16+ | `[Tester Name]` | `[YYYY-MM-DD]` | Essential release sign-off case. |
| Settings | Account settings, data tools, developer tools, and logout | Performance/regression testing – repeated settings actions and long-screen usability | `SET-010` | Settings screen is reachable on small and large devices. | 1. Scroll through the full Settings screen repeatedly.<br>2. Open/close dialogs multiple times.<br>3. Revisit Settings from other tabs.<br>4. Observe responsiveness and visual consistency in light/dark mode. | Settings screen remains responsive and visually consistent; repeated actions do not introduce lag, duplicate dialogs, or rendering issues. | `TBD during execution` | Not Tested | Medium | Medium | Android phone, iPhone | `[Tester Name]` | `[YYYY-MM-DD]` | Include small-device scrolling and theme checks. |

### Settings Summary

| Summary Metric | Count |
|---|---:|
| Total Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Tested | 10 |

---

# Overall Execution Summary

| Module | Total Cases | Passed | Failed | Blocked | Not Tested |
|---|---:|---:|---:|---:|---:|
| Login | 10 | 0 | 0 | 0 | 10 |
| Standard Delivery Request | 10 | 0 | 0 | 0 | 10 |
| Pull Out Request | 10 | 0 | 0 | 0 | 10 |
| Navigation Menu | 10 | 0 | 0 | 0 | 10 |
| Settings | 10 | 0 | 0 | 0 | 10 |
| **Grand Total** | **50** | **0** | **0** | **0** | **50** |

## Execution Notes

| Item | Details |
|---|---|
| Defect Logging | Link each failure to a bug/issue ID and include screenshot, video, or log evidence in `Remarks/Notes`. |
| Blocked Status Usage | Use **Blocked** when build instability, environment limitations, disabled feature flags, or unavailable test data prevent execution. |
| Severity Guidance | Critical = crash, security issue, data loss, or core flow broken; Major = major functional degradation; Medium = usability or partial feature issue; Low = cosmetic issue. |
| Priority Guidance | High = must fix before release sign-off; Medium = fix in planned sprint; Low = deferred if accepted. |
| Automation Mapping | `Test Case ID` values are stable and can be mapped to future Flutter integration, API regression, or end-to-end automated suites. |
| Platform Coverage Guidance | Execute at least one happy-path, one negative-path, and one error-handling path on both Android and iOS before release approval. |

