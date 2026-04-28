
# Air/Sea: Request History — DTO-only status-change plan

This plan is revised to match the new requirement: **do not build a full history model first**. Start from the sample history payload and create **DTOs only**, one per status change, with **only the fields needed for that status**.

## Scope

- Use the provided history records as the first supported dataset.
- Represent each history row as a **status-specific DTO**.
- Keep only the fields required to render or process that specific status change.
- Do **not** plan a full `AirSeaHistoryModel`, `copyWith`, equality helpers, or large all-fields parser.

## Source statuses from the provided data

The current sample supports these Air/Sea history states:

1. `New Request`
2. `Getting supplies ready`
3. `Item Packed`
4. `Endorsed to Guard`

Future statuses such as dispatch, drop-off, received, and provincial flow can follow the same DTO pattern later, but they are **out of scope for this first pass**.

## DTO placement

Create DTO files under:

`lib/features/logistics/dtos/air_sea/`

Recommended files for this phase:

- `air_sea_history_status_dto.dart` — minimal shared/base contract
- `air_sea_new_request_history_dto.dart`
- `air_sea_getting_supplies_ready_history_dto.dart`
- `air_sea_item_packed_history_dto.dart`
- `air_sea_endorsed_to_guard_history_dto.dart`

## Shared minimal fields

Every status-history DTO should keep only the common fields needed to identify the event:

- `int? historyId`
- `String requestId`
- `String status`
- `String changedAt`
- `String changedBy`

Notes:
- `requestID` should still be converted to `String`.
- Keep `changedAt` as raw API string.
- Ignore `actionType` for now because the status is the meaningful timeline event.

## DTOs for the provided sample data

### 1) `AirSeaNewRequestHistoryDto`

File: `lib/features/logistics/dtos/air_sea/air_sea_new_request_history_dto.dart`

Fields:
- `int? historyId`
- `String requestId`
- `String status`
- `String changedAt`
- `String changedBy`

Maps from sample record:
- `historyID: 42`
- `requestID: 2026040019`
- `status: "New Request"`
- `changedAt: "2026-04-23T14:04:37.863"`
- `changedBy: "JCA"`

No extra fields are needed for this status.

### 2) `AirSeaGettingSuppliesReadyHistoryDto`

File: `lib/features/logistics/dtos/air_sea/air_sea_getting_supplies_ready_history_dto.dart`

Fields:
- `int? historyId`
- `String requestId`
- `String status`
- `String changedAt`
- `String changedBy`
- `String? preparedBy`
- `String? itemPreparedAt`

Maps from sample record:
- `historyID: 43`
- `requestID: 2026040019`
- `status: "Getting supplies ready"`
- `changedAt: "2026-04-23T15:34:27.503"`
- `changedBy: "JCA"`
- `preparedBy: "JCA"`
- `itemPreparedAt: "2026-04-23T15:35:25.773"`

This matches the existing update flow where this status captures who prepared the item and when preparation started.

### 3) `AirSeaItemPackedHistoryDto`

File: `lib/features/logistics/dtos/air_sea/air_sea_item_packed_history_dto.dart`

Fields:
- `int? historyId`
- `String requestId`
- `String status`
- `String changedAt`
- `String changedBy`
- `String? itemPreparedEndAt`

Maps from sample record:
- `historyID: 44`
- `requestID: 2026040019`
- `status: "Item Packed"`
- `changedAt: "2026-04-23T15:34:31.927"`
- `changedBy: "JCA"`
- `itemPreparedEndAt: "2026-04-23T15:35:30.21"`

Do not carry unrelated fields from the full payload if the UI only needs the packed-complete timestamp.

### 4) `AirSeaEndorsedToGuardHistoryDto`

File: `lib/features/logistics/dtos/air_sea/air_sea_endorsed_to_guard_history_dto.dart`

Fields:
- `int? historyId`
- `String requestId`
- `String status`
- `String changedAt`
- `String changedBy`
- `String? receivedBy`

Maps from sample record:
- `historyID: 45`
- `requestID: 2026040019`
- `status: "Endorsed to Guard"`
- `changedAt: "2026-04-23T15:34:51.05"`
- `changedBy: "JCA"`
- `receivedBy: "Bryan"`

