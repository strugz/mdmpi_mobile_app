# Hotline Direct Module

## Overview

The Hotline Direct module manages hotline direct delivery requests. This is a specialized variant of the Standard Delivery flow, filtered by the "Hotline Direct" form category. It reuses the `StandardDeliveryModel` and `StandardDeliveryRepository` but has its own dedicated controller, filter manager, data manager, and role handler. The controller implements `IDeliveryRequestController` for polymorphic role-based action handling.

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
      hotline_direct_controller.dart        # Main controller (implements IDeliveryRequestController)
    helpers/
      hotline_direct_data_manager.dart      # Data fetch & sync logic
      hotline_direct_filter_manager.dart    # Status & date filtering
    screens/hotline_direct/
      hotline_direct_list.dart              # List screen
      widgets/
        hotline_direct_filter_dropdown.dart  # Filter UI
    screens/request_forms/widgets/
      hotline_direct_form.dart              # Create/edit form
    services/implementations/
      hotline_direct_role_handler.dart      # Role-based action handler

  # Reuses Standard Delivery data layer:
  data/
    repositories/standard_delivery/
      standard_delivery_repository.dart     # Shared with Standard Delivery
```

### Data Flow

```
UI (HotlineDirectList / HotlineDirectForm)
  → HotlineDirectController (implements IDeliveryRequestController)
    → HotlineDirectDataManager / HotlineDirectFilterManager
      → StandardDeliveryRepository (filtered by Hotline Direct form category)
        → StandardDeliveryMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `HotlineDirectController` | `features/logistics/controllers/` | State management, implements `IDeliveryRequestController` |
| `HotlineDirectDataManager` | `features/logistics/helpers/` | Data fetching filtered by Hotline Direct category |
| `HotlineDirectFilterManager` | `features/logistics/helpers/` | Status & date filtering |
| `HotlineDirectRoleHandler` | `features/logistics/services/implementations/` | Role-based action handling |
| `IDeliveryRequestController` | `common/services/abstracts/` | Shared controller interface |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => HotlineDirectController(), fenix: true);
```

### Notes

- **Reuses `StandardDeliveryModel`** — does not have its own model class.
- **Reuses `StandardDeliveryRepository`** — filters data by `FormCategoryType.hotlineDirect`.
- **Reuses `StandardDeliveryFormState`** — shares the same form state with Standard Delivery.
- The `IDeliveryRequestController` interface in `common/services/abstracts/` enables polymorphic role-based handling across delivery-type modules.

### Related Shared Components

- `StandardDeliveryRepository` — shared repository
- `StandardDeliveryModel` — shared domain model
- `StandardDeliveryFormState` — shared form state
- `FormCategoryConstants` — form category enum with `hotlineDirect` type
- `IRequestActionHandler` — abstract action handler interface
- `CancelRemarksRepository` — cancellation remarks
