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
| `provincialDeliveredReceiverName` | `String` | Name of the person who received the package at drop-off |
| `provincialPickUpBy` | `String` | Identifier (name or userId) of the provincial actor who performed the pick-up |


Additional recommended model fields (for explicit pick-up / delivery proofs):

| Field | Type | Description |
|---|---|---|
| `provincialPickUpProofImagePath` | `String` | Proof image reference for Provincial Pick Up. The data may be provided by the API (remote URL) and the app may save a local copy when the user captures/posts the proof. Do NOT add a DB column for binary data; treat any local-path field as transient and map it in DTOs only. |
| `provincialDeliveredProofImagePath` | `String` | Proof image reference for Provincial Delivered (drop-off photo). Same pattern as pick-up: the API provides the resource and when the user posts/saves a proof the app stores a local copy (via `FileStorageService`) but does not persist binary blobs in DB columns. |
| `provincialDeliveredReceiverSignaturePath` | `String` | Signature reference for recipient at drop-off. THIS FIELD WILL NOT BE SAVED TO LOCAL STORAGE — signatures are loaded from the API for display. If the UI captures a signature to send to the backend, do not persist its path to the DB; send it as part of the API payload and discard local temporary files (or keep only in-memory/temp cache per app policy). |

Note: the GET endpoints that surface these resources currently return raw PNG images (content-type: image/png). Implementations should therefore accept either a remote URL (that can be downloaded) or a direct image endpoint returning image/png; handle binary responses by saving to a temp/local file via `FileStorageService` or rendering directly from bytes (`Image.memory`) as appropriate for the UI.

Update `copyWith`, `toJson`, `fromJson`, `fromDbJson`.

Notes / recommendations:
- Use `DateTime?` for timestamp fields and serialize as ISO8601 strings in DTO/DB (`toIso8601String()`).
- Keep model property names camelCase, but map to backend/DB keys consistently via the mapper.


### 4. DB Schema (no runtime migration — early-phase app)

**Files to update:** `lib/data/local/db_schema.dart` (primary) — do not implement runtime ALTER TABLE migrations in `database_helper.dart` for now.

Rationale
- This project is still in an early phase. Instead of adding guarded ALTER TABLE migrations that run at runtime, update the canonical DB schema source (`db_schema.dart`) so new installs (and developer builds) include the provincial columns from the initial schema. This keeps the local DB simple during early development and avoids migration complexity. When the app reaches production / stable releases, convert this to a proper migration plan if needed.

Summary of decision for image/signature fields
- The three image/signature fields behave differently and MUST NOT be persisted as binary columns in the local DB. Follow these rules:
  - `provincialDeliveredReceiverSignaturePath`: do NOT save this signature to local storage. Signatures for delivered receiver are obtained from the API for display; if the app collects a signature to send to the backend, submit it in the API call but avoid persisting the path in the local DB or long-term file storage.
  - `provincialPickUpProofImagePath` and `provincialDeliveredProofImagePath`: these two proof images are provided and loaded via the API for display (the API may return remote URLs). When the user captures/posts a proof image (via the app), save a local copy using `FileStorageService` so the app can show a thumbnail offline and include the file in multipart uploads. Do NOT add DB columns for binary/image blobs; store only lightweight text (e.g., remote URL or local path if you need short-term caching) and handle persistence via file storage + sync queue.
      - `provincialPickUpProofImagePath` and `provincialDeliveredProofImagePath`: these two proof images are provided and loaded via the API for display. The current API surfaces these resources as PNG binary responses (content-type: image/png) or as URLs that resolve to PNGs. When the user captures/posts a proof image (via the app), save a local copy using `FileStorageService` so the app can show a thumbnail offline and include the file in multipart uploads. Do NOT add DB columns for binary/image blobs; store only lightweight text (e.g., remote URL or local path if you need short-term caching) and handle persistence via file storage + sync queue.

Schema change (add directly to canonical schema)
- Add the following columns to the `a_tblRequestAirSea` table definition in `db_schema.dart` (timestamps and textual fields only). Use empty-string defaults or nullable TEXT as preferred by the project's schema conventions:

```sql
ProvincialPickUpAt                   TEXT DEFAULT ''
ProvincialInTransitAt                TEXT DEFAULT ''
ProvincialDeliveredAt                TEXT DEFAULT ''
ProvincialDeliveredReceiverName      TEXT DEFAULT ''
ProvincialPickUpBy                   TEXT DEFAULT ''
```

