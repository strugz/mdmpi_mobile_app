# INVENTORY_ITEM_MODULE_DOCUMENTATION

Status: Active (shipped; see Implementation Status below)
Area: Logistics
Routes:

---

## Overview

This document describes the design and integration details for the Inventory Item feature: a GetX controller that manages inventory item state and a reusable, expandable/collapsible Inventory item view widget. It is intended as a developer-facing module guide (architecture, API, usage examples, testing, and troubleshooting). Implementation files are feature-scoped under `features/logistics` and DI is registered in `lib/bindings/app/general_bindings.dart`.

Note: This file follows project documentation conventions — placed under `docs/modules/inventory_item/` and named in SCREAMING_SNAKE_CASE.

---

## Goals

- Provide a small, reusable UI widget to display an inventory item with a collapsible details area (batches, serials, location info).
- Provide a GetX `InventoryItemController` so other controllers or widgets can reuse inventory state and expansion state.
- Keep UI pure: all business/data logic lives in the controller; widget only reads observables and forwards user interactions.
- Use existing project utilities (e.g., `Result<T>`, `BLoaders`, `BFormatter`, `logDebug`) and follow coding conventions from the repo.

---

## Architecture & Placement

- Controller (feature-scoped):
  - Path: `lib/features/logistics/controllers/inventory_item_controller.dart`
  - Class: `InventoryItemController` (extends `GetxController`)
  - Responsibility: maintain `items`, `expanded` map, `isLoading`, `errorMessage` observables; provide methods to load items and manage expansion state.
  - Important: do NOT create a fixed/permanent controller instance inside this file or elsewhere (for example, avoid `Get.put(InventoryItemController(), permanent: true)` or inline initialization). The controller must be registered in `GeneralBindings` via `Get.lazyPut(..., fenix: true)` so it remains injectable and recreatable.

  - Prohibited patterns (do not use):
    - Creating the controller instance inline in the file or in a widget, e.g. `final c = Get.put(InventoryItemController());` or `Get.put(InventoryItemController(), permanent: true)`.
    - Registering the controller in ad-hoc widgets or screens instead of `GeneralBindings`.
    - Declaring or instantiating other `GetxController` types as fields inside `inventory_item_controller.dart` (for example, `final other = Get.put(OtherController())` or creating controller instances directly). This is strongly discouraged and should be done only when strictly necessary. Prefer resolving controller dependencies with `Get.find<OtherController>()` when needed or accept them via constructor injection for testability. If you must keep another controller as a field, inject it via the constructor and add a short comment explaining why the controller reference is required (for example, cross-cutting coordination that cannot be moved to a service).
    - Using `Get.put(..., permanent: true)` to make the controller a fixed singleton for normal feature controllers. Permanent singletons are reserved for global services only and must be documented in `GeneralBindings` if used.

- Widget (feature-scoped):
  - Path: `lib/features/logistics/widgets/inventory_item_view.dart`
  - Class: `InventoryItemView` (extends `StatelessWidget`)
  - Responsibility: present the header (code, description, summary) and the collapsible details area. Use `Obx` only around the details subtree.

- Repository (existing):
  - Path: `lib/data/repositories/inventory/inventory_item_repository.dart`
  - Class: `InventoryItemRepository` (already present in repo). Controller depends on this repository via `Get.find()` or constructor injection (for tests).

- Bindings change:
  - File to edit: `lib/bindings/app/general_bindings.dart`
  - Register repository and controller using `Get.lazyPut(..., fenix: true)` (repository registration must come before controller registration).



---

## Controller: API & Observables

Class: InventoryItemController extends GetxController

Core observables (recommended names):

- `RxList<InventoryItemModel> items = <InventoryItemModel>[].obs;`
- `RxMap<String, bool> expanded = <String, bool>{}.obs;`  // keyed by `itemCode` (fallback to index-key if empty)
- `RxBool isLoading = false.obs;`
- `RxnString errorMessage = RxnString();`

Constructor:

- `InventoryItemController({InventoryItemRepository? repository})`
  - Accepts an optional repository for easier unit testing; default to `Get.find<InventoryItemRepository>()` if null.

Controller dependencies:

- Do NOT declare or instantiate other `GetxController` types as fields inside `inventory_item_controller.dart`. Instead prefer one of the following patterns:

  1. Constructor injection (recommended for testability):

