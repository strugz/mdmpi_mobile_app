# Air & Sea Module

## Overview

The Air & Sea module handles air and sea freight logistics requests within the MDMPI Mobile App. It manages the full lifecycle of air/sea shipment requests — from creation through item preparation, guard endorsement, dispatch, drop-off, and receipt.

## Status Flow

```
New Request
  → Getting Supplies Ready
    → Item Prepared
      → Endorsed to Guard
        → Item Packed
          → Dispatched
            → Drop Off
              → Received

(Any status) → Cancelled
```

## Architecture

### Folder Structure

```
lib/
  features/logistics/
    controllers/
      air_sea_controller.dart           # Main controller (GetxController)
    dtos/air_sea/
      air_sea_dto.dart                  # API response DTO
      air_sea_insert_dto.dart           # Create request DTO
      air_sea_update_dto.dart           # Update request DTO
    helpers/
      air_sea_data_manager.dart         # Data fetch & sync logic
      air_sea_filter_manager.dart       # Status & date filtering
      air_sea_form_state.dart           # Form field state management
      air_sea_modal_config.dart         # Modal display configuration
    mappers/
      air_sea_mapper.dart               # DTO ↔ Model mapping
    models/
      air_sea_model.dart                # Domain model
    screens/air_sea/
      air_sea_list.dart                 # List screen
      widgets/
        air_sea_dispatch_info_section.dart
        air_sea_drop_off_section.dart
        air_sea_item_packed_section.dart
        air_sea_modal.dart
        air_sea_modal_header.dart
        air_sea_request_card.dart
        air_sea_request_modal_footer.dart
        air_sea_waybill_input_section.dart
    screens/request_forms/widgets/
      air_sea_form.dart                 # Create/edit form

  data/
    repositories/air_sea/
      air_sea_repository.dart           # API + local DB operations
    local/dao/air_sea/
      air_sea_dao.dart                  # SQLite DAO
```

### Data Flow

```
UI (AirSeaList / AirSeaForm)
  → AirSeaController
    → AirSeaDataManager / AirSeaFilterManager
      → AirSeaRepository (API via BHttpHelper + local SQLite via AirSeaDao)
        → AirSeaMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `AirSeaController` | `features/logistics/controllers/` | State management, CRUD orchestration |
| `AirSeaRepository` | `data/repositories/air_sea/` | API calls + local DB persistence |
| `AirSeaDao` | `data/local/dao/air_sea/` | SQLite operations |
| `AirSeaModel` | `features/logistics/models/` | Domain model with client & document references |
| `AirSeaMapper` | `features/logistics/mappers/` | Maps API DTOs to/from domain models |
| `AirSeaDataManager` | `features/logistics/helpers/` | Data fetching & sync coordination |
| `AirSeaFilterManager` | `features/logistics/helpers/` | Status & date range filtering |
| `AirSeaFormState` | `features/logistics/helpers/` | Form field controllers & validation |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => AirSeaRepository(), fenix: true);
Get.lazyPut(() => AirSeaController(), fenix: true);
```

### Model Fields

- `id`, `clientId`, `itemCategoryId`, `mobileId`
- `datePickUp`, `itemPreparedAt`, `itemPreparedEndAt`, `preparedBy`
- `endorsedBy` (guard endorsement), `receivedBy`, `waybillNumber`, `receivedAt`
- `tripTicketNumber`, `driver`, `helper`, `dispatchedAt`, `dropOffAt`
- `status`, `remarks`, `createdBy`, `createdAt`, `updatedAt`
- Aggregates: `ClientModel client`, `List<String> documentReference`, `CancelRemarksModel cancelRemarks`

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `ImageRepository` — proof image uploads
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`, `b_dialog`
