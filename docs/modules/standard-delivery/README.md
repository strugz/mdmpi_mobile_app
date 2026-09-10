# Standard Delivery Module

## Overview

Standard Delivery is the primary delivery sub-module: request creation, item preparation,
courier transport with real-time location over WebSocket, and delivery confirmation with
signature and photo proof. It is the base that **Hotline Direct** reuses wholesale — same
model, repository, form state and status flow, separated only by form category.

Verified against app version 1.1.102.

## Status Flow

```
New Request
  → Getting supplies ready      (Release)
    → Item Prepared             (Release, if the current user is the assigned preparer)
      → For Delivery            (Courier, via Request Transport)
        → Delivered             (Courier, Drop Off)

(Any status) → Cancelled          (requires remarks)
```

Status strings live in `lib/base/utils/constants/text_strings.dart:137-141`; the
role × status action matrix is `standard_delivery_modal_config.dart`, mirrored by
`StandardDeliveryStatusFilter` in `standard_delivery_filter_manager.dart`.

Two things this flow is commonly documented wrong:

- **There is no In Transit status.** Courier work happens inside Request Transport while
  the request sits at Item Prepared or For Delivery.
- **The terminal status string is `"Delivered"`.** The constant is named
  `BTexts.statusDoneDelivery`, but its value is "Delivered", not "Done Delivery".

Before Release can mark a request Item Prepared, the delivery preparation details — trip
ticket, driver, helper, vehicle — must be complete. Release can re-assign the driver and
helper afterwards via `reassign_delivery_crew_section.dart`.

### Request Transport (courier workflow)

`screens/request_transport/` is where the courier does everything: dispatch, live location,
receiver details, signature, proof photos, item backload and drop off. It is entered from
Item Prepared or For Delivery **by the assigned crew only** (driver or helper — see
`helpers/crew_assignment.dart`, decided 2026-09-10):

- A user whose only operating role is Courier does not even see other crews' Item
  Prepared / For Delivery requests (`StandardDeliveryFilterManager`; Viewer does not
  count as an operating role).
- Users who also hold Release/Admin keep full visibility, but tapping a request they are
  not crew of opens the role-priority modal (view + Change Driver / Helper), never the
  courier screen (`standard_delivery_list.dart` `_handleRequestTap`).
- Defence in depth: `BActionButton` renders an "Assigned to …" note instead of
  Dispatch / Drop Off, and both `RequestTransportController.processRequestDispatchOrDropOff`
  and `StandardDeliveryDataManager.updateRequestStatus` refuse the For Delivery /
  Delivered transitions for non-crew. Dispatch no longer overwrites the driver with
  whoever pressed it (a helper dispatching keeps the Release-assigned driver).
- Hotline Direct shares the model, screen and rule (`hotline_direct_role_handler.dart`).

- **Proof photos** — up to three, capped by `CameraController.maxProofPhotos = 3`
  (`lib/common/controllers/camera_controller.dart:34`). UI is `b_proof_photo_list.dart`
  with `b_photo_review_screen.dart`.
- **SMS at For Delivery** — `BTexts.statusForDelivery` is in `SmsStatusPolicy`
  (`lib/data/services/sms/sms_status_policy.dart:11`), with a template that includes every
  document reference. Progress shows per recipient; a full-screen auto-dismissing
  "Message Sent!" view (`lib/base/utils/popups/full_screen_loader.dart`) replaced the old
  per-recipient snackbar on request cards.

### Item-level backload

At For Delivery the Request Transport screen shows an "Items to Deliver" checklist above
Proof of Delivery (`request_transport/widgets/backload_items_section.dart`, `.editable`).
The courier unticks items the client will not receive and must give a reason per item; Drop
Off is blocked until every unticked item has one.

The set is saved as a replace-set to `POST /api4/BackloadItem/request/{id}` **before** the
Delivered transition (`BackloadItemRepository.replaceForRequest`). On failure the transition
aborts and the entries are preserved. Completed requests render the same widget as
`.readOnly` on both detail surfaces — the request modal (`b_modal.dart`) and
`standard_delivery_page.dart` — and it hides itself when nothing was recorded.

State lives on the shared `StandardDeliveryFormState` (`backloadItemRemarks`, keyed by
`referenceCode`, plus `backloadItemsRequestId` so entries never leak into another request),
so Hotline Direct is covered automatically. There is no local DB migration — like lost
items, backloaded items are server-side and fetched on demand.

This is **distinct from the whole-request BackLoad flow** (long-press → BackLoad →
Reprocess), which is unchanged and remains the answer for header-only requests.

### Document references and inventory items

Document references are entered in a full-screen editor rather than inline: forms show a
compact "Add Document Reference (n)" button that opens
`screens/common/document_reference_screen.dart`. A hidden `FormField` keeps required and
duplicate validation inside the host form `validate()` pass.

Scanned inventory items are captured from the Stock Issue Slip, including **Part No.,
Serial No. and PTN**. Item code is optional — a line is valid with either an item code or a
part number — so repeat scans merge on part number + item code + serial together
(`helpers/inventory_item_merger.dart`). Anything keyed per item uses `referenceCode`
(part number, falling back to item code), never item code alone.

## Architecture

### Folder Structure

