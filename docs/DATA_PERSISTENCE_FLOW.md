# Data Persistence Flow — Server API and Local SQLite

How the logistics modules move data between the `/api4` backend and the local SQLite
database (`app.db`) on fetch, insert, update, cancel and delete.

> **Read this first if you are touching a repository, a data manager or a DAO.** There is
> no single shared flow. The six logistics modules use three different patterns, and the
> differences between them are the source of most of the known data-integrity risks listed
> at the end of this document.

## Module stacks

Four repositories serve six module tabs. Each shared repository also means a shared table.

| Module | Repository | Endpoint | SQLite table |
|---|---|---|---|
| Standard Delivery | `StandardDeliveryRepository` | `/api4/request` | `a_tblRequest` |
| Hotline Direct | *same as Standard Delivery* | `/api4/request` | *same table* |
| Air / Sea / Land | `AirSeaRepository` | `/api4/RequestAirSea?includeHd=true` | `a_tblRequestAirSea` |
| Air / Sea / Land HD | *same as Air / Sea* | *same endpoint* | *same table* |
| Pull Out / Return | `PullOutRepository` | `/api4/RequestPullOutReturnPickUp` | `a_tblRequestPullOutReturnPickUp` |
| Stock Receive | *same as Pull Out* | *same endpoint* | *same table* |
| Pick Up | `PickUpRepository` | `/api4/RequestPickUp` | `a_tblRequestPickUp` |

Paired modules are separated only by `formCategoryID` at read time. A cache wipe triggered
by one member of a pair therefore affects its sibling.

## Read / fetch

Two different mechanisms implement the same intent.

### Pattern A — `OfflineDataLoader` (Standard Delivery, Hotline Direct)

`lib/base/utils/helpers/offline_data_loader.dart`

1. If not `forceRemote` and the local table is non-empty, return local rows and stop. No
   network call is made and the cache is never refreshed on this path.
2. Check connectivity. If offline, return local rows when `forceRemote` is set, otherwise
   return an **empty list**.
3. Fetch remotely, write the result through `cacheRemote`, and return it.
4. If the remote call throws, return local rows when non-empty, otherwise rethrow.

The cache is written in exactly one place: after a successful remote fetch. A local-first
hit, an offline return and an error fallback all skip the write.

`forceRemote` is `!useLocalStorage`, so the Server/Local switch selects the path.

### Pattern B — repository-internal (Air / Sea, Pull Out, Pick Up)

1. If offline, return the local table (or throw when `allowLocalFallback` is false).
2. If not `forceRefresh` and the table is non-empty, return local rows and kick off
   `_syncFromApi()` in the background (not awaited).
3. Otherwise fetch, write the cache, and return.
4. On error, return local rows when non-empty, otherwise throw.

### Where the two disagree

- **Offline in Server mode.** Pattern A returns an empty list; Pattern B returns the full
  local table.
- **Staleness.** Pattern A never refreshes a local-first hit, so the Standard Delivery
  cache in Local mode can remain stale indefinitely. Pattern B background-syncs.
- **Local mode bypasses the repository.** The Air / Sea, Pull Out and Pick Up data managers
  call `getLocal*()` directly, so the repository's connectivity check, date scoping and
  cache write never run.
- **`forceRefresh: true` does not mean "from the server".** It only skips the
  table-non-empty branch. The offline guard above it and the catch block below it both
  still return local rows. Only `allowLocalFallback: false` genuinely forces a remote read,
  and the normal read paths never pass it.

### Date scoping

Reads send `?dateFilter=` derived from the selected date filter
(`lib/features/logistics/helpers/request_date_scope.dart`). `Today`, `Yesterday` and
`Tomorrow` map straight through. `5 Days Ago` and `30 Days Ago` map to `All`, because the
backend reads those two enum members as a single exact day while the app means "within the
last N days"; the client-side filter then narrows the result. The client-side
`applyFilter()` pass always runs on top of whatever the server returns.

A full-snapshot fetch (`scope == all`) replaces the table wholesale; a scoped fetch upserts
instead, so it cannot erase days it never asked for. See `cacheRequests` in each repository.

### Duplicate suppression

Each shared repository holds a `BInFlightRequests` (`lib/base/utils/helpers/`). Concurrent
calls with the same scope and flags join one HTTP round trip instead of each hitting the
network. This matters on Home, where the dashboard loads all seven tabs at once: the three
endpoint-sharing pairs used to fetch twice each. A background `_syncFromApi` is skipped
outright while a foreground fetch for the same scope is running. Joined callers receive the
same list instance, so copy before mutating.

