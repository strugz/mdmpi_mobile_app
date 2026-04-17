# Air & Sea — Provincial Delivery Extension Plan

## Overview

Extend the Air/Sea module so that after a courier marks an item "Received" at the airline, a **provincial receiver** (authorized person in the destination province) continues the transaction: picks up the item from the airline and delivers it to the final client.

## Current Flow

```
New Request → Getting Supplies Ready → Item Prepared → Item Packed
```

After **Item Packed**, there are three possible paths:

```
Path A:  Item Packed → Endorsed to Guard → Received
Path B:  Item Packed → Dispatch → Drop Off
Path C:  Item Packed → Received
```

All paths converge at a terminal status (Received or Drop Off).

## Extended Flow (Provincial Delivery Leg)

After **Received** or **Drop Off** (item arrives at destination via airline), the provincial leg begins:

```
(Received or Drop Off)
  → Provincial Pick Up        (provincial receiver collects from airline)
    → Provincial In Transit   (en route to final client)
      → Provincial Delivered  (handed off to client, proof captured)
```

`Provincial Delivered` becomes the new terminal status. `Received` and `Drop Off` are no longer terminal — they trigger the provincial leg.

Capture points and required proof at each provincial stage:
- Provincial Pick Up: capture a pick-up proof image (photo of item at airline or receipt). This proof must be stored (local path/URL) and attached to the request when marking `Provincial Pick Up`.
- Provincial In Transit: capture the timestamp when the provincial actor starts the transit to the client (this becomes `provincialInTransitAt`). No proof image required at this step, but the start timestamp should be recorded automatically when the actor taps "Start Transit".
- Provincial Delivered: capture drop-off proof image (photo), the recipient name (who accepted the delivery), the recipient signature (image or signature data), and the timestamp when the drop-off occurred (`provincialDeliveredAt`). These should be required fields for confirming delivery.

### Full Flow Diagram

```
New Request
  → Getting Supplies Ready
    → Item Prepared
      → Item Packed
          ├─ Path A: Endorsed to Guard → Received ──────┐
          ├─ Path B: Dispatch → Drop Off ───────────────┤
          └─ Path C: Received ──────────────────────────┤
                                                        ▼
                                              Provincial Pick Up
                                                → Provincial In Transit
                                                  → Provincial Delivered

(Any status) → Cancelled
```

---

## Implementation Steps

### 1. Status Constants — `BTexts`

**File:** `lib/base/utils/constants/text_string.dart`

Add:

```dart
static const String statusProvincialPickUp   = 'Provincial Pick Up';
static const String statusProvincialInTransit = 'Provincial In Transit';
static const String statusProvincialDelivered = 'Provincial Delivered';
```

### 2. New Role — `BTexts` + Role Priority

**File:** `lib/base/utils/constants/text_string.dart`

```dart
static const String roleProvincial = 'Provincial';
```

**File:** `lib/features/logistics/screens/air_sea/air_sea_list.dart`

Add to `_rolePriority`:

```dart
BTexts.roleProvincial: 2, // same level as Courier, or adjust as needed
```

Update the dispatch-status force logic to also force `roleProvincial` for provincial statuses.

### 3. Model — `AirSeaModel`

**File:** `lib/features/logistics/models/air_sea_model.dart`

Add fields:

| Field | Type | Description |
|---|---|---|
| `provincialPickUpAt` | `DateTime?` | When picked up from airline |
| `provincialInTransitAt` | `DateTime?` | When status changed to Provincial In Transit (optional) |
| `provincialDeliveredAt` | `DateTime?` | When delivered to client |

Additional recommended model fields (for explicit pick-up / delivery proofs):

| Field | Type | Description |
|---|---|---|
| `provincialPickUpProofImagePath` | `String` | Proof image captured at Provincial Pick Up (local path). NOTE: image files must NOT be persisted as DB columns — save files to app storage (via `FileStorageService`) and include them in API uploads. The model may expose transient/local-path fields but these should not be added to the DB schema. |
| `provincialDeliveredProofImagePath` | `String` | Proof image captured at Provincial Delivered (drop-off photo). See note above about local file storage and API upload. |
| `provincialDeliveredReceiverSignaturePath` | `String` | File path for recipient's signature at drop-off. See note above about local file storage and API upload. |
| `provincialDeliveredReceiverName` | `String` | Name of the person who received the package at drop-off |

