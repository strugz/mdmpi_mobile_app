# Hotline Direct Module

## Overview

Hotline Direct is the urgent-delivery variant of Standard Delivery. It is **not a separate
data model**: both tabs read one table and one endpoint, split by `FormCategoryID` —
Standard Delivery is `'6'`, Hotline Direct is `'8'`
(`lib/features/logistics/constants/form_category_ids.dart`).

It reuses `StandardDeliveryModel`, `StandardDeliveryRepository` and
`StandardDeliveryFormState` outright, and adds only its own controller, filter manager,
data manager and role handler.

The same one-table/two-tab pattern was later applied to Air / Sea / Land — see
[../air-sea/README.md](../air-sea/README.md), whose HD tab is pinned to category `'21'`.

Verified against app version 1.1.102.

## Status Flow

```
New Request
  → Getting supplies ready      (Release, or the Courier who created the request)
    → Item Prepared             (Release)
      → For Delivery            (Courier, via Request Transport)
        → Delivered             (Courier, Drop Off)

(Any status) → Cancelled          (requires remarks)
```

Identical to Standard Delivery, including the two things that flow is usually documented
wrong: **there is no In Transit status**, and the terminal status string is `"Delivered"`
(the constant is `BTexts.statusDoneDelivery`, `text_strings.dart:140`).

### Courier creation

Unlike Standard Delivery, the create button appears for the **Courier** role on this tab,
and a courier who created a request can act on it at New Request. Other roles follow the
Standard Delivery matrix. The role handlers are in
`services/implementations/hotline_direct_role_handler.dart`:
`HotlineDirectRequestRoleHandler`, `HotlineDirectReleaseRoleHandler`,
`HotlineDirectCourierRoleHandler`, `HotlineDirectViewerRoleHandler` and
`HotlineDirectDefaultHandler`.

### Inherited behavior

Everything the courier does reaches Hotline Direct through the shared
`StandardDeliveryFormState`, so these all apply here without separate wiring:

- Request Transport as the courier workflow, with up to three proof-of-delivery photos
- SMS at For Delivery, with the full-screen "Message Sent!" confirmation
- Item-level backload at For Delivery, and the read-only backloaded-items list afterwards
- The full-screen document reference editor
- Stock Issue Slip capture — Part No., Serial No., PTN, optional item code

See [../standard-delivery/README.md](../standard-delivery/README.md) for the detail on each.

## Architecture

### Folder Structure

```
lib/features/logistics/
  controllers/
    hotline_direct_controller.dart
    request_hotline_controller.dart          # see Known gaps
  helpers/
    hotline_direct_data_manager.dart
    hotline_direct_filter_manager.dart
  services/implementations/
    hotline_direct_role_handler.dart         # per-role action handlers
  screens/hotline_direct/
    hotline_direct_list.dart
    widgets/hotline_direct_filter_dropdown.dart
```

Model, repository, DAO, mapper, form state and the whole Request Transport screen are
Standard Delivery files — this module adds none of its own.

### Data Flow

```
UI (HotlineDirectList)
  → HotlineDirectController
    → HotlineDirectDataManager / HotlineDirectFilterManager
      → StandardDeliveryRepository (filtered by FormCategoryID '8')
        → StandardDeliveryMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `HotlineDirectController` | `features/logistics/controllers/` | State management for the Hotline Direct tab |
| `HotlineDirectDataManager` | `features/logistics/helpers/` | Fetch, sync and submit against the shared repository |
| `HotlineDirectFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `HotlineDirect*RoleHandler` | `features/logistics/services/implementations/` | Per-role available actions |
| `IDeliveryRequestController` | `lib/common/services/abstracts/` | Interface shared with Standard Delivery |
| `StandardDeliveryModel` | `features/logistics/models/` | Reused domain model |
| `StandardDeliveryFormState` | `features/logistics/helpers/` | Reused form state |

### DI Registration

Registered in `GeneralBindings` (`lib/bindings/app/general_bindings.dart`):

```dart
Get.lazyPut(() => HotlineDirectController(), fenix: true);  // :215
```

The repository, image repository and Request Transport controller it depends on are
registered by Standard Delivery — see that module for the full block.

### Model Fields

None of its own. See the `StandardDeliveryModel` field list in
[../standard-delivery/README.md](../standard-delivery/README.md); `formCategoryID` is the
field that puts a row on this tab.

### Related Shared Components

- Everything listed under Related Shared Components in
  [../standard-delivery/README.md](../standard-delivery/README.md)
- `FormCategoryIds` / `FormCategoryType` — `features/logistics/constants/`

## Known gaps

- **`request_hotline_controller.dart` is unreachable.** `request_controller.dart` routes
  Hotline Direct to `requestFormPages[0]` — the Standard Delivery form — so the dedicated
  Hotline Direct form and its controller are never shown. Either wire it up or delete it;
  it is also listed as known debt in `AGENTS.md`.
- **No scanner entry of its own.** Hotline Direct inherits scanned items through the
  Standard Delivery form it borrows, so it is not tracked as a target in
  [../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md);
  if the dedicated form above is ever enabled, the scanner entry has to move with it.
