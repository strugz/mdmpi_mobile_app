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
- [ ] 10. Done Engagement sends an SMS to the collector's Head — `M` (recipient decided 2026-09-24: the Head the user picked, item 13; **open:** message text)
- [ ] 11. Collection web: screen to post Actual Collection — `L` (new backend table + `/api4` endpoints + migration; web view; mobile reads it through the workspace)
- [ ] 12. **Plan only:** a separate bottom navigation bar for the Head of Collection — `M` (plan doc, no code)
- [ ] 13. The user picks who their Head is — `M` (Settings → *My Head*; stored on the user's Firestore doc)
- [ ] 14. One user directory from CNTMST (key `CNTMNN`) and Firestore `Users` (key `initial`) — `M` (feeds items 10 and 13)
- [ ] 15. Settings: suggested features for Collection — `S` to pick from (list below; nothing built)
- [x] 16. Advanced Payment is float: it counts toward Collected this Month only once applied to an invoice, in the month of the date the collector picks — `M` (done 2026-09-24, mobile; see below)

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

**Remaining.** Item 11 fills `postedActual`; the page's rows then show whatever the
posted record carries (reference, posted by).

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

**Open.** When the advance is larger than the invoice, the excess is not carried anywhere
(unchanged behavior). Should it stay as float for another invoice?

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

---

## 11. Collection web: post Actual Collection

**Requirement (raised 2026-09-24).** An interface in `mdmpi_collection_web` where the
office enters Actual Collection. Pairs with item 9: this becomes the only source of the
figure.

**Proposed shape.**
- **Backend (`MDMPI.App`, `/api4` — the production-testing backend that already serves
  every Collection call).** Table `collection_actual_collection`: id, collector code,
  collection date, amount, reference (OR / deposit slip no.), remarks, posted by, created
  and updated at. Migration SQL beside
  `migration_20260922_add_collection_invoice_ponumber.sql`. Endpoints on
  `CollectionController`: `GET /api4/Collection/actual-collections?month=yyyy-MM&collector=`,
  `POST`, `PUT /{id}`, `DELETE /{id}`. `CollectionWorkspaceDto` gains the signed-in
  collector's records for the month, so mobile needs no new call.
- **Web.** `views/ActualCollectionView.vue` + route + nav entry; `api/collectionApi.js`
  methods. A month picker and collector filter; a table with a running total and % of each
  collector's target (targets already exist: `CollectionTargetModel`); add / edit / delete
  in a dialog; amounts through `utils/money.js`.
- **Mobile.** `CollectionWorkspaceParser` reads the records; a local table (DAO + test,
  per the data-layer rule); item 9 totals them.

**Open questions.** One entry per deposit slip or one lump sum per collector per month?
Who may post and edit (all office staff or one role)? Can an entry be backdated into a
closed month?

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

**Open question.** Are `CNTMNN` and `initial` the same code for the same person? The
merge above assumes so.

---

## 15. Settings: suggested features for Collection

Collection's Settings currently has **Upload Data** and the developer tools
(`settings.dart`). Candidates, most useful first. None are built; pick which to schedule.

1. **My Head** — item 13.
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
