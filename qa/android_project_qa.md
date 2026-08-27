# QA Overview - Android Whole-App Project QA

## Scope / Overview

Screen/module coverage: MDMPI Mobile App, Android build.

Purpose: Verify the main Android app journey end to end, based only on what is visible and usable in the app. This document is intended for manual QA execution, release sign-off, and future automation mapping. Testers do not need to inspect Dart code, GetX controllers, local database tables, or repository implementations.

This QA focuses on:
- Fresh Android launch, permissions, and app folder setup.
- Authentication, onboarding, department routing, and session behavior.
- Bottom navigation, home/dashboard, request hub, logistics request forms, and request lists.
- Android-specific camera, location, SMS, notification, storage, keyboard, and performance behavior.
- Offline/reconnect handling, local data stability, and developer-only tool visibility.

Target platform: Android only.

Out of scope for this document:
- Windows desktop validation.
- Source-code review.
- API contract testing outside what is visible through the app.
- Direct production data manipulation.

---

## 1. QA Environment & Test Data

| Field | Value |
|---|---|
| Test Document Type | Manual QA checklist with automation-ready IDs |
| Default Execution Status | Not Tested |
| Platform | Android |
| Suggested Devices | Android 10+, Android 13+, one low-end device if available |
| Network Profiles | Stable Wi-Fi, mobile data, offline/airplane mode, weak connection |
| Test Data | QA/staging accounts and non-production request data only |

### Required test accounts

- [ ] `AND-QA-001` Logistics user with access to request creation and request lists is available.
- [ ] `AND-QA-002` User with request/release/courier-style permissions is available, if role-based request actions are part of the QA setup.
- [ ] `AND-QA-003` User with limited/view-only permissions is available, if supported by the QA setup.
- [ ] `AND-QA-004` User with a non-Logistics department is available to verify department routing, if configured.
- [ ] `AND-QA-005` Test accounts use QA/staging data and do not affect production records.

### Required device setup

- [ ] `AND-QA-006` Android device has enough free storage for request images, signatures, and local database data.
- [ ] `AND-QA-007` Camera, location, SMS, notification, and storage-related permissions can be granted or denied during testing.
- [ ] `AND-QA-008` The tester can uninstall/reinstall or clear app data before fresh-launch tests.
- [ ] `AND-QA-009` The tester can toggle Wi-Fi/mobile data and airplane mode.

---

## 2. Fresh Install, Launch, Permissions & Storage

2.1 **Fresh install and first launch**
- [ ] `AND-QA-010` Install the Android build on a clean device or after clearing app data.
- [ ] `AND-QA-011` Launch the app and confirm there is no crash, blank screen, or stuck loader.
- [ ] `AND-QA-012` Splash/startup flow resolves to the expected unauthenticated screen or login flow.
- [ ] `AND-QA-013` Relaunch the app from the Android launcher and confirm startup remains stable.

2.2 **Android permissions**
- [ ] `AND-QA-014` On first launch or first feature use, permission prompts appear only when needed.
- [ ] `AND-QA-015` Grant storage/location/camera/SMS/notification permissions where prompted and confirm the app continues normally.
- [ ] `AND-QA-016` Deny each permission in a separate run and confirm the app shows clear fallback behavior without crashing.
- [ ] `AND-QA-017` Permanently deny a permission from Android settings and confirm the app guides the user appropriately if that feature is used.

2.3 **App folder and file storage**
- [ ] `AND-QA-018` After permissions are granted, confirm the Android app can create and use the `MDMPIAPP` folder under `/storage/emulated/0/MDMPIAPP` where applicable.
- [ ] `AND-QA-019` Capture or attach an image and confirm it remains available after navigating away and returning.
- [ ] `AND-QA-020` Restart the app and confirm locally saved images/signatures needed by pending flows are still available.
- [ ] `AND-QA-021` If storage is unavailable or permission is denied, the app shows a graceful message and does not lose the current screen state unexpectedly.

---

## 3. Authentication, Session & Department Routing

3.1 **Login success and validation**
- [ ] `AND-QA-022` Open the Login screen from the app start flow.
- [ ] `AND-QA-023` Confirm username/email and password fields are visible, readable, and tappable.
- [ ] `AND-QA-024` Submit with empty required fields and confirm clear validation messages appear.
- [ ] `AND-QA-025` Submit invalid credentials and confirm the failure message is understandable and no stale loader remains.
- [ ] `AND-QA-026` Submit valid credentials and confirm login completes without duplicate screens or repeated navigation.

