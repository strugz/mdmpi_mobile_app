# Air / Sea / Land — Items on the Request

> Status: **Built 2026-10-15 (app only, Option A)**, uncommitted on branch
> `feature/one-scan-delivery`. `flutter analyze` shows no new issues; `flutter test` is
> green (one unrelated Collection widget test, `client_picker_sheet_test.dart`, fails
> intermittently under full-suite load and passes on its own). Not yet run on a device.
> SMS decision: **yes**, the Air/Sea New Request SMS lists the items (§7 Q1).
> Covers both **Air / Sea / Land** and **Air / Sea / Land HD** (same form, same table, same
> RequestID sequence).
> Hard requirement: **no effect on the mobile clients already in use** (any app version in the
> field), and none on Standard Delivery, Hotline Direct, Pull Out or Stock Receive.
> Recommendation: **Option A: app only, no backend change, no migration, no deploy.**

## 1. Why

Today an Air/Sea request carries only an **Item Category**. It has no item list: there is no Add
Item on the form, nothing goes to the server, and nothing is shown later. A scanned Sales Invoice
or Stock Issue Slip sent to Air/Sea (Home > Scan Document) loses its items, and the review sheet
says so. Standard Delivery, Hotline Direct and Pull Out already have items. This plan gives
Air/Sea the same item list.

## 2. Facts from the code (checked 2026-10-15)

### Backend (`MDMPI.App`)

| Fact | Where |
|---|---|
| Items live in `a_tblrequeststandarditem` (+ `a_tblrequeststandarditembatch`). The name says "standard", but the table holds **any** request's items: no PK/FK to a request table, no request-type column, no trigger | `mdmpi_app_db_schema.sql:1249-1277` |
| Pull Out items are already stored there, by RequestID only | `ItemRepository.InsertItemsAsync`; app `pull_out_repository.dart:354-375` |
| `POST /api4/Item/request/{id}` stores items for **any** id > 0; `GET /api4/Item/request/{id}` reads them. Neither checks which request table the id belongs to | `ItemController.cs:23, 36` |
| **RequestIDs are unique across all request tables.** Air/Sea, Standard Delivery, Pick Up and Pull Out all take their id from one generator (`a_tblrequestcounters`, row-locked) | `RequestIdGenerator.cs`; used at `RequestAirSeaRepository.cs:154`, `RequestRepository.cs:181`, … |
| Air/Sea create returns **201** with the new `requestID` in the body | `RequestAirSeaController.cs:48`; app `air_sea_repository.dart:270-277` already parses it |
| Only `ItemRepository` reads the item tables. No report, SMS, trigger or Collection code does. Backload items and lost items have their own tables, keyed to Standard Delivery and Pull Out only | `ItemRepository.cs`; `BackloadItemRepository.cs:21-25`; `LoseItemRepository.cs:21-25` |
| No API versioning. ASP.NET defaults: camelCase, unknown JSON fields are **silently ignored** | `Program.cs:50` |
| The Air/Sea table has a history trigger that lists every column, so adding a column means re-creating the function in full | `migration_20260910_add_air_sea_shippingmethod.sql` |

### App (`mdmpi_mobile_app`)

| Fact | Where |
|---|---|
| The Air/Sea form already takes its client and document references from the **shared** `StandardDeliveryController.formState`, the same state that holds `scannedInventoryItems` | `air_sea_form.dart:28-47`; `air_sea_data_manager.dart:167, 176` |
| After a **successful** Air/Sea create the form calls `stdController.formState.reset()`, which also clears `scannedInventoryItems`. A failed create keeps everything | `air_sea_form.dart:49-61`; `standard_delivery_form_state.dart:120` |
| Air/Sea create has **no offline queue**: without a network it fails and the form keeps its input. So items cannot be stranded on the phone | `air_sea_repository.dart:263-322` |
| Pull Out already does exactly what this plan needs. It reuses the shared scanned-items list (`ScannedItemsScreen(controller: stdController)`), POSTs the request, and on 201 POSTs the items to `/api4/Item/request/{id}`. If the item post fails it warns: "Request created, but its items could not be saved." | `pull_out_form.dart:138-149`; `pull_out_repository.dart:264-313, 354-375` |
| Items are shown through `BViewItemsButton(requestId)` → `InventoryItemsPage`, which calls `GET /api4/Item/request/{id}`. With no items it shows an empty list | `b_view_items_button.dart`; `inventory_item_repository.dart:116-118` |
| The Air/Sea SMS builder always sends `inventoryItems: const []` | `sms_payload_builder.dart:131-150` |
| One-scan skips items for the two Air/Sea forms: `ScanFormTarget.takesItems` | `scan_form_target.dart:64-66` |
| There is no SQLite item table for any request type. Items are fetched when shown | `db_schema.dart` |

## 3. Options

