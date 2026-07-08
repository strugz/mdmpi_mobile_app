# Implementation Plan: Collection Module Backend Integration

## Overview
This document outlines the complete implementation of the Collection module for REST backend integration with offline-first support using local SQLite caching and a pending change queue for sync.

## Architecture Decision Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Backend Type** | REST API via HTTP + `dotenv` | Matches existing logistics module pattern |
| **Auth** | API key in `.env` (no Bearer header) | Simple, aligns with current codebase |
| **Offline Strategy** | Offline-first with local DB cache | Enables app functionality when network unavailable |
| **Conflict Policy** | ServerWins on refresh, ClientWins on writes | Balance between data consistency and UX |
| **Background Sync** | Foreground-triggered (add WorkManager later) | Low battery impact, sufficient for MVP |
| **Widget Scope** | Keep in `features/collection/` | User requirement for feature independence |

---

## Implementation Phases

### ✅ Phase 0: DI Wiring (COMPLETE)
**Status:** Complete  
**Objective:** Wire dependency injection properly so controllers don't instantiate repositories inline.

**Files Modified:**
1. `lib/features/collection/presentation/pages/home/home.dart`
   - Changed `Get.put(CollectionActivityController())` → `Get.find()`
2. `lib/bindings/general_bindings.dart`
   - `CollectionActivityController` already registered via `Get.lazyPut(..., fenix: true)`
   - Added import and registration for `CollectionRepository`, `SyncManager`

**Result:** Controllers now use DI; ready for repository injection.

---

### ✅ Phase 1: Local DB DAO + Repository Stub (COMPLETE)
**Status:** Complete  
**Objective:** Implement offline-first foundation with local caching.

**Files Created:**
1. `lib/data/local/db_schema.dart` (modified)
   - Added `a_tblCollectionItems` table (ID, client info, amounts, status, timestamps)
   - Added `a_tblCollectionHistory` table (history records per item)
   - Added `a_tblCollectionPending` table (pending changes queue)

2. `lib/data/local/dao/collection/collection_dao.dart` (new)
   - `getCollectionItems()` — fetch all items + history from local DB
   - `getCollectionItemById(id)` — single item fetch
   - `insertCollectionItem(model)` / `insertCollectionItems(models)` — batch insert
   - `updateCollectionItem(model)` — update with history
   - `hasCollectionItems()`, `deleteAllCollectionItems()`, `getCollectionItemCount()`
   - JSON conversion helpers (`_apiJsonToDbJson`, `_dbJsonToApiJson`)

3. `lib/data/repositories/collection/collection_repository.dart` (new)
   - Extends `GetxController` (registered in DI)
   - `getAll(forceRefresh, silent)` — offline-first read with background sync
   - `claimItemsByIds(ids)` — move items to activity
   - `saveActivity(...)` — record collection on an item
   - `saveBatchActivity(...)` — batch update multiple items
   - `refreshFromApi()`, `getLocalCollectionItems()`, `clearLocalData()`, `hasLocalData()`
   - Helper methods: `_safeGet()`, `_syncFromApi()`, `_decodeRootToList()`

**Pattern:** Repository follows logistics repositories (`PickUpRepository`, `AirSeaRepository`):
- Check network via `NetworkManager.instance.isConnected()`
- Return local cache if offline
- Background sync if online but cache exists
- Fetch from API if cache empty or `forceRefresh=true`

**Result:** Full offline-first foundation ready for API calls.

---

### ✅ Phase 2: DTOs & Mappers (COMPLETE)
**Status:** Complete  
**Objective:** Map between API JSON and domain models.

**Files Created:**
1. `lib/features/collection/dtos/collection_item_dto.dart` (new)
   - `CollectionItemDto` — mirror of API response shape
   - `fromJson()` factory for API parsing
   - `toJson()` for API requests
   - Defensive parsing: handle nullable fields, type conversions

2. `lib/features/collection/mappers/collection_mapper.dart` (new)
   - `toDomainModel(DTO)` — DTO → `CollectionItemModel` + `ClientModel`
   - `toDto(model)` — Model → DTO
   - Batch conversion helpers

**Result:** API JSON shape can differ from domain model; mapping layer isolates changes.

---

### ✅ Phase 3: Pending Queue & SyncManager (COMPLETE)
**Status:** Complete  
**Objective:** Queue and retry pending changes for reliable sync.