For this first pass, keep only the guard/receiver name because that is the status-specific value present in the sample.

## Parsing rule

The repository/history parser should:

1. Read `status` from each raw JSON row.
2. Create the matching status DTO.
3. Map only the fields required by that DTO.
4. Ignore unrelated payload fields.

Pseudo-mapping rule:

- `New Request` → `AirSeaNewRequestHistoryDto`
- `Getting supplies ready` → `AirSeaGettingSuppliesReadyHistoryDto`
- `Item Packed` → `AirSeaItemPackedHistoryDto`
- `Endorsed to Guard` → `AirSeaEndorsedToGuardHistoryDto`

## Fields to ignore for this first pass

From the sample payload, do **not** include these in the first DTO set unless a later status explicitly needs them:

- `clientID`
- `itemCategoryID`
- `actionType`
- `mobileID`
- `datePickUp`
- `tripTicketNumber`
- `driver`
- `helper`
- `dispatchedAt`
- `dropOffAt`
- `waybillNumber`
- `remarks`
- `createdBy`
- `createdAt`
- `updatedAt`

## Relation to existing Air/Sea update DTO

This history plan should stay aligned with `lib/features/logistics/dtos/air_sea/air_sea_update_dto.dart` and the current status update flow in `air_sea_data_manager.dart`, but history DTOs must remain **smaller** than the update DTO.

Rule:
- `AirSeaUpdateDto` = request update payload
- History DTOs = status timeline payloads

Do not reuse the large update DTO directly for history rows.

## Repository expectation

The repository should own the full history-fetching pipeline for Air/Sea status changes: request the raw API payload, decode the list, dispatch each row by `status`, and return a DTO-only history collection.

### Repository placement

Add the history-fetch method to:

`lib/data/repositories/air_sea/air_sea_repository.dart`

This keeps history loading aligned with the existing `AirSeaRepository` pattern already used for API-backed Air/Sea operations.

### Expected method shape

Recommended direction:

- `Future<List<AirSeaHistoryStatusDto>> getRequestHistory(String requestId)`

Notes:
- Input should be the Air/Sea request id.
- Output should be a list of the shared/base history DTO type, where each item is an instance of one of the supported status DTOs.
- The repository should return parsed DTOs, not raw maps.
- The repository should not return widget-ready strings.

### Repository responsibilities

The repository method should:

1. Build the request URL for the request-specific history endpoint.
2. Perform the HTTP request.
3. Decode the response body.
4. Extract the list payload using the same tolerant list-decoding style already used in the repository.
5. Filter rows to the current `requestId` when needed.
6. Read `status` from each row.
7. Instantiate the matching status DTO.
8. Map shared fields first, then only the status-specific fields.
9. Return the final DTO list to the controller/UI layer.

### Parsing behavior

For every history row:

- Always parse:
  - `historyID` → `historyId`
  - `requestID` → `requestId` as `String`
  - `status`
  - `changedAt`
  - `changedBy`
- Then parse only the extra field(s) needed by the matched status DTO.

Examples:
- `New Request` → no extra fields
- `Getting supplies ready` → `preparedBy`, `itemPreparedAt`
- `Item Packed` → `itemPreparedEndAt`
- `Endorsed to Guard` → `receivedBy`

The repository should treat incoming JSON values as dynamic and convert defensively using `toString()` or nullable reads where appropriate.

### Status dispatch rule

The repository should use the `status` value as the single dispatch key for the first pass:

- `New Request` → `AirSeaNewRequestHistoryDto`
- `Getting supplies ready` → `AirSeaGettingSuppliesReadyHistoryDto`
- `Item Packed` → `AirSeaItemPackedHistoryDto`
- `Endorsed to Guard` → `AirSeaEndorsedToGuardHistoryDto`

If the row has a supported status but its extra field is null, the repository should still create the DTO and leave the extra field null.

### Unknown or unsupported statuses

For this first pass, if the repository encounters a history row with an unsupported `status`:

