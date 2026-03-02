# Pick Up Module

## Overview

The Pick Up module manages pick-up logistics requests within the MDMPI Mobile App. It handles the lifecycle of client item pick-up operations — from request creation through item preparation, release, and receipt confirmation.

## Status Flow

```
New Request
  → Getting Supplies Ready
    → Item Prepared
      → Taken Out (Released)
        → Received

(Any status) → Cancelled
```

## Architecture

### Folder Structure

```
lib/
  features/logistics/
    controllers/
      pick_up_controller.dart               # Main controller (GetxController)
    dtos/pick_up/
      pick_up_insert_dto.dart               # Create request DTO
      pick_up_update_dto.dart               # Update request DTO
    helpers/
      pick_up_data_manager.dart             # Data fetch & sync logic
      pick_up_filter_manager.dart           # Status & date filtering
      pick_up_form_state.dart               # Form field state management
    mappers/
      pick_up_mapper.dart                   # DTO ↔ Model mapping
    models/
      pick_up_model.dart                    # Domain model
    screens/pick_up/
      pick_up_list.dart                     # List screen
      widgets/                              # Pick-up specific UI widgets
    screens/request_forms/widgets/
      pick_up_form.dart                     # Create/edit form
    services/implementations/
      pick_up_role_handler.dart             # Role-based action handler

  data/
    repositories/pick_up/
      pick_up_repository.dart               # API + local DB operations
    local/dao/pick_up/
      pick_up_dao.dart                      # SQLite DAO
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
| `PickUpModel` | `features/logistics/models/` | Domain model with client & item category |
| `PickUpMapper` | `features/logistics/mappers/` | DTO ↔ Model mapping |
| `PickUpDataManager` | `features/logistics/helpers/` | Data fetching & sync |
| `PickUpFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `PickUpFormState` | `features/logistics/helpers/` | Form field controllers & validation |
| `PickUpRoleHandler` | `features/logistics/services/implementations/` | Role-based action handling |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => PickUpRepository(), fenix: true);
Get.lazyPut(() => PickUpController(), fenix: true);
```

### Model Fields

- `id`, `clientId`, `itemCategoryId`
- `preparedBy`, `itemPreparedAt`, `itemPreparedEndAt`
- `datePickUp`, `remarks`, `status`
- `releasedBy`, `receivedBy`, `createdBy`, `createdAt`, `updatedAt`
- Aggregates: `ClientModel client`, `ItemCategoryModel itemCategory`, `List<String> documentReference`

### Related Shared Components

- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- `IRequestActionHandler` — abstract action handler interface
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`
