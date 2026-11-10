# Reconciliation follow-up reminders: plan

Status (2026-10-13): **Phases 0–3 built** (app). Phase 3 still needs its on-device check
(below). The open questions below were settled on their defaults.

## Problem

When a collector logs a step on a reconciliation case (usually the SOA), they can set a
**next action** and a **due date**: the day they agreed with the account to check back. Today that
date does almost nothing:

- No reminder before or on the day.
- The **Next action overdue** flag only appears the day *after* the date
  (`recon_rules.dart:287`, `daysBetween(due, today) > 0`), and only inside the Tracker screens.
- The calendar never shows it. The calendar has no "planned visit" at all: every row is an
  engagement already recorded (`a_tblCollectionEngagement`, stamped at save time).
- The Reconciliation dashboard sorts by "untouched longest", not by what is due.

So a collector finds out about a follow up by opening the Reconciliation list, and only once it
is already late.

## Goal

A follow up is visible **before** it is due, **on** the day it is due, and **wherever the
collector plans their day**:

1. **Dashboard:** "Due today" / "Due in N days" on the case, and due cases sorted first.
2. **Calendar:** the follow up shows on its day as a *planned* item, and opens the case.
3. **Phone notification:** on the morning of the due date (Android).

## Design principle: derive, don't store

The due date already lives in the case's activity log (`ReconActivity.nextActionDueDate`) and is
already resolved by the rules: only the collector's **own latest step** counts, and steps the app
logs itself (payment, release, acquire) do not clear it (plan, "Rules").

All three features **read that one value**. Nothing new is stored or uploaded:

- No calendar table rows, so nothing to dedupe, sync or delete. Logging the follow up moves or
  clears the date, and the dashboard, calendar and notification all follow on the next load.
- Notifications are a *projection* of the open cases, resynced after every load (see Phase 3).

## Phase 0: the due state, in the rules (pure) — done

Built as planned. `ReconEvaluation` also carries `daysUntilDue` (0 today, negative once overdue),
and `nextAction` keeps a written next action even without a date. The overdue flag now reads the
same due state, so the two can't disagree. Tests: `recon_due_test.dart`.

`lib/features/collection/models/reconciliation/recon_evaluation.dart` and `recon_rules.dart`.

- Add to `ReconEvaluation`:
  - `DateTime? nextActionDue`: the wall-clock day from `lastLogged?.nextActionDueDate`, null when
    the case is closed or the latest own step set none. It is already parsed at
    `recon_rules.dart:286`; keep that one source.
  - `String nextAction`: that step's action text ('' when none).
  - `ReconDueState get dueState`: computed from `nextActionDue` and today.
- New enum in `recon_enums.dart`:

  | `ReconDueState` | When | Label |
  |---|---|---|
  | `none` | no date, or case closed | — |
  | `later` | more than `dueSoonDays` away | `Due Oct 30` |
  | `soon` | 1..`dueSoonDays` days away | `Due tomorrow` / `Due in 2 days` |
  | `today` | the due day | `Due today` |
  | `overdue` | after the due day | `Overdue since Oct 30` |

- `ReconSettings` gains `dueSoonDays = 2` (beside `noResponseDays`).
- `nextActionOverdue` stays exactly as it is (from the day after), so reports and the
  attention counts don't change meaning. `today` is new and is **not** a flag.
- Tests: `test/features/collection/reconciliation/recon_rules_test.dart`. Cover each state, the
  day boundary in Manila time (23:59 → 00:01), a Tracker step after the dated step (date kept),
  a later own step without a date (date cleared), and a closed case (`none`).

## Phase 1: dashboard — done

Built as planned, with one difference. The log sheet's hint only promises what exists. On Android
it reads "Shows on your calendar that day, reminds you at 8 AM, and flags the case once it
passes."; on Windows it leaves out the reminder. The Home
tile's note is "2 due today · 1 overdue" (red when anything is overdue). Tests:
`recon_due_test.dart` and `recon_screens_test.dart`.

`recon_dashboard_screen.dart` (`_CaseCard`), `recon_summary.dart`, `recon_status_style.dart`,
`recon_case_screen.dart`.

1. **Chip on the case card:** a `ReconChip` for `today` (primary), `soon` (warning) and `overdue`
   (danger). It goes beside the flags, in place of a duplicate "Next action overdue" chip when
   overdue.
2. **Sort:** `compareForReconDashboard` puts open cases in this order: overdue (oldest due first),
   due today, due soon (nearest first), then the current "untouched longest". Closed cases stay
   last.
3. **Summary line** on the dashboard: "2 follow ups due today · 1 overdue" (hidden when both are 0).
4. **Home tab:** the Reconciliation tile on the Collection home gets the same "due today" count as
   a small badge, so it is seen without opening the list.
