# Inventory Scanner Rollout Plan for Request Forms

## Overview

This plan describes how to extend the inventory scanner entry currently used in `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart` to the other request-form modules under `lib/features/logistics/screens/request_forms/widgets/`.

The goal is to reuse the existing full-screen scanner flow:

- reactive `Add Item (count)` action
- navigation to `ScannedItemsScreen`
- shared scanned item list editing/clearing behavior
- safe rollout without breaking each module's existing submit flow

## Status Flow

### Current source implementation

`standard_delivery_form.dart` already provides:

- reactive item count using `BHelperFunctions.listCount(...)`
- `TextButton.icon` entry point
- full-screen navigation to `ScannedItemsScreen(controller: stdDeliveryController)`
- backing state in `StandardDeliveryFormState.scannedInventoryItems`

### Current reuse boundaries

The request forms already share some state and widgets:

- `BClientInformation` and `BDocumentReference` depend on `StandardDeliveryController`
- `PickUpForm`, `PullOutForm`, and `AirSeaForm` already resolve `StandardDeliveryController` as `stdController`
- `HotlineDirectForm` already uses `StandardDeliveryController` form state directly
- `StockReceiveForm` is still mostly a placeholder UI

### Current persistence differences

Scanned inventory items are currently saved end-to-end only in flows backed by the standard-delivery form state:

- `standard_delivery_data_manager.dart` passes `formState.scannedInventoryItems` into `StandardDeliveryRepository.insertDelivery(...)`
- `hotline_direct_data_manager.dart` also passes `formState.scannedInventoryItems` into the same repository

Other modules currently do **not** persist scanned items during save:

- `pick_up_data_manager.dart`
- `pull_out_data_manager.dart`
- `air_sea_data_manager.dart`
- `stock_receive_data_manager.dart`

## Architecture

### Relevant UI files

- `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart`
- `lib/features/logistics/screens/request_forms/widgets/pull_out_form.dart`
- `lib/features/logistics/screens/request_forms/widgets/pick_up_form.dart`
- `lib/features/logistics/screens/request_forms/widgets/air_sea_form.dart`
- `lib/features/logistics/screens/request_forms/widgets/hotline_direct_form.dart`
- `lib/features/logistics/screens/request_forms/widgets/stock_receive_form.dart`

### Shared scanner widgets

- `lib/common/widgets/scanner/scanned_items_screen.dart`
- `lib/common/widgets/scanner/b_item_scanner.dart`
- `lib/common/widgets/scanner/scanner_actions.dart`
- `lib/common/widgets/scanner/scanned_item_tile.dart`

### State and orchestration files

- `lib/features/logistics/helpers/standard_delivery_form_state.dart`
- `lib/features/logistics/helpers/standard_delivery_data_manager.dart`
- `lib/features/logistics/helpers/hotline_direct_data_manager.dart`
- `lib/features/logistics/helpers/pick_up_data_manager.dart`
- `lib/features/logistics/helpers/pull_out_data_manager.dart`
- `lib/features/logistics/helpers/air_sea_data_manager.dart`
- `lib/features/logistics/helpers/stock_receive_data_manager.dart`
- `lib/features/logistics/controllers/request_controller.dart`

## Implementation Plan

### Phase 0 — Confirm rollout scope and success criteria

1. Confirm which modules need UI-only parity versus full persistence.
2. Treat these as primary rollout targets because they already use shared request widgets/state:
   - `pull_out_form.dart`
   - `pick_up_form.dart`
   - `air_sea_form.dart`
3. Treat these as special cases:
   - `hotline_direct_form.dart` — already close to standard delivery behavior, but its route currently points to the shared standard form in `request_controller.dart`
   - `stock_receive_form.dart` — dedicated widget exists but current routing still points to the pull-out form and the widget itself is incomplete
4. Define success for phase 1 as:
   - every target form shows the `Add Item` action
   - the count updates reactively
   - the button opens `ScannedItemsScreen`
   - no form crashes when the scanner is unused

### Phase 1 — Add the scanner entry UI to forms already using `stdController`

Apply the same pattern from `standard_delivery_form.dart` to:

- `pull_out_form.dart`
- `pick_up_form.dart`
- `air_sea_form.dart`

Implementation notes:

1. Add imports only where missing:
   - `helper_functions.dart`
   - `scanned_items_screen.dart`
