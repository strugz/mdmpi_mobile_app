# Collection Normalization — Stage C Sub-Plan

**Date:** 2026-09-15 · **Status:** C1–C3 done; C4 automated gates passed 2026-09-15 — on-device sign-off pending (see `COLLECTION_C4_VERIFICATION_CHECKLIST.md`)
**Parent:** `COLLECTION_DATA_MODEL_NORMALIZATION.md` §6 Stage C
**Scope:** backend `MDMPI.App` + mobile `mdmpi_mobile_app`. First stage that touches the phone.

---

## 1. Goal

Close the gap between what the mobile Collection design does and what is persisted and
uploaded. Today only three actions reach SQLite and the upload queue
(`claimItemsByIds`, `saveActivity`, `saveBatchActivity`). These six exist **only in
memory** — lost on app restart, never uploaded:

| Controller action | Concept | Today |
|---|---|---|
| `saveGlobalActivity(type:'Deposit')` | Deposit → *Actual Collection* | in-memory `globalActivities` |
| `saveGlobalActivity(type:'CWT Pick-up')` | CWT Pick-up | in-memory |
| `markInvoicesForReconciliation` + `saveGlobalActivity('Reconciliation')` | Reconciliation | status flipped in memory only |
| `saveAdvancedPayment` | Advanced Payment (no invoice yet) | in-memory `unassignedAdvancedPayments` |
| `assignInvoiceToPayment` | Assign advance → creates invoice | in-memory |
| `unclaimAccount` / `unclaimWithReason` | Clear / **Defer** (+ reason) | in-memory `clientHistory`; **local DB still shows the invoice claimed** |
| `TotalCollectedController.targetAmount` | Monthly Target | in-memory |

After Stage C every one of these is **saved to SQLite**, **queued for Upload All**, applied
on the server into the normalized tables (Stage A/B), and **re-downloaded** with the bucket.

---

## 2. Design decisions (recommended defaults — proceed unless overruled)

1. **One aggregate download.** Add `GET /api4/Collection/workspace?collector=` returning
   `{ Items, Advances, Deposits, Activities, AccountHistory, Target }` in one call, so the
   field "Download Bucket" stays a single request. `GET /bucket` is kept unchanged for
   compatibility.
2. **Advances are account-level and shared** — any collector who downloads sees the
   unallocated advances of the accounts in the pool (like the bucket itself), not only
   their own. Matches "Advanced Payment waits under Home until assigned to an invoice".
3. **Advance identity across days.** The phone creates an advance offline with a local id
   (`AP-<millis>`). It is uploaded as `ADVANCED_PAYMENT` with that id as **`ExternalRef`**;
   the server stores it on `payment.externalref`. A later `ASSIGN_ADVANCE` (possibly days
   later, or even in the *same* upload) references the advance by `ExternalRef`, so no
   server id round-trip is needed. Requires one small additive column (§4 C1).
4. **Deposit ↔ payments link by selected invoices.** The Record Deposit form already lets
   the collector pick "the invoices being deposited". The upload sends one `DEPOSIT` with
   `DocumentIds[]`; the server creates the deposit and sets `payment.depositid` on the
   payments allocated to those invoices for that client (matching `CheckNo` when given).
   A deposit with no invoices is still allowed (amount only).
5. **Explicit operations** instead of overloading `OFFICE_ACTIVITY`:
   `DEPOSIT`, `CWT_PICKUP`, `RECONCILIATION`, `ADVANCED_PAYMENT`, `ASSIGN_ADVANCE`,
   `SET_TARGET`. `OFFICE_ACTIVITY` stays as a compatibility alias keyed on `ActivityType`.
6. **Account-scoped ops carry `ClientCode`, not `ItemId`.** `ApplyUploadAsync` gains an
   account-scoped path; invoice-scoped ops keep the existing `ItemId` path.