**Files Created:**
1. `lib/data/local/dao/collection/collection_pending_dao.dart` (new)
   - `PendingChange` model (operation, payload, itemId, createdAt, retryCount, lastRetryAt)
   - `getPendingChanges()` — fetch all pending
   - `getPendingChangesForItem(itemId)` — item-scoped pending
   - `addPendingChange(change)`, `updatePendingChange(change)`, `removePendingChange(id)`
   - `getPendingChangeCount()`, `hasPendingChanges()`

2. `lib/features/collection/helpers/sync_manager.dart` (new)
   - Extends `GetxController` (registered in DI as `Get.lazyPut(..., fenix: true)`)
   - Observable state:
     - `syncStatus` (Rx<String>): 'idle' | 'syncing' | 'failed'
     - `isSyncing` (RxBool)
     - `hasPendingChanges` (RxBool)
     - `syncErrorMessage` (RxnString)
   - `queueChange(operation, payload, itemId)` — add to pending queue
   - `trySync()` — attempt sync of all pending changes
   - `_syncChange(change, dao)` — sync one change with retry logic
   - `discardChange(id)`, `discardAllChanges()`
   - Max retries: 3, initial backoff: 5 seconds

**Result:** Pending changes persist across app restarts and retry on connectivity restore.

---

### ✅ Phase 4: Controller Updates (COMPLETE)
**Status:** Complete  
**Objective:** Make controller async-aware and repo-integrated.

**Files Modified:**
1. `lib/features/collection/presentation/controllers/collection_activity_controller.dart` (modified)
   - Added imports for `CollectionRepository`, `SyncManager`
   - Injected dependencies: `late final CollectionRepository repository`, `late final SyncManager syncManager`
   - Added observable: `final RxnString errorMessage` for UI feedback
   - `onInit()` — initialize dependencies and call `loadBucket()`
   - `loadBucket()` — new async method to fetch items from repository
   - `_loadSampleBucketItemsAsFallback()` — fallback to sample data if API fails
   - `claimItemsByIds(ids)` — now async, updates UI + calls repo
   - `saveActivity(...)` — now async, calls repo with all parameters
   - `saveBatchActivity(...)` — now async, calls repo

**Behavior:**
- Controllers use optimistic UI updates (local state first)
- Repository calls happen after (can fail silently with `silent: true`)
- UI reflects local state immediately; sync happens in background
- Errors exposed via `errorMessage` observable for snackbars

**Result:** Full async integration; UI remains responsive while sync happens in background.

---

## File Inventory

### New Files Created
```
lib/data/local/dao/collection/
  ├── collection_dao.dart
  └── collection_pending_dao.dart

lib/data/repositories/collection/
  └── collection_repository.dart

lib/features/collection/
  ├── dtos/
  │   └── collection_item_dto.dart
  ├── mappers/
  │   └── collection_mapper.dart
  └── helpers/
      └── sync_manager.dart
```

### Files Modified
```
lib/
  ├── data/local/db_schema.dart (added 3 new tables)
  ├── bindings/general_bindings.dart (registered CollectionRepository, SyncManager)
  ├── features/collection/presentation/pages/home/home.dart (DI fix)
  └── features/collection/presentation/controllers/
      └── collection_activity_controller.dart (async + repo integration)
```

---

## Compilation Status
**Status:** ✅ No errors (cleaned)  
**Warnings:** Minor info messages (deprecated API usage in other modules — not related to collection changes)

Ran: `flutter analyze lib/data/repositories/collection/ lib/data/local/dao/collection/ lib/features/collection/helpers/sync_manager.dart`

---

## Next Steps (Phase 5+)

### Phase 5: Tests & Analysis (Recommended Next)
- Unit tests for `CollectionRepository` (mock HTTP, mock DAO)
- Unit tests for `CollectionActivityController` (mock repo)
- Unit tests for `SyncManager` (mock pending DAO, mock repo)
- Run `flutter test` on all test files under `test/`
- Run full `flutter analyze`

### Phase 6: Backend Integration (When API Available)
Once backend REST endpoints are ready:

1. **Provide API Contract** — Share endpoint URLs, JSON request/response shapes, pagination format
2. **Implement HTTP Calls** — Update `_syncChange()` in `SyncManager` to actually push to server
3. **Toggle Endpoints** — Use `.env` flags to route between mock and real API
4. **Test Offline Flows** — Verify pending queue, retry logic, UI feedback

### Phase 7: Background Sync (Optional, Later)
- Add `workmanager` configuration for scheduled background sync
- Integrate with Android/iOS background modes
- Battery and permission considerations

### Phase 8: Conflict Resolution UI (Future)
- If merge conflicts occur, show UI dialog to user
- Allow manual conflict resolution if needed

---

## Key Design Decisions