2. Insert the scanner action directly below `BDocumentReference()` to keep form layout consistent with standard delivery.
3. Use the already-resolved `StandardDeliveryController` instance (`stdController`) for the count and navigation.
4. Keep the widget implementation identical where possible to minimize behavior drift.

Expected result:

- scanner UI parity across the three forms
- shared count sourced from `stdController.formState.scannedInventoryItems`
- no new controller registrations required

### Phase 2 — Add or align scanner entry for Hotline Direct

For `hotline_direct_form.dart`:

1. Add the same `Add Item (count)` entry using its `StandardDeliveryController` instance.
2. Keep it consistent with the standard delivery button label and placement.
3. Verify whether this form is actually reachable in create-flow navigation, because `RequestController.openFormForCurrentCategory()` currently maps Hotline Direct to `AppRoutes.requestFormPages[0]` (the standard-delivery form), not `HotlineDirectForm`.

Decision point:

- If Hotline Direct should continue using `StandardDelivery`, then no dedicated `HotlineDirectForm` scanner work is needed beyond documentation cleanup.
- If Hotline Direct should use its dedicated form, routing must be corrected before or during the rollout.

### Phase 3 — Decide how Stock Receive should participate

`stock_receive_form.dart` cannot receive the scanner feature as-is because it is only a shell screen today.

Plan:

1. Decide whether Stock Receive should remain a pull-out-derived form or gain a dedicated create form.
2. Review current routing because `RequestController.openFormForCurrentCategory()` maps Stock Receive to `AppRoutes.requestFormPages[1]` (pull-out form).
3. If Stock Receive keeps reusing `PullOutForm`, the scanner can be added there and documented as shared behavior.
4. If Stock Receive gets its own real form later, add the scanner only after that form contains:
   - client section
   - document reference section
   - submission flow

### Phase 4 — Harden the shared scanner contract

The current scanner widgets use loose duck typing, but one widget is still strongly typed:

- `ScannerActionRow` requires `StandardDeliveryController`

This creates a risk if future modules want their own controller-backed scanner flow.

Refactor target:

1. Introduce a small shared scanner contract or interface for:
   - `formState.scannedInventoryItems`
   - `isAnalyzingFile`
   - `pickAndAnalyzeFromCamera()`
   - `pickAndAnalyzeFromFile()`
   - `clearScannedItems()`
   - item update/remove helpers used by `ScannedItemTile`
2. Update:
   - `scanned_items_screen.dart`
   - `b_item_scanner.dart`
   - `scanner_actions.dart`
   - `scanned_item_tile.dart`
3. Keep backward compatibility so `StandardDeliveryController` still works unchanged.

This phase is not strictly required for UI rollout, but it reduces long-term coupling.

### Phase 5 — Decide persistence scope for non-standard modules

This is the largest product/technical decision.

#### Option A — UI-only rollout first

- Add scanner UI and local editing to other forms.
- Keep persistence only for Standard Delivery and Hotline Direct.
- Clear scanner state on submit/reset for modules that do not save items.

**Pros**
- fastest and lowest-risk rollout
- no API or repository contract changes

**Cons**
- user expectation gap if scanned items are visible but not saved

#### Option B — Persist only where backend already supports it

- Keep scanner fully functional only in Standard Delivery and Hotline Direct.
- Use a reduced or hidden rollout for other forms until APIs are ready.

**Pros**
- avoids false expectations

**Cons**
- inconsistent UX across modules

#### Option C — Extend persistence across all modules

For each non-standard module:

1. update model/DTO/mapper if needed
2. update repository insert/update payloads
3. update local DB persistence if required
4. update save flows in data managers
5. verify server contracts

Affected files likely include:

- `pick_up_data_manager.dart` and repository/model chain
- `pull_out_data_manager.dart` and repository/model chain
- `air_sea_data_manager.dart` and repository/model chain
- `stock_receive_data_manager.dart` and repository/model chain

**Pros**
- complete feature parity

**Cons**
- highest scope and backend dependency

## API Details

No API change is required for the initial UI-only rollout.

If full persistence is chosen later, verify for each module:

1. whether the create endpoint accepts inventory item payloads
2. whether local storage tables need extension
3. whether update/history endpoints must include scanned items
4. whether existing mappers or DTOs need nested item serialization

## Testing Guide

### Form-level checks per module

For each rollout target:

