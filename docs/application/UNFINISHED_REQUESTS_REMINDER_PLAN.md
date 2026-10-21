# Daily unfinished-requests reminder: plan

Status (2026-10-21): **Built** (app only; analyze and tests pass). The on-device check is still
open (see Tests). Decided: a phone notification at 8 AM, not a pop-up. The other answers keep
their defaults (below).

## Where things ended up

- **Rules (pure):** `lib/features/logistics/helpers/unfinished/unfinished_requests.dart`
  (`BUnfinishedRequests`).
- **Model:** `lib/features/logistics/models/unfinished/unfinished_request.dart`. It reuses
  `FormCategoryType` for the 7 types.
- **Reminder:** `unfinished_requests_reminder.dart` (`BUnfinishedRequestsReminder`) in the same
  helpers folder.
- **Controller:** `lib/features/logistics/controllers/unfinished_requests_controller.dart`.
  - `UnfinishedRequestsController.changed()` is called at the end of `loadForScope` in the
    Standard Delivery, Hotline Direct, Pull Out, Stock Receive, Pick Up and Air / Sea
    controllers. The HD controller inherits it.
  - A status change updates the counts on the next list load, not at once.
- **Data:** `_loadLocalLogisticsRequests` in `GeneralBindings` reads the four local tables.
  - It uses the new `StandardDeliveryRepository.getLocalRequests()`, `getLocalPullOuts()`,
    `getLocalPickUps()` and `getLocalAirSeaRequests()`.
  - A repository that isn't registered (desktop without Firebase) counts as empty.
- **First open or login of the day (added 2026-10-21).** On top of 08:00, the same notification
  shows **at once** after the first request load of the day (Manila date), so it can appear twice
  a day.
  - It goes through `BUnfinishedRequestsReminder.showNow`, under its own id (`0x20000003`) on the
    same channel. It uses the new `INotificationService.showNow`, which never asks for
    permission.
  - "Once a day" is per user: GetStorage
    `logistics.unfinishedReminder.shownOn.<INITIAL>` = `yyyy-MM-dd`.
  - Logging in again the same day doesn't repeat it. A different user on the same phone gets
    their own.
  - The date is saved only when the notification actually showed, so a day that starts with
    nothing unfinished still gets one later.
  - The Settings switch turns this off too.
- **Permission:** asked once, the first time there is something to remind about. Stored under
  GetStorage `logistics.unfinishedReminder.permissionAsked`.
- **Tap routing:** `BCollectionNotificationRouter` also routes `logistics-unfinished`, so the
  existing warm-tap and cold-start paths in `main.dart` / `NavigationController.onReady` handle
  it without a second router.
- **Opening a row:** each list's tap handler is now public, and `BUnfinishedRequestOpener` calls
  it, so a row opens exactly as it does from its own list:
  - `handleStandardDeliveryTap`
  - `HotlineDirectList.showAppropriateDialog`
  - `handlePullOutTap`
  - `handleStockReceiveTap`
  - `handlePickUpTap`
  - `handleAirSeaTap`
- **Collection users:** get no reminder (the department check is in the controller).
- **Tests:** `test/features/logistics/unfinished/` (41 tests).

## What we want

Every day at **8:00 AM**, a phone notification tells each Logistics user which requests are
still **not finished**, meaning not at a final status. For example: a Standard Delivery stuck at
Getting supplies ready, Item Prepared or For Delivery. It shows only when there is at least one.

The point is awareness: nothing is left half-done and forgotten.

## The 7 request types and their final statuses

Anything **not** in the "Final" column counts as unfinished.

| Request type | Unfinished statuses | Final (not counted) |
|---|---|---|
| Standard Delivery | New Request, Getting supplies ready, Item Prepared, For Delivery, Back Load | Delivered, Cancelled |
| Hotline Direct | same as Standard Delivery | Delivered, Cancelled |
| Pull Out | New Request, For Pull Out, In Transit | Taken Out, Picked-up, Cancelled |
| Stock Receive | New Request, In Transit | Taken Out, Picked-up, Cancelled |
| Pick Up | New Request, Getting supplies ready, Item Packed | Received, Cancelled |
| Air / Sea / Land | New Request, Getting supplies ready, Item Packed, Endorsed to Guard, For Dispatch, Dispatch, Provincial Pick Up, Provincial In Transit | Received, Drop Off, Provincial Delivered, Cancelled |
| Air / Sea / Land HD | same as Air / Sea / Land | same |

Status names are compared case-insensitively, as the DAOs' status maps do
(`status_progression.dart`).

## Who sees what (default kept)

| Role | Counted for them |
|---|---|
| Admin, Viewer | every unfinished request |
| Release | the ones waiting on preparation: New Request through Item Prepared / Item Packed, Back Load, Endorsed to Guard |
| Courier | the ones where they are the driver or helper |
| Request | the ones they created (`createdBy`) |
| Provincial | Air / Sea / Land at the provincial stages |

- A user with several roles gets the combined set, with no request counted twice.
- "Me" is the user's `initial`, compared case-insensitively.

## How it works

This copies the Collection upload reminder (`BUploadReminder`, a daily notification at 17:00
Manila).

- **The notification:**
  - Title: **"5 unfinished requests"**.
  - Body: **"Standard Delivery 3 · Pull Out 2. Tap to see them."**
  - Android shows the body on one line and expands it when pulled down.