3.2 **Session and relaunch behavior**
- [ ] `AND-QA-027` Close and relaunch the app after successful login.
- [ ] `AND-QA-028` Confirm the app restores the expected authenticated destination or asks the user to log in again according to product rules.
- [ ] `AND-QA-029` Log out and confirm the app returns to the unauthenticated flow.
- [ ] `AND-QA-030` Relaunch after logout and confirm the user is not silently routed into an authenticated screen.

3.3 **Sign Up and account creation entry**
- [ ] `AND-QA-031` Open the Sign Up screen from Login or the configured entry point.
- [ ] `AND-QA-032` Confirm all required sign-up fields and actions are visible and readable.
- [ ] `AND-QA-033` Submit incomplete or invalid information and confirm validation is shown near the affected fields.
- [ ] `AND-QA-034` Use valid QA sign-up data, if account creation is enabled, and confirm success or verification flow appears.
- [ ] `AND-QA-035` Return from Sign Up to Login without duplicate back-stack behavior.

3.4 **Department routing and onboarding**
- [ ] `AND-QA-036` Log in with a Logistics user and confirm routing lands on the expected Logistics home/onboarding state.
- [ ] `AND-QA-037` Log in with each available non-Logistics department user and confirm routing matches that department's expected destination.
- [ ] `AND-QA-038` Complete onboarding where shown and confirm the completion state persists after app restart.
- [ ] `AND-QA-039` Clear app data or use a fresh account and confirm onboarding appears again when expected.
- [ ] `AND-QA-040` Confirm users are not routed to a department screen they should not access.

---

## 4. Home, Navigation & Android System Back

4.1 **Home/dashboard**
- [ ] `AND-QA-041` Confirm the Home screen loads after successful routing.
- [ ] `AND-QA-042` Dashboard cards, counters, shortcuts, or summaries render without clipped text or overlapping UI.
- [ ] `AND-QA-043` Pull-to-refresh or refresh actions update visible data when supported.
- [ ] `AND-QA-044` Empty, loading, and failed-load states are understandable and recoverable.

4.2 **Bottom navigation**
- [ ] `AND-QA-045` Confirm all expected bottom navigation tabs are visible for the logged-in user's department.
- [ ] `AND-QA-046` Tap each tab and confirm the correct screen opens.
- [ ] `AND-QA-047` Switch tabs repeatedly and confirm no duplicate pages, frozen tab state, or stale data appears.
- [ ] `AND-QA-048` Rotate the device, if rotation is supported, and confirm navigation remains usable.

4.3 **Android back behavior**
- [ ] `AND-QA-049` Use the Android system back button from each main tab and confirm behavior is predictable.
- [ ] `AND-QA-050` Use back from nested request forms, modals, detail screens, and settings pages.
- [ ] `AND-QA-051` Confirm back navigation does not submit forms, lose data without warning, or leave duplicate screens in the stack.
- [ ] `AND-QA-052` Confirm bottom sheets/dialogs close before the underlying page exits.

---

## 5. Request Hub & Logistics Entry Points

5.1 **Request screen**
- [ ] `AND-QA-053` Open the Request screen from bottom navigation or the configured shortcut.
- [ ] `AND-QA-054` Confirm request categories are visible, readable, and tappable.
- [ ] `AND-QA-055` Select each available category and confirm the visible state changes as expected.
- [ ] `AND-QA-056` Tap the add/new request entry point and confirm the correct request form opens for the selected category.
- [ ] `AND-QA-057` Return from a request form to the Request screen without losing the selected category unexpectedly.

5.2 **Reference data and empty states**
- [ ] `AND-QA-058` Confirm client, user, item category, form category, vehicle, location, and contact lists load where used.
- [ ] `AND-QA-059` Simulate missing reference data where possible and confirm forms show an empty or disabled state without crashing.
- [ ] `AND-QA-060` Search/filter within selectors where available and confirm results update correctly.

---

## 6. Logistics Request Forms

6.1 **Standard Delivery**
- [ ] `AND-QA-061` Open the Standard Delivery request form.
- [ ] `AND-QA-062` Fill client, document reference, item category, form category, delivery date, priority, requester, and required delivery details.
- [ ] `AND-QA-063` Submit with missing required fields and confirm inline validation blocks submission.
- [ ] `AND-QA-064` Submit a complete request and confirm success feedback and navigation behavior.