Notes and developer guidance
- Do NOT add columns that store binary data or base64-encoded images. Store file paths (if needed transiently) only in memory or in DTOs; persist any returned remote URLs as lightweight TEXT fields if backend returns them.
- Update DAO queries and `fromDbJson` / `toDbJson` mappings to read these new columns; treat empty string values as null when converting to `DateTime?`.
- Because we're changing the canonical schema rather than performing a runtime migration, developers should:
  - Recreate their local DB (uninstall/reinstall or delete the app DB) after pulling this change during development to obtain the updated schema.
  - Document this behavior in a short dev note in the PR so reviewers understand that no runtime migration was added intentionally.
- When the project stabilizes, replace the direct-schema approach with idempotent ALTER TABLE migrations in `database_helper.dart` and bump the DB version — follow the repository's existing migration pattern at that time.

Offline and upload behavior
- Repositories should continue to enqueue image uploads and status updates if offline; use the existing pending-upload/sync queue pattern rather than attempting to store files in the DB.


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
  - provincial_pick_up_by
  - provincial_in_transit_at
  - provincial_delivered_at
  - provincial_delivered_proof_image_path
  - provincial_delivered_receiver_name
  - provincial_delivered_receiver_signature_path

Mapper responsibilities:
- Convert DateTime <-> ISO8601 string.
- Treat empty string / null interchangeably for backward compatibility.
- Map DB column names (PascalCase or existing convention) to model properties in `fromDbJson`.
  - Map `provincial_pick_up_by` (DTO/JSON) <-> `ProvincialPickUpBy` (DB column) <-> `provincialPickUpBy` (model).

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

Recommended approach: reuse and extend the existing `updateRequestStatus` method in `AirSeaDataManager` rather than adding three separate provincial-only methods.

Rationale
- `AirSeaDataManager.updateRequestStatus(...)` already implements the established patterns for status transitions in this module: it builds an updated model via `copyWith`, handles timestamps, uploads signatures and proof images (with offline handling), converts the model to a DTO via `AirSeaMapper.toUpdateDto(...)`, calls `_repository.updateWithPayload(...)`, and refreshes the controller list. Reusing this single method keeps status-transition behavior consistent and centralizes upload/validation logic.

What to change
- Extend `updateRequestStatus` to recognise the new provincial statuses (`statusProvincialPickUp`, `statusProvincialInTransit`, `statusProvincialDelivered`) and to populate the appropriate fields already added to the `AirSeaModel` (for example: `provincialReceiverName`, `provincialPickUpAt`, `provincialInTransitAt`, `provincialDeliveredAt`, `provincialDeliveredReceiverName`, `provincialRemarks`). The method already contains hooks for signature and proof upload; align those hooks to handle provincial-specific proof/signature sources (formState fields and `CameraHandlerController.imageProofPath`).

Controller responsibilities
- Keep `AirSeaController` thin. Reuse the existing controller helper `updateStatusWithInputs(...)` (it already wraps `dataManager.updateRequestStatus`) to perform provincial transitions from the UI layer. This keeps call-sites consistent and centralizes loader/error handling. Example usage:
  - `onConfirmProvincialPickUp(AirSeaModel request)` → call `updateStatusWithInputs(request, BTexts.statusProvincialPickUp)`
  - `onStartProvincialTransit(AirSeaModel request)` → call `updateStatusWithInputs(request, BTexts.statusProvincialInTransit)`
  - `onConfirmProvincialDelivery(AirSeaModel request)` → call `updateStatusWithInputs(request, BTexts.statusProvincialDelivered)`
These small UI handlers only need to validate formState preconditions (e.g., proof image present) before delegating to `updateStatusWithInputs` which calls `dataManager.updateRequestStatus` under the hood.

Validation and UI rules
- Keep validation in the controller/formState layer (e.g., ensure the proof image exists before calling the data manager), or let `updateRequestStatus` perform defensive checks and return a failure result. Use `BLoaders` / `BFullScreenLoader` for consistent UX and `BLoaders.warningSnackBar` for offline messaging (follow the pattern already used in `updateRequestStatus`).

Return types
- `updateRequestStatus` returns void today (updates the controller directly). If you prefer explicit success/failure semantics, consider refactoring it to return `Result<bool>`; otherwise use the existing pattern (it updates controller state and shows snackbars) and keep controller wrappers async `Future<void>` that await the data manager call.