5. **Case screen:** the Last-activity card says `Next: Follow up · due today` using the state
   label. The timeline's raw `due 2026-10-30` uses the same `MMM d, yyyy` format as the card
   (current inconsistency).
6. **Log sheet:** rename **Set a due date** to **Next follow-up date**, with a one-line hint:
   "Shows on your calendar and reminds you that morning." It still defaults to today + 3.

Tests: `recon_summary_test.dart` (sort and counts), `recon_screens_test.dart` (chip, summary
line, label).

## Phase 2: calendar (planned follow ups) — done

Built as planned. The widgets are `CalendarPlannedSection` and `CalendarPlannedCard` in
`calendar/widgets/calendar_planned_card.dart`. The grid shows a ring beside the work dot, and the
screen reader announces "1 planned follow up". With no written next action, the card falls back
to the stage hint ("Follow up with the account"). Tests: `calendar_planned_test.dart`; the existing
`calendar_screen_test.dart` is unchanged and still passes.

`calendar.dart`, a new `calendar/widgets/calendar_planned_card.dart`, and
`ReconciliationController`.

- **Source:** `ReconciliationController.plannedFollowUps`. These are **my** open cases
  (`holds()`) with a `nextActionDue`, grouped by day. It's a getter over `cases`, so it is
  reactive.
- **Read once per frame** at the top of the calendar's `Obx`, next to `_byDate` (same reason as
  the comment at `calendar.dart:56`: the day builders run where an `Obx` can't see reads).
- **Day cell:** a planned follow up gets its own marker (an outlined dot) beside the engagement
  count, so a future day with only a plan still shows something. `CalendarDayCell` /
  `CalendarDayMarker` take a `plannedCount`.
- **Day list:** a "Planned" section above the day's engagements, one `CalendarPlannedCard` per
  case. It shows the account name, the next action text (or "Follow up on SOA"), the stage, the
  open amount, and the due-state chip. The card has an outlined/dashed style so it never reads as
  work already done.
  - Tap: `Get.toNamed(BRoutes.reconciliationCase, arguments: caseId)`, where the collector logs
    the follow up.
- **Overdue:** an overdue follow up stays on its own day (marked Overdue) **and** is listed under
  **today** as "Overdue since Oct 30", so it can't be lost in the past.
- **Empty state:** a day with only planned items shows the Planned section, not
  `CalendarDayEmptyState`.
- **Not added:** planned items don't count as engagements (heading count, filter bar,
  monthly summaries) and are never uploaded.

Tests: a new `test/features/collection/calendar_planned_test.dart` covering a future day with
only a plan, overdue shown on today, and tap opening the case. Extend `calendar_screen_test.dart`
so engagement counts are unchanged.

## Phase 3: phone notification (Android) — built

Built as planned. Where things ended up:
- **Dependency:** `timezone` (`latest_10y` data). It is loaded lazily inside `NotificationService`
  the first time something is scheduled, not in `platform_init.dart`.
- **Service:** `INotificationService` gains `canSchedule`, `scheduleAt` (Android only, inexact,
  returns false for a past time), `cancel`, `pending` and `launchPayload`.
- **Manifest:** `ScheduledNotificationBootReceiver` is registered.
- **Scheduler:** `ReconReminderScheduler` (`helpers/reconciliation/`):
  - `plan()` is pure: 08:00 Manila on the due day; nothing for overdue, no date, closed, or due
    today after 08:00.
  - `sync()` cancels follow-up reminders that are no longer wanted, re-schedules every wanted one
    under a stable FNV-1a id (bit 30 set), and folds overlapping calls into one more run.
  - Registered permanent in `GeneralBindings.registerReconciliationTracker`.
  - `ReconciliationController.load()` calls `syncReminders()`.
- **Taps:** handled by `BReconNotificationRouter`.
  - A tap while the app runs goes straight to the case.
  - A tap that launches the app is held in `main.dart` and opened from
    `NavigationController.onReady`.
- **Permission:** asked the first time a date is picked in the log sheet (Android, reminders
  on). It never opens Settings on a permanent denial.
- **Setting:** Settings (Collection, Android) → **Follow-up reminders** switch,
  `collection.followUpReminders`, on by default. Turning it off cancels them at once.
- **Tests:** `recon_reminder_scheduler_test.dart` (12 tests).

Windows is not a target for new features (2026-10-09). There, scheduling is a no-op, and the
dashboard and calendar still cover it.

### What exists

`flutter_local_notifications ^19.2.1`. `INotificationService` only has `init`, `showSimple` and
`cancelAll`. The manifest declares `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`, and the
plugin's `ScheduledNotificationReceiver`, but no boot receiver. Taps ignore the payload
(`main.dart:81-88`). The `timezone` package is not installed.

### Changes

1. **Dependency:** add `timezone` to `pubspec.yaml`. Initialise it in `platform_init.dart`
   (`tz.initializeTimeZones()`) and schedule in `Asia/Manila`, matching `BReconClock`, whatever
   the phone's zone. `flutter_timezone` isn't needed.