6.2 **Air/Sea**
- [ ] `AND-QA-065` Open the Air/Sea request form.
- [ ] `AND-QA-066` Fill required client, document, category, shipping, delivery, and requester details.
- [ ] `AND-QA-067` Validate Air/Sea-specific fields such as air/sea shipping options and provincial delivery-related fields where visible.
- [ ] `AND-QA-068` Submit a complete request and confirm success or queued/offline behavior.

6.3 **Pick Up**
- [ ] `AND-QA-069` Open the Pick Up request form.
- [ ] `AND-QA-070` Fill required client, item/category, date, priority, requester, and pickup details.
- [ ] `AND-QA-071` Confirm pickup-specific validation appears for missing required information.
- [ ] `AND-QA-072` Submit a valid request and confirm the created record appears where expected.

6.4 **Pull Out / Return / Pick-Up**
- [ ] `AND-QA-073` Open the Pull Out request form.
- [ ] `AND-QA-074` Fill required request details, including return/pick-up related fields where visible.
- [ ] `AND-QA-075` Confirm invalid or incomplete data is blocked with clear validation.
- [ ] `AND-QA-076` Submit a valid request and confirm visible success behavior.

6.5 **Hotline Direct**
- [ ] `AND-QA-077` Open the Hotline Direct request form.
- [ ] `AND-QA-078` Fill required fields and confirm category behavior matches Hotline Direct.
- [ ] `AND-QA-079` Submit incomplete data and confirm validation.
- [ ] `AND-QA-080` Submit a complete request and confirm success or queued/offline behavior.

6.6 **Stock Receive**
- [ ] `AND-QA-081` Open the Stock Receive screen or form.
- [ ] `AND-QA-082` Confirm current visible fields/actions match the build under test.
- [ ] `AND-QA-083` If the screen is still placeholder-like, confirm it remains stable, navigable, and free of broken controls.
- [ ] `AND-QA-084` If fields are available, validate required inputs and successful submission behavior.

6.7 **BackLoad**
- [ ] `AND-QA-085` Open BackLoad from the expected request/list context.
- [ ] `AND-QA-086` Confirm BackLoad-specific details render correctly from the selected source request.
- [ ] `AND-QA-087` Submit or save BackLoad details where supported and confirm success or queued/offline behavior.
- [ ] `AND-QA-088` Return to the source list without duplicate navigation or stale status.

6.8 **Inventory Item / OCR**
- [ ] `AND-QA-089` Open the inventory item scanner/intake flow where available.
- [ ] `AND-QA-090` Capture or select an image for inventory OCR.
- [ ] `AND-QA-091` Confirm OCR/analyze results appear clearly or an understandable error appears if the backend/AI service is unavailable.
- [ ] `AND-QA-092` Confirm scanned data can be reviewed and corrected before being used in a request.

---

## 7. Request Lists, Statuses & Role-Based Actions

7.1 **List loading and refresh**
- [ ] `AND-QA-093` Open each available request list: Standard Delivery, Air/Sea, Pick Up, Pull Out, Hotline Direct, Stock Receive, and BackLoad where visible.
- [ ] `AND-QA-094` Confirm loading indicators appear during fetch and settle into list, empty, or error states.
- [ ] `AND-QA-095` Pull to refresh each list and confirm data updates or a clear failure message appears.
- [ ] `AND-QA-096` Confirm repeated refreshes do not create duplicate rows.

7.2 **Filtering, search, and status display**
- [ ] `AND-QA-097` Use available search, date, status, and category filters.
- [ ] `AND-QA-098` Clear filters and confirm the full list returns.
- [ ] `AND-QA-099` Confirm status chips/labels are readable and visually distinct.
- [ ] `AND-QA-100` Confirm long text in cards does not overflow, overlap, or hide important actions.

7.3 **Request details and modal flows**
- [ ] `AND-QA-101` Tap a request card and confirm the expected detail screen, bottom sheet, or action modal opens.
- [ ] `AND-QA-102` Long-press a request card, if supported, and confirm the behavior is intentional and stable.
- [ ] `AND-QA-103` Close detail screens and modals using visible close controls and Android back.
- [ ] `AND-QA-104` Confirm action buttons shown in modals match the request status and user role.

7.4 **Status transitions and cancellation**
- [ ] `AND-QA-105` Execute one permitted status transition using a QA request and confirm the visible status updates.
- [ ] `AND-QA-106` Attempt a status transition with missing required proof/signature/recipient fields and confirm validation blocks it.
- [ ] `AND-QA-107` Cancel a request where allowed and confirm cancellation reason/remarks are captured if required.
- [ ] `AND-QA-108` Confirm final-status requests do not expose invalid next actions.