### Offline-First
- Always try local DB first; reduces latency and network calls
- Background sync keeps cache fresh without blocking UI
- Pending queue ensures offline edits are not lost

### Dual-Write Pattern
- Write to local DB immediately (optimistic)
- Queue for server push asynchronously
- Gives instant UI feedback; eventual consistency with backend

### ServerWins on Refresh
- Full `getAll(forceRefresh: true)` replaces local cache with server data
- Prevents stale local data from contradicting server truth
- Users can manually trigger refresh for latest data

### ClientWins on Writes
- User-initiated saves (claim, save activity) prioritize client state
- If server rejects, user sees error; can retry or discard
- Avoids silent loss of user work

### Error Handling
- All repository methods return success/failure feedback
- Controllers expose `errorMessage` observable for UI
- Try/catch + typed exceptions from `base/utils/exceptions/`

---

## Testing Checklist (Phase 5)

- [ ] `CollectionRepository.getAll()` returns local data when offline
- [ ] `CollectionRepository.getAll(forceRefresh: true)` fetches from API and updates cache
- [ ] `SyncManager.queueChange()` adds to pending table
- [ ] `SyncManager.trySync()` processes and removes synced changes
- [ ] `CollectionActivityController.loadBucket()` loads items and updates UI
- [ ] `CollectionActivityController.claimItemsByIds()` updates local + queues
- [ ] `CollectionActivityController.saveActivity()` records history + updates state
- [ ] Error messages display properly when operations fail
- [ ] UI remains responsive during long API calls
- [ ] No console errors or warnings from analysis

---

## Deployment Readiness

### Pre-deployment Checks
- [ ] `flutter analyze` passes (no errors)
- [ ] `flutter test` all tests pass
- [ ] Cold start performance acceptable (no ANR/timeout)
- [ ] Network-on-main-thread issues resolved (all HTTP calls in async context)
- [ ] Permissions correctly declared (internet access)
- [ ] `.env` file configured with API_URL
- [ ] Data retention policy compliant (local DB cleanup if needed)

### Production Considerations
- API rate limiting and backoff strategy
- Error logging and monitoring (Firebase Crashlytics, Sentry)
- Cache invalidation strategy (timestamp, version header)
- User feedback (loading spinners, error toasts)
- Rollback plan if backend contract changes

---

## References

- **Logistics Pattern:** `lib/data/repositories/pick_up/pick_up_repository.dart` — offline-first baseline
- **Local DB:** `lib/data/local/database_helper.dart`, `lib/data/local/db_schema.dart`
- **DI Pattern:** `lib/bindings/general_bindings.dart`
- **Error Handling:** `lib/base/utils/exceptions/`
- **Logging:** `lib/base/utils/logger.dart` (`logDebug()`)
- **UI Feedback:** `lib/base/utils/popups/loaders.dart` (`BLoaders`)
- **Network Check:** `lib/base/utils/helpers/network_manager.dart`

---

## Status Summary

| Phase | Task | Status | Notes |
|-------|------|--------|-------|
| 0 | DI Wiring | ✅ Complete | Controllers use Get.find() |
| 1 | Local DB DAO + Repo | ✅ Complete | Offline-first foundation ready |
| 2 | DTOs & Mappers | ✅ Complete | API shape abstracted |
| 3 | Pending Queue + Sync | ✅ Complete | Retry logic implemented |
| 4 | Controller Updates | ✅ Complete | Async + repo integration done |
| 5 | Tests & Analysis | ⏳ Pending | Ready for unit tests |
| 6 | Backend Integration | ⏳ Waiting | Needs API contract |
| 7 | Background Sync | ⏳ Optional | Can add later |
| 8 | Conflict UI | ⏳ Future | Advanced feature |

---

## Questions for Backend Team

1. **API Endpoints** — What are the exact URLs for:
   - GET collection items (pagination format?)
   - POST/PATCH save activity
   - POST claim items
   - POST batch activity

2. **Response Format** — Expected JSON structure:
   - Top-level array, `data` key, `items` key, or other?
   - Pagination format (page/limit, offset, cursor)?
   - Error responses (HTTP status, error object format)?

3. **Authentication** — Bearer token required?
   - If yes: token endpoint, refresh strategy?
   - If no: other auth mechanism?

4. **Conflict Resolution** — If offline user edits same item as online user:
   - Always server wins?
   - Field-level merge?
   - User prompt?

5. **Rate Limiting** — Any throttling or batch size limits?

---

**Ready for Phase 5 (Tests) or Phase 6 (Backend Integration) — waiting on user direction.**

