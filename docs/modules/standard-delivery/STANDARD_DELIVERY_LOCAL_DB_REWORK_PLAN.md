# Standard Delivery Local DB Rework Plan

## Purpose

This plan covers the rework of the Standard Delivery local database layer to match the current request lifecycle, status handling, and offline-first synchronization behavior.

The goal is to keep Standard Delivery fully usable on Android and Windows even when network connectivity is unstable, while aligning the SQLite schema and DAO logic with the current controller/data-manager flow.

## Current Local DB Role

The local database currently acts as:

- storage for all data fetched from the API
- offline support for Standard Delivery requests
- a local update buffer that can be sent to the server later
- persistent storage for request metadata and related records
- a recovery store for media such as signatures and delivery images
- a source for list loading, filtering, and status counts

## How the DAO Uses the Local Tables

Based on `lib/data/local/dao/standard_delivery/standard_delivery_dao.dart`, the Standard Delivery local DB is used in these ways:

- `a_tblRequest` stores the main request row, including status, timestamps, client, delivery details, driver/helper, mobile, trip ticket, category IDs, and receiver fields.
- `getRequests()` reads from `a_tblRequest`, joins `a_tblMobile` for `MobileName`, and then enriches each record with client and document reference data.
- When a request is cancelled, the DAO writes the cancellation remarks into `a_tblRequestRemarks` and updates the request status to `Cancelled`.
- `insertRequest()` and `insertRequests()` persist API-fetched request data locally so the app can reuse it offline.
- `updateRequest()` writes status progress and other field updates back to `a_tblRequest`, but prevents backward status movement by comparing the current stored status with the new one.
- `a_tblRequestDocumentReference` stores one row per document reference for each request.
- `a_tblRequestReceiverSignature` stores the receiver signature and supports delayed sync if upload fails.
- `a_tblRequestImage` stores delivery proof images for later recovery or upload.
- `ACCMST_` caches client details so the client can still be resolved from the local DB.
- `a_tblMobile` provides the local mobile name lookup used in request display.

In short, the local tables are not only a cache: they are the offline copy of the fetched API data, the place where local edits are saved, and the buffer used to sync changes to the server later.

## Reusable Pattern for Other Logistics Modules

The same local DB concept should be used as the baseline for these logistics modules as well:

- `Pull Out / Return`
- `Pick Up`
- `Air / Sea`

For each module, the local tables should follow the same core idea:

- store all request data fetched from the API
- support offline viewing and editing
- keep local changes until they can be synced later
- preserve related records such as remarks, references, and media
- use the local DB as the offline copy of the server data, not just a temporary cache

This means the Standard Delivery DAO behavior should be treated as the reference pattern when reviewing the DAO and schema design for those modules.

`Back Load` is not part of this local DB rework. Based on the BackLoad module notes, it is handled as an API-first flow, with local history only when BackLoad history already exists. When a request is reprocessed through BackLoad, the request status returns to `New Request`, only `deliveryDate` is changed, and the rest of the request data is treated as a newly requested Standard Delivery record. For this plan, the local DB scope remains Standard Delivery only.

## Why the Rework Is Needed

The Standard Delivery flow has evolved, and the local DB layer must stay consistent with:

- the current status lifecycle
- new or changed fields used by the controller and form state
- media upload and fallback behavior
- request filtering and dashboard counts
- offline updates that are later synced back to the server

## Target Status Flow

The local DB must support the current Standard Delivery flow:

```text
New Request
  → Getting supplies ready
    → Item Prepared
      → For Delivery
        → Delivered

(Any status) → Cancelled
```

## Existing Local DB Tables In Scope

The rework should review and confirm the purpose of these tables:

- `a_tblRequest` — main request row and status history anchor
- `a_tblRequestDocumentReference` — request document references
- `a_tblRequestRemarks` — cancellation remarks

## Rework Objectives

1. **Align schema with current request model**
   - Verify all fields required by `StandardDeliveryModel` are stored locally.
   - Keep request-level metadata, timestamps, assignees, and media references in sync.

2. **Preserve offline-first behavior**
   - Continue to load from local DB first when enabled.
   - Continue to fall back to the API when local data is empty.
   - Continue to persist API results locally for later reuse.

