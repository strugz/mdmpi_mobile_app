# PullOut Module

Purpose
- Reference implementation for modules with similar request/fulfillment flows (e.g., Standard Delivery-like).
- Documents data model, JSON mapping, UI filter reuse, and GetX integration points.

What we implemented
- Data model: `PullOutModel` with safe defaults and helpers.
  - Methods: `fromJson`, `toJson`, `toJsonInsert`, `copyWith`, `empty()`.
  - Parsing tolerant to API key casing/variants and nulls; supports nested `ClientModel` and a `DocumentReference` list.
- UI guidance: reuse the Standard Delivery `FilterDropdown` pattern for Pull Out status filtering.
- Integration guidance: controllers, bindings, and services per project architecture (GetX + DI via `Get.lazyPut(fenix: true)`).

Key file(s)
- lib/features/logistics/models/pull_out_model.dart

Data model highlights
- Fields
  - Identifiers: `id`
  - Client: `clientId`, `clientContactPerson`, `client: ClientModel`
  - Categorization: `formCategoryId`, `itemCategoryId`
  - Docs/IRRF: `slipNo`, `irrfNumber`, `irrfDate`, `documentReference: List<String>`
  - Reason & logistics: `reasonForReturn`, `releasedBy`, `pullOutDate`, `pullOutDateStartAt`, `pullOutDateEndAt`
  - Status & transport: `requestStatus`, `tripTicketNumber`, `driver`, `helper`
  - Audit: `createdAt`, `updatedAt`, `createdBy`, `requestedBy`
- JSON strategy
  - `fromJson` picks the first present key among common variants (e.g., `RequestID`, `requestId`, ...).
  - `toJson` mirrors API field names used by backend.
  - `toJsonInsert` emits a minimal, create-focused payload (omit server-managed identifiers/timestamps).

Example usage
```text
// Parse from API
final model = PullOutModel.fromJson(apiResponse);

// Serialize to full/update payload
final payload = model.toJson();

// Minimal insert payload
final insertPayload = model.toJsonInsert();

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
  - `Get.lazyPut(() => PullOutController(service: Get.find()), fenix: true);`
  - Register `IPullOutService` → `PullOutService` in the same binding.
- Controller responsibilities
  - Fetch, filter, and expose `RxList<PullOutModel>`; manage `filterManager` and derived views.
  - Call services/repositories; no direct network in widgets.
- Services
  - `IPullOutService` in `common/services/abstracts`.
  - `PullOutService` in `common/services/implementations` (API calls, mapping to/from `PullOutModel`).

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
  - Create `<Module>Model` with: defaults, `empty()`, `copyWith`, `fromJson` (multi-key tolerance), `toJson`, `toJsonInsert`.
- Controller
  - Expose filters and computed lists; keep logic out of UI.
- Binding
  - Register controller and service via `Get.lazyPut(fenix: true)`.
- Service
  - Define `I<Module>Service` + implementation; return strongly typed models.
- UI
  - Reuse `FilterDropdown` pattern for status or category filters.
- Tests (optional but recommended)
  - JSON parsing round-trip; filter logic; controller computed getters.

Notes
- Follow naming/style conventions: PascalCase classes, snake_case filenames, camelCase members; use `const` where applicable; use `logDebug()` instead of `print`.
- Keep platform-specific concerns (permissions/notifications) inside centralized services.
- Maintenance policy: Any change to PullOut-related code, data contracts, or UI flows must be reflected here. CI will fail PRs that change PullOut files without updating this README (see .github/workflows/pull_out_readme_guard.yml).