1. open the request form
2. verify `Add Item` is visible near the document reference section
3. verify label changes to `Add Item (N)` after scanning/adding items
4. open `ScannedItemsScreen`
5. verify capture, attach, edit, delete, and clear flows
6. return to the form and confirm the count stays in sync
7. submit the form and confirm state reset behavior is correct
8. reopen the form and confirm no item leakage from prior form usage

### Module QA files to reuse

- `qa/standard_delivery_request_qa.md`
- `qa/pull_out_request_qa.md`
- `qa/pick_up_request_qa.md`
- `qa/air_sea_request_qa.md`
- `qa/hotline_direct_request_qa.md`
- `qa/stock_receive_request_qa.md`

### Static checks

After implementation:

1. run `flutter analyze`
2. run `flutter test`
3. smoke-test create-request flows for each affected form

## Troubleshooting / Risks

### 1. Shared state leakage

Risk: multiple forms use `StandardDeliveryController.formState.scannedInventoryItems`, so scanned items may carry over between modules if reset timing is incomplete.

Mitigation:

- explicitly clear scanner state on successful save and on form reset
- smoke-test switching between modules without app restart

### 2. Routing mismatch

Risk: `RequestController.openFormForCurrentCategory()` currently routes:

- Hotline Direct → `StandardDelivery`
- Stock Receive → `PullOutForm`

Mitigation:

- decide whether rollout should follow the actual routed forms or the dedicated form widgets
- fix navigation before documenting dedicated behavior

### 3. UI/persistence mismatch

Risk: users may believe scanned items are submitted for Pick Up, Pull Out, Air/Sea, or Stock Receive when they are currently only held in shared UI state.

Mitigation:

- choose UI-only vs persistence rollout explicitly before release
- if UI-only, add a clear internal note or temporary restriction

### 4. Controller coupling in scanner widgets

Risk: `ScannerActionRow` is typed to `StandardDeliveryController`, while other scanner widgets rely on dynamic access.

Mitigation:

- extract a formal scanner contract before broader controller reuse

## Recommended Delivery Order

1. `pick_up_form.dart`
2. `pull_out_form.dart`
3. `air_sea_form.dart`
4. `hotline_direct_form.dart` or navigation cleanup in `request_controller.dart`
5. stock receive routing/form decision
6. shared scanner contract hardening
7. persistence expansion only if product/backend confirms scope

## Recommendation

Use a **two-step rollout**:

### Step 1

Deliver UI parity first for:

- Pick Up
- Pull Out
- Air / Sea

using the existing shared `StandardDeliveryController` scanner state.

### Step 2

Before enabling broader production use, decide whether scanned items must be truly persisted for those modules. If yes, implement repository/model/API support module by module instead of forcing one large refactor.
````</attachment></attachments>User have attached following context reference, if you did not seen them, they might got omitted due to contents are too large:<attached_context>Files:- file:///F:/mdmpi_mobile_app/docs/README.md (61 lines, 3514 characters)Total: 1 file(s), 61 lines, 3514 characters</attached_context><context>The current date is April 29, 2026.</context><reminderInstructions>You are an agent - you must keep going until the user's query is completely resolved, before ending your turn and yielding back to the user.Your thinking should be thorough and so it's fine if it's very long. However, avoid unnecessary repetition and verbosity. You should be concise, but thorough.You MUST iterate and keep going until the problem is solved.You have everything you need to resolve this problem. I want you to fully solve this autonomously before coming back to me.Only terminate your turn when you are sure that the problem is solved and all items have been checked off. Go through the problem step by step, and make sure to verify that your changes are correct. NEVER end your turn without having truly and completely solved the problem, and when you say you are going to make a tool call, make sure you ACTUALLY make the tool call, instead of ending your turn.Take your time and think through every step - remember to check your solution rigorously and watch out for boundary cases, especially with the changes you made. Your solution must be perfect. If not, continue working on it. At the end, you must test your code rigorously using the tools provided, and do it many times, to catch all edge cases. If it is not robust, iterate more and make it perfect. Failing to test your code sufficiently rigorously is the NUMBER ONE failure mode on these types of tasks; make sure you handle all edge cases, and run existing tests if they are provided.You MUST plan extensively before each function call, and reflect extensively on the outcomes of the previous function calls. DO NOT do this entire process by making function calls only, as this can impair your ability to solve the problem and think insightfully.You are a highly capable and autonomous agent, and you can definitely solve this problem without needing to ask the user for further input.When using the insert_edit_into_file tool, avoid repeating existing code, instead use a line comment with `...existing code...` to represent regions of unchanged code.Skip filler acknowledgements like 
