# BackLoad Module Documentation

## Overview

BackLoad is a logistics workflow for marking a transaction as back load after it is reviewed and modified.

It records a BackLoad event for a request using the following data fields:

- `RequestID`
- `Remarks`
- `DateReported`

`DateReported` is generated and stored by the server.

Each BackLoad entry is recorded per request, and a request may have multiple BackLoad entries.

Unlike cancel remarks, the `Remarks` field is **not free text**. It must be chosen from a fixed dropdown list.

## Purpose

The BackLoad feature is intended to let users:

- open a transaction for review
- modify the transaction for backload handling
- mark the transaction as `Back Load`
- store backload remarks for later viewing
- record every BackLoad entry for the request
- reset the transaction into the standard workflow when reprocessed

## Remarks Options

The dropdown must contain the following values:

- Wrong item
- Time constraint
- Unavailable customer
- Refused delivery
- Reroute
- Expiry not expected

## Suggested Architecture

BackLoad should follow the same GetX-oriented pattern used by logistics request features in this app:

- **Model** for the BackLoad payload
- **Repository** for API/local persistence calls
- **Controller** for state and orchestration
- **Page / Widget** for transaction review and dropdown selection
- **Binding registration** in `GeneralBindings`

### Follow repo Copilot instructions (required)

- Before creating any new widget or UI component, search the repo for existing utilities and shared widgets under `lib/base/utils` and `lib/common/widgets` and reuse or extend them. Do NOT invent new low-level UI widgets when an appropriate shared one exists.
- Preferred reuse candidates (examples): `BCancelRemarks`, `BViewItemsButton`, `RequestModalScaffold`, `RequestModalHeader`, `RequestModalBody`, `RequestModalFooter` and other modal scaffolding. If a BackLoad-specific summary widget is needed, place it under `lib/common/widgets/modals/` (we added `b_backload_remarks.dart` as an example).
- If no suitable component exists, create a new widget and place it in either `lib/base/utils/popups/` (framework-level) or `lib/common/widgets/<category>/` (shared UI) depending on scope and reusability. Document the placement decision in a short README/TODO near the new file.
- Respect naming conventions and public API patterns from the repository (`B` prefix for shared utilities, snake_case file names, PascalCase classes).
- Register controllers/repositories in `GeneralBindings` using `Get.lazyPut(..., fenix: true)` unless there is a documented reason to use `Get.put` or a different lifecycle.
- Keep UI code pure: no business/data logic in `build` methods; controllers call repositories and expose minimal observable state for `Obx` bindings.
- Use `Result<T>` and typed exceptions from `base/utils/exceptions/` for async result handling. Avoid throwing raw exceptions to the UI.


## Proposed Folder Placement

### Model

`lib/features/logistics/models/backload_model.dart`

### Repository

`lib/data/repositories/app_data/backload_repository.dart`

### Controller

`lib/features/logistics/controllers/backload_controller.dart`

### UI

Possible reusable UI locations:

- `lib/common/widgets/dialogs/`
- `lib/common/widgets/modals/`
- `lib/features/logistics/presentation/pages/`

## Back Load Process Workflow

### 1) Accessing a Transaction

When a user long-presses a transaction for back load, the system opens the **Transaction Details** page.

That page should display only the Standard Delivery `InsertDto` fields for review.
Only `deliveryDate` should be editable.
 
 Note: the long-press flow for initiating a Back Load must **directly navigate** to the
 `BackLoadTransactionPage` (or equivalent conversion page). Do **not** invoke
 `BDialog.showRemarksDialog(...)` or present a Cancel/Back Load choice sheet from
 the long-press action — the app should open the Back Load page immediately.

### 2) Updating Transaction to Back Load

Once the transaction data is modified and marked for back load:

- the transaction status is updated to `Back Load`
- the save should persist the BackLoad record to the API first; if the API save fails, nothing should be written to the local BackLoad table
- after API success, any local BackLoad history sync can be updated, and the transaction workflow state should be reset so the request can re-enter the standard flow when reprocessed
- this status change triggers specific behavior in other modules

### 3) Standard Delivery Modal Behavior

If a transaction has a status of `Back Load`, the **Standard Delivery modal** should display the **Back Load remarks** instead of the default content.

### 4) Reprocessing Back Load Transactions

When a user taps a transaction with `Back Load` status:

- the system should treat it as a new request
- all previous process states are reset
- the transaction re-enters the standard workflow from the beginning

### 5) Data Loading on App Initialization

Upon opening the application:

- Back Load data is retrieved from the API
- the system loads and maps this data only for transactions that already have BackLoad history
- only existing BackLoad entries are loaded and mapped per request

## Data Flow

```text
Transaction list / detail page
  → BackLoadController
    → BackLoadRepository
      → API-first persistence; local history only when BackLoad history already exists
```

## Behavior Notes

