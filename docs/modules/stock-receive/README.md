# Stock Receive Module

## Overview

The Stock Receive module manages stock receive logistics requests within the MDMPI Mobile App. This is a specialized variant of the Pull Out flow, filtered by the "Stock Receive" form category. It reuses the `PullOutModel` and `PullOutRepository` but has its own dedicated controller, filter manager, data manager, and role handler. Stock Receive tracks incoming stock items received from clients or returns.

## Status Flow

```
New Request
  → Getting Supplies Ready
    → Item Prepared
      → For Delivery
        → In Transit
          → Done Delivery

(Any status) → Cancelled
```

## Architecture

### Folder Structure

```
lib/
  features/logistics/
    controllers/
      stock_receive_controller.dart         # Main controller (GetxController)
    helpers/
      stock_receive_data_manager.dart       # Data fetch & sync logic
      stock_receive_filter_manager.dart     # Status & date filtering
    screens/stock_receive/
      stock_receive_list.dart               # List screen
      widgets/
        stock_receive_filter_dropdown.dart   # Filter UI
        stock_receive_modal.dart             # Detail modal
    screens/request_forms/widgets/
      stock_receive_form.dart               # Create/edit form
    services/implementations/
      stock_receive_role_handler.dart       # Role-based action handler

  # Reuses Pull Out data layer:
  data/
    repositories/pull_out/
      pull_out_repository.dart              # Shared with Pull Out
    local/dao/pull_out/
      pull_out_dao.dart                     # Shared SQLite DAO
```

### Data Flow

```
UI (StockReceiveList / StockReceiveForm)
  → StockReceiveController
    → StockReceiveDataManager / StockReceiveFilterManager
      → PullOutRepository (filtered by Stock Receive form category)
        → PullOutMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `StockReceiveController` | `features/logistics/controllers/` | State management, CRUD orchestration |
| `StockReceiveDataManager` | `features/logistics/helpers/` | Data fetching filtered by Stock Receive category |
| `StockReceiveFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `StockReceiveRoleHandler` | `features/logistics/services/implementations/` | Role-based action handling |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => StockReceiveController(), fenix: true);
```

### Notes

- **Reuses `PullOutModel`** — does not have its own model class. The `RxList<PullOutModel> stockReceives` holds Stock Receive data.
- **Reuses `PullOutRepository`** — filters data by `FormCategoryType.stockReceive`.
- **Reuses `PullOutFormState`** — shares the same form state with Pull Out.
- **Reuses `PullOutFilterManager`** — in addition to its own `StockReceiveFilterManager`.
- The relationship between Stock Receive and Pull Out mirrors the Hotline Direct / Standard Delivery pattern.

### Related Shared Components

- `PullOutRepository` — shared repository
- `PullOutModel` — shared domain model
- `PullOutFormState` — shared form state
- `FormCategoryConstants` — form category enum with `stockReceive` type
- `IRequestActionHandler` — abstract action handler interface
- `CancelRemarksRepository` — cancellation remarks
