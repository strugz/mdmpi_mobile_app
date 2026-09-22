# Collection — Stage E Plan (web client enrichment)

**Date:** 2026-09-15 · **Status:** E1 IMPLEMENTED 2026-09-15 — backend `8aea616` (163 tests; apply `migration_20260915_collection_stage_e1_client_audit.sql` first), web `ClientsView.vue` + `clientsApi.js` built. E2/E3 pending.
Follows Stage D (`COLLECTION_NORMALIZATION_STAGE_D_PLAN.md`, deployed 2026-09-15).
Web app: `mdmpi_collection_web`. Backend: MDMPI.App `master`.

## 1. Why

Since Stage D, `a_tblcollectionclient` is the **only** place a client's name, address, contact
and email live. The SAP AR export fills only code and name, so every collector card on the
phone shows a blank address today (`account_item_card.dart`, `bucket_item_card.dart`,
`activity_info_card.dart`, `collection_account_information_screen.dart` all render
`client.address`). The office knows these details; there is nowhere to type them.

Stage E1 gives the admin web app a **Clients** screen to search the registry and fill in
address / contact / email. The phone picks the values up on its next Download Bucket with no
mobile change.

Stage E is split so each part ships alone:

| Part | Scope | This plan |
|---|---|---|
| **E1** | Client enrichment screen (web) + client API (backend) | **yes** |
| E2 | Deposits and monthly-target reporting on the web | E2a implemented — `COLLECTION_STAGE_E2_PLAN.md` |
| E3 | "Released" history entry for Clear Engagement | needs a process-flow decision first |

## 2. Rules the screen must respect

- **Codes are immutable.** Clients are created only by the SAP import (and the auto-register
  path on upload). The web can edit details, never create or delete a client, never change a
  code.
- **SAP stays authoritative for the name.** The monthly re-import overwrites `clientname`
  (existing `UpsertClientAsync` behaviour) and leaves address / contact / email alone because
  it only writes non-blank incoming values. A name edited on the web will therefore be
  replaced at the next import; the screen says so next to the Name field.
- **Every edit is attributable.** The client table gets `updatedby` and an audit history
  table with the same trigger pattern as invoices and payments.
- **No new auth model.** The API today has no authentication; the web app is Firebase-gated
  on the client side only. E1 sends the signed-in user's email as `UpdatedBy` for attribution.
  Verifying Firebase ID tokens server-side is a separate hardening task (§8).

## 3. Backend (MDMPI.App)

### 3.1 Migration `migration_20260915_collection_stage_e1_client_audit.sql`

1. `ALTER TABLE a_tblcollectionclient ADD COLUMN IF NOT EXISTS updatedby varchar(150);`
2. `CREATE TABLE a_tblcollectionclient_history (historyid identity PK, actiontype, changedat, changedby, clientcode, clientname, clientaddress, clientcontact, clientemail, area, updatedat, updatedby)`.
3. Trigger `trg_a_tblcollectionclient_history` AFTER INSERT OR UPDATE OR DELETE, same shape as
   the payment trigger from Stage A.
4. Index `idx_a_tblcollectionclient_name_lower ON a_tblcollectionclient (lower(clientname))`
   for the search box.

Additive, re-runnable, no data change. Append to `mdmpi_app_db_schema.sql`.

### 3.2 DTOs (`Core/Collection/DTOs/CollectionClientDtos.cs`, PascalCase pinned)

```
CollectionClientDto        { ClientCode, ClientName, ClientAddress, ClientContact, ClientEmail,
                             Area, InvoiceCount, OpenBalance, UpdatedAt, UpdatedBy }
UpdateCollectionClientDto  { ClientName, ClientAddress, ClientContact, ClientEmail, UpdatedBy }
PagedResultDto<T>          { Items, Total, Page, PageSize }
```

`InvoiceCount` / `OpenBalance` are read-only aggregates from `a_tblcollectioninvoice`
(count, Σ `tobecollected`) so the operator can prioritise clients that still owe.

### 3.3 Repository + service

New `Data/Collection/Repositories/CollectionClientRepository.cs` with
`ICollectionClientRepository` (keeps `CollectionInvoiceRepository` focused on invoices):

