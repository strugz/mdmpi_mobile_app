# PullOut Module

Purpose
- Reference implementation for modules with similar request/fulfillment flows (e.g., Standard Delivery-like).
- Documents data model, JSON mapping, UI filter reuse, and GetX integration points.

What we implemented
- Data model: `PullOutModel` with safe defaults and helpers.
  - Methods: `fromJson`, `toJson`, `copyWith`, `empty()`.
  - Parsing tolerant to API key casing/variants and nulls; supports nested `ClientModel` and a `DocumentReference` list.
- UI guidance: reuse the Standard Delivery `FilterDropdown` pattern for Pull Out status filtering.
- Integration guidance: controllers, bindings, and services per project architecture (GetX + DI via `Get.lazyPut(fenix: true)`).

Key file(s)
- lib/features/logistics/models/pull_out_model.dart
- lib/features/logistics/controllers/pull_out_controller.dart
- lib/features/logistics/helpers/pull_out_data_manager.dart
- lib/features/logistics/helpers/pull_out_filter_manager.dart
- lib/features/logistics/helpers/pull_out_form_state.dart

Data model highlights
- Fields
  - Identifiers: `id`
  - Client: `clientId`, `clientContactPerson`, `client: ClientModel`
  - Categorization: `formCategoryId`, `itemCategoryId`
  - Docs/IRRF: `irrfNumber`, `irrfDate`, `documentReference: List<String>`
  - Reason & logistics: `reasonForReturn`, `releasedBy`, `pullOutDate`, `pullOutDateStartAt`, `pullOutDateEndAt`
  - Status & transport: `requestStatus`, `tripTicketNumber`, `driver`, `helper`
  - Mobile: `mobileID: int?`, `mobileName`
  - Audit: `createdAt`, `updatedAt`, `createdBy`, `requestedBy`
  - Cancel: `cancelRemarks: CancelRemarksModel`
- JSON strategy
  - `fromJson` picks the first present key among common variants (e.g., `RequestID`, `requestId`, ...).
  - `toJson` mirrors API field names used by backend (PascalCase keys).

Example usage
```text
// Parse from API
final model = PullOutModel.fromJson(apiResponse);

// Serialize to payload
final payload = model.toJson();

// Immutable-style updates
final updated = model.copyWith(requestStatus: 'Approved');
```

UI — reuse Standard Delivery FilterDropdown
- Apply the same filter widget and controller pattern in Pull Out screens.
```text
const BFilterDropdown(),
const SizedBox(height: BSizes.spaceBtwItems),
FilterDropdown(
  selectedFilter: requestController.filterManager.selectedStatusFilter,
  filterValues: RequestStatusFilter.values,
  getDisplayName: (filter) => filter.displayName,
  onFilterChanged: (filter) {
    requestController.selectStatusFilter(filter);
  },
),
```
- Keep UI pure; do not compute business/data logic in `build`. Use computed getters in the controller, and wrap minimal subtrees in `Obx` when needed.

UI — list onTap/onLongPress behavior
- On tap:
  - Sets `PullOutController.currentSelectedPullOut` to the tapped item.
  - Dispatches to role-based handlers (Request/Release/Courier/Viewer) via `pull_out_role_handler.dart`.
  - Cancelled or Picked-up items default to read-only view.
- On long press:
  - When not Cancelled/Picked-up, shows a read-only bottom sheet with core details (temporary until dedicated modal).

GetX wiring (reference)
- Bindings (register once, lazily):
  - `Get.lazyPut(() => PullOutController(), fenix: true);`
  - Repositories (`PullOutRepository`, `CancelRemarksRepository`, etc.) are registered separately.
- Controller responsibilities
  - Fetch, filter, and expose `RxList<PullOutModel>`; manage `filterManager`, `dataManager`, and `formState`.
  - Delegates business operations to `PullOutDataManager` (orchestration layer).
  - No direct network in widgets.
- Data Manager
  - `PullOutDataManager` in `features/logistics/helpers/` orchestrates save/update/fetch operations.
  - Calls repositories (API calls, mapping to/from `PullOutModel`).
  - Validates connectivity and handles full-screen loaders.

New files
- `lib/features/logistics/services/implementations/pull_out_role_handler.dart` — role-based action handlers (temporary read-only/confirm flows).
- `lib/features/logistics/controllers/pull_out_controller.dart` — added `currentSelectedPullOut` for selection state.
- `lib/features/logistics/screens/pull_out_return_pick_up/pull_out_return_pick_up_list.dart` — wired `onTap`/`onLongPress` similar to Standard Delivery.

Quality gates
- After edits affecting Dart code, run:
```powershell
flutter analyze
flutter test
```

Edge cases covered by model
- Missing/nullable fields from API → default to empty strings or empty collections.
- Mixed key casing across endpoints (`RequestID`, `requestId`, etc.).
- `DocumentReference` that may be absent or non-uniform typed list → coerced to `List<String>`.

Checklist to replicate for similar modules
- Model
  - Create `<Module>Model` with: defaults, `empty()`, `copyWith`, `fromJson` (multi-key tolerance), `toJson`.
- Controller
  - Expose filters and computed lists; keep logic out of UI.
  - Use `RxList` for reactive state; manage `filterManager`, `dataManager`, and `formState`.
- Data Manager
  - Create `<Module>DataManager` in `features/<domain>/helpers/` for business logic orchestration.
  - Handle connectivity validation, loading states, and repository calls.
- Binding
  - Register controller via `Get.lazyPut(fenix: true)`.
  - Ensure repositories are registered separately.
- Repository
  - Implement repository pattern in `data/repositories/<module>/` for API/data access.
- UI
  - Reuse `FilterDropdown` pattern for status or category filters.
  - Implement `onTap`/`onLongPress` handlers for list items.
- Tests (optional but recommended)
  - JSON parsing round-trip; filter logic; controller computed getters.

Notes
- Follow naming/style conventions: PascalCase classes, snake_case filenames, camelCase members; use `const` where applicable; use `logDebug()` instead of `print`.
- Keep platform-specific concerns (permissions/notifications) inside centralized services.
- Maintenance policy: Any change to PullOut-related code, data contracts, or UI flows must be reflected here. CI will fail PRs that change PullOut files without updating this README (see .github/workflows/pull_out_readme_guard.yml).