```
lib/features/logistics/
  controllers/
    standard_delivery_controller.dart
    request_transport_controller.dart
    inventory_item_controller.dart
    backload_controller.dart
    web_socket_delivery_controller.dart      # live location during delivery
  helpers/
    standard_delivery_modal_config.dart      # role/status action matrix
    standard_delivery_data_manager.dart      # fetch, sync, submit
    standard_delivery_filter_manager.dart    # status & date filtering
    standard_delivery_form_state.dart        # shared form state (also Hotline Direct)
    inventory_item_merger.dart               # scanned-item identity & merge
    b_proof_image.dart
    proof_image_outbox_uploader.dart
  models/
    standard_delivery_model.dart
    backload_model.dart                      # whole-request backload
    backload_item_model.dart                 # per-item backload
  dtos/standard_delivery/
  mappers/standard_delivery_mapper.dart
  screens/standard_delivery/
    standard_delivery_list.dart
    standard_delivery_page.dart              # full-screen delivery details
    inventory_items_page.dart
    widgets/
      b_modal.dart
      b_request_card_horizontal.dart
      b_filter_dropdown.dart
      b_floating_button.dart
      request_modal_widgets/
        request_modal_header.dart
        request_modal_body.dart
        request_modal_footer.dart
        request_modal_footer_actions.dart
        b_document_reference_list.dart
        reassign_delivery_crew_section.dart
  screens/request_transport/
    request_transport.dart
    widgets/
      b_action_button.dart                   # Dispatch / Drop Off, with validation
      backload_items_section.dart
      b_proof_photo_list.dart
      b_photo_review_screen.dart
      b_drop_off_capture.dart
      b_request_details.dart
      b_dispatcher.dart
      b_client_search.dart
      b_document_reference.dart
      b_mobile.dart
      b_prepared_by_and_dispatcher_information.dart
      b_route_loading_overlay.dart
lib/data/repositories/standard_delivery/
lib/data/repositories/app_data/backload_item_repository.dart
lib/data/local/dao/standard_delivery/
```

### Data Flow

```
UI (StandardDeliveryList / RequestTransport)
  → StandardDeliveryController / RequestTransportController
    → StandardDeliveryDataManager / StandardDeliveryFilterManager
      → StandardDeliveryRepository (API via BHttpHelper + local SQLite via StandardDeliveryDao)
        → StandardDeliveryMapper (DTO ↔ Model)
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `StandardDeliveryController` | `features/logistics/controllers/` | State management, CRUD orchestration |
| `RequestTransportController` | `features/logistics/controllers/` | Courier transport workflow, dispatch/drop off |
| `StandardDeliveryRepository` | `data/repositories/standard_delivery/` | API calls + local DB persistence |
| `BackloadItemRepository` | `data/repositories/app_data/` | Per-item backload replace-set |
| `StandardDeliveryDao` | `data/local/dao/standard_delivery/` | SQLite operations |
| `StandardDeliveryModel` | `features/logistics/models/` | Domain model with client & document references |
| `StandardDeliveryMapper` | `features/logistics/mappers/` | Maps API DTOs to/from domain models |
| `StandardDeliveryModalConfig` | `features/logistics/helpers/` | Role/status action matrix |
| `StandardDeliveryDataManager` | `features/logistics/helpers/` | Data fetching & sync coordination |
| `StandardDeliveryFilterManager` | `features/logistics/helpers/` | Status & date range filtering |
| `StandardDeliveryFormState` | `features/logistics/helpers/` | Form controllers, scanned items, backload remarks |
| `InventoryItemMerger` | `features/logistics/helpers/` | Scanned-item identity and merge rules |

### DI Registration

Registered in `GeneralBindings` (`lib/bindings/app/general_bindings.dart`):

```dart
Get.lazyPut(() => StandardDeliveryRepository(), fenix: true);  // :144
Get.lazyPut(() => ImageRepository(), fenix: true);             // :145
Get.lazyPut(() => InventoryItemRepository(), fenix: true);     // :152
Get.lazyPut(() => BackLoadRepository(), fenix: true);          // :170
Get.lazyPut(() => BackloadItemRepository(), fenix: true);      // :175
Get.lazyPut(() => StandardDeliveryController(), fenix: true);  // :181
Get.lazyPut(() => RequestTransportController(), fenix: true);  // :188
Get.lazyPut(() => BackLoadController(), fenix: true);          // :194
Get.lazyPut(() => InventoryItemController(), fenix: true);     // :218
```

Repositories at `:140-152` sit inside the `Firebase.apps.isNotEmpty` guard;
`BackLoadRepository`, `LoseItemRepository` and `BackloadItemRepository` are registered
outside it so Windows works without FlutterFire.

### Model Fields

`StandardDeliveryModel`:

- `id`, `clientId`, `formCategoryID`, `itemCategoryID`
- `shippingMethod`, `deliveryTerms`, `deliveryDate`, `preference`, `status`
- `requestBy`, `createdBy`, `createdAt`
- `itemPreparedBy`, `itemPreparedAt`, `itemPreparedEndAt`
- `deliveredBy`, `deliveredAt`, `deliveredEndAt`
- `locationStartedAt`, `locationEndAt`
- `tripTicketNumber`, `mobileID`, `mobileName`, `helper`
- `receiver`, `signature`, `image`
- `recipientName`, `recipientContactDetails` — both **optional** on the form
- Aggregates: `ClientModel client`, `List<String> documentReference`,
  `CancelRemarksModel cancelRemarks`

### Related Shared Components

- `CancelRemarksRepository` — cancellation remarks
- `ImageRepository` — proof image uploads
- `ItemCategoryRepository` — item category lookup
- `ClientRepository` — client data
- `InventoryItemRepository` / `InventoryItemController` — scanned items
- Signature and proof-image outboxes — see
  [../personalization/README.md](../personalization/README.md)
- Common screen widgets: `b_client_information`, `b_document_reference`, `b_request_form`,
  `b_dialog`

## Known gaps

- **The scanner contract is still Standard-Delivery-shaped.**
  `lib/common/widgets/scanner/scanner_actions.dart` declares
  `final StandardDeliveryController controller;`, so any other module adopting the scanner
  inherits that dependency. Phase 4 of
  [../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](../request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md)
  covers extracting a shared interface; it has not been started.