| Method | Behaviour |
|---|---|
| `SearchAsync(search, area, missingOnly, page, pageSize)` | `search` matches code or name, case-insensitive, `ILIKE %term%`; `area` filters on `area`, with `OTHERS` = area not in the seven named prefixes (same rule as the phone's `BCollectionArea`); `missingOnly` = address **and** contact both blank; ordered by name; `pageSize` clamped to 1–200. |
| `GetAsync(code)` | by normalized (upper/trim) code, or null. |
| `UpdateAsync(code, dto)` | null when unknown; trims all four fields; **rejects blank name** (400); enforces the MaxLength attributes; stamps `UpdatedAt` (UTC) and `UpdatedBy`; returns the refreshed DTO. Code is never written. |

Reuse `NormalizeCode` / `DeriveArea` — move them to a small shared `CollectionCodes` static
class so both repositories use one copy.

`ICollectionService` gains `SearchClientsAsync`, `GetClientAsync`, `UpdateClientAsync`
(thin pass-through as today). Register the new repository in `Program.cs` next to the invoice
repository.

### 3.4 Controller (`CollectionController`)

| Route | Result |
|---|---|
| `GET /api4/Collection/clients?search=&area=&missingOnly=&page=1&pageSize=25` | 200 `PagedResultDto<CollectionClientDto>` |
| `GET /api4/Collection/clients/{code}` | 200 dto · 404 |
| `PUT /api4/Collection/clients/{code}` body `UpdateCollectionClientDto` | 200 dto · 400 (blank name / too long / bad email) · 404 |

CORS already allows the web origin.

### 3.5 Tests

`Tests/Collection/CollectionClientRepositoryTests.cs` (SQLite in-memory, same harness):
search by partial code and by name; area filter incl. `OTHERS`; `missingOnly`; paging total
vs items; update trims, keeps code, stamps `UpdatedBy`; blank name rejected; unknown code
→ null; SAP re-import after enrichment keeps address/contact (regression for rule 2).
Controller tests: 404 and 400 paths.

## 4. Web (`mdmpi_collection_web`)

| File | Change |
|---|---|
| `src/api/clientsApi.js` (new) | `searchClients(params)`, `getClient(code)`, `updateClient(code, body)` on the shared axios instance; tolerant `pick` for casing like `collectionApi.js`. |
| `src/views/ClientsView.vue` (new) | The screen (below). |
| `src/router/index.js` | `{ path: '/clients', name: 'clients', component: ClientsView, meta: { requiresAuth: true } }`. |
| `src/App.vue` | Add `v-tabs` under the app bar: **Import Bucket** (`/`) · **Clients** (`/clients`). |
| `README.md` | Document the screen and the "SAP overwrites name" rule. |

### Screen

- **Toolbar**: search text field (debounced 300 ms, searches code or name), Area select
  (All, North Luzon, South Luzon, Central Luzon, NCR, Visayas, Mindanao, Medical Imaging,
  Others — same labels as the phone), switch **Missing details only** (default on, because
  that is the work queue).
- **Table**: `v-data-table-server`, 25 per page, columns Code · Name · Area · Address ·
  Contact · Email · Invoices · Open balance · Updated. Blank address/contact cells render a
  muted "—" so gaps are scannable. Row click opens the editor.
- **Editor** (`v-dialog`, 520 px): Name (required, helper text "Replaced by the SAP name on the
  next import"), Address (textarea, max 500), Contact (max 100), Email (max 150, format
  check). Save = PUT; on success the row updates in place and a snackbar confirms. Enter
  saves, Esc closes, Save disabled while the request is in flight (same busy pattern as the
  phone's Upload All). Errors from the API show inline under the form.
- **Attribution**: footer of the editor shows "Last updated 2026-09-15 by jca@…" when present.
- Empty state when the filter matches nothing; error alert when the API is unreachable.

## 5. Mobile

No change. `ACCMSTDto` already carries address / contact / email and the cards already render
them. After the office fills a client in, the collector's next Download Bucket shows it.

## 6. Order of work

1. **E1a backend**: migration → DTOs → repository/service/controller → tests → `dotnet test`.
2. **E1b web**: API module → view → route/nav → `npm run build`.
3. **E1c verify** (§7), then commit + push each repo (grouped as today).

Backend can deploy before the web is ready; the endpoints are additive.

## 7. Verification

- Gates: `dotnet test` (count rises), `npm run build`, mobile suites unchanged.
- Web: search "NCR-2" lists matching codes; switch off "missing only" and the list grows;
  edit one client, reload the page, the values persist.
- Postgres: `SELECT clientcode, clientaddress, updatedby FROM a_tblcollectionclient WHERE updatedby IS NOT NULL;`
  and one row per edit in `a_tblcollectionclient_history`.
- Phone: Download Bucket → the edited client's card shows the address.
- Rule 2: re-import the month's SAP file → address/contact unchanged, name refreshed, web
  summary shows Added 0.

## 8. Not in E1

- Server-side verification of Firebase ID tokens on `/api4/Collection/*` (today anyone who can
  reach the API can call it; the web app only gates its own UI). Worth its own task before the
  web app is exposed beyond the office network.
- Bulk edit / CSV upload of client details.
- Editing `area` (derived from the code prefix on import).
- E2 reporting and E3 Clear Engagement history.
