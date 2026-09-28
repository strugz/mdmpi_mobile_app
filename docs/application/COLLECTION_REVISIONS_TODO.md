# Collection Revisions — TO DO List

> Companion to [POST_DEMO_REVISIONS_TODO.md](../POST_DEMO_REVISIONS_TODO.md), which is
> Logistics-only. Each item restates the request as a requirement, records the behavior
> found in code, lists the exact touch points across the three repos, and keeps the
> deployment steps that are still open. Status boxes are for pinning/tracking.
>
> Repos: **mobile** `mdmpi_mobile_app` · **backend** `MDMPI.App` (Postgres, `/api4/Collection/*`)
> · **web** `mdmpi_collection_web` (admin import / clients / reports).
>
> Legend: `S` small (UI/validator only) · `M` medium (model/DAO/UI) · `L` large
> (schema migration and/or backend API contract change).

## Quick checklist

- [x] 1. P.O. number from the SAP `BP Ref. No.` column, end to end — `L` (code done 2026-09-22 in all three repos and verified; **open:** run `MDMPI.App/migration_20260922_add_collection_invoice_ponumber.sql` on production Postgres **before** the backend deploy and before the next monthly import; commit the three repos)
- [x] 2. Filter engagements by P.O.: typed lookup + Has P.O. / No P.O. chips — `M` (done 2026-09-22, mobile only; ships with item 1)
- [x] 3. Manual *Add to Bucket*: optional P.O. field — `S` (done 2026-09-23, mobile only; the backend already accepted `PoNumber`)
- [x] 4. Admin web Clients dialog: invoices grouped by P.O. — `M` (done 2026-09-23; needed a new read-only endpoint `GET /api4/Collection/clients/{code}/invoices` — backend deploy required, no migration)
- [x] 5. Bucket: account cards count P.O.s, account screen folds invoices under collapsible P.O. rows — `M` (done 2026-09-23, mobile only)
- [x] 6. Label changes — `S` (done 2026-09-23, mobile only): "Clear Engagement" → "Done Engagement"; Account Details "Total Amount Past Due", "Total # of past invoices", "Current Amount", "Total # of current invoices"; Engagement Details "Current Balance" → "Balance"; Home card "Due Date" → "Past Due" (also the category key in `category_detail_screen.dart`)
- [x] 7. Engagement Details: hide the Balance tile when it is ₱0 — `S` (done 2026-09-23)
- [x] 8. Actual Collection % toward the manually set monthly target — `S` (the page already had it; the home card now shows "N% of ₱target" / "Target met"; both floor the percent so 99.6% never reads 100%)
- [x] 9. *For Deposit* (Field Engagement) is the collector's activity only; its amount counts toward neither Actual Collection nor Collected this Month — `M` (decided 2026-09-24: Actual Collection comes from what the office posts on the web, item 11; mobile done 2026-09-24: deposits count toward neither Actual Collection nor Collected this Month; Actual Collection reads ₱0.00 until item 11 posts)
- [x] 10. Done Engagement sends an SMS to the collector's Head — `M` (done 2026-09-25, mobile only; message text decided the same day)
- [x] 11. Collection web: screen to post Actual Collection — `L` (done 2026-09-25 in all three repos; **open:** run `MDMPI.App/migration_20260925_add_collection_actual.sql` before the backend deploy, give the `CollectionPoster` role to the office staff who post, check the Firestore rules let a user read their own `Users/{uid}`; server-side auth is a separate item)
- [x] 12. **Plan only:** a separate bottom navigation bar for the Head of Collection — `M` (closed 2026-09-25: superseded by items 21–22, which built the bar; no plan doc written)
- [x] 13. The user picks who their Head is — `M` (done 2026-09-25, mobile only: Settings → *My Head*, saved on the user's Firestore doc as `HeadKey`/`HeadName` and in the cached user; **open:** none, no backend or migration)
- [x] 14. One user directory from CNTMST (key `CNTMNN`) and Firestore `Users` (key `initial`) — `M` (done 2026-09-25, mobile only; feeds items 10 and 13)
- [x] 15. Settings: suggested features for Collection — `S` (picked 2026-09-25: Default area, Storage, About; all three done, mobile only)
- [x] 16. Advanced Payment is float: it counts toward Collected this Month only once applied to an invoice, in the month of the date the collector picks — `M` (done 2026-09-24, mobile; see below)
- [x] 17. Apply advance: partial payment of an invoice — (decided 2026-09-25: the current design stands; an advance smaller than the invoice pays it partially, the collector enters the due date and the collection date, the rest stays in the bucket. No *amount paid* field, no split, no backend change)
- [x] 18. Apply advance — add a P.O. number field when creating the invoice — `S` (done 2026-09-25, mobile + backend; **open:** deploy the backend, which until then drops the P.O. on upload)
- [x] 19. Engagement History: a From–To date filter (today by default) and a status filter naming every status, Advance Payment included — `M` (done 2026-09-25, mobile only; see below)
- [x] 20. The monthly target is the team's, set only by the office (CollectionPoster, admin web); the phone shows it read-only — `S` (done 2026-09-25 in all three repos; ships with item 11: same migration, same backend deploy)
- [x] 21. Head Admin: a new bottom navigation bar where the Head sees every collector's field activity — `L` (done 2026-09-25, mobile + backend; decided: the Head sees every collector, online only, and also collects; **open:** deploy the backend, give the `CollectionHead` role to the Head's Firestore user)
- [x] 22. Head Admin: a calendar with a collector picker that shows that collector's activity — `M` (done 2026-09-25 with item 21: the *Team Activity* tab)
- [x] 23. Collection SMS: six triggers with fixed templates (Acquiring Account, Saving Engagement, Defer Account, Clear Engagement, Adding Deposit, CWT Pick-Up) — `M` (spec received and done 2026-09-25, mobile only; recipients: the Head + Contact Directory "Collection" contacts; replaces item 10's Done Engagement summary)
- [ ] 24. **Next week (from 2026-09-28):** Save Engagement still does not send its SMS on the phone — `M` (raised 2026-09-25 after the item 23 fixes; investigate on a real device, see below)

---

## 24. Save Engagement SMS still not sending (next week)

**Reported (2026-09-25).** On the phone, pressing *Save engagement* (Engagement Details,
outcome Collected) does not send the Saving Engagement SMS, after every item 23 fix. Scheduled
for the week of 2026-09-28.

**What is already known.**
- The button is wired: `ActivityDetailScreen._saveActivity` → `CollectionActivityController.saveActivity`
  → `CollectionRepository.saveActivity` → `_notifySms` → `CollectionSmsService.notifyEngagementSaved`
  (sends only for `Collected` / `Partially Collected`; Pre-Collection and Others send nothing,
  per the spec).
- One earlier test on the phone showed the "Message Sent!" view after this save, so the radio
  accepted the send at least once. Since then "Message Sent!" requires the SENT report for
  every recipient, as Logistics does; otherwise a dialog says why.
- Recipients are the Head (Settings → My Head, phone from the user directory) plus Contact
  Directory contacts tagged "Collection". Logistics sends from the same phone use the
  Logistics contacts and the CNTMST manager chain, a different recipient list.

**To check first.**
1. What the phone shows after the save now: the sending view, "Message Sent!", the Messages
   app, or which dialog (no one to text / may not have been sent / not sent + reason).
2. `adb logcat` for `CollectionSmsService:` lines during the save: recipients found,
   permission, the pre-flight reason, "confirmed / unconfirmed / failed" per number.
3. The Head's number as the directory returns it (format: `09…`, `+639…`, or empty), and
   whether a Contact Directory contact with department "Collection" exists on the phone.
4. Whether a Logistics notice from the same phone arrives (rules out SIM load and carrier).
5. `saveActivity` runs the SMS after `_archive` and `_queueChange`: confirm neither throws
   (a throw skips the SMS and is only logged by the repository's catch).
6. Whether `CollectionSmsService` is registered when the save runs (`Get.isRegistered`);
   `_notifySms` returns silently when it is not.

**Touch points.** `lib/data/services/collection_sms_service.dart`,
`lib/data/repositories/collection/collection_repository.dart` (`saveActivity`, `_notifySms`),
`lib/features/collection/presentation/pages/activity/activity_detail_screen.dart`,
`test/features/collection/collection_sms_test.dart`.

**Cause found (2026-09-28, on the phone).** The radio log showed
`SmsDispatcher.sendText(): getSubmitPdu() returned null` for both saves: the phone refused the
text before sending it. The `₱` in the amount is outside the GSM-7 SMS alphabet, so the whole
message became UCS-2 (70 characters per SMS); the ~113-character text was sent as one SMS
(`isMultipart` only above 160 characters) and could not fit. The telephony plugin
(`another_telephony` 0.4.1) reports SENT for every result code, so the app logged "confirmed"
and showed no warning.

**Fixed (mobile, 2026-09-28).** Amounts are written `PHP 24,281.25`; every Collection SMS is
sent multipart (Android splits only when needed). The texts now reach the network. Still to
confirm: on 2026-09-28 SMART rejected every text from the test SIM (`MODEM_ERR`, error code 21,
"Not Sent" in Messages), a SIM/load issue outside the app. Tick item 24 once a text arrives.

**Wording changed (2026-09-28).** The six templates now lead with what happened and end with
the collector's initials:

| # | Trigger | Message |
| --- | --- | --- |
| 1 | Acquiring Account | `Now handling [Client]. 5 POs, 6 invoices, PHP [balance]. - MAR`; several accounts acquired together: one text, `Now handling 3 accounts: [Client] (5 POs, 6 invoices, PHP [balance]); … Total PHP [sum]. - MAR` |
| 2 | Saving Engagement | `Collected PHP [total] from [Client]. Invoice [Invoice] (PO [PO]). Check [Bank] [No.], dated [Date]. - MAR` (Partial: `Partial payment of PHP [total] from …`; several invoices list each amount; the check part only when paid by check) |
| 3 | Defer Account | `Postponed [Client]. Reason: [Remarks]. - MAR` |
| 4 | Clear Engagement | `Done with [Client]. - MAR` |
| 5 | Adding Deposit | `Deposited PHP [Amount] at [Bank]. Check [No.]. Note: [Remarks]. - MAR` |
| 6 | CWT Pick-Up | `Picked up CWT from [Client]. Note: [Remarks]. - MAR` |

Blank optional parts are left out. The spec table under item 23 is superseded by this one.

---

## 23. Collection SMS: six triggers

**Spec (received 2026-09-25).** Six events, each with fixed parameters and a template:

| # | Trigger | Parameters | Template |
| --- | --- | --- | --- |
| 1 | Acquiring Account | Client, POs, Invoices | `Acquiring Account Update: [Client Name]. POs: [POs]. Invoices: [Invoices].` |
| 2 | Saving Engagement | Client, POs (optional), Invoices & Amount, Status Collected / Partial | `Engagement Saved for [Client Name]. POs: [POs]. Invoices/Amt: [Invoices & Amount]. Status: [Collected/Partial].` |
| 3 | Defer Account | Client, Remarks | `Account Deferred: [Client Name]. Remarks: [Remarks].` |
| 4 | Clear Engagement | Client | `Notice: You have been cleared and are now out of account [Client Name].` |
| 5 | Adding Deposit | Bank, Amount, Check (optional), Remarks (optional) | `Deposit Added: [Bank Name] \| Amt: [Amount] \| Check: [Check Details] \| Remarks: [Remarks].` |
| 6 | CWT Pick-Up | Client, Remarks | `CWT Pick-Up logged for [Client Name]. Remarks: [Remarks].` |

**Decided (2026-09-25).** Every message goes to the collector's Head (Settings → My Head,
at the directory's number) **and** to the Contact Directory contacts tagged "Collection",
de-duplicated. Trigger 4 replaces item 10's Done Engagement summary.

**Done (2026-09-25, mobile).**
- `CollectionSmsService` rewritten: six static template builders, six `notify*` methods,
  one `send` to `recipients()` (Head first, then contacts), `CollectionSmsOutcome`
  (`sent`, `handedOff` via the Messages app when SMS permission is refused, `noRecipients`,
  `unavailable` off Android, `failed`). Injectable head / contacts / permission / send /
  hand-off hooks. The old per-collection `notifyEngagement` / `notifyBatch` are gone.
- Hooks: 1 in `CollectionRepository.claimItemsByIds` (one message per account claimed,
  POs and invoice ids from the claimed items); 2 in `saveActivity` (one invoice) and
  `saveBatchActivity` (every invoice with its amount; Partial if any is), sent only for a
  Collected or Partially Collected outcome; 3 in `unclaimWithReason` (reason - remarks);
  4 in `unclaimAccount`; 5 and 6 in `saveGlobalActivity` by type.
- Optional segments are left out when blank (POs on 2; Check and Remarks on 5).
- The one-time "No Head set" hint stays on Clear Engagement.
- **Seen on screen (2026-09-25, second pass).** Delivery now mirrors the Logistics
  notifications step for step: SIM / service pre-flight, permission (Messages app as the
  fallback), then the full-screen "Please wait message sending... (i/N)" view
  (`BFullScreenLoader.openProgressLoadingDialog`) while each recipient is sent, and the
  "Message Sent!" view on success. The first pass used an indefinite snackbar, which stayed
  up when the radio never answered; now every platform call is bounded (15 s, then 3 s for
  the SENT report) and the view comes down in a `finally`. As in Logistics, "Message Sent!"
  shows only when the radio confirms SENT for **every** recipient; an accepted but
  unconfirmed send (usually no SIM load, or a carrier delay) is `unconfirmed` and warns
  "SMS may not have been sent" with the reason. Warnings say why nothing went out ("no one to text" once per run, the SIM /
  service reason, "did not accept the message", "Android only").
- **No snackbar while sending (2026-09-25).** `CollectionSmsService.smsFollows({status})`
  says, without waiting, whether a save is about to send (Android, a Collected / Partial
  outcome for Saving Engagement, and a recipient count warmed at start and after each
  lookup). The seven trigger screens (engagement, batch, defer, clear, deposit, CWT,
  claim / acquire) skip their "Saved" snackbar when it is true; the sending view and
  "Message Sent!" are the only feedback. What went wrong is shown in a small dialog, not a
  snackbar; the "No Head set" snackbar hint is gone.
- Tests: `collection_sms_test.dart` (20).

---

## 21. Head Admin: a bottom bar to see all collectors' field activity

**Requirement (raised 2026-09-25).** A new bottom navigation bar for the Head Admin, where
the Head can see all the activity of every collector in the field. Builds what item 12 only
asked to plan.

**Today.**
- `NavigationController.screens` (`lib/data/controllers/navigation_controller.dart`) picks
  tabs by department only: Collection gets Home, Field Engagement, Calendar, Profile.
  Nothing distinguishes a Head from a collector.
- Every activity screen reads the signed-in collector's own work: `GET
  /api4/Collection/workspace?collector=` returns one collector's items, activities,
  deposits and engagements; `CollectionActivityController.ownEngagements` and the local
  `a_tblCollectionEngagement` archive hold only that. There is no endpoint that lists
  another collector's, or the team's, activity.
- The admin web's Reports page already sums per collector (Collected, Deposited) for a
  month, but not per activity.

**Proposed.**
- **Who is a Head.** A `Role` on the Firestore user (the web already gates on the
  comma-separated `Users/{uid}.Role`, e.g. `CollectionPoster`): add `CollectionHead`. The
  phone reads it from the cached user, so the tab set is known on cold start.
- **Tabs.** Team Activity (item 22's calendar, the first screen), Reports (the team tiles
  the web shows: Actual, Target, Collected), Profile. Whether the Head also collects, and
  so keeps Field Engagement and their own Home, is to be decided; the routing falls out of
  `app_router.dart` plus a third branch in `NavigationController.screens` / `screenRoutes`.
- **Data.** A read-only `GET /api4/Collection/team/engagements?from=&to=&collector=`
  returning engagement rows (collector, account, activity type, status, amount, date,
  remarks) across collectors, from `a_tblCollectionEngagement` and its activity tables;
  paged or date-bounded. Online only at first: the Head reads what has been uploaded, so a
  collector's unsent outbox is not visible until they Upload All (the screen should say
  "as of last upload").
- **Mobile.** `TeamActivityRepository` → `Result<List<TeamEngagement>>`; controller with
  collector, date range and status filters (reuse `EngagementFilter` / `EngagementStatus`
  from item 19); cards from `activity_history_list.dart` with the collector's name added.

**Decided (2026-09-25).** The Head sees every collector; online only; the Head also
collects, so their own four tabs stay and Team Activity is a fifth.

**Done (2026-09-25).**
- **Role.** `BTexts.roleCollectionHead` = `CollectionHead`, read from the user's Firestore
  `Role` field (comma-separated, case-insensitive) by `BCollectionRoles.isHead`
  (`features/collection/helpers/collection_roles.dart`); it needs the Collection department
  too. Set it on the Head's `Users/{uid}` doc like `CollectionPoster`.
- **Tabs.** `NavigationController.screens` / `items`: Collection + Head gets Home, Field
  Engagement, Calendar, **Team Activity** (people icon), Profile. Nothing is taken away.
- **Backend.** `GET /api4/Collection/team/engagements?from=&to=&collector=` (read-only, no
  migration): `Collectors` = everyone who has ever uploaded, by the latest name they uploaded
  under; `Engagements` = every engagement row (Field / Batch / Office / Reconciliation /
  Deferred), bank deposit (account-less ones included) and CWT pick-up whose date is in the
  window, newest first, with the client name. A Reconciliation shows once, from its
  per-invoice engagement row. Float advances are payments, not engagements, and appear once
  applied. The service rejects a bad window (dates `yyyy-MM-dd`, from ≤ to, ≤ 366 days) with
  400. `ICollectionReportRepository.GetTeamEngagementsAsync`, DTOs in
  `CollectionReportDtos.cs`. Tests: `CollectionTeamEngagementsTests` (6).
- **Mobile.** `TeamActivityFeed` / `TeamEngagement` (`features/collection/models/`),
  `TeamActivityRepository` (`data/repositories/collection/`, plain GET, `Result`),
  `TeamActivityController` (one month per load, for the picked collector; a slower answer
  for a superseded month is dropped; a failed reload keeps the month on screen with a
  banner) and `TeamActivityScreen` (`presentation/pages/team/`, route
  `BRoutes.teamActivity`). Tests: `team_activity_controller_test.dart` (12),
  `team_activity_screen_test.dart` (5).
- The web does not get the screen; its Reports page stays the office's monthly view.

---

## 22. Head Admin: calendar with a collector picker

**Requirement (raised 2026-09-25).** On the Head Admin bar, a calendar; the Head selects
a user and the calendar shows all of that user's activity.

**Today.** `CollectionCalendarScreen`
(`presentation/pages/calendar/calendar.dart`) shows the signed-in collector's own days:
dots per day from `ownEngagements`, and the day's list beneath. It cannot switch users.

**Proposed.**
- A collector picker above the calendar (the item 14 directory filtered to the Collection
  department, searchable like *My Head*), defaulting to the first collector or to "All".
- The calendar itself is the existing widget fed by a different source: item 21's team
  endpoint for the picked collector and the visible month, so the month's dots and the
  selected day's list are that collector's. Counts follow the existing rule: the calendar
  counts collections, not deposits or CWT.
- Tapping a day lists the engagements with the same cards as Engagement History, plus the
  collector's name in the heading when "All" is picked.
- Ships with item 21 (same role, same endpoint); the calendar is the first tab built.

**Done (2026-09-25, with item 21).** The *Team Activity* tab is this calendar. A chip above
the month opens a sheet: *All collectors* then every Firestore `Users` record whose
Department is Collection, by name (decided 2026-09-25: only those; not CNTMST-only rows,
and not "whoever uploaded"). Each is keyed by the Firestore username, which is what the
backend files uploads under (`DirectoryUser.username` / `collectorCode`). Someone who has
not uploaded yet is listed and shows "uploaded nothing". Searchable by name or code. The month's dots and counts and the selected
day's list come from that collector's (or everyone's) feed; the day list reuses
`ActivityHistoryCard` with the collector's name on each card, so with everyone picked each
row says who did it. Deposits read "Bank deposit · <bank>". The header shows "as of <time>"
and a reload button, because the feed is what has been uploaded, not what is on the
collectors' phones. Every row in the window is shown (deposits and CWT pick-ups included);
`collectedOn` sums only collections.

**Design pass (2026-09-25).** The chip became a full-width selector row (avatar · name ·
"N collectors · updated 4:14 PM" · chevron). The day heading shows the day's collected
total on the right. With *All collectors* on screen the day's cards are grouped under a
small collector header (initials, name, count), newest collector first; one collector shows
no headers. Empty days get a muted card instead of a bare line, and the day list crossfades
(fade + 6 px rise, 180 ms, ease-out, off under reduced motion) when the day or collector
changes.

---

## 19. Engagement History: date filter and status filter

**Requirement (raised 2026-09-25).** Engagement History shows the current day by default,
with a From–To date filter for other days and ranges, and a status filter covering every status: Advance
Payment, Partial Payment, CWT Pick-up and the rest.

**Previous behavior.** `RecentActivitiesScreen` and the home preview listed
`allRecentHistory`: every entry the phone had cached, all days, built from the bucket
cache (so an advance received never appeared, and a settled invoice took its entry with
it). Ten raw-status chips and no Advance chip.

**Done (2026-09-25, mobile).**
- `CollectionActivityController.engagementsBetween(from, to)` / `engagementsOn(day)` /
  `todayEngagements`: the entries from the archive (`activitiesByDate`), the calendar's source.
- `helpers/engagement_history_filter.dart`: `EngagementStatus` — Collected, Partial
  Payment, Advance Payment, Advance Applied, Deposit, CWT Pick-up, Reconciliation, Follow
  Up, Pre-Collection, Customer Unavailable, Refused to Pay, Others. Every stored status
  maps to one; an unknown one reads as Others; a reconciliation an outcome finished is
  also listed under Reconciliation. Search over account, invoice and P.O. The day's total
  uses `CollectionOutcome.countsAsCollected`.
- `recent_activities_screen.dart`: a search beside a filter button
  (`CollectionSearchFilterBar`, as on the bucket), one quiet line "Sep 19 – 25, 2026 · N
  engagements · ₱X collected", and the list. No date bar on the page. Over more than one
  day the list has a heading per day ("Today", "Yesterday", "Tuesday, Sep 23").
- `pages/home/widgets/engagement_filter_sheet.dart` (`EngagementFilterSheet`), one sheet
  for both filters:
  - **Date:** *From* and *To* fields (date pickers, no future days; a From after To moves
    To with it and the other way round, so the range is never empty), with presets Today,
    Yesterday, Last 7 days, This month (the preset matching the fields shows selected).
  - **Status:** the twelve statuses in three groups (Payments, Office activities, Visits
    without payment), each with the count for the range in the draft; several can be
    picked.
  - The apply button counts ("Show 3 engagements") and is off when nothing would show;
    Reset returns to today, every status.
- `EngagementFilterChips` under the search: the range when it is not just today (removing
  it goes back to today) and each picked status, all removable. Statuses hold when the day
  changes.
- Empty states for a day with nothing and for no match (Clear filters).
- Home preview: today's entries only, "No engagements yet today".
- Tests: `test/features/collection/engagement_history_test.dart` (16).

---

## 9. *For Deposit* is activity only, never Actual Collection

**Requirement (raised 2026-09-24).** The amount entered on a *For Deposit* activity in
Field Engagement does not count as Actual Collection. *For Deposit* only records what the
collector did.

**Current behavior.** Actual Collection *is* the deposits:
`TotalCollectedController.actualCollectionTotal` sums `depositEntries`, built by
`_collectDeposits()` from `globalActivities` rows of type `Deposit`
(`presentation/controllers/total_collected_controller.dart`). The home card and the
Actual Collection page (`monthly_summary_screen.dart`, `type: 'Deposit'`) both read it.

**Done (2026-09-24, mobile).**
- `TotalCollectedController`: deposits are no longer read. `actualCollectionTotal`,
  `postedEntries` and `actualEntries` come from `postedActual`, an `RxList<MonthlyEntry>`
  that item 11's workspace download will fill. Until then it is empty and Actual
  Collection reads ₱0.00.
- `MonthlySummaryScreen`: mode `'Deposit'` renamed `'Actual'` (home card link updated);
  "Deposited" → "Posted"; the empty month reads "No Actual Collection posted for
  <month>" and says deposits stay in the engagement history.
- The home card's % toward the target (item 8) now measures the posted total, so it
  reads 0% until the office posts.
- **Collected this Month leaves deposits out too** (raised the same day: For Deposit is
  just a regular activity of the collector). A deposit is archived as an `OFFICE`
  engagement carrying its amount, and `_collectMonth` added it — the same pesos counted
  once when collected and again when banked. It now skips `OFFICE` rows with status
  `Deposit`. Other office activities (CWT Pick-up, Reconciliation) still count as before.
- Deposits are untouched everywhere else: `deposit_form.dart`, the archive itself,
  engagement history, the calendar, the upload outbox.
- Tests (`monthly_summary_test.dart`): deposits alone leave Actual Collection at zero and
  the page explains why; posted entries set the total, other months are excluded, and the
  search never moves the total; target progress runs off posted entries.

**The form (2026-09-25).** *Record Deposit* no longer asks for an account or bucket
invoices: a deposit is the collector's activity, not tied to an account. It takes **Bank,
Amount, Check Number** and optional **Remarks** (`deposit_form.dart`); the remarks are no
longer prefixed with an invoice list. The backend accepts a `DEPOSIT` with no `ClientCode`
(stored with no client, linking no payments; an older build that still sends an account
and invoices takes the old path). History cards name such a deposit "Bank deposit · BPI"
with "Check #…" instead of "Account Engagement / Whole account". Tests:
`deposit_form_test.dart`, `engagement_history_test.dart`, and the backend
`Deposit_WithoutAnAccount_IsRecordedAsTheCollectorsActivity`.

**Until the backend is deployed** the testing server still runs the old rule and rejects
the new form's deposit with "ClientCode is required" (seen 2026-09-25: *Rejected —
attempts: 5*). The outbox used to show only the attempt count, so the cause was invisible
on the phone; it now keeps the server's reason (`a_tblCollectionPending.lastError`, added
with `addColumnIfMissing` so an existing queue is not rebuilt) and prints it under the
attempts line, with "Ref: ACT-…" instead of "Invoice:" for activity rows. Once the backend
with the account-less `DEPOSIT` branch is up, tap Upload All again and the row clears.

**Remaining.** Item 11 fills `postedActual`; the page's rows then show whatever the
posted record carries (reference, posted by).

---

## 17. Apply advance: partial payment of an invoice

**Requirement (raised 2026-09-24).** An invoice created from an advance can be partially
paid; the rest stays in the bucket as the invoice's remaining balance.

**Decided (2026-09-25): the current design stands.** The Apply sheet
(`category_detail_screen.dart`, `_ApplyAdvanceSheet`) already does this. The collector
enters the invoice number, the invoice's amount due, its due date and the collection date
of the amount paid. An advance smaller than the invoice (₱750,000 on a ₱1,000,000 invoice)
is spent in full and the invoice goes to the bucket with ₱250,000 remaining; an advance
larger than the invoice keeps the excess as float (item 16). The server allocates
`min(unallocated, invoice remaining)`, which matches. Test: `advance_float_test.dart`
("an advance smaller than the invoice is spent and leaves the list").

Not built, by decision: an *amount paid* field, splitting one advance across invoices in
one step, and the backend `AmountApplied` field.

**Follow-up (done 2026-09-25).** *Amount due* starts blank instead of prefilled with the
advance: left prefilled on a larger invoice, it recorded the invoice paid in full and
nothing reached the bucket. Its helper says what happens either way. The sheet's own drag
handle is gone; the theme's remains. Tests: `category_detail_advance_test.dart`.

---

## 18. Apply advance: P.O. number on the new invoice

**Requirement (raised 2026-09-24).** When an advance is applied, the collector fills out
the P.O. number of the invoice being created.

**Current behavior.** `_ApplyAdvanceSheet` has no P.O. field, so an invoice created from an
advance carries no P.O. and does not group under one in the bucket (items 1, 5).

**Done (2026-09-25).**
- Mobile: an optional *P.O. number (optional)* field on `_ApplyAdvanceSheet` (key
  `advance-po-number`, characters capitalization, no autocorrect), passed through
  `assignInvoiceToPayment(poNumber:)` → `CollectionItemModel.poNumber`, and queued on
  `ASSIGN_ADVANCE` as `PoNumber` (blank → `null`). The new invoice groups under its P.O. in
  the bucket at once.
- Backend (`MDMPI.App`): the handler did **not** store it (`CollectionChangeDto` had no
  `PoNumber`, so System.Text.Json dropped it). `CollectionChangeDto.PoNumber` added; a new
  invoice takes `NormalizePoNumber(change.PoNumber)`; an existing invoice with a blank P.O.
  gets it filled, a stored one is never overwritten (the import backfill rule). No
  migration. Test `AssignAdvance_StoresPoNumber_FillsBlank_NeverOverwrites`; collection
  invoice repository tests 26/26.
- Tests (mobile): `advance_float_test.dart` (P.O. reaches the invoice and the repository;
  none typed → none), `category_detail_advance_test.dart` (the field reaches
  `assignInvoiceToPayment`).

**Deployment.** Deploy the backend. Until then the phone shows the P.O. but the server
drops it, and the next download loses it.

---

## 16. Advanced Payment is float until applied

**Requirement (raised 2026-09-24).** An Advanced Payment is a float amount. It does not add
to Collected this Month when received; it stays under Advanced Payment. Applying it to an
invoice, on a date the collector picks, is what puts it in Collected this Month — in that
date's month.

**Previous behavior.** It counted twice: the `ADVANCE` archive row on the day it was
received, then an `INVOICE` "Advanced Payment Applied" row stamped at the moment of
tapping Assign, carrying the whole advance even when the invoice was due less.

**Done (2026-09-24, mobile).**
- `TotalCollectedController._collectMonth` skips `ADVANCE` rows. The advance still shows
  under Advanced Payment and in the history.
- The Assign sheet (`category_detail_screen.dart`) has a **Collection Date**, today by
  default, never before the day the advance was received, any later date allowed.
- `assignInvoiceToPayment(collectionDate:)` → `assignAdvance(appliedAt:, appliedAmount:)`:
  the chosen day (with the current time of day, `collectionStamp`) is the invoice
  history's date, the archive row's `engagedAt` and the queued `ASSIGN_ADVANCE`
  `EngagementDate`, so the server files it in the same month. The archived amount is
  what went onto the invoice (never more than it was due), matching its history.
- Tests (`monthly_summary_test.dart`): an unapplied advance adds nothing; an applied one
  counts in its chosen month and not the current one; the stamp files under the chosen
  day.

**Excess stays float (decided and done 2026-09-24).** An advance larger than the invoice
covers what the invoice is due; the rest stays under Advanced Payment on the **same**
advance (`CollectionAdvanceDao.keepRemainder`, same `externalRef`), ready for the next
invoice. The backend already worked this way — one payment, many allocations,
`ASSIGN_ADVANCE` applies `min(unallocated, invoice balance)` and a download reports the
remainder as `Unallocated` — so no server change. `assignInvoiceToPayment` returns the
float left; the Apply sheet says so ("₱250,000.00 stays as float for another invoice") and
the amount-due field notes that any excess stays as float. Tests: `advance_float_test.dart`
(excess kept, smaller advance spent, remainder applied to a second invoice) and the DAO
test in `collection_extras_dao_test.dart`.

**Calendar and badges (2026-09-24).** One rule, `CollectionOutcome.countsAsCollected`,
now decides what counts as collected everywhere (Collected this Month, the calendar's visit
totals, the history cards): not an `ADVANCE` / "Advanced Payment", not a "Deposit". A visit
with a ₱750,000 advance and ₱350,000 applied from it totals ₱350,000.00 (it read
₱1,100,000.00); the advance keeps its row and amount, in ink rather than green, titled
"Advance received" instead of "Invoice #AP-…", with no fake invoice or due line. The
"Advanced Payment" / "Advanced Payment Applied" badges were white on white (unmapped
statuses fell back to a near-white); they are amber and green, and any unmapped status is
neutral grey. Tests: `calendar_advance_test.dart`, `collection_status_colors_test.dart`
(every status at least 3:1 contrast, tinted and solid).

---

## 10. Done Engagement → SMS to the collector's Head

**Decided (2026-09-24).** The SMS goes to the Head the user picked (item 13), at that
person's phone number from the directory (item 14: `CNTMST.CNTNUM`, or the Firestore
user's phone).

**Still open.** The message text, and whether it covers one account or batches the day.

**Touch points.**
- `CollectionActivityController.unclaimAccount` (Done Engagement) → send after the
  release is saved; never block the release on the SMS.
- `MessagingController` / `sms_message_template_service.dart` — a Collection template
  (today every template is a Logistics status). The Messages-app fallback for a refused
  `SEND_SMS` permission is already in (`5f00a84`).
- No Head picked → no SMS, and the Done Engagement snackbar says so once, pointing to
  Settings → *My Head*.

**Decided (2026-09-25).** One SMS per Done Engagement (the *Done* release, not a Deferred
one), summarising today's outcomes on that account:

    MDMPI Collection: Jay Abaoag finished an engagement with Metro Globe
    (Inv 700011347), Collected ₱6,001.00, 25 Sep 2:59 PM.

Several invoices read "(3 invoices)"; nothing recorded today reads "no collection
recorded". `CollectionSmsService.doneEngagementMessage` / `stamp`.

**Done (2026-09-25, mobile).**
- `CollectionActivityController.unclaimAccount` → after the release is saved,
  `doneEngagementSummary` (today's `INVOICE` rows for the account in `ownEngagements`:
  distinct invoice ids, summed amount) → `notifyHeadOfDoneEngagement`, never awaited by the
  release.
- `CollectionSmsService.notifyDoneEngagement` → the Head from the user's `headKey`, at the
  number `UserDirectoryRepository.find` holds; returns `DoneEngagementSms` (`sent`,
  `handedOff` when SMS permission is refused and the Messages app opens pre-filled via
  `MessagingController.buildMessagingAppUri`, `noHead`, `noPhone`, `unavailable` off
  Android, `failed`). The service now takes injectable head / permission / send / hand-off
  hooks; the per-collection notifications are unchanged.
- Snackbars: *No Head set* once per install (`collection.headHintShown`), *Head not
  notified* when the Head has no number or the send failed; nothing on success.
- Tests: `done_engagement_sms_test.dart` (12).

---

## 11. Collection web: post Actual Collection

**Requirement (raised 2026-09-24).** An interface in `mdmpi_collection_web` where the
office enters Actual Collection. Pairs with item 9: this becomes the only source of the
figure.

**Decided (2026-09-25).**
- Actual Collection is **the team's figure**, not a collector's. The CollectionPoster does
  not pick a collector (that is not their job): an entry is only **Amount, Reference No.
  (deposit slip / OR) and Remarks**, dated the Manila day it is posted (an edit keeps the
  day). A reference is posted once.
- The monthly **target is the team's too**, one per month, set only by the office (item 20).
- Only the Firestore role **`CollectionPoster`** (on `Users/{uid}.Role`, comma-separated like
  the other roles) may post, edit, delete and set the target. Enforced on the web for now:
  the backend has no auth on any Collection endpoint, so the API records who posted
  (`PostedBy`, like the client editor's `UpdatedBy`) but does not check it. Server-side
  checks (verify the Firebase ID token and the role) are a separate item.
- Deposits are the collectors' activity and count toward neither Actual Collection nor
  Collected this Month, on the web as on the phone.

**Backend (done 2026-09-25, `MDMPI.App`).**
- `migration_20260925_add_collection_actual.sql` (appended to `mdmpi_app_db_schema.sql`):
  `a_tblcollectionactual` (actualid, collectiondate `yyyy-MM-dd`, amount `numeric(18,2)` > 0,
  referenceno, remarks, postedby, createdat, updatedat, updatedby) with a unique index on
  the upper trimmed reference and an audit table `a_tblcollectionactual_history` + trigger
  (a delete stamps `updatedby` first, so the DELETE row names the web user); and
  `a_tblcollectionteamtarget` (yearmonth PK, targetamount, updatedat, updatedby). The old
  per-collector `a_tblcollectiontarget` rows are left alone and no longer read.
- `CollectionActualModel`, `CollectionTeamTargetModel`, `CollectionActualDtos.cs`,
  `ICollectionActualRepository` / `CollectionActualRepository` through `ICollectionService`
  and `CollectionController`:
  - `GET /api4/Collection/actual-collections?month=yyyy-MM`; `POST` / `PUT /{id}` with
    `{ Amount, ReferenceNo, Remarks, PostedBy }` (400 with the reason; 404);
    `DELETE /{id}?by=<email>` (204 / 404). A concurrent duplicate refused by the unique
    index is answered as "already posted".
  - `GET /api4/Collection/targets?month=` and `PUT /api4/Collection/targets`
    `{ YearMonth, TargetAmount, UpdatedBy }` (0 clears it).
  - The phone's `SET_TARGET` upload is accepted and ignored (a rejected change would retry
    forever in older apps' outboxes; applying it would overwrite the office's figure).
- Workspace: every collector's download carries the team's `ActualCollections` and the
  team's `Targets` (same `{YearMonth, TargetAmount}` shape the phone already reads), last
  12 months.
- Monthly report: top-level team `TargetAmount`, `Actual`, `ActualCount`, `Achievement`;
  rows per collector carry only `Collected`, `Deposited`, `DepositCount`, `UndatedCount`
  (the per-collector target and the deposit-based `Undeposited` are gone).
- Tests: `CollectionActualRepositoryTests`, `CollectionActualEndpointTests`, the report
  tests (team figures; deposits counted only as Deposited), and the invoice test asserting
  `SET_TARGET` is ignored.

**Web (done 2026-09-25, `mdmpi_collection_web`).**
- `src/firebase.js` initialises Firestore; `src/stores/auth.js` loads `Users/{uid}.Role`
  on sign-in and session restore (`authState.roles`, `hasRole`, `rolesReady`);
  `src/utils/roles.js` holds `ROLE_COLLECTION_POSTER` and the parsing. Route
  `/actual-collection` (`meta.role`) is guarded in `src/router/index.js`; its tab in
  `src/App.vue` shows only for the role.
- `src/views/ActualCollectionView.vue` + `src/api/actualCollectionApi.js`: a month filter;
  tiles for the team's posted total, the team target (*Set target* / *Edit*) and
  achievement; *Set Target* and *Post Actual Collection* buttons; a post / edit dialog with
  Amount, Reference No. and Remarks only; a Set Target dialog (month + amount, *Clear
  target*); a table (date, reference, amount, remarks, posted by) with a total row.
- `src/views/ReportsView.vue` + `src/api/reportsApi.js`: tiles for the team's Actual
  collection, Target (with achievement), Collected this month and Deposits ("not counted
  in either figure"); per collector only Collected, Deposited and Deposits; the deposits
  list has no linked-payments column or payment breakdown; the Excel export gains a Team
  sheet.
- `npm run build` passes. No test setup in this repo.

**Mobile (done 2026-09-25).** The page and the home card read the team's figure
("Actual Collection · Team", "Team · posted by the office", "N% of ₱X team target"); the
target is read-only ("No team target set yet · the office sets it"), and `setTarget`,
`SET_TARGET` queueing and `TotalCollectedController.setTargetAmount` / `clearTargetAmount`
are removed (item 20).
- `CollectionWorkspaceParser` reads `ActualCollections` into `CollectionActualRecord` (no collector fields)
  (`lib/data/local/dao/collection/collection_actual_dao.dart`), skipping rows without an
  `ActualId` or a yyyy-MM-dd `CollectionDate`; `hasActualCollections` says whether the
  key was sent at all.
- New table `a_tblCollectionActual` (in `ensureCollectionTables`, no version bump; index
  on `collectionDate`) and `CollectionActualDao` (`replaceAll`, `forMonth`, `getAll`),
  exposed as `DatabaseHelper.collectionActualDao`. Listed by the Local Storage Data Viewer.
- `CollectionRepository._replaceAccountLevelData` replaces the table wholesale when the
  download carried the key (an empty list clears it); an older server that leaves the key
  out leaves the table untouched. `getActualCollections(yyyy-MM)` reads it back.
- `TotalCollectedController.reloadActual()` fills `postedActual` for the selected month on
  init, on a month change and on `localDataVersion`, so Actual Collection is the office's
  figure. `MonthlyEntry` gained `referenceNo`, `remarks`, `postedBy`.
- The Actual Collection page leads each row with the reference ("OR 12345" as typed, a bare
  number as "Ref. 12345"), remarks as a quiet second line, "Posted by …" in small print;
  the search matches reference and remarks.
- Tests: `test/collection_workspace_parser_test.dart`, `test/collection_actual_dao_test.dart`,
  `test/data/local/local_storage_viewer_tables_test.dart`,
  `test/features/collection/monthly_summary_test.dart`.

---

## 12. Head of Collection: a separate bottom bar (plan only)

**Requirement (raised 2026-09-24).** Plan, not build, a different bottom navigation for
the Head of Collection.

**Today.** `NavigationController.screens` (`lib/data/controllers/navigation_controller.dart`)
picks tabs by department only; Collection gets Home, Field Engagement, Calendar, Profile.
There is no role below department.

**The plan should settle.**
- **Who is a Head.** A role field on the Firestore user, the CNTMST hierarchy (`CNTTGP`,
  already walked by `CntmstDao.getUserAndManagerPhoneNumbers`), or "anyone picked as Head
  by a collector" (item 13). The last needs no admin step but makes the role depend on
  other people's settings.
- **Tabs (draft).** Team (each collector's collected vs target, today's engagements),
  Engagements feed (Done / Deferred across the team, with the SMS from item 10), Calendar
  (team view), Reports, Profile. Does the Head also collect, and so keep Field Engagement?
- **Data.** What the Head's screens need from `/api4` that the collector workspace does
  not carry (team-wide engagements and totals), and whether it can go offline like the
  collector's.
- **Routing.** A third branch in `screens` plus `app_router.dart`; `BRoutes` for any new
  pages.

Deliverable: `docs/application/COLLECTION_HEAD_NAVIGATION_PLAN.md`.

---

## 13. The user picks their Head

**Requirement (raised 2026-09-24).** Each user chooses who their Head is.

**Proposed.**
- Settings → *My Head*: a searchable picker over the directory from item 14 (name,
  department, initial), with a Clear option.
- Stored on the user's Firestore `Users` doc (`headKey`, plus the name for display) so it
  follows the user to another phone; cached in `GetStorage` for offline use.
- `profile.dart:77` shows a hardcoded "Supervisor: MDD"; it reads the chosen Head instead.
- A default when nothing is chosen: the first manager in the user's CNTMST `CNTTGP`
  hierarchy, marked "suggested" until confirmed.

**Done (2026-09-25, mobile).**
- `UserModel` carries `headKey` / `headName` (Firestore `HeadKey`, `HeadName`; also in the
  `CurrentUser` GetStorage cache, so the Head reads offline and on a desktop without
  FlutterFire). `UserController.setHead` writes Firestore when it is up, then the cached
  user; a Firestore refusal leaves the old choice in place and is shown as "Not saved".
- `MyHeadController` (`features/personalization/controller/`): loads the item 14 directory,
  search on name / code / department, `choose`, `clear`, and a suggestion from the first
  non-`EGL` segment of the user's `CNTTGP` (`CntmstDao.getByCode`), never the user
  themselves, shown only while nothing is chosen. A Head who has since left the directory
  still shows by the saved name and can be cleared.
- `MyHeadScreen` (route `BRoutes.myHead`, `/settings/my-head`): current Head card with
  *Clear*, the suggestion tile with *Use*, search, and the list; choosing asks "Set as your
  Head?" first. Reached from Settings → *My Team* → *My Head* (Collection settings, subtitle
  shows the current Head) and from the profile's *Head* row, which replaced the hardcoded
  "Supervisor: MDD".
- Tests: `my_head_controller_test.dart` (11), `my_head_screen_test.dart` (6),
  `user_model_head_test.dart`, `cntmst_dao_test.dart` (`getByCode`).
- Item 10 reads `user.headKey` → `UserDirectoryRepository.find` for the SMS number.

---

## 14. One user directory: CNTMST + Firestore `Users`

**Requirement (raised 2026-09-24).** A user is either in CNTMST or in Firestore `Users`.
Their key is `CNTMNN` in CNTMST and `initial` in Firestore.

**Proposed.**
- A read-only `UserDirectoryRepository` merging `CntmstDao` rows (`CNTMNN`, name,
  department `CNTDPT`, phone `CNTNUM`, active `CNTSTS`) and Firestore `Users`
  (`initial`, name, department, phone). Keys compared trimmed and upper-cased; when a
  person is in both, Firestore wins for name and phone, and CNTMST supplies anything
  missing.
- Returns `Result<List<DirectoryUser>>`; registered in `GeneralBindings` behind the
  existing `Firebase.apps.isNotEmpty` guard, so Windows falls back to CNTMST only.
- Tests: merge, duplicate keys differing in case or spacing, inactive CNTMST rows, and
  Firestore unavailable.

**Decided (2026-09-25).** `CNTMNN` and `initial` are the same code for the same person.

**Done (2026-09-25, mobile).**
- `lib/data/models/directory_user.dart` — `DirectoryUser`: key (trimmed, upper-cased code),
  name, department, phone, `inCntmst` / `inFirestore`, `firestoreId` (the Firebase uid, for
  item 13), email.
- `lib/data/repositories/user/user_directory_repository.dart` — `UserDirectoryRepository`:
  `load({refresh})` → `Result<List<DirectoryUser>>` sorted by name, cached in memory;
  `find(code)`. The merge is a pure static `merge(cntmst, firestore)`:
  - Firestore wins for name, phone and department; CNTMST fills what it leaves blank
    (name `CNTMCN`, else first + last).
  - An inactive CNTMST row (`CNTSTS` '0') is dropped unless the person has a Firestore
    account; rows without a code, and Firestore users without an `initial`, are skipped;
    duplicate codes in one source are one person (first non-blank value kept).
  - A failure only when neither source can be read; Firestore failing or absent gives the
    CNTMST directory.
- `CntmstDao.getAll()` — every CNTMST row with a code (unlike `getRequesters`, collectors
  and inactive rows included).
- Registered in `GeneralBindings` outside the Firebase guard, with the Firestore loader
  only when `Firebase.apps.isNotEmpty`, so Windows without FlutterFire gets CNTMST only.
- Tests: `test/data/user_directory_repository_test.dart` (13), `test/cntmst_dao_test.dart`.
- Nothing uses it yet: item 13 (*My Head*) is the first caller.

---

## 15. Settings: suggested features for Collection

Collection's Settings currently has **Upload Data** and the developer tools
(`settings.dart`). Candidates, most useful first. None are built; pick which to schedule.

1. **My Head** — item 13 (done 2026-09-25).
2. **Sync status** — last download and upload times, pending uploads, and a link to the
   upload outbox (today it is reached only from the home screen).
3. **End-of-day reminder** — a local notification at a chosen time when uploads are still
   pending.
4. **Default area** — preselect the bucket's area filter for collectors who work one
   territory.
5. **Done Engagement SMS** — on/off, with a preview of the message (item 10).
6. **Default bank** — prefill the bank on deposits and check payments
   (`bank_field.dart` already keeps suggestions).
7. **Monthly target** — the month's target and progress, read-only (set on the web).
8. **Storage** — local data size, clear cached photos, re-download the bucket.
9. **Compact lists** — denser account and invoice cards for a collector with a long
   bucket.
10. **About** — app version and what's new in this build.

**Picked and done (2026-09-25).** Default area, Storage and About, under a new *Preferences*
heading in Collection Settings (`settings.dart` `_CollectionSettings`):
- **Default area** — `CollectionSettingsController` (GetStorage key `collection.defaultArea`,
  '' = all). `DefaultAreaSheet` lists All areas then every territory in Filter by Area's
  order, none dimmed. `CollectionActivityController.onInit` opens the bucket on the saved
  area; Filter by Area still changes it for the day and writes nothing back; choosing a
  new default applies to the open bucket at once.
- **Storage** — `CollectionStorageController` / `CollectionStorageScreen` (route
  `BRoutes.collectionStorage`): `app.db` size (with `-wal`/`-journal`), rows per
  `a_tblCollection*` table, pending uploads; *Re-download the bucket* goes through
  `downloadBucket()` so un-uploaded work is still checked; *Clear cached pictures* empties
  `flutter_cache_manager`'s `DefaultCacheManager` (profile photos and other network images;
  Collection stores no photos of its own). Both confirm first. Collections, engagements and
  the upload queue are never cleared here. `flutter_cache_manager` is now a direct
  dependency (it was already pulled in by `cached_network_image`).
- **About** — `AboutScreen` (route `BRoutes.about`, `AboutController`): app name and
  version from `package_info_plus` with copy; *What's new* from `BWhatsNew.groups`
  (`features/personalization/models/whats_new.dart`, in code so it works offline). The group
  for the running version is shown, else the newest with a note. **When bumping the
  version, add a group for it at the top of `BWhatsNew.groups`.**
- Not picked: Sync status, End-of-day reminder, Default bank, Monthly target (the home card
  already shows it), Compact lists, Done Engagement SMS toggle (waits for item 10).
- Tests: `collection_settings_controller_test.dart` (5), `collection_storage_test.dart` (9),
  `about_screen_test.dart` (5).

---

## 5. Bucket: P.O. count on the account card, invoices folded by P.O.

**Requirement (raised 2026-09-23).** A P.O. holds many invoices. The Collection Bucket must
show how many P.O.s and invoices an account has, and inside the account the invoices sit
under their P.O., opened by tapping it.

**Previous behavior.** The account card said "7 invoices"; the account screen was a flat
list of invoice cards.

**Done (2026-09-23, mobile only).**
- `presentation/controllers/collection_activity_controller.dart` — `_poCountByClient`
  aggregate (bucket-only, open invoices only, case-insensitive) and `getAccountPoCount`.
- `presentation/widgets/account_card.dart` — `poCount`; the metadata line reads
  "3 P.O.s · 7 invoices" (P.O. leads: accounts payable releases payment per order). Zero
  P.O.s → "7 invoices", unchanged. Wired in `collection_bucket_screen.dart`.
- `helpers/po_grouping.dart` — `PoGrouping.of(invoices)`: pure fold, first appearance
  first (the caller's sort still decides which P.O. leads), case-insensitive key, display
  keeps the first spelling; invoices with no P.O. go to `ungrouped`.
- `presentation/widgets/po_invoice_group_card.dart` — `PoInvoiceGroupCard`: one row per
  P.O. with count, overdue badge, total due and a chevron that rotates; opens with
  `AnimatedSize` 200 ms ease-out-cubic so the cards slide from the header instead of the
  list jumping. Invoices underneath are indented with a hairline and drop their own P.O.
  line (`InvoiceCard.showPoNumber = false`) since the header already names it.
  `PoSectionLabel('No P.O.')` rules off the unnamed tail.
- `pages/bucket/collection_account_invoices_screen.dart` — grouped list when any invoice
  has a P.O., else the old flat list. Default open state: closed when the account spans
  several P.O.s, open when there is only one or a search is narrowing the list (a match
  hidden in a closed group is a match nobody sees). Hand-toggled state is kept per P.O.
  across filter rebuilds.
- Tests `test/features/collection/po_grouping_test.dart` — fold order and case, totals and
  overdue, no-P.O. case, controller count, card label both ways, group row closed/open/
  closed. Collection suites: 341 pass; `flutter analyze` 0 errors.

**Follow-up (2026-09-23): the Activity side folds the same way.**
- `getActivityAccountPoCount` (engaged, open invoices, case-insensitive) feeds `poCount` on
  the Activity list's `AccountCard` in `pages/activity/activity.dart`.
- `pages/activity/activity_account_invoices_screen.dart` — same grouped list; one shared
  `_invoiceCard` keeps the record / tick / details behaviour for grouped and flat rows.
  **While selecting, every group is open and cannot be closed**, because a tick inside a
  closed group is a tick the collector cannot see or undo. Select All still acts on every
  invoice.
- `PoInvoiceGroupCard` now takes an `itemBuilder` (the caller wires its own taps) and a
  `selectedCount` shown as an "N selected" badge on the header.
- Tests: Activity P.O. count, selected badge, caller-built cards. Collection suites: 344.

**Follow-up (2026-09-23): preview the P.O.s from the bucket list itself.**
- The count line on the bucket's `AccountCard` ("3 P.O.s · 7 invoices ▾") is now its own
  control (`onBreakdownTap`, `breakdownExpanded`, `breakdown`). It opens an inline
  `AccountPoBreakdown` (`presentation/widgets/account_po_breakdown.dart`): one line per P.O.
  with count and total, one quiet line per invoice (number, due date, red dot if overdue,
  amount), "No P.O." tail. Capped at 12 lines with "+N more · View all invoices" into the
  account screen. Opening it never ticks the account (the card body still does).
- The overdue badge moved to the empty left half of the amount line; on the metadata line
  it squeezed the count to "1 P.O. · 1 in…" on a 390pt phone. It scales down before the
  amount ever does.
- Open state is view state on `collection_bucket_screen.dart` (not the controller); the
  breakdown is only built while open. `getBucketOpenInvoices` feeds it the same invoices
  the card counts.
- Tests `test/features/collection/account_po_breakdown_test.dart`.

**Follow-up (2026-09-23): breakdown on the Activity list, copy icons.**
- `pages/activity/activity.dart` — same count control and `AccountPoBreakdown` on every
  Field Engagement card, fed by `getActivityOpenInvoices` (engaged, open, unfiltered).
  The screen is stateless, so each card's open state lives in a keyed `_BreakdownHost`;
  "View all invoices" opens the Activity account screen.
- `lib/common/widgets/buttons/b_copy_icon_button.dart` — `BCopyIconButton`: 16pt glyph in
  a 32pt target, copies to the clipboard, light haptic, glyph becomes a tick for 1.4 s
  (scale + fade from 0.6), floating snackbar "P.O. 23-122 copied". Uses
  `ScaffoldMessenger.maybeOf`, not `Get.context`, so it works in sheets and tests.
- Placed on: every P.O. and invoice line of the breakdown; the P.O. group header (its own
  target — copying never opens or closes the group); the invoice number and P.O. line on
  `InvoiceCard` (hidden in selection mode, where every tap is a tick).
- Test `test/common/widgets/b_copy_icon_button_test.dart`. Collection suites: 352 pass.

**Follow-up (2026-09-23): the breakdown moved to its own page.** Opened inline, a five-P.O.
account grew to fill the screen and pushed the other accounts out of the list you pick
from. The inline `AccountPoBreakdown` (and its test) is removed.
- `presentation/pages/po/account_po_invoices_screen.dart` — `AccountPoInvoicesScreen`:
  app bar with the account and "5 P.O.s · 7 invoices", a "To be collected" total with the
  overdue count, a search over P.O. and invoice numbers, then one card per P.O. (full
  number on up to two lines, count, overdue, total, copy) with its invoice rows (number +
  copy, due date or "N days overdue" in red, amount). All P.O.s start open; tapping a
  header folds it (200 ms ease-out). A search keeps every match open. Tapping an invoice
  opens its details sheet. Read-only; follows the list live through the `invoices`
  callback read inside `Obx`.
- `AccountCard.onPoInvoicesTap` replaces the inline breakdown params. The count line reads
  as a link (primary colour, trailing arrow, like Details beside it); opening it never
  ticks the account. Wired on the bucket (`getBucketOpenInvoices`) and Activity
  (`getActivityOpenInvoices`) lists; the Activity `_BreakdownHost` is gone.
- Test `test/features/collection/account_po_invoices_screen_test.dart`. Collection suites:
  348 pass.

---

## 1. P.O. number from SAP `BP Ref. No.`

**Requirement (raised 2026-09-22).** Collectors and the office must know which customer
**Purchase Order** an invoice belongs to. SAP's AR aging export carries it in the
**`BP Ref. No.`** column. One P.O. is often billed as **several invoices**, so the
relationship is P.O. 1 → N invoices. Add it to the backend, the database, the admin web
import and the mobile client.

**Previous behavior.** The monthly import kept six SAP columns (BP Code, BP Name,
Doc. No., Posting Date, Due Date, Balance Due). Nothing in any repo knew about a P.O.

**Design.** [COLLECTION_ADR_001_PO_NUMBER.md](COLLECTION_ADR_001_PO_NUMBER.md) — a
nullable `ponumber` column on the invoice (not a P.O. table), because a P.O. is the
customer's free text, not a key: the same string recurs under different clients, so it is
only meaningful **within a client**. Findings from the sample export that shaped it:
99.6% of invoices carry one, 16.7% of P.O.s cover 2+ invoices, 11 P.O.s appear under two
customers, and Excel had already coerced 76 values into dates.

**Done (2026-09-22).**

*Backend (`MDMPI.App`)*
- `migration_20260922_add_collection_invoice_ponumber.sql` — `ponumber varchar(100)`
  plus a partial index on `(clientcode, ponumber)`. Re-runnable, metadata-only. Also
  appended to `mdmpi_app_db_schema.sql`.
- `CollectionInvoiceModel.PoNumber`, `CreateCollectionInvoiceDto.PoNumber`,
  `CollectionItemDto.PONumber` (JSON key `PONumber`, matching the `BPCode` style).
- `CollectionInvoiceRepository`: `BuildInvoiceEntity` trims / null-normalizes;
  `ToItemDto` emits it; **`ImportInvoicesAsync` fills a blank P.O. on a duplicate
  invoice** and touches nothing else — the one exception to insert-only, so the whole
  bucket backfills on the next monthly run. A stored P.O. is never overwritten.
- Tests: store + expose, backfill without moving balance or dates, never overwrite.
  186/187 pass; the one failure is the WebSocket max-connections flake, green alone.
- The invoice history trigger is intentionally unchanged (same as `originalamount` /
  `source`).

*Admin web (`mdmpi_collection_web`)*
- `src/utils/excelParser.js` — `ponumber` header aliases (`bp ref. no.`, `po number`,
  …); the sheet is read a second time with `raw: false` and the P.O. is taken from the
  **displayed text**, so Excel-coerced dates arrive as `12/19/24` rather than a `Date`.
  Blank stays blank, casing kept, not validated (~0.4% of SAP invoices have none).
  Template gains a `PO Number` column.
- `src/views/BucketImportView.vue` — `P.O. No.` preview column.
- `README.md` and `docs/SAP_AR_IMPORT_PLAN.md` §3 / §4 / §6 updated.
- `vite build` passes; verified on the real SAP file: 3,855 of 3,870 kept invoices carry
  a P.O., all strings, no `Date` leaks, 509 client+P.O. pairs cover 2+ invoices.

*Mobile (`mdmpi_mobile_app`)*
- `lib/data/local/db_schema.dart` — `poNumber TEXT` on `a_tblCollectionItems`, added by
  `_addColumnIfMissing` (no DB version bump; un-uploaded field work untouched).
- `lib/data/local/dao/collection/collection_dao.dart` — `PONumber` both directions.
- `lib/features/collection/dtos/collection_item_dto.dart`,
  `models/collection_item_model.dart` — `poNumber`, blank when missing (never `'N/A'`),
  `hasPoNumber`, `copyWith`. Mapper unchanged (JSON round-trip).
- `presentation/controllers/collection_activity_controller.dart` — account invoice
  search matches the P.O. (both filter paths).
- UI, all gated on `hasPoNumber`: `PO …` line under the due date on `invoice_card.dart`;
  chip on `bucket_item_card.dart`; tile in `invoice_details_modal.dart`; row in
  `activity_info_card.dart`; `engagement_invoice_picker.dart` subtitle leads with the P.O.
- Tests: `test/collection_dao_test.dart` (round trip; legacy table gains the column),
  `test/collection_item_po_number_test.dart` (DTO/mapper contract, blank handling,
  `copyWith`). `flutter analyze` 0 errors.
- Docs: ADR-001 Accepted; `docs/modules/collection/README.md` notes the field.

**Deployment order.**
1. [x] Run the migration on the testing-server Postgres (2026-09-23).
2. [x] Deploy the backend build (2026-09-23; `GET /bucket` now returns `PONumber`).
3. [x] Re-upload the month's SAP file from the updated web (2026-09-23). Existing invoices
       reported as *Skipped* while gaining their P.O. — the backfill rule worked as designed.
4. [ ] Ship the mobile build (older builds keep working; they ignore the new key).
5. [ ] Verify after the next monthly import: `SELECT count(*) FILTER (WHERE ponumber IS
       NULL), count(*) FROM a_tblcollectioninvoice WHERE source = 'SAP';` → nulls ≈ 0.4%.
6. [ ] Commit the three repos.

**Lesson (2026-09-23).** Importing from the updated web against the *old* backend lost the
P.O. silently: System.Text.Json drops a body property the DTO does not declare, so the
rows saved fine without it, and the phone (no `API4_URL_ANDROID` override, so it talks to
the testing server) showed "No accounts match" on *Has P.O.*. Whenever a contract field is
added, confirm the deployed build returns the key before testing a client against it.

**Notes.**
- Changing `ActivityFilter` / `CollectionItemModel` fields needs a **hot restart**, not a
  hot reload (const classes).
- The backend and web trees also hold the unfinished **Reports** feature; stage the P.O.
  files separately if Reports is not ready to commit.

---

## 2. Filter engagements by P.O.

**Requirement (raised 2026-09-22).** The *Filter engagements* sheet on the Collection
Bucket must let a collector narrow the list by P.O.

**Design.** A P.O. cannot be a chip row like Due or Amount — a bucket carries thousands
of distinct values — so the group is a **typed lookup** plus a **presence** row. Matching
is a case-insensitive *contains* on the invoice P.O. (people remember the middle of a
long reference). Presence and typed text are **one group** for the badge count.

**Done (2026-09-22, mobile only).**
- `lib/features/collection/models/activity_filter.dart` — `PoPresence { any, has, none }`,
  `poPresence`, `poNumber`, `hasPoNumber`, `isPoActive`; wired into `matches`,
  `isActive`, `activeCount`, `copyWith`, `==` / `hashCode`.
- `presentation/pages/activity/widgets/activity_filter_sheet.dart` — "P.O. number" group
  after *Amount due*: `Any / Has P.O. / No P.O.` chips over a text field styled like the
  list's search bar (clear button fades 160 ms, no entrance animation, no autocorrect,
  characters capitalization). The two controls never contradict: **No P.O.** clears the
  text and disables the field; typing while **No P.O.** is on flips it to **Any**. Reset
  empties the field, not just the draft. The sheet pads for the keyboard once
  (`viewInsets.bottom`) and the nav bar once (`padding.bottom`).
- `ActiveFilterChips` — removable `PO 2026-0262` chip; a typed P.O. hides the redundant
  *Has P.O.* chip; *No P.O.* shows as its own chip.
- Live count on the apply button recounts on every keystroke, so a P.O. not in the bucket
  says "No accounts match" before anything is applied. Opening an account afterwards
  shows only its invoices on that P.O. (the account screen applies the same spec).
- Tests: `test/features/collection/activity_filter_test.dart` — matching, blank input,
  badge count, typing drives the count and applies, Reset clears the field, No P.O.
  clears + disables, typing flips presence back, both chip variants. 334 collection
  tests pass.

---

## 3. Manual *Add to Bucket*: optional P.O. field

**Requirement (raised 2026-09-23).** A supervisor adding an invoice by hand can record
the customer's P.O., so it shows on the cards and answers the P.O. filter like an
SAP-imported one.

**Previous behavior.** `add_to_bucket_screen.dart` built the request without a P.O.;
hand-added invoices stored `null` and showed no chip.

**Done (2026-09-23, mobile only — the backend DTO already accepted `PoNumber`).**
- `presentation/pages/bucket/add_to_bucket_screen.dart` — "P.O. Number (customer purchase
  order)" field after Document References. Optional; characters capitalization, autocorrect
  and suggestions off (a reference, not prose). Blank is sent as `null`.
- `presentation/controllers/collection_activity_controller.dart` `addInvoiceToBucket` and
  `data/repositories/collection/collection_repository.dart` `createInvoice` — new optional
  `poNumber`, sent as `PoNumber` in the POST body; the backend trims and null-normalizes.
- The created item comes back through the bucket DTO with `PONumber`, so the local cache
  and the card show it at once.

---

## 4. Admin web Clients dialog: invoices grouped by P.O.

**Requirement (raised 2026-09-23).** From the Clients screen the office must see which
invoices each P.O. covers for one client.

**Previous behavior.** `ClientsView.vue` showed only a per-client invoice **count**; no
endpoint returned a client's invoices (the bucket endpoint is per collector).

**Done (2026-09-23).**

*Backend (`MDMPI.App`, no migration)*
- `GET /api4/Collection/clients/{code}/invoices` → `List<CollectionClientInvoiceDto>`
  (`DocumentId`, `PONumber`, `PostingDate`, `DueDate`, `ToBeCollected`, `TotalCollected`,
  `Status`, `CollectorName`, `Source`). `404` when the client code is unknown; `[]` when it
  has no invoices. Ordered P.O.s together (blank last), oldest due first within a P.O.
- `ICollectionClientRepository.GetInvoicesAsync` / `CollectionClientRepository`,
  `ICollectionService.GetClientInvoicesAsync` / `CollectionService`, controller action.
- Test `GetInvoices_GroupsByPo_BlankLast_AndIsPerClient` — order, blank-last, per-client
  scoping (two clients share the P.O. string), unknown code → null. Collection suites:
  60/60.

*Admin web (`mdmpi_collection_web`)*
- `src/api/clientsApi.js` — `getClientInvoices(code)`.
- `src/views/ClientsView.vue` — "Invoices by P.O." section under the client editor:
  one expansion panel per P.O. with count and open balance, a "No P.O." panel last, rows
  Doc. No. / Due / Balance / Status (manual adds marked). Multi-invoice P.O.s start open,
  single-invoice ones folded. Loads on dialog open; a stale response for a previous
  client is discarded. `vite build` passes.

**Deployment.** Ships with the item 1 backend deploy (same build). Until the backend is
deployed the dialog shows "Could not load invoices (404)" for this section only; editing
still works.