- **When:** 08:00 Asia/Manila every day, as a repeating daily notification (`daily: true`).
  - It is inexact, so it may arrive a few minutes late. That means no exact-alarm permission.
- **Keeping it current:**
  - Every time a request list loads or changes, the reminder is recalculated and the 08:00
    notification is rescheduled with the new counts.
  - With **0** unfinished requests, the reminder is **cancelled**, so nothing shows.
- **Data:** the requests already on the phone (local SQLite, loaded with `dateFilter=All`).
  - No server or `/api4` changes.
- **Limit:** the counts are from the last time the app loaded the lists. If nobody opens the app
  for a few days, it keeps showing the last counts. Tapping it opens the app, which reloads, and
  the list shows the current requests.
- **Tap:** opens the **Unfinished requests** screen.
- **Permission:**
  - The phone asks once for notification permission, the first time the reminder is scheduled.
    This goes through `IPermissionService.requireForFeature`, as the follow-up reminders do.
  - If the user says no, nothing else breaks, and the list screen is still in Settings.
- **Turning it off:** Settings → **Unfinished requests reminder** switch, on by default. Off
  cancels the notification at once.
- **Windows:** nothing is scheduled. The list screen still works from Settings.

## What the user sees

| Where | What |
|---|---|
| Phone, 8:00 AM | "5 unfinished requests" · "Standard Delivery 3 · Pull Out 2. Tap to see them." |
| **Unfinished requests** screen | Requests grouped by type, oldest first. Each row shows the request number, client, status and date. A tap opens that request's existing detail screen. Pull down to refresh. |
| Settings (Logistics) | **Unfinished requests**: opens the screen. **Unfinished requests reminder**: the on/off switch (Android only). |

## Steps (in order)

Each step must pass `flutter analyze` and `flutter test`.

1. **Model.**
   - `UnfinishedRequest`: type, request id, number, client, status, date.
   - `UnfinishedSummary`: total, counts by type, and the notification text.
   - Both go in `lib/features/logistics/models/unfinished/`.
2. **Rules (pure).** `BUnfinishedRequests` in `lib/features/logistics/helpers/unfinished/`:
   - the final-status table;
   - `isFinished(type, status)`;
   - `forUser(requests, user)`, the role filter;
   - `summarize(...)`.
3. **Repository.** No new one. It reads the existing request DAOs (standard delivery, pull out,
   pick up, air sea) through the existing repositories.
4. **Service.** `BUnfinishedRequestsReminder` (next to the rules), shaped like `BUploadReminder`:
   - id `0x20000002`, payload `logistics-unfinished`;
   - channel `logistics_unfinished_reminders` ("Unfinished request reminders"), `hour = 8`;
   - `sync(summary)` schedules the daily 08:00 notification when the total is above 0, and
     cancels it at 0 or when the switch is off. It never throws.
   - Overlapping calls fold into one more run.
5. **Controller.** `UnfinishedRequestsController`:
   - collects the 7 types for the current user and exposes the grouped list for the screen;
   - `requestSync()` calls the reminder.
   - It is called after `loadForScope` in the Standard Delivery, Pull Out, Pick Up, Air / Sea
     and Stock Receive controllers, after a status change, and at startup.
   - The switch lives in GetStorage `logistics.unfinishedReminder` (default on).
6. **Binding.** In `GeneralBindings`, after the request repositories:
   - `Get.lazyPut(..., fenix: true)` for the reminder and the controller;
   - the request controllers call it through `Get.isRegistered`, so tests and Windows run
     without it.
7. **UI.**
   - `UnfinishedRequestsScreen`.
   - The two Settings tiles in `_LogisticsSettings`, with the switch tile copying
     `_FollowUpRemindersTile`.
8. **Route and tap.**
   - `BRoutes.unfinishedRequests` and its `GetPage` in `AppRoutes.pages`.
   - Payload `logistics-unfinished` → that route, both when the app is open (`main.dart` tap
     handler) and on a cold start (`NavigationController.onReady`), next to the Collection
     router.

## Tests

- `test/features/logistics/unfinished/unfinished_requests_test.dart`:
  - every final status of every type is excluded, case-insensitively;
  - Back Load and every middle status are included;
  - the role filter, including combined roles without duplicates;
  - counts and notification text, which list only types with a count above 0.
- `unfinished_requests_reminder_test.dart` (fake `INotificationService`, like
  `upload_reminder_test.dart`):
  - schedules at 08:00 Manila today before 8, and tomorrow after 8;
  - the daily flag is set;
  - the text matches the counts;
  - cancels at 0 and when the switch is off;
  - never throws;
  - leaves the recon and upload reminders alone (own id and payload).
- Router test: the `logistics-unfinished` tap opens the screen, warm and cold start.
- Widget test: the screen groups by type, and tapping a row opens the right request screen.
- Device check (Android): with a debug time a few minutes ahead, confirm the notification
  arrives, the tap opens the list, and it is still there after a reboot.

## Defaults kept (say if any should change)

1. **Types:** all 7 above.
2. **Who sees what:** by role, as in the table.
3. **Air / Sea / Land:** finished at Received, Drop Off, Provincial Delivered or Cancelled.
