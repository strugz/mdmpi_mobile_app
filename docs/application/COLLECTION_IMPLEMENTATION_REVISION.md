# Collection Module — Backend, Offline Persistence & Web Import (Revision)

**Date:** 2026-09-14
**Scope:** Collection department — `mdmpi_mobile_app` (Flutter), `MDMPI.App` (ASP.NET
backend), and a new `mdmpi_collection_web` (Vuetify) admin web app.
**Status:** Code complete and verified (build + unit tests). Manual/deployment steps
are listed in §7.

---

## 1. Why this change

The Collection feature was UI-complete but **not persisted and had no backend**: the
local SQLite tables were never created (so the app silently ran on random sample
data), writes were never queued, sync was a stub, and the repository pointed at a
placeholder endpoint. This revision makes Collection a working **offline-first field
tool** with a real backend, and adds a **web app** to load the bucket from Excel.

Field workflow now supported end-to-end (per
`COLLECTION_PROCESS_FLOW_AND_NARRATIVE.docx`):

> Admin/supervisor loads the bucket → collector downloads the shared bucket →
> **Acquires** accounts → records collections **offline** (an SMS goes to the head on
> each save) → end-of-day **Upload All** → server resolves claim conflicts. A new
> bucket download is **blocked** while un-uploaded work remains.

---

## 2. Backend (`MDMPI.App`, PostgreSQL) — new, additive

The existing SQL-Server `CollectionTransactionController` is **left untouched and
unused**. A fresh PostgreSQL vertical slice was added, mirroring the Logistics
(Pick-Up) pattern on `PostgreSqlAppDbContext`.

### 2.1 Database (run `migration_20260914_add_collection_tables.sql` on Postgres)
- **`a_tblcollectioninvoice`** — the bucket unit (one invoice). `assignedto IS NULL`
  means unclaimed/shared pool. Denormalized client columns so the mobile DTO
  round-trips without a CRM join.
- **`a_tblcollectionengagement`** — every recorded save (field engagement + office
  activities); also serves as the invoice `History[]`.
- **`a_tblcollectioninvoice_history`** — audit trail populated by an
  `AFTER INSERT/UPDATE/DELETE` **trigger** (`trg_a_tblcollectioninvoice_history`),
  mirroring the Pick-Up history pattern.
- Date-like fields are stored as text (the app treats them as display strings);
  only `createdat`/`updatedat` are real timestamps.

### 2.2 API — new `CollectionController` (served as `/api4/Collection/*`)
| Method & path | Purpose |
|---|---|
| `GET /api4/Collection/bucket?collector={code}` | Shared unclaimed pool + this collector's claimed items. |
| `POST /api4/Collection/invoices` | Create one invoice (mobile "Add to Bucket"). |
| `POST /api4/Collection/invoices/import` | Bulk create (web Excel import). Returns `{ Created, Skipped:[{Reference,Reason}] }`. |
| `POST /api4/Collection/upload` | End-of-day batch: `{ CollectorCode, Changes:[…] }`. Applied in one transaction; returns `{ Accepted, Rejected }`. |

- **Business rules** live in `CollectionInvoiceRepository`: settle (amount clears
  balance → `Status='Collected'`), **CLAIM first-wins** (a claim on an
  already-claimed invoice is rejected), Defer/Clear release.
- DTO JSON keys are pinned to **PascalCase** (and `id`/`BPCode`) to match the mobile
  contract regardless of the controller's JSON naming policy.
- Layers: `Core/Collection/{Entities,DTOs,Interfaces,Services}`,
  `Data/Collection/Repositories/CollectionInvoiceRepository.cs`, DbSets in
  `PostgreSqlAppDbContext.cs`, DI in `Program.cs`.

### 2.3 CORS (required for the web app)
CORS was enabled in `Program.cs` (previously commented out). By default it allows any
origin (the REST API is open and sends no cookies); set `Cors:AllowedOrigins` (array)
in configuration to restrict it to the deployed web URL(s).

---

## 3. Mobile (`mdmpi_mobile_app`) — offline-first Collection

### 3.1 Local database (SQLite)
- Added `ensureCollectionTables()` (in `db_schema.dart`) creating
  `a_tblCollectionItems`, `a_tblCollectionHistory`, `a_tblCollectionPending`
  **idempotently**. DB version **19 → 20**.
- These tables are **deliberately excluded** from the destructive
  `_recreateAllTables` rebuild in `database_helper.dart`, so **un-uploaded field work
  survives app upgrades** (same protection as the `contacts`/image-outbox tables).
- Fixed a client round-trip bug in `CollectionDao` (client name/id were lost on local
  save due to mismatched JSON keys).

### 3.2 Repository / sync
- `CollectionRepository` now uses `BApiEnvironment.api4Uri('/api4/Collection/...')`
  (was a placeholder `dotenv` URL) and parses via the DTO + mapper layer (the mapper
  was dead/buggy — rewritten as a correct thin adapter).
- Every write (**claim / save / batch**) is queued to `a_tblCollectionPending`.
- `uploadAll()` sends the whole queue in one batch, removes accepted rows, keeps
  rejected ones for review. `SyncManager` drives it (the simulated push was removed).

### 3.3 UI
- **Home sync bar**: "Download Bucket" (gated) and "Upload (N)" / "All uploaded".
- **Upload Outbox** screen (`/collection/upload-outbox`): review, retry, discard
  queued changes — modeled on the Signature Outbox.
- **Pre-download gate**: downloading a new bucket is blocked while pending changes
  exist (protects un-uploaded edits from being cleared by a refresh).
