# Pull Out / Return Module

## Overview

Pull Out / Return handles pulling stock back from a client site. Release prepares the trip,
a Courier drives it, and items that could not be collected are recorded with a reason.

It is the base that **Stock Receive** reuses — same model, repository and form state, split
by form category (`'4'` for Pull Out / Return, `'9'` for Stock Receive). See
[../stock-receive/README.md](../stock-receive/README.md).

Verified against app version 1.1.102.

## Status Flow

```
New Request
  → For Pull Out                (Release — "Set For Pull Out"; enters trip ticket,
    |                            driver, helper and vehicle)
    → In Transit                (Courier departs)
      → Taken Out               (Courier completes)

In Transit → For Pull Out       (Courier — "Pause (Back to For Pull Out)")
(Any status) → Cancelled          (requires remarks)
```

The role × status matrix is `pull_out_modal_config.dart`, mirrored by
`PullOutStatusFilter` in `pull_out_filter_manager.dart`; status strings are
`text_strings.dart:141-145`.

The correction worth stating plainly: **Release acts first, not the Courier.**
`New Request → For Pull Out` is a Release transition and it is where the transport details
are captured. Older documentation had the Courier setting In Transit straight from New
Request and entering the trip ticket, which is wrong on both counts.

### Pause

A courier interrupted mid-trip can pause an In Transit request back to For Pull Out via a
secondary action. Pausing clears the start time (`pull_out_data_manager.dart`); departing
again records a fresh one, so a paused-and-resumed trip does not report a misleading
duration.

### Lost items

While In Transit the courier marks items that were **not** pulled out, each with a required
reason (`screens/pull_out_return_pick_up/widgets/pull_out_lost_items_section.dart`).

The set is saved to `a_tblLoseItem` via `POST /api4/LoseItem/request/{id}` **before** the
Taken Out transition; if that save fails the transition aborts and the entries are kept.
`LoseItemRepository` is registered outside the Firebase guard so Windows is unaffected.

The section deliberately renders nothing for Stock Receive.

### Item lists

Pull Out requests carry scanned inventory items. The form shows an "Add Item (n)" button;
items are POSTed to `/api4/Item/request/{id}` after the request insert, and surfaced as
"View Items" in the modal body. The entry is suppressed when the form is opened as Stock
Receive (`pull_out_form.dart`, guarded by `if (!isStockReceive)`).

Anything keyed per item — lost-item and backload remarks alike — uses `referenceCode`
(part number, falling back to item code), never item code alone: item code became optional
when Stock Issue Slip capture landed, and keying on it would collapse several slip lines
onto the empty string.

## Architecture

### Folder Structure

```
lib/features/logistics/
  controllers/pull_out_controller.dart
  helpers/
    pull_out_modal_config.dart               # role/status action matrix
    pull_out_data_manager.dart               # fetch, sync, submit, pause
    pull_out_filter_manager.dart             # status & date filtering
    pull_out_form_state.dart
  models/
    pull_out_model.dart
    lose_item_model.dart
  dtos/pull_out/pull_out_insert_dto.dart
  mappers/pull_out_mapper.dart
  screens/pull_out_return_pick_up/
    pull_out_return_pick_up_list.dart
    widgets/
      pull_out_modal.dart
      pull_out_modal_header.dart
      pull_out_modal_body.dart               # includes "View Items"
      pull_out_request_card.dart
      pull_out_request_modal_footer.dart
      pull_out_lost_items_section.dart
  screens/request_forms/widgets/pull_out_form.dart
lib/data/repositories/pull_out/
  pull_out_repository.dart
  lose_item_repository.dart
lib/data/local/dao/pull_out/pull_out_dao.dart
```

### Data Flow

```
UI (PullOutReturnPickUpList / PullOutForm)
  → PullOutController
    → PullOutDataManager / PullOutFilterManager
      → PullOutRepository (API via BHttpHelper + local SQLite via PullOutDao)
        → PullOutMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `PullOutController` | `features/logistics/controllers/` | State management, CRUD orchestration |
| `PullOutRepository` | `data/repositories/pull_out/` | API calls + local DB persistence |
| `LoseItemRepository` | `data/repositories/pull_out/` | Lost-item replace-set per request |
| `PullOutDao` | `data/local/dao/pull_out/` | SQLite operations |
| `PullOutModel` | `features/logistics/models/` | Domain model with client & document references |
| `LoseItemModel` | `features/logistics/models/` | Item not pulled out, with remarks |
| `PullOutMapper` | `features/logistics/mappers/` | Maps API DTOs to/from domain models |
| `PullOutModalConfig` | `features/logistics/helpers/` | Role/status action matrix, incl. Pause |
| `PullOutDataManager` | `features/logistics/helpers/` | Data fetching, sync, start-time handling |
| `PullOutFilterManager` | `features/logistics/helpers/` | Status & date range filtering |
| `PullOutFormState` | `features/logistics/helpers/` | Form field controllers & validation |
| `IPullOutRequestController` | `lib/common/services/abstracts/` | Decouples the shared modal from the concrete controller |

### DI Registration

Registered in `GeneralBindings` (`lib/bindings/app/general_bindings.dart`):

```dart
Get.lazyPut(() => PullOutRepository(), fenix: true);  // :147
Get.lazyPut(() => LoseItemRepository(), fenix: true); // :173 — outside the Firebase guard
Get.lazyPut(() => PullOutController(), fenix: true);  // :211
```

### Model Fields

`PullOutModel`:

- `id`, `clientId`, `clientContactPerson`, `formCategoryId`, `itemCategoryId`
- `irrfNumber`, `irrfDate`, `reasonForReturn`
- `releasedBy`, `requestedBy`, `createdBy`, `createdAt`, `updatedAt`
- `pullOutDate`, `pullOutDateStartAt`, `pullOutDateEndAt`
- `requestStatus` (note: not `status`, unlike the other request models)
- `tripTicketNumber`, `driver`, `helper`, `mobileID`, `mobileName`
- Aggregates: `ClientModel client`, `List<String> documentReference`,
  `CancelRemarksModel cancelRemarks`

### Routes

| Route | Constant |
|---|---|
| `/pull-out-return-pick-up` | `BRoutes.pullOutList` |
| `/pull-out-form` | `BRoutes.pullOutForm` |

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- `InventoryItemRepository` / `InventoryItemController` — scanned items
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`,
  `b_dialog`

## Known gaps

- **Scanned-item persistence is unconfirmed.** `pull_out_data_manager.dart` reads
  `scannedInventoryItems` from the Standard Delivery form state, but only the Standard
  Delivery and Hotline Direct data managers are known to pass that list through to the
  repository insert payload. Worth verifying that Pull Out items actually reach the server
  rather than only the `/api4/Item/request/{id}` call. See Phase 5 of
  [../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md).
