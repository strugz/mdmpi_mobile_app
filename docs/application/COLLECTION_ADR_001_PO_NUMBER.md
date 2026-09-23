# ADR-001: Carry the SAP `BP Ref. No.` (P.O. Number) through import, backend, web and mobile

**Status:** Accepted — implemented 2026-09-22 in backend (`MDMPI.App`), admin web
(`mdmpi_collection_web`) and mobile; migration run, backend deployed and bucket
re-imported with P.O.s on 2026-09-23
**Date:** 2026-09-22
**Deciders:** Collection team lead (business rule), mobile/backend developer (JCA)
**Related:** `mdmpi_collection_web/docs/SAP_AR_IMPORT_PLAN.md` (§3 column mapping, §6 re-import
semantics), `COLLECTION_DATA_MODEL_NORMALIZATION.md`, `COLLECTION_STAGE_E_PLAN.md`

---

## Context

The monthly SAP AR aging export already feeds the Collection Bucket through the admin web
app (*Import Collection Bucket*) → `POST /api4/Collection/invoices/import` →
`a_tblcollectioninvoice` → mobile bucket download. Today only six SAP columns are kept
(BP Code, BP Name, Doc. No., Posting Date, Due Date, Balance Due).

Collectors and the office need to know **which customer Purchase Order an invoice belongs
to**. The SAP column **`BP Ref. No.`** carries that P.O. number. One P.O. is frequently
billed as **several invoices** (partial deliveries), so the relationship is
**P.O. 1 → N invoices**.

Facts from the reference export (`C&C SAMPLE OF RAW SAP REPORTS AND MODULE.xlsx`, `AR`
sheet, IN rows with Balance Due > 0):

| Measure | Value |
|---|---|
| IN rows | 3,872 |
| IN rows with `BP Ref. No.` filled | 3,855 (99.6%) |
| Distinct P.O. values | 3,086 |
| P.O.s covering 2+ invoices | 516 (16.7%); max 10 invoices on one P.O. |
| P.O.s that appear under more than one BP Code | 11 |
| Longest value | 46 characters |
| Cell types Excel hands us | string 2,482 · integer 1,297 · **date 76** |

Two of those facts shape the design:

1. **The P.O. number is free text owned by the customer**, not a SAP key. Formats vary
   (`230736`, `23-122`, `2025-00210`, `ADC-CHEM-2023-001-A`). The same string can be reused
   by two different customers, so a P.O. is only meaningful **within a client**.
2. **Excel mangles some values into dates** (76 rows, e.g. a P.O. like `3-5` becomes
   5 March). SheetJS with `cellDates: true` then returns a `Date` and the original text is
   lost unless the *formatted* cell text is read instead of the typed value.

Constraints already in force:

- Import is **insert-only for invoices, dedupe on `documentid`** (plan §6). A plain column
  add would leave every invoice already in the bucket with a null P.O. until it is settled
  and re-created, which for long-running accounts is never.
- The mobile JSON contract (`CollectionItemDto`, keys like `BPCode`, `DueDate`) is shared
  by backend, mobile DTO and the mobile SQLite mirror in `CollectionDao`; every field is
  spelled three times.
- Mobile collection tables are **never dropped**; new columns must arrive through
  `_addColumnIfMissing` in `lib/data/local/db_schema.dart` (no DB version bump needed).
- Every mobile change must work on Android and Windows desktop.

> **Terminology:** the request says "erfweb". No project on disk uses that name. This ADR
> takes it to mean the **Collection Admin web app** (`mdmpi_collection_web`, Vuetify 3),
> which owns the SAP import screen. If "erfweb" is a different system, §Action Items still
> hold; only the web bullets move.

---

## Decision

Add a **`ponumber` column on `a_tblcollectioninvoice`** (nullable `varchar(100)`), mapped
from SAP `BP Ref. No.` at import, exposed as **`PONumber`** in the bucket JSON, mirrored to
the mobile SQLite table and model, and shown on the invoice surfaces. Group-by-P.O. is a
**query over that column scoped by client**, not a separate table.

Two supporting rules:

- **Re-import fills gaps.** `ImportInvoicesAsync` keeps skipping duplicate invoices, but
  when the existing row has a **null/blank `ponumber`** and the incoming DTO has one, it
  **sets it**. Nothing else on an existing invoice is touched, so the "app owns the running
  balance" guarantee from plan §6 is intact. This backfills the whole bucket on the next
  monthly run with no one-off script.
- **Read the P.O. as text, never as a typed value.** The web parser must take the formatted
  cell string for this column so date-mangled values survive verbatim.

---

## Options Considered

### Option A: Nullable `ponumber` column on the invoice (chosen)

| Dimension | Assessment |
|---|---|
| Complexity | Low — one column, one DTO field per layer, one parser alias |
| Cost | One additive migration; no data moves |
| Scalability | Indexed `(clientcode, ponumber)` answers "invoices under this P.O." in one lookup |
| Team familiarity | High — identical to how `bpcode`/`postingdate` already flow |