---

## 8. Android Device Features

8.1 **Camera, image capture, and scanning**
- [ ] `AND-QA-109` Open every flow that uses camera capture or scanning.
- [ ] `AND-QA-110` Grant camera permission and confirm preview/capture works.
- [ ] `AND-QA-111` Deny camera permission and confirm fallback guidance appears.
- [ ] `AND-QA-112` Capture multiple images and confirm previews, retakes, and removals work where available.
- [ ] `AND-QA-113` Confirm text extraction/scanner flows populate the expected fields or show understandable no-result behavior.

8.2 **Signature capture**
- [ ] `AND-QA-114` Open a flow that requires receiver or proof signature.
- [ ] `AND-QA-115` Draw, clear, redraw, and save a signature.
- [ ] `AND-QA-116` Confirm blank signatures cannot be saved if a signature is required.
- [ ] `AND-QA-117` Confirm saved signatures remain visible through submission, offline queueing, or retry flows.

8.3 **Location and maps**
- [ ] `AND-QA-118` Open map/location-based flows with location permission granted.
- [ ] `AND-QA-119` Confirm current location or selected delivery location resolves correctly enough for QA validation.
- [ ] `AND-QA-120` Deny location permission and confirm the app does not crash.
- [ ] `AND-QA-121` Search/select places or location alternatives where available and confirm selection persists in the form.

8.4 **SMS and notifications**
- [ ] `AND-QA-122` Trigger any SMS-related flow available in QA and confirm permission handling is clear.
- [ ] `AND-QA-123` Confirm local or push notifications display with readable title/body when triggered in the QA setup.
- [ ] `AND-QA-124` Tap a notification and confirm it opens the expected destination or safely opens the app.
- [ ] `AND-QA-125` Deny notification permission on Android versions that require it and confirm the app continues without notification crashes.

---

## 9. Offline, Local Data & Reconnect

9.1 **Offline startup and navigation**
- [ ] `AND-QA-126` Turn on airplane mode and launch the app.
- [ ] `AND-QA-127` Confirm the app opens to the expected cached/auth state or shows a clear network message.
- [ ] `AND-QA-128` Navigate through cached screens and confirm the app remains stable.

9.2 **Offline request behavior**
- [ ] `AND-QA-129` Start a supported request flow while offline or lose network before submission.
- [ ] `AND-QA-130` Confirm the app either queues the action locally or clearly explains that submission requires a connection.
- [ ] `AND-QA-131` Confirm no duplicate request is created after repeated taps during offline/weak-network conditions.
- [ ] `AND-QA-132` Restore network and confirm queued or retried data syncs as designed.

9.3 **Local database stability**
- [ ] `AND-QA-133` Create or update QA requests and confirm they persist after app restart when local persistence is expected.
- [ ] `AND-QA-134` Refresh lists after reconnect and confirm local/server data does not duplicate.
- [ ] `AND-QA-135` Confirm local image/signature references still resolve after restart and reconnect.
- [ ] `AND-QA-136` Confirm failed syncs show recoverable messaging and do not trap the user in a busy state.

---

## 10. Settings, Profile & Contact Directory

10.1 **Settings**
- [ ] `AND-QA-137` Open Settings from the bottom navigation or configured entry point.
- [ ] `AND-QA-138` Confirm account/profile information is visible and accurate for the logged-in user.
- [ ] `AND-QA-139` Tap each visible settings tile and confirm it opens the expected screen or action.
- [ ] `AND-QA-140` Confirm destructive or reset actions show confirmation before proceeding.

10.2 **Profile and account actions**
- [ ] `AND-QA-141` Open profile-related screens and confirm user information renders correctly.
- [ ] `AND-QA-142` Edit allowed profile fields, if supported, and confirm validation plus save feedback.
- [ ] `AND-QA-143` Cancel profile edits and confirm unsaved changes are not accidentally applied.

10.3 **Contact Directory**
- [ ] `AND-QA-144` Open Contact Directory from Settings or its configured entry point.
- [ ] `AND-QA-145` Confirm contact rows load from local data where available.
- [ ] `AND-QA-146` Search, filter, view details, add, edit, or delete contacts where the current build exposes those actions.
- [ ] `AND-QA-147` Confirm empty contact data is handled with a clear empty state.

---

## 11. Developer-Only Tools & Production Visibility