3. **Make status updates safe and consistent**
   - Ensure local updates follow the same status order as the app UI.
   - Prevent invalid backward status movement.
   - Preserve cancellation as a terminal state.

4. **Support media recovery and delayed sync**
   - Keep signature and image data locally if upload fails.
   - Preserve API sync status for retries.

5. **Reduce schema drift**
   - Keep DAO, model mapping, and controller/data-manager logic aligned.
   - Avoid hidden dependencies on old field names or outdated status labels.

6. **Apply the same pattern to related logistics modules**
   - Reuse the Standard Delivery local DB approach for Pull Out / Return, Pick Up, and Air / Sea.
   - Ensure each module has the same offline-first flow: fetch, store locally, update locally, and sync later.
   - Keep module-specific tables and attachments aligned with their own request lifecycle.

## Proposed Work Plan

### Phase 1 — Audit the Current Local DB Contract

- Review `lib/data/local/db_schema.dart`
- Review `lib/data/local/dao/standard_delivery/standard_delivery_dao.dart`
- Review `lib/features/logistics/models/standard_delivery_model.dart`
- Review `lib/features/logistics/helpers/standard_delivery_data_manager.dart`
- Review `lib/features/logistics/controllers/standard_delivery_controller.dart`

Deliverable:
- a clear mapping of model fields ↔ SQLite columns ↔ API fields

### Phase 2 — Verify Status and Lifecycle Mapping

- Confirm the canonical status labels used by the UI and controller
- Confirm which statuses should be persisted locally
- Confirm how cancellation is stored and reloaded
- Confirm whether any legacy status names still exist in DB data

Deliverable:
- a status mapping table for UI, model, and local DB

### Phase 3 — Review Schema Coverage

- Check whether `a_tblRequest` contains every field needed by the current workflow
- Check whether media tables support the current signature/image sync flow
- Check whether request remarks and client cache tables are still sufficient
- Identify any fields that should be added, renamed, or deprecated

Deliverable:
- schema gap list
- migration recommendations

### Phase 4 — Update DAO Behavior

- Ensure local inserts and updates match the latest `StandardDeliveryModel`
- Keep request status progression rules in the DAO consistent with the app flow
- Ensure document references, signature, and proof image tables are updated correctly
- Ensure cancellation writes both status and remarks locally

Deliverable:
- DAO methods aligned with current request lifecycle

### Phase 5 — Rework Sync and Fallback Behavior

- Confirm how `StandardDeliveryDataManager` loads from local DB vs API
- Confirm that updates persist locally after server sync
- Confirm that offline updates show a warning but remain available locally
- Confirm that media retry data is preserved if upload fails

Deliverable:
- stable offline/online sync rules for Standard Delivery

### Phase 6 — Validate UI Dependencies

- Confirm list counts still match local DB status values
- Confirm filters still work with the loaded local data
- Confirm request detail modal reads the correct locally cached fields
- Confirm cancelled and delivered states render correctly from cached data

Deliverable:
- no UI regressions after DB rework

### Phase 7 — Testing and Verification

- Test fresh API sync into the local DB
- Test local-only request loading
- Test status transitions in order
- Test cancellation flow with remarks
- Test signature and proof image fallback storage
- Test DB behavior on Android and Windows

Deliverable:
- validated local DB flow across supported platforms

## Migration Considerations

If schema changes are required, the rework should include:

- backward-compatible migration steps
- safe handling of existing `a_tblRequest` rows
- preservation of document references and media records
- a fallback path for older cached rows with missing fields

## Risks

- breaking current offline loads if schema changes are not migrated carefully
- losing media data if signature/image fallback logic is changed incorrectly
- status mismatch between UI labels and SQLite records
- breaking old cached records if field names or status labels are renamed too aggressively

## Success Criteria

The rework is complete when:

- Standard Delivery can load fully from local DB
- offline updates remain usable and recoverable
- request statuses stay consistent across UI, controller, DAO, and storage
- cancellation and media fallback data persist correctly
- Android and Windows behavior remains stable

## Suggested Next Step

After this plan is approved, the next step should be a detailed audit of:

- `db_schema.dart`
- `standard_delivery_dao.dart`
- `StandardDeliveryModel`
- `StandardDeliveryDataManager`

That audit should produce the exact schema changes needed before any code is modified.




