QA Test Plan — MDMPI Mobile App

1. Purpose and Scope
- Purpose: Validate functional correctness, reliability, and compliance of the MDMPI Mobile App across Authentication, Onboarding, Home, Logistics Requests, Transport, Delivery Location (maps), and Personalization.
- In scope: Flutter app using GetX; Firebase Auth/Firestore/Storage/Messaging; Google Maps/Location; WebSockets; sqflite; camera + ML Kit OCR; local notifications; permissions (storage/location/camera/sms); Workmanager background tasks; SMS via another_telephony.
- Out of scope: Backend internals beyond API contracts; non-mobile platforms unless stated.

2. Architecture Context (Test Targets)
- Presentation: GetX controllers (Rx) with DI via Get.lazyPut/Get.find; pages registered via BRoutes and AppRoutes.pages.
- Data: Repositories talking to Firebase/HTTP/WebSocket and local sqflite cache; get_storage for simple key/value.
- Platform services: IPermissionService/PermissionService and INotificationService/NotificationService centralize OS interactions.
- Realtime: WebSocket controllers for notifications/dispatcher/delivery; FCM + local notifications.

3. Test Types and Levels
- Unit: Controllers logic (Rx state, computed values), services (permission/notification), repositories (mappers), utilities.
- Widget/UI: Rendering, Obx updates for minimal subtrees, empty/loading/error states, form validation.
- Integration: Repository↔Firebase (prefer Emulator); sqflite DB ops; permission + notification flows with stubs; camera/ML OCR mock.
- E2E (manual/automated): Critical user journeys across auth → request → map → status/notification → profile.
- Non-functional:
  - Performance: cold/warm start, list scrolling jank, memory/battery.
  - Security/Privacy: Auth/session handling, Firestore/Storage rules sanity, PII in logs, deeplink intent safety.
  - Accessibility: Semantics, focus order, contrast, dynamic text.
  - Compatibility: Android 10–15, OEM skins, small/large screens, tablets.
  - Resilience: Offline/online transitions, retries, idempotency, Doze.

4. Environments and Devices Matrix
- Environments:
  - Local Dev: Firebase Emulator Suite for Auth/Firestore/Storage/Messaging where feasible; Maps key for test.
  - Staging: Separate Firebase project; limited QA data; FCM topics for QA.
  - Production: Post-release smoke only.
- Devices/OS:
  - OS: Android API 29, 30, 31, 33, 34, 35.
  - Vendors: Pixel (reference), Samsung A/S (One UI), Xiaomi Redmi (MIUI), Oppo/Realme (ColorOS), low-RAM 2–3GB.
  - Form factors: Small phones (<5.5”), large phones (>6.5”), 7–10” tablets.
  - SIM: Single/Dual; required for SMS tests.
- Network Profiles: Offline, metered 2G/3G/4G/5G, Wi‑Fi; captive portal; high latency/packet loss; switching networks; airplane mode.
- App States: Foreground, background, terminated; Doze/standby; cold/warm start; battery optimization ignored/granted.
- Permissions States: First run prompts, granted, denied, “Don’t ask again”, revoked via Settings.

5. Data and Test Accounts
- Auth: Seed users (unverified, verified, locked, password reset candidate). Use test domains.
- Firestore: Seed logistics requests across statuses; address book; indexes validated.
- Storage: Sample images/docs to upload; size/format variety.
- FCM: Device tokens, topics; payload samples (data-only and notification with click_action).
- Maps: Test API key; representative coordinates (urban/rural/over-water), autocomplete quota.
- sqflite: Pre-populated DB for migration/upgrade; versioned schema snapshot.
- SMS: QA SIMs; operator coverage; templates.
- .env/flags: Redact secrets; provide example values for QA.
- Cleanup: Scripts or doc steps for Firestore/Storage teardown and PII masking.

6. Critical User Flows (Must-Pass)
- Signup → Email verification → Login → Home.
- Forgot password → Reset → Login.
- Onboarding → permissions flow → Home.
- Create Standard Delivery → attach photo → ML OCR → select transport → choose location on map → submit → status updates via WebSocket → receive push/local notification → tap to details.
- Profile edit → avatar upload → address add/edit → settings toggles persisted.
- Logout → relaunch → login required; session cleared.

