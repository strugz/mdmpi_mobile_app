# Collection — Stage C4 End-to-End Verification Checklist

**Date:** 2026-09-15 · **Scope:** the full monthly Collection loop after Stages A–C, including the six concepts that used to live only in memory (Deposit, CWT Pick-up, Reconciliation, Advanced Payment, Assign Advance, Defer/account history, Target).
Companion to `COLLECTION_NORMALIZATION_STAGE_C_PLAN.md` §4 C4.

## 1. Automated gates (run 2026-09-15)

| Gate | Result | Notes |
|---|---|---|
| `dotnet test` (MDMPI.App) | ✅ 151 / 151 | SQLite in-memory repository + controller tests |
| `flutter analyze` | ✅ 0 errors | 26 warnings, all pre-existing (Logistics / app.dart / 3 dead-null-aware lines in `total_collected_controller.dart` already in HEAD); 110 infos (deprecations, `tool/` prints) |
| `flutter test` | ✅ 250 passed | 5 failures are pre-existing and outside Collection: `ai_agent_test.dart` and `pull_out_model_from_json_test.dart` have no `main`, `widget_test.dart` is the Flutter template counter test, `request_dao_insert_test.dart` late-init of `db` in setUpAll. Collection suites (DAO, extras DAO, workspace parser) all pass. |
| `npm run build` (mdmpi_collection_web) | ✅ built | Chunk-size warning only (Vuetify + xlsx) |

## 2. Deployment prerequisites (manual, ordered)

1. Apply Postgres scripts in this order, each once:
   `migration_20260915_add_collection_client.sql` → `..._stage_a.sql` → `..._stage_b.sql` → `..._stage_c.sql` (C1) → `..._stage_c3.sql` → `..._stage_d.sql` (drops the invoice snapshot columns; backs them up first).
2. Deploy the MDMPI.App backend build that includes `GET /api4/Collection/workspace`.
3. Install the mobile build (local DB v21 upgrades itself; nothing to wipe).
4. Contact Directory: at least one contact with department **Collection** and a mobile number (SMS recipient).
5. Web `.env` has the Firebase **Web** app keys and `VITE_API4_BASE_URL`.

Sanity query after step 1:

```sql
SELECT column_name FROM information_schema.columns
 WHERE table_name = 'a_tblcollectiondeposit' AND column_name = 'clientcode';   -- 1 row
SELECT column_name FROM information_schema.columns
 WHERE table_name = 'a_tblcollectionpayment' AND column_name = 'externalref';  -- 1 row
```

## 3. On-device loop

Use two devices (A = collector, B = same collector account or supervisor) or one device with a
reinstall between steps 5 and 6. Replace `EMP1` with the collector code (username, or user id
when username is empty).

### Step 1 — Import the month (web)
- Log in to mdmpi_collection_web, import the SAP AR file.
- Expect: summary shows Added = number of new `IN` rows, Skipped = subtotals / RC / CN / JE / duplicates.

```sql
SELECT count(*) FROM a_tblcollectioninvoice WHERE source = 'SAP';   -- web import; manual adds use 'MANUAL'
SELECT count(*) FROM a_tblcollectionclient;
-- Re-import the same file: both counts unchanged, web shows Added = 0.
```

### Step 2 — Download Bucket (device A, online)
- Home → **Download Bucket**. Expect item count = unclaimed pool + own claims; no error.
- With **any** pending change present the button must instead show the “Upload first” dialog.

### Step 3 — Claim and collect (device A, airplane mode ON)
1. Claim 2–3 invoices of one account.
2. Record a **partial** payment on one invoice (check no. `CHK-1`).
3. Record a **batch** payment on two invoices (one check).
4. **Defer** a different account (reason “Follow Up”, remark “Call Monday”).
5. Record **Deposit** for the collected account (bank BDO, ref `DEP-1`).
6. Record **CWT Pick-up** and **Reconciliation** for an account.
7. Record **Advanced Payment** for an account (amount 5,000, remark “October”).
8. **Assign** part of that advance (2,000) to one of its invoices.
9. Set the monthly **Target** (150,000).

Expect on device A: Upload badge shows the pending count; Actual Collection lists the deposit;
Advanced Payment tile shows 3,000 remaining; account history shows the defer reason; SMS is
queued/sent to the Collection contact (Android).