Update `copyWith`, `toJson`, `fromJson`, `fromDbJson`.

Notes / recommendations:
- Use `DateTime?` for timestamp fields and serialize as ISO8601 strings in DTO/DB (`toIso8601String()`).
- Keep model property names camelCase, but map to backend/DB keys consistently via the mapper.


### 4. DB Schema + Migration

**Files:** `lib/data/local/db_schema.dart`, `lib/data/local/database_helper.dart`

Summary of decision for image/signature fields
-- The three image/signature fields (`provincialPickUpProofImagePath`, `provincialDeliveredProofImagePath`, `provincialDeliveredReceiverSignaturePath`) MUST NOT be added as columns in the local DB. This matches the existing pattern used by the Standard Delivery module: images and signature files are saved to the app's local file storage (via `FileStorageService`) and uploaded to the backend by the repository (multipart or upload endpoint). The DB will therefore only persist structured/text fields (timestamps, receiver name, etc.).

Add columns to `a_tblRequestAirSea` (timestamps and textual fields only):

```sql
ProvincialPickUpAt                   TEXT DEFAULT ''
ProvincialInTransitAt                TEXT DEFAULT ''
ProvincialDeliveredAt                TEXT DEFAULT ''
ProvincialDeliveredReceiverName      TEXT DEFAULT ''
```