### Home dashboard

The dashboard counts by year and month, so it needs every module's full history. It no
longer fetches that on each Home visit. `DashboardDataSource`
(`lib/features/logistics/helpers/`) reads all four request tables straight from SQLite and
normalizes them; a full server snapshot runs only when the last one is older than 15 min
(stamped in `GetStorage` under `dashboard_last_full_sync`) or on pull-to-refresh. The
controller watches whichever module controllers already exist and re-reads the cache when
their lists change, so a status update on a tab shows on Home without a fetch. It never
instantiates a controller just to observe it; only the full sync does.

Net cost of opening Home: 0 GETs while the cache is fresh, 4 when stale (see Duplicate
suppression above).

### Connectivity

`NetworkManager.isConnected()` calls `connectivity_plus.checkConnectivity()` only. It
reports whether a network interface is up, not whether the API is reachable. Captive
portals, wifi without upstream and a down backend all report online. Real offline handling
therefore lives in the `catch` blocks, not the `if (!isConnected)` blocks — and those two
branches behave differently.

## Insert / create

**Creating a request is API-first and online-only. There is no offline queue.** Every
create path opens with a connectivity gate that shows a warning snackbar and returns
without writing anywhere. The form keeps its input, so the user can retry when back online.

After a successful `201`:

| Module | Writes SQLite on create | Parses the server-assigned ID |
|---|---|---|
| Pull Out, Stock Receive, Pick Up, Air / Sea | Yes | Yes |
| Standard Delivery, Hotline Direct | No | No |

Standard Delivery and Hotline Direct rely entirely on the post-create refetch to make the
row appear locally. The other four dual-write, but the refetch overwrites that row anyway,
so the local write is mostly belt-and-braces. Local write failures are caught, logged and
deliberately ignored so they cannot fail the create.

The Collection module is the exception in the codebase: it is genuinely local-first, with a
durable pending-change queue (`SyncManager`, `a_tblCollectionPending`) and a batched
user-triggered upload.

## Update / status change

Nothing is optimistic. The local row is written only after the server confirms.

```dart
final updated = await _repository.updateDelivery(request, userInitial, ...);
if (!updated) return false;                        // server holds the old status
await _dbHelper.updateRequest(requestModel: request);
```

Pull Out and Stock Receive are the exception: `updateWithPayload` never touches SQLite at
all, so the local row only changes when the following refetch succeeds.

### Status progression guard

Each of the Standard Delivery, Air / Sea and Pick Up DAOs holds its own
`_statusStringToInt` ordinal map (a fourth, unused copy lives in `database_helper.dart`).
Before an update, the DAO reads the stored status and compares ordinals:

> If both the stored status and the incoming status are keys of that module's map, and the
> incoming ordinal is lower, the **entire row update is abandoned** — not just the status
> column.

This is what stops a stale server payload rewinding a fresher local status. Standard
Delivery routes its bulk refresh through the same guarded upsert on purpose, so a list
refresh cannot regress a row.

The guard fails silently. It is a bare `return;` in a `Future<void>`, so the caller cannot
tell "written" from "discarded" — it reports success, sends the SMS and patches the
in-memory list regardless. The UI can therefore display a status the local DB refused to
store.

## Cancel

All modules call `PATCH {resource}/cancel/{requestID}/{user}` with the remark as a bare
JSON string body. Local behaviour afterwards differs:

- **Standard Delivery / Hotline Direct** — writes the remark and status locally in a
  transaction, bypassing the progression guard (intentional for cancel).
- **Pick Up, Air / Sea** — no targeted write; they call `getAll(forceRefresh: true)`, which
  wipes and rebuilds the whole table to flip one column.
- **Pull Out, Stock Receive** — nothing at all; the row keeps its old status until the
  caller's refetch.

## Delete

- `DatabaseHelper.deleteRequest()` clears `a_tblRequest` only. Triggered by the Standard
  Delivery **or** Hotline Direct hard reset. The signature, image, image-outbox and
  document-reference tables are shared with Pick Up and Air / Sea and are deliberately left
  alone; re-downloaded requests re-attach to them by id.
- `clearLocalData()` per module clears that module's own table — and therefore its sibling
  tab's rows too.
- Every unscoped refresh implicitly deletes: `cacheRequests` runs `deleteAll()` when
  `scope == all` before reinserting.

The "cascade delete via foreign keys" comments in the Pick Up and Air / Sea DAOs are
inaccurate. Those foreign keys reference `a_tblRequest`, and sqflite leaves
`PRAGMA foreign_keys` off, so nothing cascades.