### Step 4 — Persistence (device A, still offline)
- Force-close the app, reopen. Every item from Step 3 is still there, pending count unchanged.
- Open Upload outbox: each row is labelled by operation (Claim, Save, Batch, Defer, Deposit,
  CWT Pick-up, Reconciliation, Advanced Payment, Assign Advance, Set Target).

### Step 5 — Upload All (device A, online)
- Home → **Upload (N)**. Expect “All uploaded”, badge cleared, outbox empty.

```sql
-- One payment per Save, one per Batch (not one per invoice), one for the advance
SELECT paymentid, clientcode, totalamount, externalref, depositid, collectorcode
  FROM a_tblcollectionpayment WHERE collectorcode = 'EMP1' ORDER BY paymentid;

-- Batch payment has N allocations; advance has exactly one (2,000)
SELECT p.paymentid, p.externalref, count(a.*) AS allocations, coalesce(sum(a.amount),0) AS allocated
  FROM a_tblcollectionpayment p
  LEFT JOIN a_tblcollectionpaymentallocation a ON a.paymentid = p.paymentid
 WHERE p.collectorcode = 'EMP1' GROUP BY p.paymentid, p.externalref;

-- Deposit linked to its payments and stamped with the account
SELECT d.depositid, d.clientcode, d.bankname, d.referenceno, d.totalamount,
       (SELECT count(*) FROM a_tblcollectionpayment WHERE depositid = d.depositid) AS payments
  FROM a_tblcollectiondeposit d WHERE d.collectorcode = 'EMP1';
SELECT * FROM a_tblcollectionpayment WHERE depositid IS NOT NULL;

-- Unallocated advances (should show 3,000 for the AP-… ref)
SELECT p.paymentid, p.externalref, p.clientcode,
       p.totalamount - coalesce((SELECT sum(amount) FROM a_tblcollectionpaymentallocation WHERE paymentid = p.paymentid),0) AS unallocated
  FROM a_tblcollectionpayment p
 WHERE p.totalamount > coalesce((SELECT sum(amount) FROM a_tblcollectionpaymentallocation WHERE paymentid = p.paymentid),0);

-- Activities, account-level defer, target
SELECT activitytype, clientcode, remarks FROM a_tblcollectionactivity WHERE collectorcode = 'EMP1';
SELECT clientcode, status, remarks FROM a_tblcollectionengagement WHERE documentid IS NULL;
SELECT * FROM a_tblcollectiontarget WHERE collectorcode = 'EMP1';

-- Invoice caches recomputed from allocations
SELECT documentid, originalamount, tobecollected, totalcollected, status, collectorcode
  FROM a_tblcollectioninvoice WHERE collectorcode = 'EMP1';
```

### Step 6 — Download on device B
- Log in as the same collector on device B (or reinstall on A), **Download Bucket**.
- Expect: the claimed invoices with their balances, the deposit in Actual Collection with the
  account name (not “N/A”), Advanced Payment tile = 3,000, account history shows “Follow Up /
  Call Monday”, Target = 150,000 for the month, CWT/Reconciliation rows in the activity list.
- Press **Download Bucket** again: nothing duplicates (server rows replace local rows).

### Step 7 — Idempotency / rejection
- Re-send the same Advanced Payment ref from device A (queue → upload): payment count unchanged.
- Have device B claim an invoice that A already claimed offline, then A uploads: A's Claim row
  is **Rejected** and stays in the outbox with the reason; all other rows are accepted.

### Step 8 — Release
- On A, **Clear** a deferred account → Upload → the invoices reappear in the shared pool for B.

## 4. Sign-off

| Step | Device A | Device B | Postgres | Done |
|---|---|---|---|---|
| 1 Import | | | ☐ | ☐ |
| 2 Download gate | ☐ | | | ☐ |
| 3 Offline actions | ☐ | | | ☐ |
| 4 Restart persistence | ☐ | | | ☐ |
| 5 Upload All | ☐ | | ☐ | ☐ |
| 6 Download elsewhere | | ☐ | | ☐ |
| 7 Idempotency / rejection | ☐ | ☐ | ☐ | ☐ |
| 8 Release | ☐ | ☐ | | ☐ |

When all rows are ticked, Stage C is closed and **Stage D** (drop the invoice snapshot / cache
columns) can be planned.
