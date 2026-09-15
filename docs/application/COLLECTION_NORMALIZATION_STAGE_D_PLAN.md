# Collection Normalization — Stage D Plan (drop redundancy)

**Date:** 2026-09-15 · **Status:** PROPOSED — awaiting go-ahead
Parent design: `COLLECTION_DATA_MODEL_NORMALIZATION.md` §6 row D. Stages A–C are live
(mobile PR #19, MDMPI.App `476b81e`).

## 1. Goal

Stages A–C made the normalized tables the **source of truth** but left the old columns on
`a_tblcollectioninvoice` and `a_tblcollectionengagement` in place so nothing broke. Stage D
removes what is now duplicated, so there is exactly one place for each fact:

| Fact | Lives in (after D) |
|---|---|
| Client name / address / contact / email | `a_tblcollectionclient` only |
| Bank, cheque no., cheque date | `a_tblcollectionpayment` only |
| Balance, total collected, Collected status | computed from `a_tblcollectionpaymentallocation`; invoice keeps them as **server-maintained caches** |

**The mobile app, the web import and the JSON contract do not change.** The server keeps
emitting the same `CollectionItemDto` / `CollectionHistoryDto`; only where it reads from moves.

## 2. What is dropped, what is kept

### `a_tblcollectioninvoice`

| Column | Decision | Reason |
|---|---|---|
| `clientid`, `clientname`, `clientaddress`, `clientcontact`, `clientemail` | **DROP** | Duplicates `a_tblcollectionclient`; SAP never fills address/contact/email. `clientcode` becomes a real FK to the client table. |
| `bankname` | **DROP** | Bank belongs to a payment, not a receivable. Unused since Stage B. |
| `clientcode` | keep, add **FK** → `a_tblcollectionclient(clientcode)` | The only client link. |
| `bpcode` | **keep** | SAP *BP Code* is an invoice-level attribute (it can differ from Customer Code) and Filter by Area matches on it. Not a duplicate. |
| `collectorname` | **keep** | Workflow state next to `assignedto` (who holds the invoice). Postgres has no user table to derive it from. |
| `tobecollected`, `totalcollected`, `status`, `lastoutcome` | **keep as caches** | Decision 1 in the design doc (recommended). Recomputed on every upload; Stage D adds a SQL recompute function so they can be rebuilt from allocations at any time. |
| `documentreferences` (CSV) | keep | For SAP it is just the Doc. No. Normalizing gains nothing today. |
| `collectioninvoiceid` identity PK | **keep** (do NOT switch PK to `documentid`) | Every child table already references `documentid` via the UNIQUE constraint. Changing the PK is churn with no behavioural gain and a real risk on a live table. Revised from the original §6 wording. |

### `a_tblcollectionengagement`

| Column | Decision | Reason |
|---|---|---|
| `bankname`, `checkno`, `checkdate` | **DROP** | Stage B moved these onto the payment and every paying engagement now has `paymentid`. `ToHistoryDto` already prefers the payment. |
| everything else | keep | |

## 3. Preconditions (verify before running the migration)

All three must return **0 rows**. If any does not, fix data first (queries in §7).

```sql
-- P1: every invoice's client exists in the registry (Stage B backfilled these)
SELECT i.documentid, i.clientcode FROM a_tblcollectioninvoice i
  LEFT JOIN a_tblcollectionclient c ON upper(c.clientcode) = upper(i.clientcode)
 WHERE c.clientcode IS NULL;

-- P2: no paying engagement without a payment (bank details would be lost)
SELECT engagementid FROM a_tblcollectionengagement
 WHERE amountcollected > 0 AND paymentid IS NULL;

-- P3: no engagement carrying bank details that its payment lacks
SELECT e.engagementid FROM a_tblcollectionengagement e
  JOIN a_tblcollectionpayment p ON p.paymentid = e.paymentid
 WHERE coalesce(e.checkno,'') <> '' AND coalesce(p.checkno,'') = '';
```

## 4. Migration `migration_20260915_collection_normalization_stage_d.sql`

Runs in one transaction. Order matters.

1. **Backup** the columns about to disappear (irreversible drop otherwise):
   `CREATE TABLE a_tblcollectioninvoice_stage_d_backup AS SELECT collectioninvoiceid, documentid, clientid, clientname, clientaddress, clientcontact, clientemail, bankname FROM a_tblcollectioninvoice;`
   and the same for engagement `bankname, checkno, checkdate`.
2. **Normalize case** so the FK can be created: `UPDATE a_tblcollectioninvoice SET clientcode = upper(trim(clientcode))` (client table is already uppercased by the import; run the same on it defensively).
3. **Register any missing client** (defensive re-run of Stage B step): insert into the client table from invoice snapshot columns for codes in P1.
4. `ALTER TABLE a_tblcollectioninvoice ADD CONSTRAINT fk_a_tblcollectioninvoice_client FOREIGN KEY (clientcode) REFERENCES a_tblcollectionclient(clientcode);`
5. `ALTER TABLE a_tblcollectioninvoice DROP COLUMN clientid, DROP COLUMN clientname, DROP COLUMN clientaddress, DROP COLUMN clientcontact, DROP COLUMN clientemail, DROP COLUMN bankname;`
6. `ALTER TABLE a_tblcollectionengagement DROP COLUMN bankname, DROP COLUMN checkno, DROP COLUMN checkdate;`
7. **Recompute function** `fn_collection_recompute_invoice_caches(p_documentid text DEFAULT NULL)` that sets `totalcollected = Σ allocations`, `tobecollected = originalamount − Σ`, `status = 'Collected'` when balance is 0, for one invoice or all. Run it once at the end of the migration.
8. Replace the invoice **history trigger function** so it no longer references the dropped columns (the trigger copies `NEW.*` into `a_tblcollectioninvoice_history`; that table gets the same columns dropped, after its own backup).

Append to `mdmpi_app_db_schema.sql`.

## 5. Backend code (MDMPI.App)

| File | Change |
|---|---|
| `Core/Collection/Entities/CollectionInvoiceModel.cs` | Remove `ClientId, ClientName, ClientAddress, ClientContact, ClientEmail, BankName`. |
| `Core/Collection/Entities/CollectionEngagementModel.cs` | Remove `BankName, CheckNo, CheckDate`. |
| `Data/Collection/Repositories/CollectionInvoiceRepository.cs` | `ToItemDto`: client comes **only** from the registry (no snapshot fallback); `BankName` on the item DTO = bank of the most recent payment, or null. `ToHistoryDto`: payment only. `BuildInvoiceEntity` (import + manual create): stop copying client fields onto the invoice; route them to `UpsertClientAsync` instead, so a manual Add to Bucket still registers/refreshes the client. `GetBucketAsync` / `GetWorkspaceAsync`: load clients for all invoices (already done) and treat a missing client as an empty `ACCMSTDto` with the code. |
| `Core/Collection/DTOs/CreateCollectionInvoiceDto.cs` | **Unchanged.** Web import and mobile Add to Bucket keep sending `ClientName` etc.; the server now writes them to the client table. |
| `Core/Collection/DTOs/CollectionItemDto.cs`, `CollectionHistoryDto.cs` | **Unchanged** (contract). |
| `Data/PostgreSqlAppDbContext.cs` | Nothing to add; removed properties disappear from the mapping. Optional: declare the new FK for the SQLite test provider. |
| `Tests/Collection/CollectionInvoiceRepositoryTests.cs` | Fixtures that set the removed properties move that data to a client row; add tests: import registers client and item DTO reads name from registry; history bank details come from payment; manual create with new client code upserts the client. |

Compile errors after removing the properties are the checklist: every red line is a read that
must move to the client or payment table.

## 6. Web and mobile

- **Web (`mdmpi_collection_web`)**: no change. The parser still emits the full DTO; blank
  address/contact/email are ignored by the upsert (existing behaviour).
- **Mobile**: no change. Same JSON in, same JSON out. Nothing to install.

## 7. Verification

**Gates:** `dotnet test` (all green, count goes up), `flutter test` on the Collection suites
(unchanged, proves the contract held), `npm run build`.

**Postgres after migration**

```sql
-- columns are gone
SELECT column_name FROM information_schema.columns
 WHERE table_name='a_tblcollectioninvoice'
   AND column_name IN ('clientid','clientname','clientaddress','clientcontact','clientemail','bankname');  -- 0 rows

-- FK is in place and satisfied
SELECT conname FROM pg_constraint WHERE conname = 'fk_a_tblcollectioninvoice_client';        -- 1 row

-- caches agree with allocations
SELECT i.documentid, i.totalcollected, coalesce(a.s,0) AS allocated
  FROM a_tblcollectioninvoice i
  LEFT JOIN (SELECT documentid, sum(amount) s FROM a_tblcollectionpaymentallocation GROUP BY 1) a USING (documentid)
 WHERE i.totalcollected <> coalesce(a.s,0);                                                  -- 0 rows
```

**End to end:** on the phone, Download Bucket. Every account still shows its name (from the
registry), history rows still show bank / cheque no. (from payments), Total Collected matches
the server sum. Record one payment, Upload All, download on another device.

**Rollback:** the `_stage_d_backup` tables allow re-adding the columns and restoring values
with one `UPDATE ... FROM`. Keep them until the next month's import has run cleanly, then drop.

## 8. Effort and risk

- Migration: small, but **destructive** (column drops). The backup tables are the safety net.
- Backend: mostly deletions plus moving the manual-create client fields into the upsert.
  Roughly one session including tests.
- Risk is concentrated in P1: an invoice whose client code has no registry row would lose its
  name. The migration registers such clients from the snapshot before dropping it, and the
  precondition query makes the count visible beforehand.

## 9. Not in Stage D (candidates for a later Stage E)

- Web: client registry enrichment screen (address, contact, email), deposits and target
  reporting.
- `documentreferences` child table.
- Clear Engagement leaving a visible "Released" history entry (asked on 2026-09-15; needs a
  process-flow decision first).