Implementation note
- This approach reduces code duplication, centralises upload/queue/offline logic, and leverages the existing `AirSeaDataManager` code paths that already correctly handle signatures and proof images. Only small additions are required: recognise the new status constants and add any provincial-specific field mapping in the `copyWith` block (the current `updateRequestStatus` already contains several `provincial*` fields—verify and finish any missing mappings).

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


### 10. UI Widgets (simplified)

Design goals
- Keep provincial UI minimal and predictable: each provincial status (Pick Up, In Transit, Delivered) is presented as a clearly labelled section separated by a divider so users can quickly identify the active stage.
- Only show the minimal input controls required to complete the active status. After a status is completed, show its inputs as a readonly summary so the user can verify prior steps without confusion.

Structure & placement
- Implement three small section widgets under `lib/features/logistics/screens/air_sea/widgets/`:
  - `air_sea_provincial_pick_up_section.dart` — captures pick-up proof and shows pick-up summary after confirm.
  - `air_sea_provincial_in_transit_section.dart` — shows Start Transit button and in-transit summary after start.
  - `air_sea_provincial_delivery_section.dart` — captures delivery inputs (recipient name, signature, proof) and shows delivery summary after confirm.

Divider & summary behavior
- Use the project's section divider (`BTextDivider`) or a thin `Divider` at the top of each section with the status title (e.g., "Provincial Pick Up"). This visually separates stages and makes scanning simple.
- Each section contains two modes:
  1. Active/edit mode — show only the required inputs and action button(s) for that status.
  2. Summary/read-only mode — after successful completion of the status, replace inputs with a compact readonly summary showing the captured values (timestamp, actor name, proof thumbnail, signature preview, remarks). Use `BLabelValueText` rows and `CapturedSignatureImage`/image thumbnail widgets for previews.

Visibility rules and previous-status visibility
- When a section becomes active, it should display its inputs plus a compact readonly summary of all previous provincial stages above or below it (not editable). For example:
  - When "Provincial In Transit" is active, show readonly Pick Up summary (pick-up timestamp, pick-up by, proof thumbnail) and the Start Transit control.
  - When "Provincial Delivered" is active, show readonly Pick Up and In Transit summaries and the delivery inputs.
- This guarantees users always see prior inputs and reduces confusion about what was already recorded.

Interaction patterns
- Keep each section self-contained and small (<= 6 visible elements). Wrap only the minimal bits in `Obx` so updates are efficient.
- Disable the action button for the active section until validation passes (e.g., proof image present, recipient name/signature required for Delivered).
- After a successful action, show a brief confirmation snackbar and immediately switch the section to summary mode.

Reuse & widgets to prefer
- Dividers: `BTextDivider` (consistent with project style).
- Readonly rows: `BLabelValueText` for label/value display.
- Image capture/preview: `BDropOffCapture` for capture; use `CameraHandlerController.imageProofPath` and a small preview widget for thumbnails.
- Signature preview: `CapturedSignatureImage` (existing) for loaded signature images; `SignatureCaptureDialog` to capture new signatures.

Developer notes
- Implement a tiny `ProvincialSectionState` data holder in the formState/controller to track each section's active/completed state and values; derive UI visibility from these observables.
- Keep upload/save operations inside the repository/data manager; sections should call controller methods like `onConfirmPickUp(...)`, `onStartTransit(...)`, `onConfirmDelivery(...)` which handle saving, queueing uploads, and error handling.


Widget mapping for provincial fields
----------------------------------

This section lists recommended existing widgets or small widget compositions to capture/display each provincial field added to the plan. Prefer reuse of shared widgets in `lib/common/widgets` and `lib/base/utils` where available.

- provincial_pick_up_proof_image_path (pick-up proof)
  - Widget: capture using `BDropOffCapture` (camera review) and show previously uploaded/returned images with `ViewDeliveredItemButton` (or similar viewer used across logistics features).
  - Behavior: use `onCapture: (camera) => camera.takePictureWithAnimation(requestId)` (existing pattern) and read `CameraHandlerController.imageProofPath` after confirm. When the user posts the proof to the API, save a local copy via `FileStorageService` so the image can be previewed offline and enqueued for upload if offline.
  - Placement: inside `air_sea_provincial_pick_up_section.dart` as an inline image preview + capture button; show any API-provided proof using `ViewDeliveredItemButton`.

  - API note: the GET endpoint for this resource currently returns an `image/png` response. To render an API-provided proof you can either:
    - fetch the binary and render it with `Image.memory(bytes)`; or
    - download and persist it via `FileStorageService` and show it through the project's image preview widgets (`ViewDeliveredItemButton` / thumbnail). Prefer persisting a local copy when offline viewing or re-use is required.

