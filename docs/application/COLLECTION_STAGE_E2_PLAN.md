# Collection — Stage E2 Plan (deposits and monthly-target reporting on the web)

**Date:** 2026-09-22 · **Status:** E2a IMPLEMENTED 2026-09-22 — backend report repository + 3 endpoints, 183 tests (from 163); web `ReportsView.vue` + `reportsApi.js` built. §9 decisions taken as recommended: read-only, payments, derived names, all-time undeposited. E2b not started. Still to do: §7 device and SQL cross-checks against the testing database.
Follows Stage E1 (`COLLECTION_STAGE_E_PLAN.md`, backend `8aea616`, 163 tests).
Web app: `mdmpi_collection_web`. Backend: MDMPI.App `master`.

---

## 1. Why

Since Stage C every deposit, payment and monthly target a collector records on the phone is
persisted on the server (`a_tblcollectiondeposit`, `a_tblcollectionpayment`,
`a_tblcollectiontarget`). Today the **only** reader of that data is the collector's own phone:
`GET /workspace` returns one collector's deposits and targets, and the Monthly Summary screen
(`total_collected_controller.dart`) computes *Actual Collection vs Target* locally.

The office has no view across collectors. The questions it asks each month cannot be answered
without running SQL by hand:

- How much did each collector **deposit** this month, against their **target**?
- How much has been **collected but not yet deposited** (cash and cheques in hand)?
- Which deposits went in, when, to which bank, covering which cheques?

Stage E2 adds a **Reports** screen to the admin web app that answers these from the same
tables the phone writes to. It is read-only unless decision §9.1 says otherwise.

## 2. Definitions — the numbers must agree with the phone

The web must never show a collector a different month than their phone does. Each figure
below names the phone computation it mirrors.

| Figure | Definition | Phone equivalent |
|---|---|---|
| **Actual Collection** (collector, month) | `Σ deposit.totalamount` where `depositdate` starts with `yyyy-MM` | `_collectDeposits()` — deposits whose parsed date falls in the selected month |
| **Target** (collector, month) | `target.targetamount` for `(collectorcode, yearmonth)`; 0 / "not set" when absent | `reloadTarget()` → `getTarget(yyyy-MM)` |
| **Achievement** | `Actual / Target`, null when Target is 0 | progress bar on Monthly Summary |
| **Collected** (collector, month) | `Σ payment.totalamount` where `paymentdate` starts with `yyyy-MM` | `_collectMonth()` — engagements with amount > 0 in the month (post Stage B every such engagement has a payment, so the sums match) |
| **Undeposited** (collector, all time) | `Σ payment.totalamount` where `depositid IS NULL` | not shown on the phone; this is the office's "cash in hand" number |
| **Deposit linked amount** | `Σ payment.totalamount` for payments with that `depositid` | — |

Rules:

- Dates in these tables are `yyyy-MM-dd` **strings** (see `GetWorkspaceAsync`, which already
  relies on ordinal compare). Month filtering is `StartsWith(yearMonth)`; no parsing.
- A deposit or payment with a NULL / unparseable date is excluded from month figures (the
  phone drops it too) but is counted in a per-collector `UndatedCount` so it is not silently
  lost.
- Month is a Manila calendar month. The default month on the web is "today in Asia/Manila",
  computed client-side; the API takes `yearMonth` explicitly and never infers it.
- **Collector identity.** `collectorcode` is the mobile user's `username` (falls back to user
  id). No collector registry exists. Display names come from the latest
  `a_tblcollectioninvoice.collectorname` per `assignedto`, falling back to the code. See §9.3.

## 3. Backend (MDMPI.App)

No migration for E2a. E2b (§3.5) needs one and is decision-gated.

### 3.1 Repository

New `ICollectionReportRepository` / `CollectionReportRepository` on
`PostgreSqlAppDbContext`, registered scoped in `Program.cs`. Kept separate from
`CollectionInvoiceRepository` (1 258 lines, write-heavy) — reports are read-only and
`AsNoTracking()` throughout.

```
Task<MonthlyCollectionReportDto>            GetMonthlyReportAsync(string yearMonth);
Task<PagedResultDto<CollectionDepositReportDto>> SearchDepositsAsync(CollectionDepositQuery q);
Task<CollectionDepositDetailDto?>           GetDepositAsync(long depositId);
Task<IReadOnlyDictionary<string,string>>    GetCollectorNamesAsync();   // code → name
```

Query shape for the monthly report (three small aggregate queries + one name lookup, then
join in memory — the tables are thousands of rows, not millions):

1. deposits: `GROUP BY collectorcode` over `depositdate LIKE 'yyyy-MM%'` → sum, count.
2. payments: `GROUP BY collectorcode` → month sum (`paymentdate LIKE`), and undeposited sum
   (`depositid IS NULL`, all time).
3. targets: `WHERE yearmonth = @m`.
4. names: `a_tblcollectioninvoice` where `assignedto IS NOT NULL`, latest `assignedat` per
   `assignedto`.

One row per collector that appears in **any** of 1–3 (a target with no deposits must show as
0 % achieved, not vanish). Totals row is the sum of the rows.