7. Feature-Specific Test Scenarios
- Authentication:
  - Valid/invalid inputs; password rules; throttling/lockout; error messaging.
  - Email verification deep links: fresh, expired, already-used; app closed/background/foreground.
  - Session persistence; token refresh; logout state.
- Onboarding:
  - Carousel paging; skip/continue; permission prompts sequence/rationale; deny/allow/DNAA handling.
- Home:
  - Initial load; empty/loading/error states; pull-to-refresh; cached vs fresh data.
- Logistics Requests (Standard Delivery, Pick Up, Pull Out, Stock Receive, Air/Sea):
  - Form validation, required attachments; camera capture & gallery pick; large item lists performance.
  - ML Kit OCR: angled/low-light/blurred text; language variants; manual correction flow.
  - Draft/save, submit, update, cancel with remarks; status transitions; conflict resolution.
  - Offline create/queue/sync; deduplication on reconnect.
- Request Transport:
  - Vehicle selection constraints (size/weight/availability); pricing tiers; disabled states; recalculation.
- Delivery Location (Maps/Location):
  - Permission flows; GPS off; coarse vs precise; mock locations safeguard.
  - Map render, markers, polylines; autocomplete; reverse geocoding update.
- Personalization:
  - Profile fields edit; avatar upload (type/size), retry/resume; address CRUD and default; settings toggles.
- Notifications:
  - Local: schedule/immediate; foreground/background/terminated; tap routing to right screen.
  - Push: permission on Android 13+; token register/refresh; topic vs direct; collapsed updates.
- Permissions (via IPermissionService):
  - storage/location/camera/sms ask/rationale/settings redirection; battery optimization prompt; partial grants.
- WebSockets:
  - Connect/retry/backoff; ping/pong; message ordering/dedup; resume after offline; unauthorized handling.
- Background tasks (Workmanager):
  - Periodic/one-off; constraints; retries/backoff; survives reboot; interacts with notifications/data sync.
- SMS (another_telephony):
  - Send/receive; dual-SIM selection; blocked/filtered cases; permission revoked mid-flow.

8. Offline, Caching, and Persistence
- Read: cached Home/Requests views with stale indicators; manual refresh.
- Write: queue in sqflite; retry policy; idempotency; conflict merges.
- App restart: recover queues; schema migrations tested; partial data resilience.
- Firestore offline persistence interplay (if enabled) vs local cache to avoid duplication.

9. Notifications Strategy and Validation
- Channel creation/importance; DND handling; grouping.
- Tap behaviors: NavigationController index updates; route-level deep links; payload parsing.
- OEM background restrictions (Samsung/Xiaomi): confirm delivery and fallbacks.

10. Permissions and Privacy
- Centralized ensure/ensureAll flows via PermissionService; map app permissions to OS prompts.
- Storage: /storage/emulated/0/MDMPIAPP created only when storage granted; denial handling logged.
- Location: foreground/background justification; revocation handling; in-app gating.
- Camera: EXIF/rotation; privacy indicators.
- SMS: rationale and compliance; graceful degradation on denial.
- Battery optimization: prompt; fallback behavior if denied.

11. Real-Time and WebSockets
- Network transition tests; backpressure; large payloads; serialization errors.
- Security: token usage; reconnection after token refresh; unauthorized server responses.

12. Background Tasks (Workmanager)
- Schedule windows and OS constraints (Android 14–15); idempotency; retries with exponential backoff; reboot persistence.

13. Security and Compliance
- Auth leakage prevention; secure storage; clipboard/overlay protections as applicable.
- Firestore/Storage Rules: allow/deny matrix per roles/resources/fields.
- Deeplink/Intent: URL validation; unexpected payloads safe handling.
- Logging: No PII; redact sensitive payload fields; release log levels.

14. Entry Criteria
- QA environment ready; Firebase project/emulators configured; API keys present.
- QA builds signed and installable; feature flags configured; seed data loaded.
- No open blockers for targeted scope.