```dart
class InventoryItemController extends GetxController {
  final InventoryItemRepository _repo;
  final OtherController _other; // injected dependency

  InventoryItemController({InventoryItemRepository? repository, OtherController? otherController})
    : _repo = repository ?? Get.find<InventoryItemRepository>(),
      _other = otherController ?? Get.find<OtherController>();
}
```

  2. Lazy resolve inside methods (acceptable when dependency is optional and not needed in constructor):

```dart
void someMethod() {
  final other = Get.find<OtherController>();
  // use `other` locally
}
```

- If the logic required from another controller is substantial or cross-cutting, prefer extracting that logic into a service (e.g., `common/services/implementations/`) and inject the service into the controller. This reduces tight coupling between controllers and improves testability.

Note: If you do add another controller as a constructor-injected dependency, include an inline comment documenting the necessity and why extracting to a shared service was not appropriate in this case.

Public methods (signatures and behavior):

- `Future<Result<List<InventoryItemModel>>> loadItems({ String path = '/api/inventory/items', Map<String, String>? queryParameters, bool showLoader = true })`
  - Fetches items from `InventoryItemRepository.fetchItems(...)`.
  - Sets `isLoading` while running, populates `items` on success and resets `expanded` map.
  - On failure sets `errorMessage` and returns `Result.failure(...)`.

- `void setItems(List<InventoryItemModel> newItems)`
  - Replaces `items` and resets `expanded` to default (all collapsed).

- `void toggleExpanded(String key)`
  - Toggles `expanded[key]` (creates with `true` when absent).

- `bool isExpanded(String key)`
  - Helper to check expansion flag (returns `expanded[key] ?? false`).

- `void expandAll()` / `void collapseAll()`
  - Set all flags to `true` or `false`.

- `void updateItem(InventoryItemModel item)`
  - Replace a single item in `items` by matching key (`itemCode` or id).

- `void clear()`
  - Clear `items` and `errorMessage`.

Error handling:
- Wrap async operations in `try`/`catch`.
- Use `logDebug()` to log caught exceptions.
- Avoid throwing raw exceptions to UI — return `Result.failure(...)` and set `errorMessage`.

---

## Widget: API & Behavior

Class: InventoryItemView extends StatelessWidget

Constructor (recommended):

- `const InventoryItemView({ Key? key, required this.item, this.controller, this.keyId, this.showTrailingActions = true })`
  - `item` — instance of `InventoryItemModel` to display (preferred)
  - `controller` — optional `InventoryItemController`; if omitted, widget does `Get.find<InventoryItemController>()` within `build`
  - `keyId` — optional override for expansion key (falls back to `item.itemCode` or index-based key)
  - `showTrailingActions` — optional toggle for actions like edit/scan

Behavior rules:

- The widget must remain pure: no repository calls or business logic inside `build`.
- Resolve controller via `controller ?? Get.find<InventoryItemController>()`.
- Use `Obx` only to observe the single expansion flag for this item:
  - `Obx(() { final expanded = ctrl.isExpanded(keyId); return AnimatedCrossFade(...) /* details */; })`
- Header (always visible): shows `itemCode`, `description`, and a summary (quantity + unit) formatted via `BFormatter` (or `NumberFormat` if appropriate).
- Expand/collapse affordance: trailing `IconButton` calling `ctrl.toggleExpanded(keyId)`.
- Details area (visible when expanded): lists batches/serials/locations; if empty, show a subtle placeholder.
- Use shared widgets/styles from `lib/common/widgets` and `lib/base/utils/*` where possible. If a suitable shared widget does not exist, implement with Material widgets and project theme constants (`BColors`, `BTexts`, `BAppTheme`).

Accessibility & performance:
- Make expand/collapse hit target >= 48x48dp.
- Use `AnimatedCrossFade` or `AnimatedSize` for smooth transitions.
- Keep rebuilds minimal: header should not be inside `Obx` that observes the entire list.

---

## DI / Binding Registration

Edit `lib/bindings/app/general_bindings.dart` (follow existing ordering):

- Under repository registrations (ensure repository is registered before controllers):

```dart
Get.lazyPut<InventoryItemRepository>(() => InventoryItemRepository(), fenix: true);
```

- Under controllers registrations:

```dart
Get.lazyPut<InventoryItemController>(() => InventoryItemController(), fenix: true);
```