- provincial_pick_up_at (timestamp)
  - Widget: auto-captured `DateTime` when user confirms Pick Up. Display with a readonly `Text` widget using `BFormatter.formatDateWithAmPm` or `formatDate2`.
  - Placement: show the captured timestamp in the pick-up section; store in controller/formState and persist via mapper.

- provincial_pick_up_by (actor id / name)
  - Widget: display current user (from `UserController`) as readonly `ListTile` or `BDeliveryDetailsSection` row showing name and role. If storing display name + id, show display name and attach id in DTO.
  - Behavior: populated automatically from `Get.find<UserController>()` on confirm; do not allow manual edit unless project requires override.

- provincial_in_transit_at (timestamp)
  - Widget: `Start Transit` button in modal which captures `DateTime.now().toUtc()` when tapped. Show the recorded timestamp in the modal as readonly text.
  - UX: disable the Start Transit button if `provincialPickUpProofImagePath` is missing.

- provincial_delivered_proof_image_path (drop-off proof)
  - Widget: capture using `BDropOffCapture` and display API-provided or locally-saved proofs using `ViewDeliveredItemButton` (thumbnail + full-screen viewer).
  - Notes: capture flow consistent with pick-up; when the user posts a proof save a local copy via `FileStorageService` and include the file in the multipart API call; repository handles upload and persists remote URLs in lightweight DB/text fields if needed.

  - API note: the GET endpoint for the delivered proof typically returns `image/png`. Render the bytes directly or download to a local file for the preview widget. Reuse the same approach as pick-up proofs.

- provincial_delivered_receiver_name (recipient name)
  - Widget: simple `TextFormField` (single-line) with validation (non-empty) inside the delivery section.
  - UX: provide keyboardType: `TextInputType.name` and `autocorrect: false`.

- provincial_delivered_receiver_signature_path (recipient signature)
  - Widget: signatures for delivered receiver are expected to be loaded from the API and shown via the existing `CapturedSignatureImage` widget (or a viewer that accepts a remote URL). Do NOT persist the signature path to local DB or long-term storage.
  - Behavior: if the UI captures a signature to be sent to the backend, send it as part of the API payload (multipart) but avoid saving its path into local storage. For display, fetch the signature image from the API and render via `CapturedSignatureImage` or the app's image viewer.
  - Placement: show signature preview (API-provided) and, if capturing is allowed, provide a transient `Capture Signature` action that sends the signature to the backend without persisting its path locally.

  - API note: the signature endpoint returns an image/png payload. Fetch and render as binary (Image.memory) or download temporarily for display; do not write into long-term storage. If the backend returns a redirect or URL, treat it as a URL that resolves to a PNG.

General UI notes for provincial sections
- Wrap only necessary subtrees with `Obx` and keep controller logic in `AirSeaController` or a small `ProvincialFormController` registered lazily.
- Disable modal submit/confirm buttons until required fields for the target transition are present. Use `BLoaders` / `BFullScreenLoader` for long-running upload/sync operations.
- Use `BFormatter` for displaying timestamps and `logDebug()` for replacing any temporary `print()` debug statements.
- Keep image/signature saving and upload logic inside the repository / data manager; widgets only collect and preview inputs.

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
8. Extend `AirSeaDataManager.updateRequestStatus(...)` to recognise provincial statuses and map provincial fields; add thin wrapper methods in `AirSeaController` that call `updateRequestStatus` for each provincial action.
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
| `air_sea_controller.dart` | Add thin wrapper methods that call `updateRequestStatus` for provincial actions |
| `air_sea_data_manager.dart` | Extend `updateRequestStatus` to handle provincial statuses and uploads |
| `air_sea_modal_config.dart` | Add provincial role configs |
| `air_sea_modal.dart` | Show provincial sections |
| `air_sea_list.dart` | Update guards + role priority |
| `air_sea_filter_manager.dart` | Add provincial statuses to filters |
| `status_color_mapper.dart` | Add 3 color entries |
| **New:** `air_sea_provincial_pick_up_section.dart` | Pick-up UI |
| **New:** `air_sea_provincial_delivery_section.dart` | Delivery UI |