**Pros:** additive, matches the existing per-invoice shape, re-import backfill is a two-line
change, mobile mirror is one `ALTER` via the existing helper.
**Cons:** the same P.O. string is stored once per invoice (harmless: ≤46 chars); P.O.-level
attributes (P.O. amount, P.O. date) have no home — SAP AR does not export them anyway.

### Option B: Separate `a_tblcollectionpo` table with FK from invoice

| Dimension | Assessment |
|---|---|
| Complexity | Medium–High — upsert a P.O. row per (client, P.O.) at import, FK, join in `GET /bucket` |
| Cost | New table, new repository, new mobile table and DAO |
| Scalability | Same query cost as A; extra join on every bucket read |
| Team familiarity | Medium — mirrors the `a_tblcollectionclient` registry pattern |

**Pros:** a natural home if the business later needs P.O. amount, P.O. date, or a P.O.
"fully billed" status.
**Cons:** the P.O. is not a stable key (reused across customers, sometimes typos); the AR
export gives no P.O.-level attributes to store, so the table would hold only the key. The
normalization work of Stages A–E deliberately kept the invoice as the unit collectors act
on; a P.O. entity today would be a table with one column.

### Option C: Append the P.O. to `documentreferences`

| Dimension | Assessment |
|---|---|
| Complexity | Trivial |
| Cost | None |
| Scalability | Cannot filter or group |
| Team familiarity | High |

**Pros:** zero schema change.
**Cons:** `documentreferences` is defined as the Doc. No. list and the mobile bucket card
renders its first element as the invoice number; mixing in a P.O. corrupts that display and
makes "invoices under this P.O." a string-split. Rejected.

---

## Trade-off Analysis

- **A vs B** comes down to whether a P.O. is an *entity* or an *attribute* here. SAP AR
  treats it as a reference attribute on the document; nothing in the requested purpose
  ("know the P.O. of the invoices, some P.O.s have several invoices") needs P.O.-level
  state. A gives the grouping with an index and keeps every layer's change mechanical.
  If P.O. attributes arrive later, B can be introduced additively by promoting the column
  into a registry the same way `a_tblcollectionclient` was split out in Stage D.
- **Backfill on re-import vs one-off SQL.** Filling null P.O.s inside the dedupe path is
  idempotent, testable in `CollectionInvoiceRepositoryTests`, and needs no operator step.
  A one-off `UPDATE ... FROM` would require exporting the same file to CSV and loading it
  server-side. The import path wins; a repair script remains available if a month is
  skipped.
- **Scope P.O. by client, not globally.** 11 P.O.s in the sample belong to two customers.
  Any "group by P.O." on web or mobile must key on `(clientcode, ponumber)`; the mobile
  account-invoices screen already works inside one client, so this is free there.
- **Text vs typed cell.** Reading `raw: false`/`cell.w` for one column costs one extra
  lookup per row; losing 2% of P.O. numbers to Excel date coercion is a silent data defect.
  Text wins.

---

## Consequences

**Easier**
- Collectors can see and search the P.O. of any invoice offline.
- Office can answer "which invoices are still open under P.O. X for client Y" with an
  indexed query; the web Clients/Reports views can show a P.O. column.
- Existing bucket rows gain their P.O. automatically at the next monthly import.

**Harder / to watch**
- The JSON contract grows by one key spelled in five places (backend DTO, backend mapper,
  mobile DTO, mobile DAO both directions, mobile model). Miss one and the field silently
  reads `N/A`; the DAO round-trip test must assert it.
- Manual *Add to Bucket* on mobile gained an optional P.O. field on 2026-09-23 (revisions
  item 3); invoices added before that carry `null`.
- P.O. is optional data: UI must hide the row/chip when blank rather than print `N/A`.

**Revisit when**
- SAP starts exporting P.O. amount/date, or the business wants "P.O. fully collected"
  status → promote to Option B.
- A customer's P.O. numbering collides *within* the same client → nothing to do; the
  column is a label, not a key.

---

## Action Items

Ordered by the dependency chain: database → backend → web importer → mobile.
Deploy backend + migration **before** running the next import; mobile can ship in either
order because a missing key reads as blank.

### 1. Database (`MDMPI.App/`)
1. [ ] `migration_20260922_add_collection_invoice_ponumber.sql`:
   `ALTER TABLE public.a_tblcollectioninvoice ADD COLUMN IF NOT EXISTS ponumber varchar(100);`
   plus `CREATE INDEX IF NOT EXISTS idx_a_tblcollectioninvoice_client_po ON
   public.a_tblcollectioninvoice (clientcode, ponumber) WHERE ponumber IS NOT NULL;`
2. [ ] Add the same column to `mdmpi_app_db_schema.sql` (the `a_tblcollectioninvoice` block).

### 2. Backend (`MDMPI.App/`)
3. [ ] `MDMPI.App.Core/Collection/Entities/CollectionInvoiceModel.cs`: `[MaxLength(100)] public string? PoNumber { get; set; }`
   with a doc comment "SAP `BP Ref. No.`; the customer's P.O. Several invoices may share one."