7. **Mobile SQLite stays a flat worklist cache** — new tables mirror the phone's own
   concepts (activities, advances, account history, target), not the server's normal form.
   Created idempotently via `ensureCollectionTables`, DB **v20 → v21**, kept out of the
   destructive rebuild (same protection as today).
8. SMS on deposit: **out of scope** (optional later).

---

## 3. Upload contract additions (`CollectionChangeDto`)

New optional fields (PascalCase-pinned like the rest):
`ClientCode`, `ExternalRef`, `DocumentIds: string[]`, `YearMonth`, `TargetAmount`,
`AmountDue`, `DueDate`. `ItemId` becomes optional (required only for invoice-scoped ops).

| Operation | Scope | Server effect |
|---|---|---|
| `DEPOSIT` | account | insert `deposit`; set `payment.depositid` for payments allocated to `DocumentIds` of that client (filter by `CheckNo` if present) |
| `CWT_PICKUP` | account | insert `activity(type='CWT Pick-up')` |
| `RECONCILIATION` | account | insert `activity(type='Reconciliation')`; set `invoice.status='Reconciliation'` for `DocumentIds` |
| `ADVANCED_PAYMENT` | account | insert `payment` (no allocation) with `externalref = ExternalRef` |
| `ASSIGN_ADVANCE` | account | find payment by `ExternalRef` (this upload's ctx first, then DB); create invoice `ItemId` if missing (`source='MANUAL'`, `originalamount = AmountDue`, `DueDate`); insert allocation `min(unallocated, AmountDue)`; recompute cache |
| `SET_TARGET` | collector | upsert `target(collectorcode, YearMonth, TargetAmount)` |
| `DEFER` / `CLEAR` | invoice | *(exists since Stage B)* release + one account-level engagement per account for Defer |

Rejection reasons are explicit (`"Client not found"`, `"Advance <ref> not found"`,
`"Advance already fully allocated"`), so the outbox can show them.

---

## 4. Phases

### C1 — Backend: contract + account-scoped ops + workspace read  ✅ DONE 2026-09-15 (`migration_20260915_collection_normalization_stage_c.sql`; 151 tests)
- **DDL** `migration_20260915_collection_normalization_stage_c.sql` (additive):
  `payment.externalref varchar(100)` + index; nothing else.
- **DTOs:** extend `CollectionChangeDto` (§3); new `CollectionWorkspaceDto`
  (`Items`, `Advances[]`, `Deposits[]`, `Activities[]`, `AccountHistory[]`, `Target`) and
  its child DTOs, all `[JsonPropertyName]`-pinned.
- **Repository:** account-scoped branch in `ApplyUploadAsync` for the six ops (§3);
  `GetWorkspaceAsync(collector)` = existing bucket + unallocated advances
  (`payment.totalamount − Σ allocations > 0`) + deposits/activities for the collector's
  current month (+ previous, for the 12-month selector to be fed lazily later) +
  account-level engagements for the pool's accounts + the collector's current-month target.
- **Controller:** `GET /api4/Collection/workspace?collector=`.
- **Tests:** deposit links the right payments; advance → assign creates invoice +
  allocation and reports the remainder; assign in the *same* upload as the advance works;
  reconciliation flips statuses; target upserts; workspace returns advances/history.
- **Verify:** `dotnet test`; apply C1 SQL; deploy.

### C2 — Mobile: persist the six concepts + queue everything  ✅ DONE 2026-09-15 (SQLite v21, 4 DAOs, repository methods, six actions DAO-backed + queued, target persisted per month; analyze clean, 7 tests)
- **SQLite** (`ensureCollectionTables`, v21): `a_tblCollectionActivity` (type, clientId,
  clientName, date, amount, bankName, checkNumber, remarks, documentIds CSV, collector),
  `a_tblCollectionAdvance` (externalRef PK, clientId, amount, date, remarks, collector,
  assignedDocumentId), `a_tblCollectionAccountHistory` (clientId, date, reason, remarks,
  collector), `a_tblCollectionTarget` (yearMonth PK, amount). DAOs under
  `lib/data/local/dao/collection/`.
- **Repository** (`CollectionRepository`): `releaseAccount(clientId, {reason, remarks})`
  → DAO `assignedAt=''` per invoice **and** queue `DEFER`/`CLEAR` per invoice (server
  dedupes the reason per account); `saveOfficeActivity(...)` → DAO + queue
  `DEPOSIT`/`CWT_PICKUP`/`RECONCILIATION` (Reconciliation also updates invoice status in
  DAO); `saveAdvance(...)` → DAO + queue `ADVANCED_PAYMENT`; `assignAdvance(...)` → DAO
  (new invoice + advance.assignedDocumentId) + queue `ASSIGN_ADVANCE`; `setTarget(...)` →
  DAO + queue `SET_TARGET`.
- **Controller:** the six actions call the repository instead of mutating lists only;
  `onInit` loads `globalActivities`, `unassignedAdvancedPayments`, `clientHistory` and
  the target **from the DAOs** (survives restart). `TotalCollectedController` reads/writes
  the target through the repository.
- **Outbox labels** for the new ops in `CollectionUploadOutboxScreen`.
- **Verify:** `flutter analyze` + `flutter test` (DAO round-trips); on device: record a
  deposit / CWT / advance / defer offline → kill app → everything still there and the
  pending count includes them.

### C3 — Mobile: download the workspace  ✅ DONE 2026-09-15 (one /workspace call replaces items + account-level tables; bucket-only fallback; background sync now gated on pending changes; deposit.clientcode via `migration_20260915_collection_normalization_stage_c3.sql`; analyze clean, 10 tests)
- `CollectionRepository.getAll/refreshFromApi` call `/workspace`; items cached as today;
  advances, deposits/activities, account history and target **replace** the local tables
  (server wins on download — still gated by the existing "upload first" check so no
  un-uploaded work is overwritten).
- Home/Calendar/summaries read the same DAO-backed lists, so *Actual Collection*, *Total
  Collected*, *Advanced Payment* tile and account history now reflect server state after a
  download on any device.
- **Verify:** record on device A → Upload All → download on device B shows the advance,
  the deposit in Actual Collection, and the defer reason in account history.

### C4 — End-to-end verification
Full monthly loop incl. the six new concepts; re-download idempotency; Postgres checks:
`SELECT * FROM a_tblcollectionpayment WHERE depositid IS NOT NULL`,
unallocated advances query, `a_tblcollectiontarget`. Gates: `dotnet test`,
`flutter analyze` + `flutter test`, `npm run build` (web unaffected but re-run).

**Automated gates — ✅ 2026-09-15:** `dotnet test` 151/151 · `flutter analyze` 0 errors (all
warnings pre-existing) · `flutter test` 250 passed (5 pre-existing failures outside Collection) ·
`npm run build` OK. **On-device loop:** step-by-step script with the Postgres checks per step
lives in `COLLECTION_C4_VERIFICATION_CHECKLIST.md`; Stage C closes when its sign-off table is
ticked.

## 5. Dependency order
C1 → C2 → C3 → C4. C1 can be deployed alone (nothing calls the new ops yet). C2 can be
built against C1 immediately; C3 needs C1 deployed to test end-to-end.

## 6. Key files
- Backend: `migration_20260915_collection_normalization_stage_c.sql`,
  `Core/Collection/DTOs/{UploadCollectionDto.cs,CollectionWorkspaceDto.cs}`,
  `Data/Collection/Repositories/CollectionInvoiceRepository.cs`,
  `Api/Controllers/Collection/CollectionController.cs`, tests.
- Mobile: `lib/data/local/db_schema.dart`, `database_helper.dart` (v21),
  `lib/data/local/dao/collection/*` (4 new DAOs),
  `lib/data/repositories/collection/collection_repository.dart`,
  `lib/features/collection/presentation/controllers/{collection_activity_controller.dart,total_collected_controller.dart}`,
  `.../pages/upload/collection_upload_outbox_screen.dart`.