- The dropdown should enforce a single selected reason.
- The UI should prevent empty submission.
- `DateReported` should come from the server-side backend contract.
- If BackLoad is viewable after save, it should use a read-only summary widget similar to the cancel-remarks display pattern.
- The BackLoad page should reuse the request context, but **reset the editable Standard Delivery fields** instead of reusing the existing live form state unchanged.
- The Transaction Details page should view only the Standard Delivery `InsertDto` fields, while `deliveryDate` remains editable.
- Read-only request identity fields may remain visible, but the editable delivery input should be limited to `deliveryDate` for the conversion flow.
- BackLoad remarks should be shown inside the Standard Delivery modal when the request status is `Back Load`.
- Reprocessing a BackLoad transaction should clear the prior workflow state and start the standard workflow over.
- Multiple BackLoad entries per request are supported and should all be preserved.
- When the request re-enters the workflow, the Standard Delivery `InsertDto` should keep its structure with all fields remaining `null` except `deliveryDate`; only `deliveryDate` needs to be edited.

## Reuse From Cancel Remarks

The existing cancel-remarks implementation provides a useful reference for:

- request-level action entry points
- shared dialog patterns
- GetX controller delegation
- loading/error feedback
- summary display widgets

What should change for BackLoad:

- replace free-text reason entry with a fixed dropdown
- store `DateReported` instead of cancellation date semantics
- use a **new BackLoad-specific backend endpoint** and persist to the API first; local BackLoad rows should only exist when the transaction already has BackLoad history
- treat the workflow as a transaction conversion flow, not only a remarks-entry flow

## Implementation Plan

1. Add the BackLoad model.
2. Add repository methods for saving BackLoad to the API and fetching existing BackLoad history from `a_tblRequestBackload`.
3. Add a GetX controller for transaction review, selected reason, save state, and loaded data.
4. Create a transaction details page / conversion page that opens on long-press.
5. Add a read-only BackLoad remarks widget for the Standard Delivery modal.
6. Register the repository/controller in `GeneralBindings`.
7. Wire the long-press action to directly open `BackLoadTransactionPage` (do **not** use `BDialog.showRemarksDialog`). Also wire BackLoad modal behavior into the relevant logistics request screens.
8. Confirm backend endpoint shape, field casing, and status reset behavior.

## Transaction ID Rule

BackLoad reprocessing must **preserve the original transaction ID**, even when the request is reprocessed.

- The `Transaction ID` is the same identifier used by the Standard Delivery, Pull Out, Pick Up, and Air Sea models.
- A BackLoad action creates a new BackLoad record entry, but it does **not** replace the original transaction ID.
- When the request re-enters the workflow, the system keeps the same transaction ID and resets the standard delivery `InsertDto` state, with only `deliveryDate` remaining editable.
- Because BackLoad supports multiple entries per request, the preserved transaction ID is used to link all BackLoad history rows back to the same request.

## Documentation Status

This document is a planning and alignment reference for the BackLoad feature.

## Implementation Status

All layers have been implemented:

| Layer | File | Status |
|-------|------|--------|
| Model | `lib/features/logistics/models/backload_model.dart` | ✅ Complete |
| DAO | `lib/data/local/dao/common/backload_dao.dart` | ✅ Complete |
| DB Schema | `lib/data/local/db_schema.dart` (`a_tblRequestBackload`) | ✅ Complete |
| Repository | `lib/data/repositories/app_data/backload_repository.dart` | ✅ `Result<T>` wrapped, API-first save |
| Controller | `lib/features/logistics/controllers/backload_controller.dart` | ✅ `Result<T>`, reprocess, load remarks |
| Transaction Page | `lib/features/logistics/screens/back_load/backload_transaction_page.dart` | ✅ Complete |
| Remarks Widget | `lib/common/widgets/modals/b_backload_remarks.dart` | ✅ Complete |
| Bindings | `lib/bindings/general_bindings.dart` | ✅ Repo + Controller registered |
| Route Constant | `lib/base/utils/routes/routes.dart` (`BRoutes.backLoad`) | ✅ Defined |
| Route Page | `lib/base/utils/routes/app_routes.dart` (`GetPage`) | ✅ Registered |
| Status Constant | `lib/base/utils/constants/text_string.dart` (`BTexts.statusBackLoad`) | ✅ Defined |
| Modal Config | `lib/features/logistics/helpers/standard_delivery_modal_config.dart` | ✅ Back Load → Reprocess action |
| SD Modal | `lib/features/logistics/screens/standard_delivery/widgets/b_modal.dart` | ✅ BackLoad remarks section |
| SD Page | `lib/features/logistics/presentation/pages/standard_delivery/standard_delivery_page.dart` | ✅ BackLoad remarks section |
| SD List | `lib/features/logistics/screens/standard_delivery/standard_delivery_list.dart` | ✅ Long-press + tap wiring |

### Key behaviors

- **API-first save:** `BackLoadRepository.addBackLoad` posts to API first; local DB write only on API success.
- **Local table loading:** local `a_tblRequestBackload` only populated via API sync or after successful save.
- **Reprocessing:** tapping a Back Load request opens the SD modal with a "Reprocess" button that resets status to `New Request`.
- **Long-press guard:** Back Load status is excluded from the long-press flow (cannot back-load an already back-loaded request).
- **All BackLoad entries** for a request are shown in the modal (not just the latest).