- log the unsupported status using `logDebug()`
- skip that row
- continue parsing the rest of the list

Do not fail the whole history request because of one unknown status row.

### Ordering expectation

The repository should not rely on the backend always returning the desired order.

Expectation for the first pass:
- sort the parsed DTO list by `changedAt`
- use newest-first ordering for timeline display
- if a row has an invalid or empty `changedAt`, place it after valid dated rows

### Duplicate handling

If duplicate history rows are returned by the API, the repository should prefer lightweight de-duplication before returning the list.

Recommended rule:
- first dedupe by `historyId` when present
- if `historyId` is missing, dedupe by a composite of `requestId + status + changedAt + changedBy`

This should remain a small repository concern only; do not introduce a large normalization layer for it.

### Error handling expectation

The repository should handle failures in a way that is safe for controllers and UI:

- network/HTTP failure → throw a repository-level exception or standard exception consistent with existing repository behavior
- malformed response root → return an empty list when no parseable list exists
- malformed individual row → log and skip that row, continue with the rest

This keeps the method resilient while still surfacing actual request failures.

### What the repository must not do

For this phase, the history repository method must **not**:

- build a full `AirSeaHistoryModel`
- create a large all-fields DTO
- mutate request workflow state
- patch/update request status
- store history rows in local SQLite
- format dates for display
- generate UI labels or presentation strings
- embed widget logic

### Final contract for this phase

For this phase, the repository should behave as a thin DTO parser/loader only.

Required outcome:
- input: `requestId`
- source: raw history API payload
- output: `List<AirSeaHistoryStatusDto>`
- contents: only supported per-status DTOs
- scope: only the fields needed by the current timeline/history UI

For this phase:
- No full history model
- No large all-fields normalization layer
- No status-agnostic “everything bag” object

Only parse enough data to support the current timeline/status-history UI.

## UI expectation

The UI should render a **read-only history/timeline section** from the repository-provided status DTO list.

### UI placement

For the first pass, the history section should live inside the existing Air/Sea request modal:

`lib/features/logistics/screens/air_sea/widgets/air_sea_modal.dart`

Recommended placement:
- show the history section as a dedicated block inside the modal body
- place it **before** `AirSeaRequestModalFooter`
- keep it visible alongside current request details instead of opening a separate screen

Reason:
- the user is already reviewing a single request inside the modal
- history is supporting context for the current request
- this avoids adding a new route or navigation path for the first pass

### UI data ownership

The UI must stay presentation-only.

Expected ownership split:
- `AirSeaRepository` fetches and parses history rows
- `AirSeaController` owns observable history state
- `AirSeaModal` and any history widgets only render the controller state

The widget layer must **not**:
- call the API directly
- read raw JSON maps
- decide how rows are parsed
- deduplicate or sort history items

### Recommended controller-facing state

The UI section should be driven by controller observables similar to other GetX patterns in the app.

Expected state shape for the history section:
- loading state
- error state
- history list state

Minimal expectation:
- `RxBool isHistoryLoading`
- `RxnString historyErrorMessage`
- `RxList<AirSeaHistoryStatusDto> requestHistory`

The UI should react to these states with minimal `Obx` scope around the history section only.

### Section-level UI states

The history area should support these inline states without replacing the rest of the modal:

#### 1) Loading state
- show a small inline loading state inside the history section
- do not block the entire modal
- keep request details and footer visible

Examples:
- a simple `CircularProgressIndicator`
- or an existing lightweight loader/shimmer if one already fits the modal style

#### 2) Error state
- show a compact inline error message inside the history section
- keep the message passive and readable
- optional: include a small retry action routed through the controller

The retry action, if added, must call the controller method, not the repository directly from the widget.

#### 3) Empty state
- show a small empty-state message such as “No history available”
- do not render placeholder fake rows
- do not treat empty history as an error

#### 4) Success state
- render the timeline/history rows in repository order after repository sorting
- assume the repository already returns newest-first items for the first pass

### Widget composition expectation

Before creating new widgets, reuse existing shared widgets where they fit the timeline row design.