15. Exit Criteria
- 100% pass on P0/P1; P2 documented with mitigations.
- No critical/blocker defects open; performance meets baselines; security checks pass.
- Accessibility checks done; store policy risks addressed.
- Regression suite green; release notes ready.

16. Risks and Mitigations
- OEM background task limits affect Workmanager/FCM → test on Samsung/Xiaomi; use constraints/fallback to local notifications.
- Permission denial loops → clear UX, settings redirect tested.
- SMS policy/operator limits → narrow scope; clear opt-in; fallback verification.
- Maps/Geocoding quotas → caching; friendly errors; backoff.
- ML OCR variability → capture guidance, manual corrections, confidence thresholds.

17. Reporting and Metrics
- Case management with IDs; daily pass/fail; defect trends.
- Performance: startup time, jank %, memory baselines.
- Release readiness checklist; post-release smoke and crash monitoring.

18. Ownership and Schedule
- Feature owners: Auth, Logistics, Maps/Location, Notifications, Background, SMS.
- Milestones: Feature complete → QA pass → Regression → RC → Production smoke.

19. Traceability (Optional)
- Map requirements/user stories to test scenarios and case IDs; prioritize critical flows.

20. Compact Test Case Index (IDs)
- See docs/test_cases_index.csv for a living list. Initial seed (IDs imply area):
  - AUTH-001 Signup valid inputs → verify email sent
  - AUTH-002 Signup invalid email/password → validation
  - AUTH-003 Login valid → lands on Home
  - AUTH-004 Login wrong password → lockout
  - AUTH-005 Email verification deep link verifies
  - AUTH-006 Forgot password flow completes
  - AUTH-007 Session persists and refreshes token
  - ONB-001 Onboarding completes with permissions granted
  - ONB-002 Deny location then grant via Settings
  - HOME-001 Home loads data with skeleton
  - HOME-002 Empty state render when no requests
  - HOME-003 Pull-to-refresh updates data
  - LOG-STD-001 Create Standard Delivery minimal fields
  - LOG-STD-002 Attach photo; OCR populates fields
  - LOG-STD-003 Submit offline; queued; sync on reconnect
  - LOG-STD-004 Server validation error shows message
  - LOG-PU-001 Create Pick Up request
  - LOG-PO-001 Create Pull Out with attachment
  - LOG-SR-001 Stock Receive with large list
  - LOG-AIR-001 Air freight rules/pricing
  - LOG-SEA-001 Sea freight rules/pricing
  - TRN-001 Vehicle selection respects constraints
  - TRN-002 Pricing updates on option changes
  - MAP-001 Map renders with current location
  - MAP-002 Autocomplete search & select
  - MAP-003 Reverse geocode from pin
  - MAP-004 Location permission denied path
  - MAP-005 Route polyline render
  - NOTI-001 Local notification delivered in all app states
  - NOTI-002 Tap notification routes to details
  - NOTI-003 FCM push foreground/background
  - NOTI-004 Token refresh handled
  - PERM-001 Storage permission creates app folder
  - PERM-002 Deny with DNAA; settings redirect
  - PERM-003 Battery optimization prompt behaviors
  - WS-001 WebSocket connects and receives updates
  - WS-002 Reconnect after network loss without duplicates
  - BG-001 Workmanager task runs with constraints
  - BG-002 Retry with exponential backoff
  - BG-003 Survives reboot/Doze
  - SMS-001 Send SMS success
  - SMS-002 Receive SMS parsed and handled
  - SMS-003 Dual SIM selection prompt
  - DB-001 sqflite migrations retain data
  - DB-002 Cache eviction under low storage
  - SEC-001 Firestore rules deny unauthorized
  - SEC-002 Storage rules owner-only access
  - ACC-001 TalkBack focus order and labels
  - PERF-001 Cold start within target
  - PERF-002 Requests list scrolling smooth

Appendix A — How to run basic checks (optional)
- Static checks:
  - flutter analyze
- Unit/widget tests:
  - flutter test
- Emulator setup (suggested):
  - Use Firebase Emulator Suite for Auth/Firestore/Storage/Messaging; configure .env to point to emulator hosts.

Notes
- Keep this plan in sync with feature changes. Update docs/test_cases_index.csv as scenarios evolve.