- **Add to Bucket** screen (`/collection/add-to-bucket`) from the bucket app bar
  (supervisor path; saved to the DB first).

### 3.4 SMS to the head (Android, over cellular → works offline)
- New `CollectionSmsService` reuses the telephony + permission plumbing; fires on
  each `saveActivity` (per invoice) and once per `saveBatchActivity` (summary).
  Android-only — a clean no-op on Windows.
- **Recipients**: contacts tagged **Department = "Collection"** in the existing
  **Contact Directory** (Settings). No new screen required.

### 3.5 Sample data removed
The hardcoded demo generator (`_loadSampleBucketItems`, 8 fake clients with random
invoices) and its fallback were **removed**, so the app no longer masks errors or an
empty bucket with fake accounts. (There were no JSON sample assets.)

---

## 4. New web app (`mdmpi_collection_web`, Vuetify 3 + Vite)

A browser admin tool to bulk-load the bucket from Excel.
- **Auth:** Firebase (email/password) against the **same `mdmpi-app` project** as the
  mobile app — shared logins. Register a *Web app* in the Firebase console for the
  web `apiKey`/`appId`.
- **Flow:** sign in → upload `.xlsx/.xls/.csv` → the app parses & previews rows (with
  per-row validation) → **Import** → `POST /api4/Collection/invoices/import` →
  created/skipped summary. A blank **template** is downloadable in-app.
- **Stack:** Vue 3, Vuetify 3, `firebase`, `axios`, `xlsx` (SheetJS). Static build
  (`npm run build` → `dist/`) deployable to Firebase Hosting / any static host.

See `mdmpi_collection_web/README.md` for setup.

---

## 5. Excel import format (also used by mobile "Add to Bucket")

| Column | Required | Notes |
|---|---|---|
| **Client Code** | ✅ | **Area-prefixed**: `NLN- / SLN- / CLN- / VIS- / MIN- / RAD-`. |
| Client ID | | Defaults to Client Code (groups invoices per account). |
| **Client Name** | ✅ | |
| Client Address, Contact, Email | | |
| Document References | | Separate multiple with `,` `;` or `|`. |
| **Amount Due** | ✅ | Must be > 0. |
| Bank, Document Date, Posting Date, Due Date, Remarks | | |
| Document ID | | Unique invoice id; generated by the backend if blank. Duplicates are skipped. |
| Assigned To | | Blank = shared pool. |

> **Critical:** "Filter by Area" in the mobile app matches on **both** `ClientCode`
> and `BpCode` prefixes. `BpCode` defaults to `ClientCode`, so the **area prefix on
> Client Code is mandatory** or area filtering returns nothing.

---

## 6. Verification performed

- **Backend:** `dotnet build` (0 errors); **9 unit tests** pass — settle rule,
  CLAIM first-wins, Defer release, bucket read, controller responses
  (`MDMPI.App.Tests/Collection`, `.../Controllers/CollectionControllerTests`).
- **Mobile:** `flutter analyze` (0 errors); Collection DAO tests pass
  (`test/collection_dao_test.dart`) — table creation, item+history round-trip,
  pending queue.
- **Web:** `npm run build` succeeds (Vite production build).
- The Postgres **trigger** is exercised only against a real Postgres instance (the
  mobile test harness uses SQLite); verify on deploy — see §7.

---

## 7. Deployment & remaining manual steps

1. **Postgres:** run `MDMPI.App/migration_20260914_add_collection_tables.sql` on the
   target database. Confirm the history trigger by inserting/updating a row and
   checking `a_tblcollectioninvoice_history`. *(Done — DB & backend deployed.)*
2. **Backend:** deploy the updated `MDMPI.App`; set `Cors:AllowedOrigins` to the web
   app URL(s) for production (optional — defaults to any origin).
3. **Web app:** register a Firebase **Web app** under project `mdmpi-app`; fill
   `mdmpi_collection_web/.env` (`apiKey`, `appId`, `VITE_API4_BASE_URL`);
   `npm install && npm run build`; host `dist/`.
4. **Mobile:** set `.env` `API4_URL_ANDROID` (and `API4_URL_WINDOWS`) for dev; add
   the head's number to the Contact Directory with Department = "Collection".
5. **Load the bucket** (web Excel import or mobile Add-to-Bucket) using the
   area-prefixed Client Code, then smoke-test the on-device loop
   (download → acquire → record offline + SMS → blocked re-download → Upload All).

---

## 8. Key files

**Backend:** `migration_20260914_add_collection_tables.sql`, `mdmpi_app_db_schema.sql`,
`MDMPI.App.Core/Collection/*`, `MDMPI.App.Data/Collection/Repositories/CollectionInvoiceRepository.cs`,
`MDMPI.App.Data/PostgreSqlAppDbContext.cs`,
`MDMPI.App.Api/Controllers/Collection/CollectionController.cs`, `MDMPI.App.Api/Program.cs`.

**Mobile:** `lib/data/local/{db_schema.dart,database_helper.dart}`,
`lib/data/local/dao/collection/*`, `lib/data/repositories/collection/collection_repository.dart`,
`lib/features/collection/helpers/sync_manager.dart`,
`lib/features/collection/presentation/controllers/{collection_activity_controller.dart,collection_upload_controller.dart}`,
`lib/features/collection/presentation/pages/{upload,bucket,home}/*`,
`lib/data/services/collection_sms_service.dart`, `lib/bindings/app/general_bindings.dart`,
`lib/base/utils/routes/{routes.dart,app_routes.dart}`.

**Web:** `mdmpi_collection_web/` (see its `README.md`).