### 3.2 DTOs (`Core/Collection/DTOs/CollectionReportDtos.cs`, PascalCase pinned with `JsonPropertyName`, same as the workspace contract)

```
MonthlyCollectionReportDto  { YearMonth, Rows: List<CollectorMonthRowDto>, Totals: CollectorMonthRowDto }
CollectorMonthRowDto        { CollectorCode, CollectorName, TargetAmount, Actual, Collected,
                              Undeposited, DepositCount, UndatedCount, Achievement (decimal?) }
CollectionDepositReportDto  { DepositId, Date, CollectorCode, CollectorName, ClientCode, ClientName,
                              BankName, ReferenceNo, Amount, LinkedCount, LinkedAmount, Remarks }
CollectionDepositDetailDto  : CollectionDepositReportDto + Payments: List<LinkedPaymentDto>
LinkedPaymentDto            { PaymentId, Date, ClientCode, ClientName, Method, BankName, CheckNo,
                              CheckDate, Amount, DocumentIds: List<string> }
CollectionDepositQuery      { YearMonth?, Collector?, Search?, Page = 1, PageSize = 25 }
```

`Search` matches `referenceno`, `bankname`, client code or client name, case-insensitive.
`LinkedAmount ≠ Amount` is surfaced, not hidden — it is exactly what reconciliation looks for.

### 3.3 Service

Three pass-through methods on `ICollectionService` under a `// Stage E2 — reporting` banner,
mirroring E1. `yearMonth` validation (`^\d{4}-(0[1-9]|1[0-2])$`) lives in the service so both
the controller and tests hit one rule.

### 3.4 Controller (`CollectionController`, same file, E2 banner)

| Method | Route | Notes |
|---|---|---|
| GET | `/api4/Collection/reports/monthly?yearMonth=2026-09` | 400 on bad month |
| GET | `/api4/Collection/deposits?yearMonth=&collector=&search=&page=&pageSize=` | paged |
| GET | `/api4/Collection/deposits/{id}` | 404 when missing |

All additive; the mobile app is unaffected.

### 3.5 E2b — office edits targets (only if §9.1 says yes)

- Migration `migration_2026MMDD_collection_stage_e2_target_audit.sql`: add
  `updatedby varchar(150)` to `a_tblcollectiontarget`, plus `a_tblcollectiontarget_history`
  and the same trigger pattern as E1's client history. Re-runnable.
- `PUT /api4/Collection/targets/{collector}/{yearMonth}` with `{ TargetAmount, UpdatedBy }`,
  upsert, amount ≥ 0.
- Conflict rule with the phone: **last write wins**, same as today between two phones. The
  phone picks the web value up on its next Download Bucket; a `SET_TARGET` still queued on a
  phone will overwrite it on upload. The screen says so next to the field.

### 3.6 Tests (`MDMPI.App.Tests/Collection/CollectionReportRepositoryTests.cs`, `Controllers/CollectionReportEndpointTests.cs`)

Seed through the **real write paths** like E1 did (`ImportInvoicesAsync`, then
`ApplyUploadAsync` with `SAVE_ACTIVITY`, `DEPOSIT`, `SET_TARGET` changes) so the report is
tested against rows shaped exactly as production writes them. SQLite in-memory as before;
`StartsWith` translates to `LIKE` there and on Npgsql.

Cases:

1. Month rollup sums only that month's deposits; a deposit dated the previous month is
   excluded and an undated one increments `UndatedCount`.
2. A collector with a target and no deposits appears with `Actual = 0`, `Achievement = 0`.
3. A collector with deposits and no target appears with `TargetAmount = 0`, `Achievement = null`.
4. `Undeposited` drops to zero after a `DEPOSIT` change links the payments; `LinkedAmount`
   equals the payments' sum.
5. `Collected` equals the sum of that month's payments, including an `ADVANCED_PAYMENT`.
6. Collector name resolves from the latest assignment; unknown code falls back to the code.
7. Deposits search by reference no. and client name, paged; detail returns linked payments
   with their allocation document ids; unknown id → 404.
8. Endpoint returns 400 for `yearMonth=2026-13` and for a missing value.

Gate: `dotnet test` count rises from 163.

## 4. Web (`mdmpi_collection_web`)

- `src/api/reportsApi.js` — same axios/`pick()` pattern as `clientsApi.js`:
  `getMonthlyReport(yearMonth)`, `searchDeposits(params)`, `getDeposit(id)`
  (+ `updateTarget()` for E2b).
- `src/views/ReportsView.vue`, route `/reports` (`requiresAuth`), third tab **Reports**
  (`mdi-chart-box-outline`) in `App.vue`.