Database migration guidance:
- Follow the repository's existing migration pattern (increment DB version and add ALTER TABLE statements guarded so they run only once). Use nullable/empty-string values for existing rows and parse empty strings as null in the mapper.
- Do NOT add columns to store binary data or image/base64 content. Image and signature file paths are stored on disk (app documents/cache) using the project's `FileStorageService`. Reuse the Standard Delivery implementation as a reference for saving signature/image files locally and for queueing uploads.
- Repositories should handle uploading image files as part of the API call. On success the backend may return a remote URL; if the app needs to cache that remote URL it can store it in a separate sync table or attach it to the request record in a non-image DB column (for example `provincialDeliveredProofRemoteUrl`), but only store lightweight text values in the DB.
- If offline, repositories should enqueue the file upload and the status update; persist a pending-sync record (or use the project's existing pending upload queue) rather than attempting to store binary blobs in the DB.

### 5. DTOs + Mapper

**Files:**
- `lib/features/logistics/dtos/air_sea/air_sea_dto.dart`
- `lib/features/logistics/dtos/air_sea/air_sea_update_dto.dart`
- `lib/features/logistics/mappers/air_sea_mapper.dart`

Add provincial fields to DTOs. Update mapper to convert between DTO ↔ model ↔ DB columns.

Recommended DTO / JSON keys
- Use snake_case keys for API/DTO if the backend follows that convention (confirm with backend):
  - provincial_pick_up_at
  - provincial_pick_up_proof_image_path
  - provincial_in_transit_at
  - provincial_delivered_at
  - provincial_delivered_proof_image_path
  - provincial_delivered_receiver_name
  - provincial_delivered_receiver_signature_path

Mapper responsibilities:
- Convert DateTime <-> ISO8601 string.
- Treat empty string / null interchangeably for backward compatibility.
- Map DB column names (PascalCase or existing convention) to model properties in `fromDbJson`.

API/DTO image guidance:
- DTOs must include the image/signature payloads only in the API request (multipart form-data or as files) — do not rely on a persisted DB image column. The repository should attach File objects (or multipart fields) when calling the backend and may store returned remote URLs in lightweight DB fields or a dedicated sync table; do NOT add image columns for binary data.

### 6. DAO

**File:** `lib/data/local/dao/air_sea/air_sea_dao.dart`

Update insert/update/select queries to include the new timestamp/text columns (timestamps + receiver name). Do NOT include image/signature path columns in DB queries — images are saved on disk and uploaded via the repository.

### 7. Form State — `AirSeaFormState`

**File:** `lib/features/logistics/helpers/air_sea_form_state.dart`

Add:
- `provincialSignature` (Rx<Uint8List?>)

Wire into `reset()` and `dispose()`.

Notes:
- Reuse existing signature capture widget and storage utilities. Prefer storing a file path in the model/DB after saving the signature image via the project's FileStorageService.

### 8. Controller — `AirSeaController` / `AirSeaDataManager`

**Files:**
- `lib/features/logistics/controllers/air_sea_controller.dart`
- `lib/features/logistics/helpers/air_sea_data_manager.dart`

Add methods:
- `updateProvincialPickUp()` — sets status to `Provincial Pick Up`, saves signature + timestamp.
- `updateProvincialInTransit()` — sets status to `Provincial In Transit`.
  - `updateProvincialDelivery()` — sets status to `Provincial Delivered`, saves recipient name + timestamp + proof image + recipient signature.

Each builds `AirSeaUpdateDto`, calls repository, refreshes list.

Controller implementation notes:
- Controllers must call repository methods (do not call HTTP client directly). Repositories extend `GetxController` and are registered in `GeneralBindings`.
- Use `try`/`catch` and return `Result<T>` types (`Result.success(...)` / `Result.failure(...)`).
- Compress/resize images before saving/uploading. Save local file path in DTO and let repository handle uploading to remote storage if required.

### 9. Modal Config — `AirSeaModalConfig.resolve()`

**File:** `lib/features/logistics/helpers/air_sea_modal_config.dart`

- Remove `statusReceived` and `statusDropOff` from terminal/view-only guard so they become actionable for `roleProvincial`.
 - Add config entries for the provincial role (entry → action → validation → persisted fields):

| Current Status | Next Status | Button Label | Required Fields | On-press behavior |
|---|---|---|---|---|
| Received | Provincial Pick Up | "Confirm Pick Up" | Proof image | Save `provincialPickUpProofImagePath` and `provincialPickUpAt` when confirmed |
| Drop Off | Provincial Pick Up | "Confirm Pick Up" | Proof image | Save `provincialPickUpProofImagePath` and `provincialPickUpAt` when confirmed |
| Provincial Pick Up | Provincial In Transit | "Start Transit" | — | Set `provincialInTransitAt` automatically (see details) and persist status change |
| Provincial In Transit | Provincial Delivered | "Confirm Delivery" | Recipient name, recipient signature, proof image | Save `provincialDelivered*` fields and `provincialDeliveredAt` when confirmed |

Both `Received` (Path A/C) and `Drop Off` (Path B) serve as entry points into the provincial leg.

UI / controller responsibilities & validation notes:
- Enforce required fields (proof image at Pick Up; recipient name/signature/photo at Delivered) in the controller before calling the repository.
- Keep business logic out of widget `build` methods; validation, DTO creation and side-effects belong in controllers.

Detailed behavior for "Start Transit" (Provincial Pick Up → Provincial In Transit):

- Trigger: the provincial actor taps the "Start Transit" button in the modal for a request that is currently in `Provincial Pick Up`.
- Preconditions: the request must already have a saved `provincialPickUpProofImagePath` (the Pick Up step requires proof). If missing, disable the button or show an inline validation message.
- Timestamp capture: the controller must capture the current timestamp immediately when the user confirms Start Transit. Record in the model as `provincialInTransitAt` and persist as an ISO8601 UTC string (e.g., `DateTime.now().toUtc().toIso8601String()`).
- Optional location: if location permission is granted and the app collects location for transit events, also capture a `provincialInTransitLocation` (latitude/longitude) and include it with the DTO; otherwise omit.
- Atomic update: the controller should set `provincialInTransitAt` on the DTO before sending the status update. The repository call should update status and timestamp together so the backend/audit sees them as a single transition event.
- Offline behavior: if the device is offline, persist `provincialInTransitAt` locally and mark the request (or a separate sync queue entry) with a pending sync flag. The repository should attempt to sync when connectivity returns and reconcile using server timestamps if the backend overrides timestamps.
- UI feedback: disable the Start Transit button immediately after press, show a loader, and on success update the modal UI to the `Provincial In Transit` state and display the recorded `provincialInTransitAt` timestamp. On failure, re-enable the button and show a user-friendly error.
- History/audit: push a history event (local cache and, if possible, the backend) recording: actorId, actorRole (`roleProvincial`), action `Provincial In Transit (Start)`, `provincialInTransitAt`, optional location, and any attached proof references.

Specific validation rules for provincial flow (summary):
- When transitioning Request -> `Provincial Pick Up`: require `provincialPickUpProofImagePath` (photo proof). Block transition if missing and show user-friendly message.
- When transitioning `Provincial Pick Up` -> `Provincial In Transit`: require that the Pick Up proof exists; set `provincialInTransitAt` automatically when user taps "Start Transit" and include it in the update DTO.
- When transitioning `Provincial In Transit` -> `Provincial Delivered`: require `provincialDeliveredProofImagePath`, `provincialDeliveredReceiverName` and `provincialDeliveredReceiverSignaturePath`. Save `provincialDeliveredAt` as the delivery timestamp.

DTO / Mapper notes (modal-driven updates):
- `AirSeaUpdateDto` should include `provincial_in_transit_at` (ISO8601 string) when transitioning to `Provincial In Transit`.
- Mapper must accept null/empty strings and convert to/from `DateTime?` on the model.
- When offline, enqueue the DTO update with the timestamp and pending-upload metadata so the repository can reconcile with server state on sync.


### 10. UI Widgets

**New files under** `lib/features/logistics/screens/air_sea/widgets/`:

- `air_sea_provincial_pick_up_section.dart` — shows logged-in user as receiver + proof image note.
- `air_sea_provincial_delivery_section.dart` — client contact input + delivery timestamp + remarks.

Widget requirements:
  - `air_sea_provincial_pick_up_section.dart` should include an image picker / camera control and show an inline preview of `provincialPickUpProofImagePath`.
- `air_sea_provincial_delivery_section.dart` should include fields for `provincialDeliveredReceiverName`, a signature capture control (reusing `SignatureCaptureDialog`), a camera/image picker for `provincialDeliveredProofImagePath`, and display the `provincialDeliveredAt` timestamp after confirmation.
- The modal submit buttons should be disabled until required proof fields are present. Validation logic must run in controller.

**Update:** `air_sea_modal.dart` — conditionally show provincial sections based on status. All non-empty details from prior statuses (waybill number, dispatch info, etc.) remain visible during provincial statuses — the provincial user sees the same request details that were visible at "Received" or "Drop Off", plus the new provincial-specific fields.

UI recommendations:
- Reuse shared widgets for images, signatures, and delivery details (`SignatureCaptureDialog`, `BDeliveryDetailsSection`, image picker). Search `lib/base/utils` and `lib/common/widgets` first and extend if necessary.
- Provincial form sections should be small subtrees wrapped in `Obx` to observe only the fields that change.

**Update:** `air_sea_modal_header.dart` — During provincial statuses, only show: **Preparation Details**, client info, and status chip. Guard Endorsement and Drop Off details sections are hidden (not relevant to the provincial user).

**Update:** `air_sea_request_modal_footer.dart` — Receipt Details section (`BDeliveryDetailsSection`) now also displays during provincial statuses, not only at "Received".

**Update:** `air_sea_modal.dart` — Document References remain visible during provincial statuses (already handled by `RequestModalScaffold`). Provincial-specific fields (receiver, delivered-to) are shown when populated.

### 11. Status Colors — `StatusColorMapper`

**File:** `lib/features/logistics/helpers/status_color_mapper.dart`

Add entries:

| Status | Suggested Color |
|---|---|
| Provincial Pick Up | Teal |
| Provincial In Transit | Indigo |
| Provincial Delivered | Dark Green |

Use existing `BColors` constants where appropriate. If new colors are needed add them in `lib/base/utils/constants/b_colors.dart`.

### 12. List Screen Guards — `air_sea_list.dart`

**File:** `lib/features/logistics/screens/air_sea/air_sea_list.dart`

- Update `onLongPress` guard: replace `statusReceived` with `statusProvincialDelivered` as the terminal status.
- Add provincial status force logic (similar to dispatch force for Courier).

Recommendation:
- Maintain a single canonical list of terminal statuses used by list screens and modals to avoid inconsistencies. Update it in one place (for example in the modal config or a central status constants helper) and reuse across screens.

### 13. Filter Manager

**File:** `lib/features/logistics/helpers/air_sea_filter_manager.dart`

Add the three new statuses to the available filter options.

Ensure the filter UI labels match `BTexts` constants and the filter logic uses internal status keys.

--

## Transaction history & audit trail

Describe how the full Air/Sea transaction history will be loaded and displayed so stakeholders can identify everything that happened during delivery. Suggested approach and implementation notes:

- Source of truth: prefer a backend audit/history endpoint that returns an ordered list of events for a request (e.g., GET /requests/{id}/history). Each event should include: `eventId`, `requestId`, `timestamp` (ISO8601), `status` (old/new or single status), `actorId`, `actorName`, `actorRole`, `remarks`, `location` (optional lat/lng), `proofImagePath` (optional), `signaturePath` (optional), and a `meta` JSON object for extensibility.

- DTO & Mapper: add `RequestHistoryDto` / `RequestHistoryModel` objects and map them in `air_sea_mapper.dart` (or a shared mapper). Store timestamps as `DateTime` in the model.

- Local cache: persist history entries in a local table (e.g., `a_tblRequestHistory`) or reuse an existing remarks/history table. Schema suggestion:
  - Id TEXT PRIMARY KEY
  - RequestId TEXT
  - Timestamp TEXT
  - Status TEXT
  - ActorId TEXT
  - ActorName TEXT
  - ActorRole TEXT
  - Remarks TEXT
  - ProofImagePath TEXT
  - SignaturePath TEXT
  - Location TEXT (JSON or lat/lng)
  - Meta TEXT (JSON)

- Loading strategy:
  - On request modal open: load the most recent N history items from local DB immediately for fast UI, then fetch the canonical history from backend and merge (de-duplicate by eventId), updating the local cache.
  - Provide a "Load more history" control to lazily fetch older events if the history is long.
  - When offline, show cached history and mark any local-only events as pending sync.

- UI presentation:
  - Show a timeline view in `air_sea_modal.dart` or a separate `RequestHistorySection` widget. Group events by day, show time, actor name/role, status chip, remarks, and inline thumbnails for proof images/signatures.
  - Allow tapping a thumbnail to open a full-screen viewer (reuse existing image viewer widget). For signature images, show who signed and the timestamp.
  - Highlight key transition events (e.g., Received → Provincial Pick Up, Start Transit, Delivered) with status color and an icon.

- Security & privacy:
  - Ensure only authorized users can fetch full history (backend authorization). Mask sensitive information in the UI when the current user is not permitted.
  - Sanitize/validate any remote URLs before rendering.

- Backend considerations:
  - The backend should emit structured history events when status changes or when proofs/signatures are added. If possible, include a `createdBy` and `createdAt` on each event.
  - Consider supporting incremental history fetches (since=timestamp) for efficient sync.

- Tests:
  - Unit tests for mapper/DAO round-trip of history entries.
  - Widget tests for the timeline UI with mixed event types (status change, image proof, signature).
  - Integration tests that exercise merging remote history with local cache and handling duplicate events.

Implementing the history/audit trail as a first-class entity will make troubleshooting and QA much easier and also provide a clear place to attach proof images and signatures for each step.

## Decisions Needed / Confirm with Backend

Before implementing DTOs/mapper/repository changes confirm the following with the backend team:
- Exact API field names and casing (the recommended keys above are snake_case but may differ).
- Whether images should be uploaded to cloud storage (Firebase Storage or other) and whether the API expects a remote URL in the DTO or a multipart upload endpoint.
- Whether to store the provincial actor's identity as a user ID (preferred) or also persist a display name.
- Whether `provincial_proof_image` is required for `Provincial Delivered` (plan recommends required) and whether the backend will enforce this.

--

## Offline / Sync considerations

- If the app supports offline mode, ensure provincial updates are queued and synchronized when online. The repository should mark records with a pending sync flag and handle conflicts on sync.
- Show visual indicators for pending sync and for sync errors.

--

## Image & signature handling

- Reuse existing FileStorageService and image utilities. Compress images before saving. Store file paths or remote URLs in the DB; avoid storing large base64 strings in table columns.

Additional handling notes:
- Keep separate file paths for pick-up proof and drop-off proof (`provincialPickUpProofImagePath` vs `provincialDeliveredProofImagePath`).
- Store recipient signature as an image file and save the path in `provincialDeliveredReceiverSignaturePath`.
- Consider adding a small, indexed `pending_upload` flag or sync queue entry for image uploads so that images taken offline are uploaded later and the remote URL is persisted by the repository on successful upload.

BDropOffCapture usage and implications
- The codebase uses a shared camera review widget, `BDropOffCapture` (located at `lib/features/logistics/screens/request_transport/widgets/b_drop_off_capture.dart`) for capturing proof images. Observed behavior:
  - `BDropOffCapture` itself captures a temporary image for review using `CameraHandlerController.takePictureForReviewWithAnimation()` and shows `BPhotoReviewScreen`.
  - When the user confirms the review, `BDropOffCapture` calls the `onCapture` callback provided by the caller: `await widget.onCapture(cameraController);` and then closes the screen.
  - In most callers the provided `onCapture` is `camera.takePictureWithAnimation(requestId)`, which performs a second capture and saves the resulting file via `BImageHelperFunctions.saveImage(...)` and sets `CameraHandlerController.imageProofPath`.

Implications for provincial flow design
- Images are only persisted to local storage when the `onCapture` callback executes; the temporary path shown during review is not automatically saved unless the caller's `onCapture` implementation does that explicitly.
- Current project pattern: callers pass `camera.takePictureWithAnimation(requestId)` as `onCapture`, which results in a fresh capture on confirm (double-capture). This is an established pattern in the repo and is safe but may be surprising: the reviewed photo is not saved — a new photo is taken and saved when the user confirms.

Recommendations (choose one, document in implementation tasks)
1. Keep the existing pattern (recommended for minimal changes):
   - Use `BDropOffCapture` with `onCapture: (camera) => camera.takePictureWithAnimation(requestId)` in provincial pick-up/delivery flows. After confirm, read `CameraHandlerController.imageProofPath` for the saved local file path and include that path in the DTO for upload handling by the repository.
2. Improve UX by saving the reviewed image instead of re-capturing (optional refactor):
   - Modify `BDropOffCapture` to pass the reviewed `capturedImagePath` into the `onCapture` callback (e.g., `onCapture(camera, capturedImagePath)`), and add an overload or small wrapper so callers can save the reviewed file instead of triggering a second capture. Update callers accordingly.

Implementation note for this plan: to remain consistent with the rest of the codebase and reduce scope, the provincial flow in this plan will follow option (1) — use `BDropOffCapture` with `camera.takePictureWithAnimation(...)` as `onCapture` and rely on `CameraHandlerController.imageProofPath` for the saved local path.

--

## Tests & QA

 - DAO: add round-trip read/write tests for new DB columns (timestamps and receiver name).
 - Mapper: tests for DTO ↔ model ↔ DB JSON mappings (exclude image/signature DB columns).
 - Controller: unit tests for `updateProvincialPickUp`, `updateProvincialInTransit`, `updateProvincialDelivery` using mocked repository.
 - Widget tests: modal shows/hides provincial sections and validation behaves correctly.
 - Run `flutter analyze` and `flutter test` before submitting PR.

Additional tests for proofs & signatures:
 - File system tests: verify that `provincialPickUpProofImagePath`, `provincialDeliveredProofImagePath`, and `provincialDeliveredReceiverSignaturePath` are saved to the app's local storage (via `FileStorageService`) and that the repository enqueues/uploads them to the backend correctly.
 - Controller tests: ensure transitions validate required proofs and timestamps are recorded (`provincialInTransitAt`, `provincialDeliveredAt`).
 - Integration test: simulate pick-up -> start transit -> delivery flow including image/signature capture (mock file system or use test fixtures) and assert repository calls, local DB updates (timestamps/receiver name), and upload queue behavior.

Use the generator for a QA checklist:
```
dart run bin/generate_module_qa.dart --name "Air Sea Provincial" --area Logistics --routes "/air-sea"
```

--

## Edge cases & gotchas

- Migration: make ALTER TABLE operations idempotent and guard them by DB version; parse empty strings as null when converting to DateTime.
- Multiple actors updating the same request: backend must define conflict resolution. UI should handle 409/409-like responses by refreshing and showing an explanatory message.
- Date parsing: be defensive — accept null, empty string, and properly formatted ISO strings.
- Role checks: only show provincial actions to users with `roleProvincial` (or allowed departments); backend should also enforce authorization.

--

## Minimal developer checklist (implementation order)
1. Confirm API field names with backend.
2. Add BTexts constants for the three statuses and `roleProvincial`.
3. Update `AirSeaModel` with fields + copyWith/toJson/fromJson/fromDbJson.
4. Update `db_schema.dart` and add safe ALTER TABLE migration in `database_helper.dart`.
5. Update DTOs and `air_sea_mapper.dart` to include provincial fields.
6. Update DAOs to include the new columns.
7. Update repository to persist provincial fields and handle image upload/storage.
8. Add controller methods and wire up validation.
9. Update modal config and UI widgets; reuse existing shared widgets where available.
10. Update `status_color_mapper.dart`, `air_sea_list.dart`, and filter manager.
11. Add unit/DAO/mapper/controller/widget tests and run `flutter analyze` + `flutter test`.

If you want, I can apply a first-pass patch to the codebase (constants, model, db schema note) and add unit-test scaffolding — tell me which files you'd like me to edit first.

---

## Decisions Needed Before Implementation

| # | Question | Recommendation |
|---|---|---|
| 1 | New `roleProvincial` or reuse existing role? | **New role** — distinct actor, cleaner separation |
| 2 | API field names for provincial columns? | Confirm with backend team before DTO work |
| 3 | Can provincial receiver see full request history? | Yes (read-only for prior statuses) |
| 4 | Is proof image required for Provincial Delivered? | Recommend required |
| 5 | Should provincial statuses appear in existing filter chips? | Yes, appended to the filter list |

---

## Testing

- **DAO:** Round-trip read/write for new columns
- **Mapper:** Provincial field mapping DTO ↔ model
- **Controller:** Status transition logic (Received → Provincial Pick Up → In Transit → Delivered)
- **QA checklist:** Generate via `dart run bin/generate_module_qa.dart --name "Air Sea Provincial" --area Logistics --routes "/air-sea"`

---

## File Change Summary

| File | Change |
|---|---|
| `text_string.dart` | Add 3 status constants + 1 role constant |
| `air_sea_model.dart` | Add provincial timestamp fields and transient image-path fields (images/signatures stored on disk; do NOT add image columns to DB) |
| `db_schema.dart` | Add 3 timestamp/text columns to `a_tblRequestAirSea` (timestamps + receiver name). Do NOT add image/signature path columns. |
| `database_helper.dart` | Add ALTER TABLE migration |
| `air_sea_dto.dart` | Add provincial fields |
| `air_sea_update_dto.dart` | Add provincial fields |
| `air_sea_mapper.dart` | Map provincial fields |
| `air_sea_dao.dart` | Update queries |
| `air_sea_form_state.dart` | Add provincial form controllers |
| `air_sea_controller.dart` | Add 3 provincial update methods |
| `air_sea_data_manager.dart` | Support provincial updates |
| `air_sea_modal_config.dart` | Add provincial role configs |
| `air_sea_modal.dart` | Show provincial sections |
| `air_sea_list.dart` | Update guards + role priority |
| `air_sea_filter_manager.dart` | Add provincial statuses to filters |
| `status_color_mapper.dart` | Add 3 color entries |
| **New:** `air_sea_provincial_pick_up_section.dart` | Pick-up UI |
| **New:** `air_sea_provincial_delivery_section.dart` | Delivery UI |


