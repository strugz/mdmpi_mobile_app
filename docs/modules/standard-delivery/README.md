# Standard Delivery Module

## Overview

The Standard Delivery module manages standard delivery logistics requests. It is the primary delivery sub-module handling shipment creation, item preparation, dispatch, in-transit tracking (with real-time location via WebSocket), and delivery confirmation with signature/image proof capture.

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
      standard_delivery_controller.dart     # Main controller (GetxController)
      delivery_location_controller.dart     # Real-time location tracking
      delivery_vehicle_controller.dart      # Vehicle assignment
      request_transport_controller.dart     # Transport request management
      web_socket_delivery_controller.dart   # WebSocket for live delivery updates
      web_socket_dispatcher_controller.dart # WebSocket for dispatcher updates
    dtos/standard_delivery/
      standard_delivery_dto.dart            # API response DTO
      standard_delivery_insert_dto.dart     # Create request DTO
      standard_delivery_update_dto.dart     # Update request DTO
    helpers/
      standard_delivery_data_manager.dart   # Data fetch & sync logic
      standard_delivery_filter_manager.dart # Status & date filtering
      standard_delivery_form_state.dart     # Form field state management
      status_color_mapper.dart              # Status → color mapping
    mappers/
      standard_delivery_mapper.dart         # DTO ↔ Model mapping
    models/
      standard_delivery_model.dart          # Domain model
      delivery_vehicle_model.dart           # Vehicle model
      rider_location_model.dart             # Real-time rider location
      location_alternative_model.dart       # Alternative location data
    screens/standard_delivery/
      standard_delivery_list.dart           # List screen
      widgets/
        b_filter_dropdown.dart
        b_floating_button.dart
        b_modal.dart
        b_request_card_horizontal.dart
        request_modal_widgets/              # Modal sub-widgets
    screens/request_forms/widgets/
      standard_delivery_form.dart           # Create/edit form
    screens/delivery_location/
      location_google.dart                  # Google Maps location view
    screens/request_transport/
      request_transport.dart                # Transport request screen

  data/
    repositories/standard_delivery/
      standard_delivery_repository.dart     # API + local DB operations
    repositories/delivery_vehicle/
      delivery_vehicle_repository.dart      # Vehicle data operations
    repositories/image/
      image_repository.dart                 # Image upload operations
    local/dao/standard_delivery/
      standard_delivery_dao.dart            # SQLite DAO
      location_alternative_dao.dart         # Location alternative DAO
```

### Data Flow

```
UI (StandardDeliveryList / StandardDeliveryForm)
  → StandardDeliveryController
    → StandardDeliveryDataManager / StandardDeliveryFilterManager
      → StandardDeliveryRepository (API via BHttpHelper + local SQLite)
        → StandardDeliveryMapper (DTO ↔ Model)

Real-time tracking:
  WebSocketDeliveryController → DeliveryLocationController → Google Maps UI
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `StandardDeliveryController` | `features/logistics/controllers/` | State, CRUD, signature/image capture |
| `DeliveryLocationController` | `features/logistics/controllers/` | Real-time GPS location tracking |
| `DeliveryVehicleController` | `features/logistics/controllers/` | Vehicle assignment management |
| `WebSocketDeliveryController` | `features/logistics/controllers/` | Live delivery status via WebSocket |
| `WebSocketDispatcherController` | `features/logistics/controllers/` | Dispatcher updates via WebSocket |
| `StandardDeliveryRepository` | `data/repositories/standard_delivery/` | API + local DB operations |
| `StandardDeliveryDao` | `data/local/dao/standard_delivery/` | SQLite operations |
| `StandardDeliveryModel` | `features/logistics/models/` | Domain model |
| `StandardDeliveryMapper` | `features/logistics/mappers/` | DTO ↔ Model mapping |
| `LogisticsStatusColors` | `features/logistics/helpers/` | Centralized status color mapping |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => StandardDeliveryRepository(), fenix: true);
Get.lazyPut(() => StandardDeliveryController(), fenix: true);
Get.lazyPut(() => DeliveryVehicleRepository(), fenix: true);
Get.lazyPut(() => DeliveryVehicleController(), fenix: true);
Get.lazyPut(() => DeliveryLocationController(), fenix: true);
Get.lazyPut(() => WebSocketDeliveryController(), fenix: true);
Get.lazyPut(() => WebSocketDispatcherController(), fenix: true);
Get.lazyPut(() => RequestTransportController(), fenix: true);
Get.lazyPut(() => ImageRepository(), fenix: true);
```

### Model Fields

- `id`, `clientId`, `shippingMethod`, `deliveryTerms`, `deliveryDate`, `preference`
- `status`, `requestBy`, `createdBy`, `itemPreparedBy`, `deliveredBy`
- `itemPreparedAt`, `itemPreparedEndAt`, `deliveredAt`, `deliveredEndAt`
- `documentReference`, `locationStartedAt`, `locationEndAt`
- `mobileID`, `mobileName`, `helper`, `receiver`, `signature`, `image`, `tripTicketNumber`
- `itemCategoryID`, `formCategoryID`
- Aggregates: `ClientModel client`, `CancelRemarksModel cancelRemarks`

### Related Shared Components

- `ILocationTrackingService` / `LocationTrackingService` — GPS location tracking
- `IMapsService` / `MapsService` — Google Maps integration
- `IPlacesService` / `PlacesService` — Google Places autocomplete
- `ILocationAlternativeService` / `LocationAlternativeService` — fallback location
- `CancelRemarksRepository` — cancellation remarks
- `ImageRepository` — proof image uploads
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`