11.1 **Local Storage Viewer**
- [ ] `AND-QA-148` In a debug/QA build, confirm Local Storage Viewer is accessible only from the intended Developer Tools area or direct QA route.
- [ ] `AND-QA-149` Confirm table switching, row viewing, row deletion, and clear-table actions work only on safe QA data.
- [ ] `AND-QA-150` Confirm destructive actions require confirmation and show success/failure feedback.
- [ ] `AND-QA-151` In a production/release build, confirm Local Storage Viewer is hidden from normal users.

11.2 **Signature Outbox**
- [ ] `AND-QA-152` In a debug/QA build, open Signature Outbox from Developer Tools or its configured QA route.
- [ ] `AND-QA-153` Confirm pending signatures show clear status, preview, retry, ignore, and bulk action behavior where available.
- [ ] `AND-QA-154` Confirm Retry All and Clear All require safe confirmation and update counts/lists correctly.
- [ ] `AND-QA-155` In a production/release build, confirm Signature Outbox is hidden from normal users.

---

## 12. Layout, Keyboard, Accessibility & Performance

12.1 **Keyboard and small-screen layout**
- [ ] `AND-QA-156` Focus every text field in Login, Sign Up, request forms, search fields, and settings forms.
- [ ] `AND-QA-157` Confirm the Android keyboard does not hide active inputs, error messages, or primary submit buttons.
- [ ] `AND-QA-158` Confirm forms remain scrollable while the keyboard is open.
- [ ] `AND-QA-159` Test on a small Android screen and confirm text, chips, dropdowns, and buttons do not clip or overlap.

12.2 **Accessibility basics**
- [ ] `AND-QA-160` Confirm primary actions have readable text or recognizable icons.
- [ ] `AND-QA-161` Confirm disabled and enabled states are visually distinct.
- [ ] `AND-QA-162` Confirm color-only status cues also include readable labels.
- [ ] `AND-QA-163` Increase Android font/display size and confirm critical flows remain usable.

12.3 **Performance and stability**
- [ ] `AND-QA-164` Navigate through core flows for at least 20 minutes without app restart.
- [ ] `AND-QA-165` Confirm list scrolling remains smooth enough for QA acceptance on a low-end device.
- [ ] `AND-QA-166` Confirm repeated image capture, signature capture, refresh, and modal open/close operations do not freeze the app.
- [ ] `AND-QA-167` Confirm loaders eventually complete or fail with a message rather than staying indefinitely.

---

## 13. Regression Pass & Release Sign-Off

13.1 **Regression checklist**
- [ ] `AND-QA-168` Run one complete login-to-logout journey.
- [ ] `AND-QA-169` Create or validate one request from each visible logistics request type.
- [ ] `AND-QA-170` Validate one request list status/action flow for at least one role.
- [ ] `AND-QA-171` Validate one offline/reconnect scenario.
- [ ] `AND-QA-172` Validate one camera/image/signature scenario.
- [ ] `AND-QA-173` Validate Settings, Contact Directory, and developer-tool production visibility.

13.2 **Known issue / defect tracking**

| Defect ID | Test Case ID | Module / Area | Severity | Priority | Status | Notes |
|---|---|---|---|---|---|---|
| `[DEFECT-ID]` | `[AND-QA-###]` | `[Area]` | Critical / Major / Medium / Low | High / Medium / Low | Open / Fixed / Deferred | `[Notes]` |

13.3 **Execution summary**

| Field | Value |
|---|---|
| Build / APK Version | `[Version]` |
| Environment | QA / Staging / UAT |
| Device Model | `[Device]` |
| Android Version | `[Version]` |
| Tester Name | `[Tester Name]` |
| Test Date | `[YYYY-MM-DD]` |
| Total Planned Cases | 173 |
| Passed | `[Count]` |
| Failed | `[Count]` |
| Blocked | `[Count]` |
| Not Run | `[Count]` |
| QA Recommendation | Go / Conditional Go / No-Go |

13.4 **Final sign-off**

- [ ] All critical and major Android blockers are resolved or explicitly accepted.
- [ ] Production build does not expose developer-only tools.
- [ ] Offline/reconnect behavior has been checked for high-risk request flows.
- [ ] Camera, location, storage, SMS, and notification permission behavior has been checked.
- [ ] QA recommendation is documented with defect links and release notes.

**QA Sign-off:** `[Name / Date]`

---

## Maintenance Notes

- This document summarizes and complements the existing root `qa/*.md` feature checklists and the dated `qa/2026-05-20/` QA batch.
- Update this checklist when new Android permissions, logistics modules, request statuses, developer tools, or production visibility rules are added.
- Keep this document Android-specific. Create a separate Windows project QA document if desktop validation is required.