4. [ ] `MDMPI.App.Core/Collection/DTOs/CreateCollectionInvoiceDto.cs`: `public string? PoNumber { get; set; }`.
5. [ ] `MDMPI.App.Core/Collection/DTOs/CollectionItemDto.cs`: `[JsonPropertyName("PONumber")] public string? PONumber { get; set; }`.
6. [ ] `MDMPI.App.Data/Collection/Repositories/CollectionInvoiceRepository.cs`:
   - `BuildInvoiceEntity`: `PoNumber = NormalizePo(dto.PoNumber)` (trim, empty → null, cap 100).
   - `ToItemDto`: `PONumber = i.PoNumber`.
   - `ImportInvoicesAsync`: in the duplicate branch, if the existing row's `PoNumber` is
     blank and the DTO's is not, set it (load the existing entities, not just their ids,
     for the incoming batch). Keep the `Skipped` result entry so the web summary is unchanged.
7. [ ] `MDMPI.App.Tests/Collection/CollectionInvoiceRepositoryTests.cs`: tests for
   (a) import stores the P.O., (b) re-import backfills a null P.O. and leaves
   `tobecollected`/dates untouched, (c) re-import never overwrites a non-blank P.O.

### 3. Collection Admin web (`mdmpi_collection_web/`)
8. [ ] `src/utils/excelParser.js`: add `ponumber: ['bp ref. no.', 'bp ref no', 'bp ref no.', 'bpref', 'po number', 'po no.', 'po no', 'p.o. number', 'po']`
   to `HEADER_ALIASES`; `case 'ponumber'` in `rowToRecord` sets `dto.PoNumber`.
9. [ ] Read this column as **formatted text**: call `sheet_to_json` a second time with
   `{ raw: false, defval: '' }` (or read `cell.w`) and take the P.O. from that row, so
   date-coerced cells keep their original string. Unit-test with a `Date` cell.
10. [ ] `src/views/BucketImportView.vue`: preview column `{ title: 'P.O. No.', key: 'po' }`
    and `po: r.dto.PoNumber` in the row mapping; add `'PO Number'` to `TEMPLATE_HEADERS`.
11. [ ] `docs/SAP_AR_IMPORT_PLAN.md` §3 table: new row `BP Ref. No. → PoNumber → ponumber`;
    §6: note the null-P.O. backfill exception to insert-only.
12. [ ] (Optional, same release) `ClientsView.vue` invoice list: show P.O. and allow
    grouping/sorting by it within a client.

### 4. Mobile (`mdmpi_mobile_app/`)
13. [ ] `lib/data/local/db_schema.dart` — inside `ensureCollectionTables`: add `poNumber TEXT`
    to the `a_tblCollectionItems` CREATE and `await _addColumnIfMissing(db, 'a_tblCollectionItems', 'poNumber', 'TEXT');`
    (no `version` bump; the helper runs on every open).
14. [ ] `lib/data/local/dao/collection/collection_dao.dart`: `_apiJsonToDbJson` →
    `'poNumber': apiJson['PONumber'] ?? ''`; `_dbJsonToApiJson` → `'PONumber': dbJson['poNumber']`.
15. [ ] `lib/features/collection/dtos/collection_item_dto.dart`: field `poNumber`, `toJson`
    key `PONumber`, `fromJson` default `''` (not `N/A` — blank means "none").
16. [ ] `lib/features/collection/models/collection_item_model.dart`: `final String poNumber`
    (default `''`), `copyWith`; `lib/features/collection/mappers/collection_mapper.dart`: map it.
17. [ ] UI, hidden when blank:
    - `presentation/widgets/invoice_card.dart` and `bucket/widgets/bucket_item_card.dart`: small "PO 2026-0262" chip.
    - `activity/widgets/invoice_details_modal.dart` and `activity_info_card.dart`: a "P.O. No." row.
    - `activity/activity_account_invoices_screen.dart` and `engagement_invoice_picker.dart`:
      include P.O. in the search text; group header by P.O. when a client has 2+ invoices on one P.O.
18. [ ] Tests: `test/collection_dao_test.dart` round-trip asserts `PONumber`; a widget test
    that the chip is absent when `poNumber` is empty.
19. [ ] Docs: update `docs/modules/` Collection page and add a line to the QA checklist.
20. [ ] Gate: `flutter analyze; flutter test` (PowerShell `;`). Do not commit or push.

### 5. Verification (after the next monthly import)
- [ ] `SELECT count(*) FILTER (WHERE ponumber IS NULL), count(*) FROM a_tblcollectioninvoice WHERE source='SAP';`
  → null count ≈ 0.4% of rows (SAP rows with no P.O.), not the whole table.
- [ ] `SELECT clientcode, ponumber, count(*) FROM a_tblcollectioninvoice WHERE ponumber IS NOT NULL GROUP BY 1,2 HAVING count(*) > 1 ORDER BY 3 DESC LIMIT 20;`
  → multi-invoice P.O.s appear, matching the SAP preview.
- [ ] Mobile: download bucket → an invoice from a multi-invoice P.O. shows the chip; the
  account screen groups its siblings; Windows desktop shows the same.