Preferred reusable widgets already present in the project:
- `BTextDivider` from `lib/common/widgets/dividers/text_divider.dart` for the section header
- `StatusChip` from `lib/common/widgets/chips/status_chip.dart` for the status label
- `BLabelValueText` from `lib/common/widgets/texts/label_value_text.dart` for compact key-value details
- `BRoundedContainer` from `lib/common/widgets/custom_shapes/containers/rounded_container.dart` if a grouped card container is needed

Recommended first-pass structure:
- section title using `BTextDivider(text: 'History')`
- a vertical list/column of timeline rows
- each row displays one history DTO item
- use simple spacing and compact text rather than a heavy audit-log layout

If no existing shared widget fully fits the history row, create a dedicated shared widget under the Air/Sea widget folder for this first pass instead of pushing business logic into `air_sea_modal.dart`.

### Row rendering contract

Every rendered row should show the common event identity first:

- status
- changed date/time
- changed by

Then show only the extra field(s) for that specific DTO when present.

Recommended row layout:
1. top line: `StatusChip(status: dto.status)`
2. second line: changed time
3. third line: changed by
4. optional additional lines: status-specific details

Hide null or empty optional fields instead of showing empty labels.

### Per-DTO rendering expectations

#### `AirSeaNewRequestHistoryDto`
Show:
- status
- changedAt
- changedBy

Do not add extra metadata for this row.

#### `AirSeaGettingSuppliesReadyHistoryDto`
Show:
- status
- changedAt
- changedBy
- `preparedBy` when available
- `itemPreparedAt` when available

This row should communicate that preparation started and who performed it.

#### `AirSeaItemPackedHistoryDto`
Show:
- status
- changedAt
- changedBy
- `itemPreparedEndAt` when available

This row should communicate that packing was completed.

#### `AirSeaEndorsedToGuardHistoryDto`
Show:
- status
- changedAt
- changedBy
- `receivedBy` when available

This row should communicate who received or accepted the handoff.

### Date/time display expectation

The UI may format `changedAt` and any status-specific timestamps for readability, but formatting must remain a presentation concern only.

Rules:
- repository returns raw timestamp strings
- widget/controller presentation layer may format for display
- do not push display formatting back into repository DTO parsing

If formatting is needed, prefer existing shared formatter utilities instead of custom inline parsing in multiple widgets.

### Visual behavior expectation

For the first pass, keep the history block visually lightweight:

- compact vertical spacing
- minimal nesting
- no nested scroll region unless the modal content requires it
- avoid large cards per row unless readability requires grouping
- avoid excessive `Obx` nesting; wrap only the history section

The section should feel like supporting request context, not a full audit screen.

### Interaction expectation

The history section is read-only for this phase.

The UI must **not** support:
- editing history rows
- deleting history rows
- expanding into media galleries
- signature preview from history
- direct status changes from history rows
- long-press developer actions

The only optional interaction for the first pass is a small retry action in the section error state.

### What the UI must not do

For this first pass, the UI layer must **not**:

- parse raw history JSON
- infer DTO type from maps
- deduplicate rows
- reorder rows independently of repository output
- group rows by date or actor
- merge history rows with request form fields
- show unsupported status-specific fields
- fetch proof images or signature attachments for history items
- mutate request workflow state from the history section

### First-pass success criteria

The UI expectation is satisfied when:

- the Air/Sea modal shows a visible `History` section
- the section loads data through controller state
- the section handles loading, error, empty, and success states inline
- each supported DTO renders only its intended fields
- null optional fields are hidden cleanly
- the rest of the modal continues to behave normally

For the first pass, each row needs only:
- status label
- changed date/time
- changed by
- the status-specific extra field when present

Examples:
- `New Request` → show status + actor + changed time
- `Getting supplies ready` → show status + `preparedBy` + `itemPreparedAt`
- `Item Packed` → show status + `itemPreparedEndAt`
- `Endorsed to Guard` → show status + `receivedBy`

## Summary decision

Replace the previous “history model + repository + UI widgets” plan with a **DTO-only per-status history plan**.

Start with the four statuses present in the sample payload and keep every DTO compact, status-driven, and limited to only the fields actually needed by that status.