- `src/utils/month.js` — Manila "current month" and the last-12-months option list (the
  phone's selector range).
- `src/utils/money.js` — `₱` formatting with two decimals, shared by Clients and Reports.

### Screen

1. **Month selector** (last 12 months, default current Manila month) and a **Refresh** button.
2. **Collector summary** `v-data-table` — Collector · Target · Actual Collection · Achievement
   (linear progress + %) · Collected this month · Undeposited · Deposits (count) — sorted by
   Actual descending, totals row pinned at the bottom. Undated count shows as a warning chip
   on the row when non-zero. Clicking a row filters the deposits table below to that collector.
3. **Deposits** `v-data-table-server` — Date · Collector · Account · Bank · Reference · Amount ·
   Linked (count and amount, red when it differs from Amount) · Remarks, with a search box.
   Row expand loads `GET /deposits/{id}` and lists the linked payments and their invoices.
4. **Export to Excel** — the `xlsx` package is already a dependency; one click writes the
   summary and the filtered deposits as two sheets named for the month.
5. E2b only: an inline **Target** editor per row, attributed with the signed-in email, with
   the last-write-wins note from §3.5.

## 5. Mobile

No change for E2 itself. Monthly Summary already shows the same figures per collector from its
SQLite copy. If E2b ships, the office's target appears after the next Download Bucket.

### 5.1 Mobile follow-ups shipped alongside E2a (2026-09-22, `mdmpi_mobile_app`)

Not part of the E2 scope but landed on the same day on `collection/dev/dev-collection`, so
recorded here rather than in a stage of their own:

- **Reconciliation fold.** A Reconciliation entry that a later outcome on the same invoice
  finished is told once, on that outcome ("Reconciliation Collected"), with the reconciliation
  date in the detail sheet. Fold logic is a pure helper
  (`lib/features/collection/helpers/reconciliation_fold.dart`) called from the controller's
  history getters; widgets render what they are given.
- **Calendar visit card.** A day groups engagements by account (`helpers/day_entry_grouping.dart`);
  an account with several invoices on one day reads as one expandable visit card.
- **Activity type sheet.** Redesigned rows with per-status icon and colour; the four engagement
  forms now open through named routes (`BRoutes.collection*Form`).
- **Engagement invoice picker.** One shared checklist widget for the Deposit and Reconciliation
  forms, with an explicit empty state.
- **Shared status badge.** `ActivityStatusBadge` is the single badge used by the history card,
  its detail sheet and the visit card.
- Tests: `test/features/collection/{reconciled_collection,activity_history_card,
  activity_type_modal,engagement_invoice_picker,calendar_screen}_test.dart`.

## 6. Order of work

1. **E2a backend**: DTOs → report repository → service + validation → controller → tests →
   `dotnet test`.
2. **E2a web**: month/money utils → API module → view → route/tab → `npm run build`.
3. **E2a verify** (§7), commit + push each repo.
4. **E2b** (if approved): migration → PUT endpoint + tests → inline editor → verify → commit.

Backend can deploy before the web; every endpoint is additive.

## 7. Verification

- Gates: `dotnet test` (count rises from 163), `npm run build`, mobile suites unchanged.
- Cross-check against the phone: pick one collector, open Monthly Summary for the current
  month on their device, compare Target and Actual Collection with the web row. They must be
  identical to the centavo.
- Cross-check against SQL on the testing Postgres:
  `SELECT collectorcode, SUM(totalamount) FROM a_tblcollectiondeposit WHERE depositdate LIKE '2026-09%' GROUP BY 1;`
  and
  `SELECT collectorcode, SUM(totalamount) FROM a_tblcollectionpayment WHERE depositid IS NULL GROUP BY 1;`
- Record a deposit on a phone, Upload, refresh the web: the deposit row appears, that
  collector's Undeposited drops by the linked amount, Actual rises by the deposit amount.
- Export: the Excel file opens with two sheets and totals matching the screen.

## 8. Not in E2

- Server-side verification of Firebase ID tokens on `/api4/Collection/*`. Still open from E1
  §8 and **more pressing now**: reports expose every collector's cash position to anyone who
  can reach the API. Recommend it lands before the web app leaves the office network.
- A collector registry table (names, active flag, area). E2 derives names from invoice
  assignments; a registry is the right fix if that proves unreliable (§9.3).
- Editing or deleting deposits and payments from the web. Reconciliation corrections stay a
  process question (ties into E3).
- Per-client aging / receivables reports (open balance by client is already on the Clients
  screen as `OpenBalance`).
- Year-to-date or multi-month trend charts. The month table is the unit; trends can be a
  later pass once the office has used the screen.

## 9. Decisions to confirm before implementation

1. **Does the office set targets, or only the collector?** Today only the phone sets them
   (`SET_TARGET`). If the office should, E2b ships with its migration and last-write-wins
   rule. *Recommendation:* ship E2a read-only first; decide E2b after a month of use.
2. **"Collected this month" — payments or engagements?** §2 uses payments (one cheque = one
   row, matches the office's view of cash). The phone sums engagements, which agree since
   Stage B but could drift if a future op writes one without the other. *Recommendation:*
   payments, and add a test that pins the two sums equal after an upload.
3. **Collector display names.** Derive from latest invoice assignment (no schema change) vs
   add `a_tblcollectioncollector`. *Recommendation:* derive for E2; revisit if the office
   sees codes instead of names for anyone.
4. **Undeposited — all time or month?** All time is the operational number (what is
   physically not yet banked). *Recommendation:* all time, labelled as such on the screen.
