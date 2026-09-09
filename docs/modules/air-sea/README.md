# Air / Sea / Land Module

## Overview

The Air / Sea / Land module handles air, sea and land freight logistics requests within the MDMPI Mobile App. It manages the full lifecycle of air/sea shipment requests — from creation through item preparation, guard endorsement, dispatch, drop-off, and receipt.

### Air / Sea / Land HD variant (2026-09-09)

The **"Air / Sea / Land HD"** form category is the Hotline-Direct (urgent) variant of
this module — analogous to Hotline Direct vs Standard Delivery. Both tabs share the
same table (`a_tblRequestAirSea` / `a_tblrequestairsea`), endpoint
(`/api4/RequestAirSea`), status flow, and role matrix; rows are split by a nullable
`FormCategoryID` (`FormCategoryIds.airSeaHd = '21'`; NULL/legacy rows belong to the
base tab — see `AirSeaCategoryScope` in `lib/features/logistics/constants/form_category_ids.dart`).
`AirSeaHdController` (`lib/features/logistics/controllers/air_sea_hd_controller.dart`)
extends `AirSeaController`, overriding only its data scope; shared pages/sections
resolve the owning controller via `AirSeaControllers.forRequest(...)`. Creation on the
HD tab is restricted to users holding the **"HD" role** (Firestore `Roles`). The
backend GET excludes HD rows unless `includeHd=true`, so pre-HD app builds are
unaffected. Server migrations:
`MDMPI.App/migration_20260909_add_air_sea_formcategoryid.sql` and
`MDMPI.App/migration_20260909_add_air_sea_hd_category.sql`.

## Status Flow

```
New Request
  → Getting Supplies Ready
    → Item Packed
      → Endorsed to Guard
        → For Dispatch
          → Dispatch
            → Drop Off
              → Received
                → Provincial Pick Up        ┐
                  → Provincial In Transit   │ provincial extension
                    → Provincial Delivered  ┘

(Any status) → Cancelled
```

Status strings are defined in `lib/base/utils/constants/text_strings.dart:137-157`; the
role × status action matrix lives in
`lib/features/logistics/helpers/air_sea_modal_config.dart`. Note there is no "Item
Prepared" step in this flow, and the dispatch status is `Dispatch`, not "Dispatched".

### Provincial extension

Requests that continue to a provincial destination carry on past Received through three
further statuses, handled by the `Provincial` role (`BTexts.roleProvincial`) and resolved
in `air_sea_modal_config.dart` (`_resolveProvincial`). `Provincial Delivered` — not
`Received` — is the terminal status for these requests.

The seven provincial model fields (`provincialPickUpBy`, `provincialPickUpAt`,
`provincialInTransitAt`, `provincialInTransitLocation`, `provincialDeliveredEndAt`,
`provincialDeliveredLocation`, `provincialReceiverName`) are stored as `TEXT DEFAULT ''`
columns on `a_tblRequestAirSea` (`lib/data/local/db_schema.dart:234-240`) — added to the
schema directly, with no runtime migration. UI lives in
`air_sea_provincial_pick_up_section.dart`, `air_sea_provincial_in_transit_section.dart`
and `air_sea_provincial_delivery_section.dart`.

**Not yet built** (carried over from the provincial delivery plan, removed 2026-09-09):

- Transaction history / audit trail — no `RequestHistoryDto`, `RequestHistoryModel`, or
  local `a_tblRequestHistory` table exists. Related dead code: the per-status history DTOs
  under `dtos/air_sea/` and `AirSeaStatusStagesMapper` have no callers, and
  `screens/air_sea/widgets/air_sea_history_section.dart` is an empty placeholder file.
  Either finish this or delete the orphans.
- Tests — there is no DAO round-trip, mapper, controller or widget test covering the
  provincial statuses.

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
