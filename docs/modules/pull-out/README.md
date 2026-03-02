# Pull Out Module

## Overview

The Pull Out module manages pull-out / return logistics requests within the MDMPI Mobile App. It handles items being returned from clients, including IRRF (Item Return Request Form) processing, item preparation, dispatch, and completion. The Pull Out list screen is combined with "Return Pick Up" in the UI.

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
      pull_out_controller.dart              # Main controller (GetxController)
    dtos/pull_out/
      pull_out_insert_dto.dart              # Create request DTO
    helpers/
      pull_out_data_manager.dart            # Data fetch & sync logic
      pull_out_filter_manager.dart          # Status & date filtering
      pull_out_form_state.dart              # Form field state management
      pull_out_modal_config.dart            # Modal display configuration
    mappers/
      pull_out_mapper.dart                  # DTO ↔ Model mapping
    models/
      pull_out_model.dart                   # Domain model
    screens/pull_out_return_pick_up/
      pull_out_return_pick_up_list.dart      # Combined list screen
      widgets/                              # Pull-out specific UI widgets
    screens/request_forms/widgets/
      pull_out_form.dart                    # Create/edit form

  data/
    repositories/pull_out/
      pull_out_repository.dart              # API + local DB operations
    local/dao/pull_out/
      pull_out_dao.dart                     # SQLite DAO
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
| `PullOutDao` | `data/local/dao/pull_out/` | SQLite operations |
| `PullOutModel` | `features/logistics/models/` | Domain model with IRRF details |
| `PullOutMapper` | `features/logistics/mappers/` | DTO ↔ Model mapping |
| `PullOutDataManager` | `features/logistics/helpers/` | Data fetching & sync |
| `PullOutFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `PullOutFormState` | `features/logistics/helpers/` | Form field controllers & validation |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => PullOutRepository(), fenix: true);
Get.lazyPut(() => PullOutController(), fenix: true);
```

### Model Fields

- `id`, `clientId`, `clientContactPerson`, `formCategoryId`, `itemCategoryId`
- `irrfNumber`, `irrfDate`, `reasonForReturn`
- `releasedBy`, `pullOutDate`, `pullOutDateStartAt`, `pullOutDateEndAt`
- `requestStatus`, `tripTicketNumber`, `driver`, `helper`
- `mobileID`, `mobileName`
- `createdAt`, `updatedAt`, `createdBy`, `requestedBy`
- Aggregates: `ClientModel client`, `List<String> documentReference`, `CancelRemarksModel cancelRemarks`

### Notes

- The Pull Out list screen is named `pull_out_return_pick_up_list.dart` as it combines both Pull Out and Return Pick Up views.
- The `PullOutModel` is also reused by the **Stock Receive** module (see Stock Receive README).
- Route registered in `AppRoutes`: `BRoutes.pullOutForm → PullOutForm()`

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `FormCategoryRepository` — form category lookup
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`