2. **Service API** (`i_notification_service.dart` + `notification_service.dart`):
   - `Future<Result<void>> scheduleAt({required int id, required String title, required String body, required DateTime manilaWallClock, String? payload})`
     - Uses `zonedSchedule` with `AndroidScheduleMode.inexactAllowWhileIdle`. A morning reminder
       doesn't need to be exact, so **no `SCHEDULE_EXACT_ALARM`** permission (and no Play policy
       declaration).
     - Uses a new channel `recon_followups` ("Reconciliation follow ups") so collectors can mute
       it separately.
   - `Future<void> cancel(int id)`.
   - `Future<List<({int id, String? payload})>> pending()`.
3. **Manifest:** register the plugin's `ScheduledNotificationBootReceiver` (BOOT_COMPLETED,
   MY_PACKAGE_REPLACED), so reminders survive a reboot or an app update.
4. **`ReconReminderScheduler`** (new, `lib/features/collection/helpers/reconciliation/`):
   - `sync(List<ReconCaseView> mine, DateTime now)`:
     - **Wanted:** for each of my open cases with `dueState` `later` / `soon` / `today`, one
       reminder at **08:00 Manila on the due day**. If the due day is today and it's already past
       08:00, there's no reminder, because the collector just set it or the dashboard and calendar
       already show it.
     - **Diff:** compare against `pending()` filtered by payload prefix `recon-case:`. Cancel the
       ones no longer wanted (logged, released, closed, date moved) and schedule the new or moved
       ones. No local bookkeeping, since the OS's pending list is the record.
     - **Id:** a stable 31-bit hash of the caseId, in its own range so it never collides with
       `showSimple` ids.
     - **Text:** title "Follow up today: <account>". Body is "<next action or 'Follow up on
       SOA'> · <n> open · ₱<amount>".
   - Called from `ReconciliationController.load()` after `cases.assignAll`. It's fire-and-forget
     (`unawaited`), never blocks the screen, and failures go to `logDebug`. Every way a case
     changes (log, release, acquire, download, launch) already goes through `load()`.
5. **Permission:** the first time a collector sets a due date, ask for the notification permission
   through `IPermissionService.requireForFeature(PermissionType.notifications, featureName:
   'Follow-up reminders')`. If they deny it, the step still saves and the dashboard and calendar
   still remind them.
6. **Tap → the case:** route payloads in the `onSelectNotification` handler in `main.dart`:
   - `recon-case:<id>` → `Get.toNamed(BRoutes.reconciliationCase, arguments: id)`.
   - Cold start: read `getNotificationAppLaunchDetails()` once the home route is up, and route the
     same way.
   - Other payloads keep today's behaviour (Activity tab).
7. **Setting:** Settings → Collection gets a **Follow-up reminders** switch, on by default
   (`CollectionSettingsController`, GetStorage). Off: `sync` cancels every `recon-case:` reminder
   and schedules none.
8. **Registration:** `ReconReminderScheduler` is `Get.lazyPut(..., fenix: true)` in
   `GeneralBindings` before `registerReconciliationTracker`. The controller resolves it with
   `Get.isRegistered` so tests and Windows run without it.

Tests: `test/features/collection/reconciliation/recon_reminder_scheduler_test.dart` with a fake
`INotificationService`:
- schedules at 08:00 Manila on the due day;
- skips one whose time today has already passed;
- cancels when the case is logged, released or closed, or the date moves;
- leaves non-recon notifications alone;
- the setting off cancels everything.

Device check (Android): set a due date for tomorrow, then change the phone's clock or use a test
build that schedules +2 minutes. Confirm the reminder, the tap opening the case, and that it
survives a reboot.

## Order and size

| Phase | Ships alone | Rough size |
|---|---|---|
| 0 Due state | with 1 | small: rules + tests |
| 1 Dashboard | yes | small–medium |
| 2 Calendar | yes (after 0) | medium |
| 3 Notification | yes (after 0) | medium: new dependency, manifest, service API, scheduler, tap routing |

Each phase gates on `flutter analyze` + `flutter test`. Phase 3 also needs the device check above.

## Open questions (defaults in bold)

1. Reminder time: **08:00** on the due day. Should there also be one the evening before?
2. "Due soon" window: **2 days**.
3. Overdue follow ups: list them under today on the calendar (**yes**). Send a second
   notification the morning after (**no**)?
4. Should the Head get reminders for the team's due follow ups? (**No**; the Head sees them in
   Reports.)
5. Default due date when logging an SOA: **today + 3** (current). Should it be today + 7 to match
   the No-response limit?

## Not in scope

- Server-side reminders, SMS, or anything through `/api4`. Everything is on the phone.
- Planned visits for anything other than reconciliation follow ups (a general visit planner would
  need its own table and sync).
- Windows notifications.