Notes:
- Use `fenix: true` as default unless there is a strong reason to keep instances permanent.
- Do NOT instantiate repositories inline inside controllers (avoid `Get.put` inside controllers). Use `Get.find()` or constructor injection.
 - Do NOT register the controller as a fixed/permanent instance (avoid `Get.put(..., permanent: true)` or creating inline singletons in files). Register controllers in `GeneralBindings` using `Get.lazyPut(..., fenix: true)` so they follow the project's lifecycle and DI conventions.
  - Do NOT register controllers in widgets or files outside `GeneralBindings`. Controllers should be registered only in binding files so lifecycle and ordering are correct.

---

## Example usage (screen snippet)

This example demonstrates a screen that loads items and shows them in a list using `InventoryItemView`.

```dart
// inside a StatefulWidget or use a binding to ensure controller is created
final ctrl = Get.find<InventoryItemController>();

@override
void initState() {
  super.initState();
  ctrl.loadItems();
}

// In build:
Obx(() {
  if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
  if (ctrl.errorMessage.value != null) return Text(ctrl.errorMessage.value!);

  return ListView.builder(
    itemCount: ctrl.items.length,
    itemBuilder: (_, i) => InventoryItemView(item: ctrl.items[i]),
  );
});
```

---

## Testing Guide

Unit tests for the controller (recommended):

- File: `test/inventory_item_controller_test.dart`
- Strategy:
  - Provide a small fake repository implementing the same API as `InventoryItemRepository` (no extra test package dependencies required).
  - Inject the fake repo via the controller constructor: `InventoryItemController(repository: fakeRepo)`.
  - Test cases:
    - `loadItems` success: controller populates `items`, `isLoading` toggles correctly.
    - `loadItems` failure: returns `Result.failure` and `errorMessage` is set.
    - `toggleExpanded` flips expansion flag for a given key.
    - `expandAll` / `collapseAll` behavior.

Widget tests (optional):
- File: `test/widgets/inventory_item_view_test.dart`
- Use `WidgetTester` to pump `GetMaterialApp`, register a test `InventoryItemController` via `Get.put(...)` or a binding, then tap the expand button and assert details become visible.

Run tests & analyzer (PowerShell) from repo root:

```powershell
flutter pub get
flutter analyze
flutter test
```

---

## QA Checklist (pre-commit)

- [ ] File names use snake_case; classes use PascalCase.
- [ ] No `print` statements — use `logDebug()` or `BLoaders` for user messages.
- [ ] Controller registered in `GeneralBindings` with `Get.lazyPut(..., fenix: true)`.
- [ ] Repository registration precedes controller registration.
- [ ] UI keeps business logic out of `build` and uses only minimal `Obx` for expansion.
- [ ] Async methods return `Result<T>` and set `errorMessage` on failure.
- [ ] Add `///` docs to public classes/methods.
- [ ] Run `flutter analyze` and `flutter test` and resolve issues.

---

## Troubleshooting

- If `Get.find<InventoryItemRepository>()` fails:
  - Verify registration in `lib/bindings/app/general_bindings.dart` and that `GeneralBindings` runs before the screen.
- If expansion state does not persist after navigation:
  - Ensure controller is registered with `fenix: true` so it can be recreated rather than lost unexpectedly. Do NOT use a permanent instance (for example `Get.put(..., permanent: true)`) for feature controllers; permanent singletons are reserved for global services and must be documented in `GeneralBindings`.
- If parsing errors occur when calling the repository:
  - Check the `InventoryItemRepository` logs and `BLoaders` snackbars; the repository already offers guarded parsing with helpful error messages.

---

## Appendix: Paths summary

- Controller: `lib/features/logistics/controllers/inventory_item_controller.dart`
- Widget: `lib/features/logistics/widgets/inventory_item_view.dart`
- Repository: `lib/data/repositories/inventory/inventory_item_repository.dart` (existing)
- Bindings: `lib/bindings/app/general_bindings.dart`
- Docs: `docs/modules/inventory_item/INVENTORY_ITEM_MODULE_DOCUMENTATION.md` (this file)

---

If you want, I can now generate the controller and widget templates and add the binding change, plus a small demo screen and tests. (You previously requested this but asked "dont implement" — this doc prepares the team to implement when ready.)