| | A. Second call (recommended) | B. Items in the Air/Sea create body | C. New `a_tblrequestairseaitem` table |
|---|---|---|---|
| How | Create the request, then `POST /api4/Item/request/{id}`, exactly like Pull Out | Add `items` to `InsertRequestAirSeaDto` and insert them after the commit, like Standard Delivery | Own table + FK + new endpoints |
| Backend change | **None** | DTO + repository + deploy | Migration + entity + controller + deploy |
| Migration | **None** | None | Yes |
| Old apps | Unaffected: nothing they call changes | Unaffected: the field is optional | Unaffected |
| New app on the **current** backend | **Works today** | **Items silently lost**: the current backend ignores the unknown `items` field and still returns 201, so the app cannot tell. Needs a deploy first, or a capability check | Needs a deploy first |
| Atomic (request + items) | No, same as Pull Out | No (Standard Delivery isn't either: the service ignores the item result) | Could be |
| Effort | ~1 day app | ~1 day app + backend | Several days |

**A** is the only option that changes nothing the current clients or the current backend rely
on. It also matches the Pull Out flow, which is already in production. B and C buy nothing users
would notice: none of the three is atomic as designed, and both carry a deploy-order risk.

## 4. Design (Option A)

All changes are **additive** (new optional parameters with defaults that keep today's
behaviour, new widgets), and **Air/Sea code paths only**. Standard Delivery, Hotline Direct, Pull
Out and Stock Receive code is not edited, except the optional shared helper in A3.

| # | Change | File(s) | Notes |
|---|---|---|---|
| A1 | **Add Item (n)** on the Air/Sea form, opening `ScannedItemsScreen(controller: stdController)` | `air_sea_form.dart` | Same entry point and shared list as the Standard Delivery and Pull Out forms. One widget, so both Air/Sea variants get it. Placed under Document References, like the other forms |
| A2 | Save passes the items | `air_sea_data_manager.dart` `saveRequestFromForm` | `final items = stdController.formState.scannedInventoryItems.toList();` → `_repository.insert(model, silent: true, items: items)` |
| A3 | Repository posts them after the 201 | `air_sea_repository.dart` `insert` | New optional `items` (default `const []`). After a 201 **and** a parsed RequestID **and** items not empty: `POST /api4/Item/request/{id}` with `items.map((e) => e.toJson())`, expecting 200. On failure: the request stays (it exists server-side) and a warning says "Request created, but its items could not be saved. Add them from the request." If no RequestID can be parsed, the same warning. **Optional:** move Pull Out's `_insertItemsForRequest` into `InventoryItemRepository.insertItems(requestId, items) → Result<void>` and call it from both. Pull Out behaviour is unchanged by the move |
| A4 | Show the items | `air_sea_modal.dart` (next to the document references) | `BViewItemsButton(requestId: requestModel.id)`. An old request shows an empty list. Visible to every role that opens the modal, so warehouse, dispatcher and courier (HD too) all see it |
| A5 | SMS | `sms_payload_builder.dart` `_buildForAirSea` + `air_sea_data_manager.dart:252` | **Decision needed (§7 Q1).** Default: unchanged (no items in Air/Sea SMS). If wanted, pass `inventoryItems` on **create only**, the same as Standard Delivery and Pull Out |
| A6 | One-scan keeps items for Air/Sea | `scan_form_target.dart` `takesItems` → always true; `document_scan_review_sheet.dart` | The "has no items; they are left out" note can no longer appear; remove it with `itemsSkipped` or leave it unused |
| A7 | Reset | none | Already right: success clears the shared items with everything else, and failure keeps them for a retry. No change |
| A8 | Item count on the Air/Sea request card | `air_sea_request_card.dart` | **Optional**, later. It would cost one `GET` per card; Standard Delivery shows the count in the modal only |

Not in scope: **backload items** and **lost items** for Air/Sea. Their endpoints reject Air/Sea
ids by design, and they need product rules first.

## 5. Compatibility (the hard requirement)

| Situation | Effect |
|---|---|
| **Old app** (any version in the field) creating or viewing Air/Sea | **None.** No endpoint, DTO, table, trigger or response it uses changes |
| **Old app** opening an Air/Sea request a **new** app saved with items | Sees the request as today. The items are simply not shown (it has no View Items there). No error |
| **New app** with the **current** production backend | Works: `POST/GET /api4/Item/request/{id}` are live (Pull Out uses them). **Verify** once on the testing backend before release (§8 step 1) |
| **New app** viewing old Air/Sea requests | View Items shows an empty list |
| Air / Sea / Land **HD** | Same form, same table, same id sequence: covered by the same change. Old apps never see HD rows (`includeHd=false`) |
| Standard Delivery / Hotline Direct / Pull Out / Stock Receive | Code not edited (except the optional shared helper in A3, which keeps Pull Out's behaviour). Their items keep going where they go now |
| Item tables | Air/Sea rows join Standard Delivery and Pull Out rows. **Ids cannot collide** (one generator). Only `ItemRepository` reads the table |
| A new app sending items to a **future** backend | Unchanged. If Option B is ever added server-side, the app keeps using A or switches deliberately |

## 6. Risks

| Risk | Mitigation |
|---|---|
| Request saved but items not (two calls, not atomic) | Same as Pull Out today. A clear warning, and the request exists for a retry. **Follow-up (optional):** an "Add items" action on the Air/Sea modal using `PUT/POST /api4/Item/request/{id}` |
| Items left behind when a request is cancelled | Existing behaviour for every module (no FK). Cancelled requests are not shown with items anyway |
| A Standard Delivery draft is wiped by an Air/Sea save (shared state) | Existing behaviour today for client and references; items now ride along. Not made worse. Unchanged here |
| SMS sent even if the item post failed | Matches Pull Out. Items are not in the Air/Sea SMS unless §7 Q1 says so |
| `ScannedItemsScreen` relies on a `dynamic` controller | Air/Sea passes `stdController`, the type the screen expects, the same as Pull Out |
| `InventoryItemController` is registered outside the Firebase guard but needs a repository inside it (desktop only) | Pre-existing and Android-only target. Noted, not touched |

## 7. Open questions

1. ~~**SMS:** list the items in the Air/Sea "New Request" SMS?~~ **Yes (2026-10-15).** Built.
   Finding while building it: **Pull Out's SMS does not list items either.** `pull_out_data_manager`
   passes them, but `SmsPayloadBuilder._buildForPullOut` takes no items, so only Standard
   Delivery (and now Air/Sea) print them. **Left as it is (decision 2026-10-15).**
2. **Item Category stays?** It stays as is: items are added beside it, not instead of it.
3. **Who adds items:** whoever creates the request (Request role; HD role for HD). Should anyone be
   able to add or edit them later from the modal (the follow-up in §6)?

## 8. Steps

1. **Verify the backend in place (no change):** on the testing `/api4`, `POST /api4/Item/request/{an Air/Sea id}` with one item → 200; `GET` returns it; `GET /api4/RequestAirSea` is unchanged.
2. A3 (repository + optional shared helper) with tests.
3. A2 (data manager) with tests.
4. A1 (form button) and A4 (modal button).
5. A6 (one-scan) + tests updated.
6. A5 if §7 Q1 says yes.
7. `flutter analyze` + `flutter test`; QA on a device for **both** Air/Sea variants: create with
   items, no items, the item post failing (airplane mode after the 201 is hard to time; use a
   test double), then old-request View Items, and an old app build opening a new request.
8. Docs: `docs/modules/air-sea/README.md`, the one-scan plan §1 ("the two Air/Sea forms do not
   save items" no longer holds), and the TODO item.

## 8a. As built (2026-10-15)

| Step | Done in |
|---|---|
| A1 Add Item (n) on the Air/Sea form (both variants) | `air_sea_form.dart` (`ScannedItemsScreen(controller: stdController)`) |
| A2 Save passes the shared scanned items | `air_sea_data_manager.dart` `saveRequestFromForm` |
| A3 Items posted after the 201 to `/api4/Item/request/{id}`; warning on failure or missing id; the create body is unchanged | `air_sea_repository.dart` `insert(..., items:)` + `_insertItemsForRequest` (a copy of Pull Out's; Pull Out code not touched) |
| A4 View Items in the Air/Sea modal | `air_sea_modal.dart` (`BViewItemsButton`) |
| A5 Items in the New Request SMS only | `sms_payload_builder.dart` `_buildForAirSea(..., inventoryItems:)`; status updates pass none |
| A6 One-scan keeps items for Air/Sea | `scan_form_target.dart` `takesItems` → true |
| Tests | `test/data/repositories/air_sea_items_test.dart` (create body unchanged, no items means one call, item call after the 201, failure keeps the request, no id means no item call, SMS lists items on New Request only); scan tests updated; `test/air_sea_insert_mapper_test.dart` passes **unchanged** |

The repository got two `@visibleForTesting` seams (`postJsonForTest`, `warningForTest`). The
create POST now goes through the same helper as the item POST, with the same headers, body and
timeout as before.

Still to do: the device QA in §8 step 7, on both variants.

## 9. Tests

| Test | Covers |
|---|---|
| `air_sea_repository` insert test (HTTP fake) | 201 + id + items → one item POST with the exact `InventoryItemModel.toJson` body; no items → **no** item call (today's traffic unchanged); item POST fails → warning, no throw; no id → warning |
| `air_sea_data_manager` test | Passes the shared scanned items; Stock Receive-style exclusions don't apply |
| `test/air_sea_insert_mapper_test.dart` (existing) | **Must pass unchanged**: the create body has no `items` key |
| `scan_form_target_test.dart` / `delivery_document_scan_controller_test.dart` | Air/Sea now takes items |
| Widget test | Add Item (n) on the Air/Sea form for both variants; View Items in the modal |
