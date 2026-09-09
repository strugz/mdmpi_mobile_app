# Pick Up Module

## Overview

Pick Up handles requests for collecting items from a client. Unlike the delivery modules it
is a single-role workflow: Release drives every transition from creation to receipt.

Verified against app version 1.1.102.

## Status Flow

```
New Request
  → Getting Supplies Ready      (Release)
    → Item Packed               (Release)
      → Received                (Release)

(Any status) → Cancelled          (requires remarks)
```

The matrix lives at the top of `screens/pick_up/pick_up_list.dart` and in
`services/implementations/pick_up_role_handler.dart`, mirrored by `PickUpStatusFilter` in
`pick_up_filter_manager.dart`.

Three corrections against older versions of this document:

- **Only Release has actions.** There is no Courier stage in Pick Up; Courier and Viewer are
  read-only (`PickUpCourierRoleHandler`, `PickUpViewerRoleHandler`).
- **The third status is `Item Packed`**, not "Item Prepared".
- **Neither "Taken Out" nor "Released" appears in this flow.** Those belong to Pull Out and
  Stock Receive.

Proof or receiver fields may appear during the final receiving step where the screen
requires them.

### Multiple item categories

A Pick Up request can carry more than one item category. `PickUpModel` has both:

- `itemCategoryId` — the primary selection, kept scalar for backward compatibility
- `itemCategoryIds` — the full list

The form uses a multi-select dropdown, the insert DTO sends `ItemCategoryIDs`
(`dtos/pick_up/pick_up_insert_dto.dart:31`), and the list is persisted locally in the
`ItemCategoryIDs TEXT` column on `a_tblRequestPickUp` (`db_schema.dart:180`) alongside the
original scalar `ItemCategoryID`. Category filtering matches either the scalar or the list,
so requests created before this change keep filtering correctly.

## Architecture

### Folder Structure

```
lib/features/logistics/
  controllers/pick_up_controller.dart
  helpers/
    pick_up_data_manager.dart                # fetch, sync, submit
    pick_up_filter_manager.dart              # status & date filtering
    pick_up_form_state.dart
  models/pick_up_model.dart
  dtos/pick_up/
    pick_up_insert_dto.dart
    pick_up_update_dto.dart
  mappers/pick_up_mapper.dart
  services/implementations/pick_up_role_handler.dart
  screens/pick_up/
    pick_up_list.dart
    widgets/
      pick_up_modal.dart
      pick_up_modal_header.dart
      pick_up_request_card.dart
      pick_up_request_modal_footer.dart
  screens/request_forms/widgets/pick_up_form.dart
lib/data/repositories/pick_up/pick_up_repository.dart
lib/data/local/dao/pick_up/pick_up_dao.dart
```

### Data Flow

```
UI (PickUpList / PickUpForm)
  → PickUpController
    → PickUpDataManager / PickUpFilterManager
      → PickUpRepository (API via BHttpHelper + local SQLite via PickUpDao)
        → PickUpMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `PickUpController` | `features/logistics/controllers/` | State management, CRUD orchestration |
| `PickUpRepository` | `data/repositories/pick_up/` | API calls + local DB persistence |
| `PickUpDao` | `data/local/dao/pick_up/` | SQLite operations |
| `PickUpModel` | `features/logistics/models/` | Domain model with client & document references |
| `PickUpMapper` | `features/logistics/mappers/` | Maps API DTOs to/from domain models, incl. the category list |
| `PickUp*RoleHandler` | `features/logistics/services/implementations/` | Per-role available actions |
| `PickUpDataManager` | `features/logistics/helpers/` | Data fetching & sync coordination |
| `PickUpFilterManager` | `features/logistics/helpers/` | Status & date range filtering |
| `PickUpFormState` | `features/logistics/helpers/` | Form field controllers & validation |

### DI Registration

Registered in `GeneralBindings` (`lib/bindings/app/general_bindings.dart`):

```dart
Get.lazyPut(() => PickUpRepository(), fenix: true);  // :148
Get.lazyPut(() => PickUpController(), fenix: true);  // :212
```

### Model Fields

`PickUpModel`:

- `id`, `clientId`, `itemCategoryId`, `itemCategoryIds`
- `datePickUp`, `remarks`, `status`
- `preparedBy`, `itemPreparedAt`, `itemPreparedEndAt`
- `releasedBy`, `receivedBy`
- `createdBy`, `createdAt`, `updatedAt`
- Aggregates: `ClientModel client`, `List<String> documentReference`

Note this model has no `cancelRemarks` aggregate, unlike `PullOutModel` and
`StandardDeliveryModel`.

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`,
  `b_dialog`

## Known gaps

- **No scanner entry.** Pick Up is listed first in the delivery order of
  [../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md)
  but `pick_up_form.dart` still has no "Add Item" button, and `pick_up_data_manager.dart`
  has no reference to `scannedInventoryItems`. Air / Sea / Land is in the same position.
