# Stock Receive Module

## Overview

Stock Receive tracks incoming stock received from clients or returns. It is a variant of
Pull Out / Return, not a separate data model: both read the same table and endpoint, split
by form category — Pull Out / Return is `'4'`, Stock Receive is `'9'`
(`lib/features/logistics/constants/form_category_ids.dart`).

It reuses `PullOutModel`, `PullOutRepository` and `PullOutFormState`, and adds its own
controller, filter manager, data manager and modal config.

Verified against app version 1.1.102.

## Status Flow

```
New Request                   (created with trip ticket, driver, helper, vehicle)
  → In Transit                  (Courier sets In Transit)
    → Taken Out                 (Courier completes)

(Any status) → Cancelled          (requires remarks)
```

Stock Receive mirrors Pull Out **minus the For Pull Out step and the Release step**. The
dispatch info (trip ticket, driver, helper, vehicle) is entered on the create form, so the
assigned driver sees the New Request on their list straight away — couriers only see Stock
Receive requests where they are the driver or helper (`stock_receive_filter_manager.dart`). There is no Getting Supplies
Ready, Item Prepared, For Delivery or Delivered status in this flow — those belong to other
modules and were copied into this document in error for a long time.

The matrix is documented at the top of `screens/stock_receive/stock_receive_list.dart` and
driven by `helpers/stock_receive_modal_config.dart`:

| Status | Request | Release | Courier |
|---|---|---|---|
| New Request | View | View | **Action** — Set In Transit |
| In Transit | View | View | **Action** — Mark Taken Out |
| Taken Out | View | View | View |
| Cancelled | View | View | View |

There is **no `StockReceiveRoleHandler`**. Unlike Pick Up and Hotline Direct, this module
uses a config object rather than handler classes; `services/implementations/` contains only
`hotline_direct_role_handler.dart`, `pick_up_role_handler.dart` and
`request_role_handler.dart`.

### Differences from Pull Out

Two Pull Out features are deliberately suppressed here:

- **No item list.** The shared Pull Out form hides its "Add Item (n)" entry when opened as
  Stock Receive (`pull_out_form.dart`, guarded by `if (!isStockReceive)`).
- **No lost items.** `pull_out_lost_items_section.dart` renders nothing for Stock Receive.

Dispatch moves to creation:

- **Delivery Info on the create form.** When opened as Stock Receive, `pull_out_form.dart`
  shows Trip Ticket No, Driver, Helper and Vehicle. Trip ticket, driver and vehicle are
  required (helper optional); `PullOutDataManager.saveRequestFromForm` re-checks them and
  saves through the **v2 create endpoint**, `POST /api4/v2/RequestPullOutReturnPickUp`
  (`PullOutRepository.insert(withDispatchInfo: true)`), which stores `TripTicketNumber`,
  `Driver`, `Helper` and `MobileID` (a `MobileID` of 0 is stored as null).
  - **Why a v2 and not a change to v1:** older app builds already send those keys to v1
    from the Pull Out form's shared state, which can hold leftovers from the request
    modal. v1 (`POST /api4/RequestPullOutReturnPickUp`, used by Pull Out / Return) still
    ignores them, so old builds behave exactly as before.
  - **Needs the matching `MDMPI.App` build** (`InsertRequestPullOutReturnPickUpV2Dto`,
    `RequestPullOutReturnPickUpController.InsertV2`). Against an older server the v2 call
    returns 404 and the save fails with an error. No database change — the columns
    already existed.
- **Read-only Trip Info in the modal.** `pull_out_modal_body.dart` shows the trip ticket
  and vehicle for Stock Receive. The editable Delivery Info inputs are not shown to Release;
  a Courier only gets them on an older New Request that was saved without dispatch info.

And one requirement is relaxed:

- **Document references are optional.** `BDocumentReference` takes an `isRequired` flag that
  defaults to true; `pull_out_form.dart` passes false for the Stock Receive category, and
  `PullOutDataManager.saveRequestFromForm` (the real create path, see below) drops blank
  entries and allows submission with none when the category is Stock Receive. They remain
  mandatory for Pull Out and Return.

## Architecture

### Folder Structure

```
lib/features/logistics/
  controllers/stock_receive_controller.dart
  helpers/
    stock_receive_modal_config.dart          # role/status action matrix (config object)
    stock_receive_data_manager.dart          # fetch, sync, submit
    stock_receive_filter_manager.dart        # status & date filtering
  screens/stock_receive/
    stock_receive_list.dart
    widgets/
      stock_receive_modal.dart
      stock_receive_filter_dropdown.dart
  screens/request_forms/widgets/stock_receive_form.dart   # see Known gaps
```

Model, repository, DAO, mapper and form state are Pull Out files — this module adds none of
its own.

### Data Flow

```
UI (StockReceiveList)
  → StockReceiveController
    → StockReceiveDataManager / StockReceiveFilterManager
      → PullOutRepository (filtered by FormCategoryID '9')
        → PullOutMapper (DTO ↔ Model)
```

**Create goes through Pull Out.** The "+" button on the Stock Receive tab opens `PullOutForm`
with the Stock Receive category pre-selected, so a new request is saved by
`PullOutController.submitFromForm` → `PullOutDataManager.saveRequestFromForm`, which branches
on the category (no items, optional document references) and then reloads both the Pull Out
list and `StockReceiveController`, so the new request appears on this tab without a manual
refresh. `StockReceiveController.submitFromForm` / `StockReceiveDataManager.saveRequestFromForm`
are not called by any screen.

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `StockReceiveController` | `features/logistics/controllers/` | State management for the Stock Receive tab |
| `StockReceiveModalConfig` | `features/logistics/helpers/` | Role/status action matrix |
| `StockReceiveDataManager` | `features/logistics/helpers/` | Fetch, sync, submit; drops blank document references |
| `StockReceiveFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `PullOutModel` | `features/logistics/models/` | Reused domain model |
| `PullOutRepository` | `data/repositories/pull_out/` | Reused data access |
| `PullOutFormState` | `features/logistics/helpers/` | Reused form state |

### DI Registration

Registered in `GeneralBindings` (`lib/bindings/app/general_bindings.dart`):

```dart
Get.lazyPut(() => StockReceiveController(), fenix: true);  // :216
```

`PullOutRepository` (`:147`) is registered by the Pull Out module.

### Model Fields

None of its own. See the `PullOutModel` field list in
[../pull-out/README.md](../pull-out/README.md); `formCategoryId` is the field that puts a
row on this tab.

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- Common screen widgets: `b_client_information`, `b_document_reference` (with
  `isRequired: false` here), `b_request_form`, `b_dialog`

## Known gaps

- **`stock_receive_form.dart` is unreachable.** It is constructed in `AppRoutes`
  (`requestFormPages[5]`), but `request_controller.dart` routes the Stock Receive category
  to `requestFormPages[1]` — the Pull Out form — so the dedicated form is never shown.
  `hotline_direct_form.dart` is dead in exactly the same way. Either wire both up or delete
  them.
- **No scanner support.** Stock Receive is one of the modules Phase 3 of
  [../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md)
  left undecided; today the answer is "reuse the Pull Out form with the scanner suppressed".