## Database lifecycle

`app.db`, version 21. `onCreate` runs `createAllTables`. `onOpen` re-runs
`ensureCollectionTables` on every open, so additively-shipped Collection tables appear on
devices already at the current version.

`onUpgrade` calls `_recreateAllTables`, which **drops and rebuilds 18 cache-backed tables**.
Both arms of its `if / else if` call the same thing, so every version bump is destructive.

The drop list is `DatabaseHelper.cacheBackedTables`; tables that must survive are listed in
`DatabaseHelper.preservedOnUpgradeTables`, and a test asserts the two never overlap.

Preserved across upgrades, all created with `CREATE TABLE IF NOT EXISTS` and kept out of the
drop list:

- `contacts` — user-entered;
- `a_tblRequestReceiverSignature` and `a_tblRequestImageOutbox` — captured signatures and
  queued proof images awaiting upload (`ensureProofUploadTables`);
- every `a_tblCollection*` table — un-uploaded collector field work
  (`ensureCollectionTables`).

If you add a table that holds anything the device captured but has not uploaded, add it to
`preservedOnUpgradeTables` and create it idempotently. Anything in `cacheBackedTables` is
destroyed on the next version bump.

## Real-time

A WebSocket exists at `/api2/ws`. It is used almost entirely **outbound** — the data
managers publish a notification after a successful write.

Inbound status messages show an OS toast and nothing else: no SQLite write, no in-memory
list update, no refetch. The `registerNotificationListener` hook exists but has no callers.
`WebSocketDeliveryController` handles rider locations for map markers in memory only; a
terminal-status frame retires the marker without touching the request row.

The practical consequence is that a device learns about another device's status change only
through a manual pull-to-refresh.

## Conflict handling

There is no timestamp comparison, no version or etag, and no merge on the request write
path. `UpdatedAt` is written to every table and never read for comparison.

Behaviour on disagreement, best to worst:

1. **Standard Delivery, Hotline Direct** — ordinal guard on both the single update and the
   bulk refresh.
2. **Pick Up, Air / Sea** — ordinal guard on the single PATCH only; list refreshes use
   `ConflictAlgorithm.replace` and overwrite unconditionally.
3. **Pull Out, Stock Receive** — no guard anywhere.
4. **Any unscoped refresh** — `deleteAll()` then reinsert, so a local-only row simply
   disappears.

## Known risks

Ordered by severity. Items 1–5 and 7 are fixed; the rest are recorded here.

1. ~~**Pick Up / Air / Sea list refresh bypasses the progression guard.**~~ Fixed. The bulk
   inserts now read stored statuses once and skip the parent-row write when the incoming
   status would regress.
2. ~~**Air / Sea never parses its server-assigned request ID.**~~ Fixed. All three create
   paths now read the id through `BApiResponse.requestId()`, which accepts every known
   spelling and logs the response body when none is present.
3. ~~**The progression guard is inert for "Getting supplies ready".**~~ Fixed. Lookups go
   through `BStatusProgression`, which matches case-insensitively; the missing map entries
   were added.
4. ~~**A version bump destroys the outboxes.**~~ Fixed. Both tables are now created
   idempotently by `ensureProofUploadTables` and excluded from the rebuild, so un-uploaded
   proof photos and signatures survive an app update.
5. ~~**Nothing flushes the image or signature outbox automatically.**~~ Fixed.
   `ProofOutboxSyncService` (`lib/data/services/outbox/`) drains both outboxes on app
   start, on connectivity regained and on app resume, throttled to one pass per 30 s and
   backing off 5 min when every item fails. It runs only while the app is open; there is
   still no OS-scheduled background job. The Developer Tools screens remain for manual
   inspection and retry.
6. **Inbound WebSocket status changes are dropped** (see Real-time above).
7. ~~**`DatabaseHelper.deleteRequest()` crosses module boundaries.**~~ Fixed. The hard reset
   now clears `a_tblRequest` only and leaves the shared support tables intact.
8. **`a_tblRequestRemarks` is keyed on `RequestID` alone** with no module discriminator.
   Request IDs are per-module sequences, so two modules sharing a number overwrite each
   other's cancel remark.
9. **Four copies of the status ordinal map** with differing contents and no shared source of
   truth.
10. **The `/api2` reference-list readers bypass the whole abstraction** — no connectivity
    check, no cache, and raw `dotenv.env['API_URL']!` instead of `BApiEnvironment`, so a
    missing `API_URL` is a crash rather than a fallback. (These were the `/api3` readers
    before that version was retired; the endpoint moved, the shortcut did not.)
