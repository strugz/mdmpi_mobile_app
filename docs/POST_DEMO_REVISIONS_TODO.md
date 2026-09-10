# Post-Demo Revisions — TO DO List

> Source: MDMPI demo training feedback (2026-09-03). Each item below restates the raw
> concern as a clear requirement, records the **current behavior found in code**, and
> lists the exact touch points. Status boxes are for pinning/tracking.
>
> Legend: `S` small (UI/validator only) · `M` medium (model/DAO/UI) · `L` large
> (schema migration and/or backend API contract change).

## Quick checklist

- [x] 1. Standard Delivery: make Recipient Contact Details optional — `S` (done; Recipient Name made optional too per follow-up feedback)
- [x] 2. Standard Delivery: proof of delivery photos, up to 3 — `M` (done app-side; no backend or DB migration needed — see notes)
- [x] 3. Pull Out: Add Item support — `M` (done app-side; no backend change — items post to the existing `/api4/Item/request/{id}` endpoint; hidden for Stock Receive)
- [x] 4. Pull Out: per-item exclusion remarks (lost/not included) — `L` (done app + backend via new `a_tblLoseItem` table; run `MDMPI.App/migration_20260903_add_a_tblloseitem.sql` and redeploy the testing backend)
- [x] 5. Pull Out: pause an in-progress request for an urgent pull out — `M` (done; Pause reverts In Transit → For Pull Out and clears the start time — backend gained `ClearPullOutDateStartAt` on the update DTO; deploy in lockstep)
- [x] 6. Standard Delivery: Release role can change driver/helper — `S` (done; also covers Hotline Direct via the shared footer, no backend change)
- [x] 7. Pick Up: multiple item-category selection — `L` (done app + backend via new `a_tblrequestpickupitemcategory` child table; run `MDMPI.App/migration_20260904_add_a_tblrequestpickupitemcategory.sql` and redeploy in lockstep)
- [x] 8. Rename "Air / Sea" to "Air / Sea / Land" — `S` (relabel only, per decision; run `MDMPI.App/migration_20260904_rename_air_sea_category.sql` together with this app build)
- [x] 9. Hotline Direct: allow driver (Courier) to create requests — `M` (done; Courier creates on the Hotline tab only and can prepare their own requests; no backend change)
- [x] 10. Hotline Direct: support Air/Sea requests — `L` (done as a new "Air / Sea / Land HD" form category, per decision; run `MDMPI.App/migration_20260909_add_air_sea_formcategoryid.sql` first, then `migration_20260909_add_air_sea_hd_category.sql` together with this app build + backend deploy; add the "HD" role in Firestore and assign it to the designated requestors)
- [x] 11. Backload: single-item backload from a batch delivery + backload item table — `L` (done app + backend via new `a_tblbackloaditem` table; per decision the courier unchecks items at For Delivery before Drop Off — run `MDMPI.App/migration_20260907_add_a_tblbackloaditem.sql` and redeploy in lockstep)
- [x] 12. Stock Receive: document reference optional — `S` (done app-side only; Pull Out / Return and all other forms keep it required)
- [x] 13. Air / Sea / Land: per-request Mode of Shipment dropdown (Air / Sea / Land) — `L` (done app + backend as nullable `shippingmethod varchar(15)`; run `MDMPI.App/migration_20260910_add_air_sea_shippingmethod.sql` **before** the backend deploy, then ship the app build — old clients keep working, their rows stay NULL; supersedes the "option a" block under item 8)
- [x] 14. SMS: include the dispatch time when the courier presses Dispatch — `S` (done app-only; "Dispatched At: Sep 9, 2026 03:03 PM." on the For Delivery and Air/Sea Dispatch texts; completion timestamps now formatted the same way; not blocked by item 16 — the SMS prints the phone's local stamp, not the DB value)
- [ ] 15. Android: correct layout under fullscreen / gesture pill / 3-button navigation bar — `M` (app-only; system-inset audit across screens)
- [ ] 17. Live map: one courier drawn as two cars (stale marker of a finished/previous request is never removed; markers are keyed per RequestID, not per courier) — `M` (app-only; `web_socket_delivery_controller.dart` + `delivery_location_controller.dart`; ideally the WS server also stops replaying completed requests)
- [ ] 18. Gemini OCR key hygiene (decision 2026-09-10: key stays in the mobile client; backend proxy removed) — `S` (ops-side: rotate the key — it is in both repos' git history — restrict it in GCP, set a budget alert; app-side done: key moved from URL to header)
- [x] 16. Timestamps saved +8h (3 PM dispatch stored as 11 PM) — `M` (backend fixed via `TimestampNormalizer` in all five normalizers + `Timezone=Asia/Manila` on the connection string; run `MDMPI.App/repair_20260910_fix_plus8h_client_timestamps.sql` **after** deploying to fix existing rows; only the optional app follow-up remains open)

---

## 1. Standard Delivery — Recipient Contact Details optional

**Requirement.** The Recipient Contact Details field on the Standard Delivery form
must not block submission when left blank. (Recipient Name stays required.)

**Current behavior.** The field is required by a form validator only — the rest of
the chain (model default `''`, mapper sends `null` when empty) already tolerates an
empty value.

**Touch points**
- Validator: `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart:231-244` — remove the "Please enter recipient contact details" branch, relabel hint as optional.
- No model/DTO/DB change needed (`standard_delivery_model.dart`, `standard_delivery_mapper.dart:131-134` already null-safe).

**Note.** Hotline Direct reuses this same form, so the change applies there too —
confirm that is acceptable.

---

## 2. Standard Delivery — Proof of delivery photos, max 3

**Requirement.** Courier can attach **up to 3** proof-of-delivery photos (minimum 1
still required to complete delivery).

**Current behavior.** Hard limit of **one** photo, enforced at four layers:
1. Scalar state: `lib/common/controllers/camera_controller.dart:32` (`imageProofPath` is a single `RxString`; each shot overwrites the last).
2. File naming: `lib/base/utils/image_utils/image_conversion_base_64_to_string.dart:100-120` saves `deliveryShots/{requestId}.jpg` — one file per request.
3. Local DB: `lib/data/local/db_schema.dart:75-82` — `a_tblRequestImage` has `RequestID UNIQUE`; DAO replaces the single row (`standard_delivery_dao.dart:247-263`).
4. Upload naming: `lib/data/repositories/image/image_repository.dart:21-38` uploads `{requestId}_{type}.png` — a second photo collides server-side.

**Implemented (design deviates from the original plan — simpler than expected).**
Key insight: the backend (`ImagePathTypeRepository.UploadImageAsync`) keys stored
images by `(RequestID, ImageType)` and has a generic-filename fallback for unknown
types, so extra photos ride the existing `/api4/request/upload-image` endpoint as
image types `Proof_2` / `Proof_3` — **no backend change, no local DB migration**.
Slot 1 keeps the legacy `{requestId}.jpg` name and the `Proof` type, so every
existing reader (validation, `request.image` resolution, outbox retry, display)
kept working unchanged.

- [x] `camera_controller.dart` — added `imageProofPaths` (RxList, max 3),
  `takeProofPicture[WithAnimation]`, `removeProofPhoto` (compacts slots),
  `syncProofPhotos` (reloads list from disk per request). Legacy single-photo
  state is mirrored to slot 1; other flows (Pick Up, Air/Sea, Pull Out) still
  use the untouched `takePicture`/`imageProofPath`.
- [x] Filenames: slot 1 = `{requestId}.jpg` (legacy), slots 2-3 =
  `{requestId}_2.jpg` / `{requestId}_3.jpg` (`camera_controller.dart`,
  `b_proof_image.dart` `_buildFileName` maps `Proof_N` → `{id}_N.jpg`).
- [x] No schema migration: `a_tblRequestImage` still caches only the slot-1
  photo; extra photos live as files + outbox rows (distinct by `ImageType`).
  `b_proof_image.dart` guards the DB read/write fallbacks to type `Proof` only.
- [x] Upload/outbox: `standard_delivery_data_manager.dart`
  `_handleStatusMediaUploads` uploads/queues `Proof_2`/`Proof_3` via
  `getExtraDeliveryImagesAsBase64` (`image_conversion_base_64_to_string.dart`).
- [x] UI: new shared `b_proof_photo_list.dart` (thumbnails, preview, remove,
  n/3 counter, capture disabled at 3) wired into **both** capture entry points
  (`request_modal_footer.dart`, `b_request_details.dart`).
- [x] Validation: min 1 unchanged (slot 1 required by the existing checks);
  `b_action_button.dart` now also accepts any photo in the multi-photo list;
  max 3 enforced at capture.
- [x] Post-completion viewing: `showRequestImagesDialog` (swipeable pager) in
  `request_image_dialog.dart`; `BDeliveryDetailsSection` gained optional
  `imageProofTypes`; Standard Delivery passes `['Proof','Proof_2','Proof_3']`.

**Not done (deferred).** The signature-outbox-pattern extension mentioned in
`STANDARD_DELIVERY_SIGNATURE_API_STATUS_PLAN.md:221` — extra photos already reuse
the existing image outbox, so no further work was required for retry semantics.

---

## 3. Pull Out — Add Item

**Requirement.** A pull-out request can list the items to be pulled out (add via
the same scanner/manual flow Standard Delivery uses).

**Current behavior.** Pull Out is **header-only** — no item list exists anywhere in
the chain (model, DTO, mapper, DB table `a_tblRequestPullOutReturnPickUp`, form, modal).
Only an Item Category dropdown exists (`pull_out_form.dart:152-166`).

**Implemented (design deviates from the original plan — no backend change).**
Two key deviations, both confirmed against the code:
1. **Scanner state reuse instead of a new RxList.** The Pull Out form already
   borrows the Standard Delivery form state for client, doc refs, and requester
   — and the scanner stack (`ScannedItemsScreen` → `BItemScanner` →
   `ScannedItemTile`) duck-types onto a controller exposing not just
   `formState.scannedInventoryItems` but also `isAnalyzingFile`,
   `clearScannedItems`, `removeScannedItem`, `updateScannedItemByKey`, and
   `pickAndAnalyzeFrom{Camera,File}`. Duplicating all of that on
   `PullOutController` wasn't worth it; the form passes `stdController` to the
   scanner and the create path reads items from there. The existing
   `stdController.formState.reset()` in the form's `onSave` clears them.
2. **No insert-DTO/backend change.** The backend already exposes generic
   `POST /api4/Item/request/{id}` (items keyed by RequestID only), and the
   pull-out insert response returns the new `requestID` — so
   `PullOutRepository.insert` posts items in a follow-up call after create.
   If the item post fails, the user gets a warning that the request was
   created without items.

- [x] `pull_out_form.dart` — `Add Item (count)` button → `ScannedItemsScreen(controller: stdController)`, hidden when the selected category is Stock Receive; also replaced two `print()`s with `logDebug`.
- [x] `pull_out_repository.dart` — `insert(..., items:)` + `_insertItemsForRequest` (POST `/api4/Item/request/{id}`).
- [x] `pull_out_data_manager.dart` — passes scanned items on create (empty for Stock Receive) and includes them in the new-request SMS.
- [x] `pull_out_modal_body.dart` — `BViewItemsButton(requestId)` shown only for Pull Out / Return category requests (modal is shared with Stock Receive).

**Resolved question.** Stock Receive does **not** get Add Item (confirmed) —
the button and item payload are gated on `FormCategoryType.stockReceive`.

---

## 4. Pull Out — Remarks for items not included (lost)

**Requirement.** When 1 or more listed items are **not** actually pulled out (e.g.
lost), the courier can mark those items excluded and must enter a remark before
completing (`Taken Out`).

**Current behavior.** Remarks exist only per-request and only for **cancellation**
(`a_tblRequestRemarks` has `RequestID` as PRIMARY KEY — one remark per request;
`cancel_remarks_model.dart`). The status-update payload (`pull_out_mapper.dart:37-58`)
cannot carry remarks at all. No per-item anything (depends on item 3).

**Implemented (design settled with stakeholder: dedicated `a_tblLoseItem` table).**
Instead of flags on the shared item table, lost items live in their own server
table — a row means "this item was NOT pulled out" with the courier's remarks;
absence means included. Identified by RequestID + ItemCode. No mobile local-DB
table (matches item 3: items are server-side, fetched on demand).

Backend (MDMPI.App — **deploy in lockstep**; run
`migration_20260903_add_a_tblloseitem.sql` on the testing Postgres first):
- [x] `a_tblloseitem(loseitemid identity PK, requestid FK → a_tblrequestpulloutreturnpickup ON DELETE CASCADE, itemcode, remarks, createdat)` + index; both schema dumps updated.
- [x] `LoseItemModel` entity, `Fetch/InsertLoseItemDto`, `ILoseItemService/Repository`, `LoseItemService`, `LoseItemRepository` (replace-set semantics: POST deletes existing rows and inserts the new set), DbContext mapping, DI in `Program.cs`.
- [x] `LoseItemController`: `GET/POST /api4/LoseItem/request/{requestId}` — both validate the RequestID exists in `a_tblrequestpulloutreturnpickup` (404 otherwise).

Mobile:
- [x] `lose_item_model.dart` + `lose_item_repository.dart` (GET returns empty on 404; POST replaces the set), registered in `GeneralBindings` outside the Firebase guard.
- [x] `PullOutFormState.lostItemRemarks` (`RxMap<itemCode, remark>`; presence = marked lost), cleared on reset.
- [x] `pull_out_lost_items_section.dart` — editable (In Transit, courier): request items with an included checkbox; unchecking requires a reason. Read-only (Taken Out): recorded lost items + remarks. Renders nothing when the request has no items, so Stock Receive (shared modal) is naturally unaffected.
- [x] Validation in `_validateCompletionInfo`: every lost item must carry a remark before `Taken Out`.
- [x] Persistence in `updateRequestStatus`: lost items save via `POST /api4/LoseItem/request/{id}` before the status update — on failure the transition aborts with the courier's entries preserved.

---

## 5. Pull Out — Pause progress for an urgent pull out

**Requirement.** A courier working a request can put it **on hold** to service a more
urgent pull-out request, then resume it (returning to its prior status).

**Current behavior.** No pause/hold concept exists. Statuses are plain strings
(`text_strings.dart:136-156`): New Request → For Pull Out → In Transit → Taken Out /
Cancelled. There is no `previousStatus` field on the model or DB table, so resume has
nowhere to read the prior status from today.

**Implemented (final design per stakeholder: Pause reverts the request to
For Pull Out and clears the start time — no separate "On Hold" status).**
An initial On Hold-status implementation was replaced. Rationale: the
stakeholder wants `pullOutDateEndAt − pullOutDateStartAt` to measure only the
final leg, with the courier's next departure stamping a fresh start time. The
history table (`a_tblrequestpulloutreturnpickup_history`, populated by the
existing trigger on every update) still records the original departure and all
pause/resume transitions with timestamps if net-time reporting is ever needed.

- [x] Pause: Courier at In Transit gets a secondary "Pause (Back to For Pull
  Out)" action (new `secondaryNextStatus`/`secondaryButtonLabel` fields on
  `PullOutModalConfig`, rendered as an outlined button in
  `pull_out_modal.dart`) → status returns to For Pull Out and
  `pullOutDateStartAt` is cleared. Resume = the ordinary "Set In Transit"
  action, which stamps a fresh start because the field is empty again.
- [x] Backend (**deploy in lockstep**): `UpdateRequestPullOutReturnPickUpDto`
  gained `ClearPullOutDateStartAt`; `UpdateAsync` nulls the column when true
  (the `UpdateIfNotNull` pattern cannot clear columns otherwise). Mobile
  `PullOutMapper.toUpdateDto(clearPullOutDateStartAt:)` sends the flag; the
  pause is detected in `pull_out_data_manager.dart` as In Transit → For Pull
  Out.
- [x] SMS: pausing texts the client with On Hold wording (template in
  `sms_message_template_service.dart` + policy entry in
  `sms_status_policy.dart`; `BTexts.statusOnHold` survives for messaging
  only). Resume sends the normal In Transit SMS — it is a genuine new
  departure. Every SMS outcome now logs via `_storeSmsResult`
  (`messaging_controller.dart`), including silent skips.
- [x] Visibility: For Pull Out is already assigned-courier-only in the filter
  rule, so only the paused request's driver/helper sees and resumes it.
  A paused request is indistinguishable from a not-yet-departed one in
  lists/dashboards — accepted trade-off of this design.

**Resolved questions.** Pull Out only (other modules can copy the pattern
later). Backend change is limited to the clear-flag on the update DTO.

---

## 6. Standard Delivery — Release role can change driver/helper

**Requirement.** A Release-role user can **re-assign** the driver and/or helper on a
request (not just set them once during preparation).

**Current behavior.** Driver/helper dropdowns show only while status is
`Getting supplies ready` AND `itemPreparedBy == current user`
(`request_modal_footer.dart:48-51`). Assignment is write-once: the data manager only
writes `deliveredBy`/`helper` **when the existing value is empty**
(`standard_delivery_data_manager.dart:306-309, 334-336`), so reassignment is
impossible after "Packed & Ready". Roles are already defined (`Release` in
`text_strings.dart:170-176`; gate matrix in `standard_delivery_modal_config.dart:74-171`).

**Implemented (simpler than planned — the modal config and write-once guards
were left untouched).** Re-assignment is its own action, not a status
transition, so it bypasses the `isEmpty ? new : existing` guards in
`_buildUpdatedRequest` entirely instead of weakening them. The Release modal
stays view-only at these statuses; the footer gains an editing section.

- [x] New `ReassignDeliveryCrewSection` widget
  (`reassign_delivery_crew_section.dart`): driver/helper dropdowns seeded with
  the current assignment + a "Save Assignment" button. Shown in
  `request_modal_footer.dart` when the user has the Release role and the
  request is `Item Prepared` or `For Delivery`.
- [x] New `StandardDeliveryDataManager.updateDriverHelperAssignment`:
  overwrites `deliveredBy`/`helper` via the existing update payload
  (driver required; an empty helper keeps the current one — the PATCH
  endpoint ignores empty fields, so clearing is not possible, only
  replacing), persists to API + local DB, and updates the reactive lists.
- [x] Hotline Direct is covered automatically — it shares the footer and the
  Standard Delivery repository. Courier visibility follows the new assignment
  immediately (the courier lists filter on `deliveredBy`/`helper`).
- [x] Second surface in `b_request_details.dart` (RequestTransport screen):
  the list force-routes any user holding the Courier role to RequestTransport
  at `Item Prepared`/`For Delivery` (`standard_delivery_list.dart:186-199`),
  so multi-role users never see the modal footer there — the same section is
  gated on the Release role inside the transport details too.

**Resolved question.** Standard Delivery + Hotline Direct only (confirmed);
Pull Out / Air Sea can copy the pattern later if requested.

---

## 7. Pick Up — Multiple category selection

**Requirement.** The Pick Up form's **Item Category** becomes multi-select.

**Current behavior.** Single-select end to end: one `TextEditingController` holding
one `ItemCategoryID` (`pick_up_form_state.dart:21`), scalar model field
(`pick_up_model.dart:9`), scalar DTO key `ItemCategoryID`
(`pick_up_insert_dto.dart:3,25` → `POST /api4/RequestPickUp`), scalar columns in local
DB (`db_schema.dart:176-192`) and server (`a_tblrequestpickup.itemcategoryid bigint`).
No multi-select dropdown widget exists in `lib/common/widgets/dropdown/`.

**Implemented (child table + primary-category compatibility).**
The scalar `itemcategoryid` column keeps the FIRST selection on both server
and app, so existing rows, reports, and single-category consumers keep
working; the full selection lives in a new child table. History-trigger
tables were NOT touched — the child table (like document references) is not
historized.

Backend (MDMPI.App — **deploy in lockstep**; run
`migration_20260904_add_a_tblrequestpickupitemcategory.sql` first, which also
backfills one child row per existing request):
- [x] `a_tblrequestpickupitemcategory(pickupitemcategoryid identity PK, requestid FK → a_tblrequestpickupmdmpi ON DELETE CASCADE, itemcategoryid, UNIQUE(requestid,itemcategoryid))`; both schema dumps updated.
- [x] `PickUpItemCategoryModel` entity + DbContext mapping; `InsertRequestPickUpDto`/`RequestPickUpDto` gained `ItemCategoryIDs`; `RequestPickUpRepository` inserts the set on create (first fills the scalar) and returns it on GetAll.

Mobile:
- [x] New generic `BMultiSelectDropDown` (`lib/common/widgets/dropdown/multi_select_drop_down.dart`): dropdown-styled FormField opening a checkbox dialog; same items shape as `BDropDownDynamicList`.
- [x] `PickUpFormState.selectedItemCategoryIds` (the legacy `itemCategoryController` mirrors the first selection); form swaps in the multi-select with an at-least-one validator; default 'reagent' seeding covers both.
- [x] `PickUpModel.itemCategoryIds` (+DTO/mapper `ItemCategoryIDs`); local DB column `ItemCategoryIDs TEXT` (comma-joined) in `a_tblRequestPickUp`, DB version 16 → 17 (destructive cache rebuild per existing pattern), DAO writes it in all three paths.
- [x] Filtering: category filter matches the scalar OR the list.
- [x] Display: `pick_up_request_card.dart` resolves and joins all selected
  category names (the card is the only category display in the Pick Up UI).

**Resolved question.** Air/Sea stays single-select (confirmed); it can copy
this pattern later.

---

## 8. "Air / Sea" → "Air / Sea / Land"

**Requirement (needs clarification — two different readings found).**
"Air / Sea" is a **form category** (its own table `a_tblRequestAirSea` and endpoint
`/api4/RequestAirSea`) and the Air/Sea form has **no Air-vs-Sea mode selector**.
Meanwhile Standard Delivery / Hotline already have a Shipping Method dropdown of
`['Land','Air','Sea']` (`standard_delivery_form.dart:146-156`,
`hotline_direct_form.dart:71-75`). So the change is either:

- **(a) Rename the category** "Air / Sea" → "Air / Sea / Land" and add a shipping-mode
  field to the Air/Sea request, or
- **(b)** only relabel, keeping behavior identical.

**Implemented (option b: relabel only — decision confirmed).** Note the doc's
original touch points were slightly off: form categories are NOT a dedicated
`a_tblFormCategory` table — they are rows in `a_tblcategory` with
`type='Form'`, served by `/api4/Category`. The rename is therefore a one-row
data UPDATE, no backend code change.

- [x] `form_category_constants.dart` canonical name → 'Air / Sea / Land'.
- [x] `text_strings.dart` (`requestFormLabels`), `request_controller.dart`
  (`categoryOrder`), `settings_hard_reset_section.dart` (hard-reset tile).
- [x] Server: `migration_20260904_rename_air_sea_category.sql` renames the
  `a_tblcategory` row (varchar(20) fits the 16-char name) — **run together
  with this app build**: exact-name matching (`fromCategoryName`, sorting)
  needs both sides to agree; the fuzzy `contains('air')/('sea')` dispatch
  keeps old app builds functional in the interim.
- [x] Verified all 5 fuzzy dispatch sites plus `request.dart:134`: the new
  name still matches its own branch and no earlier branch (no branch tests
  'land').

**If a per-request Land mode is added (option a)** — *delivered 2026-09-10 as item 13
(§13); the boxes below are kept for history and are superseded by that section.*
- [ ] `AirSeaModel` + insert/update DTOs + `air_sea_mapper.dart` gain a `shippingMethod` field; `BDropdown` in `air_sea_form.dart` (mirror `standard_delivery_form.dart:146-156`).
- [ ] Column in local `a_tblRequestAirSea` (`db_schema.dart:210-243`) + `air_sea_dao.dart`; server table + its `_history` table + `trg_a_tblrequestairsea_history_fn()` (`mdmpi_app_db_schema.sql:29-95, 783-812`). **Backend change.**
- [ ] Status-flow review: Air/Sea statuses (`Endorsed to Guard`, `Drop Off`, `Provincial *`) may not apply to a Land request — `air_sea_modal_config.dart:60-140`, `dashboard_bucket_config.dart:165-235` (has tests: `dashboard_bucket_config_test.dart`).

---

## 9. Hotline Direct — Allow driver to create requests

**Requirement.** A driver can create Hotline Direct requests directly.

**Current behavior.** There is **no "Driver" role** in the app — roles are `Viewer,
Request, Release, Courier, Admin, Provincial` (`text_strings.dart:171-176`); driver is
the `Courier` role (driver/helper are per-request fields, not roles). Creation is
gated by a single category-agnostic check: the create FAB shows only when the user has
the `Request` role (`request.dart:1075-1093`). Note: Hotline Direct creation actually
runs through the **Standard Delivery form/controller** (`request_controller.dart:464-466`);
`HotlineDirectForm` and `HotlineDirectDataManager.saveRequestFromForm` are dead
creation paths.

**Implemented (decisions confirmed: driver = Courier role; Courier can also
PREPARE their own new request, mirroring the Release flow).**
- [x] FAB gate (`request.dart`): create button shows for the Request role
  everywhere, and additionally for the Courier role when the selected tab is
  Hotline Direct (resolved via `FormCategoryConstants.fromCategoryName`, so
  it is alias/rename tolerant).
- [x] Visibility (`hotline_direct_filter_manager.dart`): a single-role
  Courier's list now also matches `createdBy == user.initial`, so drivers see
  the requests they created before being assigned to them.
- [x] Courier handler (`hotline_direct_role_handler.dart`): at `New Request`,
  a courier can act on their OWN request (createdBy match) → Prepare Item;
  at `Getting supplies ready` with `itemPreparedBy == user` → Packed & Ready
  (same validations as Release via the shared update path). Other people's
  requests stay view-only during preparation. Creation itself flows through
  the existing Standard Delivery form (`openFormForCurrentCategory`).

**Resolved question.** No new Driver role — Courier covers it. Multi-role
users keep their existing routing (Release/Request take precedence at
preparation statuses).

---

## 10. Hotline Direct — Support Air/Sea requests

**Requirement.** Urgent (hotline-direct) requests can also be Air/Sea shipments.

**Current behavior.** Mutually exclusive by data model: Hotline Direct lives in
`a_tblRequest` keyed by `FormCategoryID='8'`; Air/Sea lives in a separate table
`a_tblRequestAirSea` with **no** `FormCategoryID` column and its own endpoint.

**Two viable shapes (decision needed)**
1. **Flag on Air/Sea**: add `FormCategoryID`/`IsHotlineDirect` to `a_tblRequestAirSea`
   (+ model/DTO/mapper/DAO, server table + history table + trigger), then merge those
   rows into the Hotline Direct list. **Backend change.**
2. **Shipping method on Hotline**: the Hotline form already has
   `['Land','Air','Sea']` (`hotline_direct_form.dart:71-75`, currently no validator) —
   route Air/Sea selections through the Air/Sea status flow. Requires status-flow
   branching (Air/Sea statuses differ: `Item Packed`, `Endorsed to Guard`,
   `For Dispatch`, `Drop Off`…).

**Groundwork already merged.** Commit `01b60aa` made `BModal`/`BFullScreenLoader`
accept an injected `IDeliveryRequestController` explicitly to share modals across
workflows. `AirSeaController` does **not** implement that interface yet — making it do
so is the natural first step either way.

**Related.** This pairs with item 8 — decide 8 and 10 together.

**Implemented (2026-09-09) — shape 1, as a new form category "Air / Sea / Land HD".**
The HD tab is to Air/Sea what Hotline Direct is to Standard Delivery: one table
(`a_tblrequestairsea`), one endpoint (`/api4/RequestAirSea`), two tabs split by a new
nullable `formcategoryid` column. Decisions locked in: same status flow & role matrix
as base Air/Sea; tab sits right after "Air / Sea / Land"; creation restricted to
designated users holding the new **"HD" role** (Firestore `Roles` collection — assign
`HD` in the user's comma-separated Role field; workflow actions stay with
Release/Courier/Provincial).

- **Backend (MDMPI.App):** nullable `FormCategoryID` on entity/history/DTOs;
  set on insert only. `GET /api4/RequestAirSea` **excludes HD rows unless
  `includeHd=true`** — the currently deployed mobile build (which sends no
  params) keeps receiving exactly the pre-HD dataset, so old clients are
  unaffected. Migrations at MDMPI.App root:
  `migration_20260909_add_air_sea_formcategoryid.sql` (column on table +
  history + full re-emit of `trg_a_tblrequestairsea_history_fn`; safe to run
  early) and `migration_20260909_add_air_sea_hd_category.sql` (pins category
  id **21**, name `'Air / Sea / Land HD'`, type `Form` — run together with the
  app rollout; verify id 21 is free first).
- **App:** `FormCategoryType.airSeaHd` appended last (home-grid lists appended
  in lockstep); new `FormCategoryIds` constants home (`'4'/'6'/'8'/'9'/'10'`
  literals swept); `AirSeaCategoryScope` splits rows in `AirSeaDataManager`
  (NULL/legacy rows stay on the base tab); `AirSeaHdController extends
  AirSeaController` (no duplicated stack) + `AirSeaControllers.forRequest(...)`
  resolves the owning controller in shared pages/sections/dialogs; the shared
  `AirSeaForm` binds to the tab's controller and shows the category read-only;
  the create FAB on the HD tab requires the parsed `HD` role; dashboard shares
  the Air/Sea buckets with its own accent/icon; settings hard-reset gained an
  HD entry; local DB v17→18 adds `FormCategoryID` to `a_tblRequestAirSea`
  (destructive cache rebuild — local cache re-syncs on first launch);
  `AirSeaRepository` GETs with `includeHd=true`. SMS dispatches on model type,
  so HD inherits the Air/Sea payloads unchanged.
- **Rollout order (keeps old clients safe):** schema migration → backend deploy
  → category INSERT + APK distribution together → add/assign the `HD` role in
  Firestore.

---

## 11. Backload — Single-item backload in a batch delivery + backload item table

**Requirement.** In a delivery carrying multiple items ("batch delivery"), the courier
can backload **just one item** (or a subset); backloaded items are recorded and shown
in a dedicated table.

**Current behavior.** Backload is a **whole-request** status flip
(`statusBackLoad`): one row per event in `a_tblRequestBackload(BackLoadID, RequestID,
Remarks, DeliveryDate, DateReported)` (`db_schema.dart:304-312`) with no item
reference; API body is `{RequestID, Remarks, DeliveryDate}`
(`backload_repository.dart:50-54`). There is no "batch delivery" entity — the analog
is a single request carrying multiple inventory items, and those items are **not in
the local DB** (fetched read-only from `/items/{requestId}` via
`InventoryItemController`, in-memory cache only). The backload page renders no item
list at all (`backload_transaction_page.dart`).

**Implemented (design settled with stakeholder — the plan below was replaced).**
Decision: "Before Drop Off, the client sometimes won't receive one or more
items — at **For Delivery** the courier gets a widget to uncheck items and
input remarks before dropping off." That is exactly the item-4 lost-items
pattern, so the implementation mirrors it 1:1 instead of extending the
whole-request backload flow:

- Item-level backload is **not** a status flip. The courier unchecks items on
  the Request Transport screen while at For Delivery; each unchecked item
  requires a reason; the set saves to the new server table on the Drop Off
  (Done Delivery) transition, and the request completes normally.
- The existing whole-request backload (long-press → `BackLoad` status →
  Reprocess, `a_tblrequestbackload`) is untouched — still the answer for
  header-only requests (confirmed) and full-request events.
- No mobile local-DB table (matches items 3/4: items are server-side,
  fetched on demand).

Backend (MDMPI.App — **deploy in lockstep**; run
`migration_20260907_add_a_tblbackloaditem.sql` on the testing Postgres first):
- [x] `a_tblbackloaditem(backloaditemid identity PK, requestid FK → a_tblrequeststandarddelivery ON DELETE CASCADE, itemcode, remarks, createdat)` + index; both schema dumps updated. The FK table hosts Standard Delivery AND Hotline Direct, so both are covered.
- [x] `BackloadItemModel` entity, `Fetch/InsertBackloadItemDto`, `IBackloadItemService/Repository`, `BackloadItemService`, `BackloadItemRepository` (replace-set semantics), DbContext mapping, DI in `Program.cs`.
- [x] `BackloadItemController`: `GET/POST /api4/BackloadItem/request/{requestId}` — both validate the RequestID exists in `a_tblrequeststandarddelivery` (404 otherwise).

Mobile:
- [x] `backload_item_model.dart` + `backload_item_repository.dart` (GET returns empty on 404; POST replaces the set), registered in `GeneralBindings` outside the Firebase guard.
- [x] `StandardDeliveryFormState.backloadItemRemarks` (`RxMap<itemCode, remark>`; presence = marked backloaded) + `backloadItemsRequestId` (the editable section clears stale entries when a different request is opened); both cleared on reset.
- [x] `backload_items_section.dart` — editable (For Delivery, Request Transport screen, above Proof of Delivery): request items with a received checkbox; unchecking requires a reason. Read-only (Done Delivery, request modal): recorded backloaded items + remarks. Renders nothing when the request has no items.
- [x] Validation in `b_action_button.dart` Drop Off flow: every backloaded item must carry a remark.
- [x] Persistence in `RequestTransportController.processRequestDispatchOrDropOff`: backloaded items save via `POST /api4/BackloadItem/request/{id}` before the Done Delivery status update — on failure the transition aborts with the courier's entries preserved; entries clear after a successful drop off.

**Not done (out of scope per decision).** The original plan's `Items[]` on
`POST /api4/RequestBackload`, local `a_tblRequestBackloadItem` cache table,
selectable table on `backload_transaction_page.dart`, and Reprocess rework —
the whole-request flow no longer needs item granularity.

---

## 12. Stock Receive — Document Reference optional

**Requirement.** Stock Receive can be submitted without a document reference.
(Pull Out keeps it required.)

**Current behavior.** Required in two independent places, both in code **shared with
Pull Out** (Stock Receive has no form of its own — it reuses `PullOutForm` /
`PullOutFormState`):
1. Widget validator: `lib/features/logistics/screens/common/b_document_reference.dart:88-99`
   — `'Document Reference is required'`. This widget is shared by Pull Out, Pick Up,
   Air Sea, Hotline Direct, and Standard Delivery.
2. Data-manager guard: `stock_receive_data_manager.dart:77-87` — errors when the list
   is empty or contains blanks. (Pull Out's identical guard at
   `pull_out_data_manager.dart:69-79` must stay.)

**Implemented (app-side only — no backend or model change needed).**
- [x] `BDocumentReference` gained `isRequired` (default `true`, so every other
  form is unchanged): an empty field no longer errors when optional, the label
  reads "Document Reference (optional)", and the duplicate-value check stays
  active either way.
- [x] `pull_out_form.dart` passes `isRequired: !isStockReceive` using the
  `FormCategoryConstants.fromCategoryName` check the form already computes.
- [x] `stock_receive_data_manager.dart` strips blank fields instead of
  erroring; `PullOutMapper.toInsertDto` already sends `null` for an empty
  list, so the insert chain tolerates no references end to end.
- [x] The auto-added blank field was kept (harmless now that it validates and
  saves as "no reference"); Pull Out's own required guard
  (`pull_out_data_manager.dart`) is untouched.

---

## 13. Air / Sea / Land — Mode of Shipment dropdown

**Requirement.** An Air / Sea / Land request must record **how it ships** — a
per-request `Mode of Shipment` dropdown with `Air` / `Sea` / `Land`. Item 8 was
decided as a **relabel only**, so today the category name mentions three modes
while the request itself stores none. This item is the deferred "option (a)"
from §8 — treat the unchecked block there as superseded by this section.

**Current behavior.** `air_sea_form.dart` has no mode selector. Standard Delivery
and Hotline Direct already have a Shipping Method dropdown of `['Land','Air','Sea']`
(`standard_delivery_form.dart:146-156`, `hotline_direct_form.dart:71-75`) — mirror
that widget and option list so the wording matches across forms.

**Scope note.** Both Air/Sea tabs (base and the `Air / Sea / Land HD` category from
§10) share `AirSeaForm`, `AirSeaModel` and `a_tblrequestairsea`, so a single column
and a single form change cover both.

**Implemented (2026-09-10).** Decisions locked in: required on create, create-only
(read-only afterwards; backend still accepts it on PATCH), no status-flow branching
(Land follows the Air/Sea statuses), shown as a chip on the card and a line in the
shared modal/page header (both hidden for legacy NULL rows). Values come from the new
shared `ShippingMethods.all` (`lib/features/logistics/constants/shipping_methods.dart`),
now also used by the Standard Delivery / Hotline Direct dropdowns. Server-side the
DTOs carry `[MaxLength(15)] [RegularExpression("^(Air|Sea|Land)$")]`; blank is
treated as "not sent". Local DB v18 → v19. Both schema dumps updated (the app-side
copy was stale since the FormCategoryID change and is now in sync). Rollout: migration
→ backend → app; verified every path the installed 1.1.102 client uses keeps working.

**Touch points**
- [x] `AirSeaModel` + insert/update DTOs + `air_sea_mapper.dart` gain a
  `shippingMethod` field; `BDropdown` in `air_sea_form.dart` (mirror
  `standard_delivery_form.dart:146-156`). Decide whether it is required on create
  (Standard Delivery's copy currently has no validator).
- [x] Local DB column in `a_tblRequestAirSea` (`db_schema.dart:210-243`) +
  `air_sea_dao.dart` (all write paths) + DB version bump in `database_helper.dart`.
- [x] **Backend change:** column on the server table, its `_history` table, and a
  full re-emit of `trg_a_tblrequestairsea_history_fn()`
  (`mdmpi_app_db_schema.sql:29-95, 783-812`); DTOs set it on insert/update. Nullable
  column so existing rows and older app builds stay valid; deploy schema first,
  then backend, then the app (same order as §10).
- [x] Display: show the mode on the request card / modal header
  (`air_sea_request_card.dart`, `air_sea_modal_config.dart`) — otherwise the field is
  write-only and the courier never sees it.
- [x] Status-flow review (decided: no branching — Land follows the same statuses;
  `dashboard_bucket_config_test.dart` untouched): Air/Sea statuses (`Endorsed to Guard`, `Drop Off`,
  `Provincial *`) may not all apply to a **Land** request —
  `air_sea_modal_config.dart:60-140`, `dashboard_bucket_config.dart:165-235`
  (has tests: `dashboard_bucket_config_test.dart`). Confirm with Logistics whether
  Land skips any step before branching the flow.

---

## 14. SMS — Dispatch time when the courier presses Dispatch

**Requirement.** The SMS the client receives when the courier presses **Dispatch**
must state the time of that dispatch, not just the new status.

**Current behavior.** Two separate "Dispatch" surfaces exist, and neither prints a
time:
- **Standard Delivery / Hotline Direct** — the courier's `Dispatch` button
  (`b_action_button.dart:141`) runs `Item Prepared → For Delivery` via
  `RequestTransportController.processRequestDispatchOrDropOff`
  (`request_transport_controller.dart:506`). The template branch for
  `BTexts.statusForDelivery` (`sms_message_template_service.dart:51-57`) prints only
  the client, document references, status and target date.
- **Air / Sea / Land (+ HD)** — the `Dispatch` button
  (`air_sea_modal_config.dart:136-141`) moves the request to `BTexts.statusDispatch`,
  which falls into the shared status branch
  (`sms_message_template_service.dart:58-71`) — same, no time.

**The timestamp already exists** — this is a formatting/plumbing change, not new data
capture:
- `deliveredAt` is stamped with `DateTime.now().toString()` on the
  `For Delivery` transition (`standard_delivery_data_manager.dart:319-322`,
  `hotline_direct_data_manager.dart:247-250`), and the SMS is sent **after** that with
  the already-updated model (`standard_delivery_data_manager.dart:249`), so the value
  is populated at send time.
- `dispatchedAt` is stamped the same way for Air/Sea
  (`air_sea_data_manager.dart:396`).

**Implemented (2026-09-10).** `SmsRequestPayload.dispatchAt` (optional, default `''`),
filled from `deliveredAt` (Standard Delivery / Hotline Direct) and `dispatchedAt`
(Air / Sea / Land, both tabs). The template appends `Dispatched At: <Sep 9, 2026
03:03 PM>.` to the `For Delivery` text and to a now-dedicated `Dispatch` case (the
other statuses in the shared branch are unchanged). New
`SmsMessageTemplateService.formatTimeForSms` renders `DateTime.now().toString()` /
ISO values via `BFormatter.formatDateWithAmPm` with raw-text fallback, and the
completion lines (`Date Time Received/Completed/...`) use it too. Not blocked by item
16: the stamp is taken on the courier's phone and the SMS is built from that local
model before anything round-trips through the DB. Tests:
`test/data/services/sms/sms_dispatch_time_test.dart`.

**Touch points**
- [x] `SmsRequestPayload` (`sms_request_payload.dart`) gains a
  `dispatchAt` + `dispatchTimeLabel` pair — keep it separate from
  `completionAt`/`completionTimeLabel`, which the completion branches use.
- [x] `SmsPayloadBuilder`: fill it from `model.deliveredAt` for
  `StandardDeliveryModel` and from `model.dispatchedAt` for `AirSeaModel`
  (`sms_payload_builder.dart:49-147`).
- [x] `SmsMessageTemplateService`: add a `dispatchTimeLine` (empty when the value is
  empty, mirroring `completionTimeLine`) and emit it in the `statusForDelivery`
  branch and in the `statusDispatch` case — split `statusDispatch` out of the shared
  branch at lines 58-71 rather than adding a time to every status in that group.
- [x] **Format the value.** `DateTime.now().toString()` yields
  `2026-09-09 14:03:12.123456`; run it through `BFormatter.formatDateWithAmPm`
  (`formatters.dart:43`) for the SMS. The existing completion lines print the raw
  string — fix them in the same pass so all SMS timestamps read alike.
- [x] ~~Depends on item 16 (timezone)~~ — verified not blocking: the SMS is built from the locally stamped model, so it already prints the courier's local time,
  so fix the +8h shift first or the message will advertise the wrong hour.
- [x] Watch SMS length (one extra ~40-char line; unchanged risk profile): templates already carry every document reference, and a
  longer body can tip a message into a second segment.
- [x] Add template unit tests (`test/`) for both dispatch branches, including the
  empty-timestamp fallback.

---

## 15. Android — Fullscreen and navigation-bar (gesture / 3-button) layout

**Requirement.** On Android phones the app must lay out correctly whether the device
uses a **gesture pill** or a **3-button navigation bar**, and when a screen runs
fullscreen — no content hidden behind or overlapping the system bars, and no dead
space where a nav bar isn't.

**Current behavior.**
- `BDevicesUtils.setFullScreen`, `hideStatusBar` and `showStatusBar`
  (`device_utility.dart:29-31, 79-85`) exist but are **never called** — nothing in
  `lib/` uses them, so the app runs in whatever mode the engine defaults to.
- Only ~25 files use `SafeArea` against ~67 that build a `Scaffold`, so bottom
  insets are applied inconsistently — the likely source of the reported clipping
  under the navigation bar.
- Newer Android releases force edge-to-edge, so bottom system insets must be
  honored explicitly rather than assumed to be zero.

**Touch points**
- [ ] Reproduce on both nav styles (Settings > System > Gestures on the test device)
  and capture the offending screens first — the fix list should be driven by real
  screenshots, not a blanket `SafeArea` sweep.
- [ ] Audit bottom-anchored UI: `Scaffold.bottomNavigationBar`, footer action
  buttons (`b_action_button.dart`, `request_modal_scaffold.dart:64`), FABs, and
  `showModalBottomSheet` bodies — the usual victims.
- [ ] Prefer `SafeArea` / `MediaQuery.viewPaddingOf` / `.padding` at the layout edge
  over per-widget magic numbers; do not double-pad a child whose parent already
  applied `SafeArea`.
- [ ] Decide the intended mode explicitly (`SystemUiMode.edgeToEdge` app-wide vs
  `immersiveSticky` only for camera/scanner/signature screens) and set it once at
  bootstrap (`main.dart` / `platform_init.dart`), then either wire up or delete the
  unused helpers in `device_utility.dart`.
- [ ] Keep keyboard behavior intact — several forms rely on `viewInsets`
  (`device_utility.dart:19-27` even infers orientation from
  `viewInsets.bottom`, which is a keyboard signal, not an orientation one; worth
  fixing while in here).
- [ ] Windows desktop must be unaffected — gate anything Android-specific behind a
  platform check.

---

## 16. Timezone — client timestamps land in the DB 8 hours late

**Symptom.** Courier presses Dispatch at ~3 PM; `requestdeliveredat` in Postgres reads
~11 PM. Same +8h on every timestamp the **phone** stamps; timestamps the **server**
stamps (`updatedat`, `createdat` on lose/backload items) come out right. That
asymmetry is the tell — it is not the phone clock.

**Root cause (confirmed in code, three links in the chain).**
1. **App sends a bare local wall clock, no offset.** Standard Delivery / Hotline stamp
   `DateTime.now().toString()` → `2026-09-09 15:03:12.123456`
   (`standard_delivery_data_manager.dart:319-322`, `hotline_direct_data_manager.dart:247-250`)
   and the mapper forwards it verbatim (`standard_delivery_mapper.dart:191`). Air/Sea
   and Pull Out go through `BFormatter.normalizeToIsoDatetime(..., toUtc: false)`
   (`formatters.dart:189-197`) → `toIso8601String()` on a *local* `DateTime`, which
   also carries no `Z`/offset (`air_sea_mapper.dart:91`, `pull_out_mapper.dart:53`).
2. **Backend relabels it as UTC instead of converting.** Every parse lands in
   `DateTimeKind.Unspecified`, and every normalizer's fallback arm is
   `_ => DateTime.SpecifyKind(value, DateTimeKind.Utc)` — 15:03 Manila becomes
   15:03 **Z** with the digits untouched:
   `RequestRepository.ParseUtcTimestamp` (`RequestRepository.cs:327-345`, callers
   278-281), `RequestAirSeaRepository.NormalizeToUtc` (`:344-357`, callers 249-261 —
   includes `DispatchedAt`), `RequestPickUpRepository.NormalizeToUtc` (`:356-363`),
   `RequestPullOutReturnPickUpRepository.NormalizeToUtc` (`:284-305`), and the global
   safety net `PostgreSqlAppDbContext.NormalizeTrackedDateTimesToUtc` on every
   `SaveChangesAsync` (`PostgreSqlAppDbContext.cs:103-166`).
3. **Postgres shifts it on the way in.** Npgsql EF 9.0.4 with no
   `EnableLegacyTimestampBehavior` switch sends a `Kind=Utc` value typed
   `timestamptz`, but all 56 timestamp columns are `timestamp without time zone`
   (`mdmpi_app_db_schema.sql`, and the team's own `migration_2026090*.sql`). Postgres'
   assignment cast `timestamptz → timestamp` renders the instant in the **session
   `TimeZone`**; with the DB server on `Asia/Manila`, `15:03Z` is written as `23:03`.
   The same cast is why `DateTime.UtcNow` stamps (`07:03Z`) come out as the correct
   `15:03` — the server-stamped columns are right *by accident of the same bug*.

Read-back does not hide it: `RequestRepository.cs:147,220` return the stored digits via
`ToString("yyyy-MM-dd HH:mm:ss")`, and the other repos return `DateTime` values that
System.Text.Json serializes without offset — after a re-sync the app shows 23:03 too.

**Verify before touching anything** (psql / pgAdmin against `mdmpi_app_db`):
```sql
SHOW timezone;                                 -- expect Asia/Manila (or +08)
SELECT column_name, data_type FROM information_schema.columns
 WHERE table_name = 'a_tblrequeststandarddelivery' AND data_type LIKE 'timestamp%';
SELECT requestid, requeststatus, requestdeliveredat, requestdeliveredendat, updatedat
  FROM a_tblrequeststandarddelivery ORDER BY updatedat DESC LIMIT 10;
```
Expected: `requestdeliveredat` / `requestdeliveredendat` are ~8h *after* the phone/SMS
time; `updatedat` (set from `DateTime.UtcNow`) matches wall-clock. If `SHOW timezone`
is `UTC`, the columns would hold the raw digits (15:03) instead — re-check before fixing.

**Fix (backend first — MDMPI.App; the app is a follow-up, not a prerequisite).**
- [x] (done — `MDMPI.App.Common/Utilities/TimestampNormalizer.ToUtc`, wired into `RequestRepository`, `RequestAirSeaRepository`, `RequestPickUpRepository`, `RequestPullOutReturnPickUpRepository` and `PostgreSqlAppDbContext`; the DB server session was confirmed at +08, Asia/Kuala_Lumpur) Replace the `_ => SpecifyKind(value, Utc)` arm in all five normalizers with a
  real conversion: `TimeZoneInfo.ConvertTimeToUtc(value,
  TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila"))` (IANA id works on the Linux
  `aspnet:8.0` image; keep `Utc`/`Local` arms as they are so an explicit `Z`/offset
  is still honoured). Centralize it in one helper in `MDMPI.App.Common` instead of
  five private copies. **Old APKs keep working** — the backend now treats an
  offset-less string as Manila time, which is exactly what they send.
- [x] (done locally; **`appsettings.json` is git-ignored, so set the same `Timezone=Asia/Manila` on the deployed server's connection string as part of the deploy**) Pin the session zone so the fix does not depend on server config: add
  `;Timezone=Asia/Manila` to `PostgreSqlDB` in `appsettings*.json`
  (Npgsql connection-string option). Document in the backend README that `timestamp`
  columns hold **Manila wall-clock** and every `DateTime` written must be a true UTC
  instant.
- [x] (done — `MDMPI.App.Tests/Common/TimestampNormalizerTests.cs`, 7 tests incl. the +08 write-cast round trip and re-save idempotence) Unit tests in `MDMPI.App.Tests` (none exist for this today): offset-less
  `2026-09-09 15:03:12` → `07:03:12Z`; `...Z` and `...+08:00` unchanged in instant
  terms; `Kind=Local` still converts.
- [x] (script ready: `MDMPI.App/repair_20260910_fix_plus8h_client_timestamps.sql` — self-scoping via history evidence (value 7-9h ahead of the server `changedat`), idempotent, takes `zz_backup_20260910_*` copies, has a PREVIEW block to review with Logistics before the REPAIR transaction; **run after the backend deploy**) **Data repair** — one-off SQL, reviewed with Logistics, scoped to rows written
  since the Npgsql 9 backend went live: subtract 8h from the client-stamped columns
  only (`requestitempreparedat`, `requestitempreparedendat`, `requestdeliveredat`,
  `requestdeliveredendat` on Standard Delivery; `itempreparedat`, `itempreparedendat`,
  `dispatchedat`, `dropoffat`, `provincial*at` on Air/Sea; `pulloutdatestartat`,
  `pulloutdateendat` on Pull Out; `itempreparedat`/`itempreparedendat` on Pick Up).
  Do **not** touch `createdat`/`updatedat`. Guard with `WHERE col > updatedat` where
  that holds, and run inside a transaction with a `SELECT` preview first. Remember
  the `_history` tables carry copies of the same columns.
- [x] (found on re-check, fixed in backend follow-up commit) **Date filters used the UTC day.** `Today/Yesterday/Tomorrow` boundaries came from `DateTime.UtcNow.Date` (Air/Sea, Pick Up) and `DateTime.Today` (Backload; `QueryFilterHelper` for Standard Delivery / Pull Out) — the API container is UTC, so days rolled over at 08:00 Manila, and with `datepickup` now correctly at midnight the Air/Sea + Pick Up "Today" filter would have missed today's rows. Now `TimestampNormalizer.BusinessToday()` / `BusinessDayStartUtc()` everywhere; no `DateTime.Today` / `UtcNow.Date` left in `lib`-equivalent code.
- [ ] App follow-up (after the backend ships): send an explicit UTC instant —
  `DateTime.now().toUtc().toIso8601String()` in the two data managers and
  `normalizeToIsoDatetime(..., toUtc: true)` in the Air/Sea and Pull Out mappers — so
  the wire format is unambiguous and no longer relies on the server's Manila
  assumption. Check `air_sea_dao.dart:14` (already `toUtc()` for the local cache) and
  the read-back formatters still display local time correctly.
- [x] ~~Blocks item 14~~ (resolved: the SMS prints the phone's local stamp before it round-trips the DB, so 14 was never blocked) Blocks item 14: do not print the dispatch time in the SMS until the stored
  value is right, or the message will advertise the wrong hour.

---

## 17. Live map — the same courier appears as two cars

**Symptom (screenshot 2026-09-10, Eton City Square).** One courier, one phone, but the
Delivery Location map draws two car markers on top of each other (pink + black). The
colours differ because the icon variant is hashed from the RequestID
(`WebSocketDeliveryController.dispatchMarkerIndexForRequestId`) — i.e. these are two
*requests*, not two devices.

**Root cause (confirmed in code).**
- Markers are **keyed per RequestID**, not per courier: `riderLocations` /
  `riderLocationUpdates` are `RxMap<String requestId, …>`
  (`web_socket_delivery_controller.dart:40-41`), and `riderBuildMarkers()` emits one
  `Marker(markerId: MarkerId(requestId))` per entry
  (`delivery_location_controller.dart:122-171`).
- **Entries are never removed.** No `riderLocations.remove/clear` exists anywhere in
  `lib/`. Once a request has sent a single frame it stays on the map until the app
  restarts — including after `Done Delivery`, `Cancelled`, or a courier switching to
  the next request. `stopTracking()` (`rider_realtime_tracking_controller.dart:110-118`)
  only stops *sending*; it never tells viewers to drop the marker.
- Two feeders make the stale entry reappear even after a restart:
  1. The WS server **replays the cached latest envelope per RequestID on connect**
     (comment at `web_socket_delivery_controller.dart:202-206`), so every finished
     request the server still remembers comes back as a car.
  2. The courier's offline queue (`_flushQueuedUpdates`,
     `rider_realtime_tracking_controller.dart:159-170`) replays frames for whatever
     request they belonged to, including a previous one, when connectivity returns.
- Net effect: courier finishes request A (car at its last position), dispatches request
  B from the same spot → A's stale car and B's live car sit on top of each other.
  Any viewer who taps the wrong one calls/looks at the finished request.

**Fix (app side; the server change is a nice-to-have, not a prerequisite).**
- [ ] Drop a request's marker when it leaves the "moving" states: on a
  `location_update` whose `status` is terminal, and on notification/status messages
  for `Done Delivery` / `Cancelled` (the same WS channel already carries
  `NotificationUpdate`), call `riderLocations.remove(id)`,
  `riderLocationUpdates.remove(id)`, `riderMarkerColors.remove(id)` and clear
  `previousPositions` / `markerBearings` in `DeliveryLocationController`.
- [ ] Have the courier publish a final `type: 'location_update', status: 'completed'`
  (or `tracking_stopped`) frame from `stopTracking()` so viewers get an explicit
  removal signal without depending on the request list; `_flushQueuedUpdates` must
  send it last and must **not** replay frames for a request that already has a
  completed frame queued.
- [ ] Belt-and-braces: reconcile against request data — a marker whose RequestID is
  not in the current For Delivery / In Transit set (Standard Delivery + Hotline
  Direct lists the viewer already loads) is hidden. Also age out markers whose last
  `timestamp` is older than a cutoff (e.g. 30 min) so a crashed courier phone does
  not leave a ghost car all day.
- [ ] Optional de-dup at render time: if two markers share the same `riderInitial`
  (or fall within ~5 m of each other), keep only the newest — this is the visual
  safety net for the case in the screenshot.
- [ ] Server (MDMPI WS relay): stop replaying cached envelopes for RequestIDs that
  have reached a terminal status, or expire the cache after N minutes. Until then the
  app-side reconciliation above is what protects the map.
- [ ] Unit tests: applying a completed frame removes the marker; a stale frame for a
  removed request does not resurrect it; render de-dup keeps the newest of two
  same-courier markers.

---

## 18. Gemini OCR — API key hygiene (key stays in the mobile client)

**Decision (2026-09-10).** Receipt OCR keeps calling Google Generative Language
**directly from the app** (`InventoryItemRepository.analyzeFileWithGemini`). The unused
backend proxy (`GeminiController` + `IGeminiService` + `GeminiSettings` +
`InventoryItemDto`, and the client's dead `analyzeFile()` /
`analyzeFileForInventory()` path) was removed the same day. Trade-off accepted: the key
is bundled into the APK via `.env` (`pubspec.yaml` assets) and is extractable by anyone
holding the APK; revoking it therefore requires shipping a new build.

**Done in the app**
- [x] Key moved from the URL query string (`?key=`) to the `x-goog-api-key` header so it
  no longer lands in proxy/CDN/device request logs.

**To do — ops side (no code)**
- [ ] **Rotate the key.** It sat in `.env` in this repo's history (removed in `d74aa51` /
  `c0bfeb6`) and in `appsettings.json` in the backend's history (2 commits before the
  file was emptied). Generate a new key in Google AI Studio / GCP, put it in the
  build machine's `.env` only, build APK, then delete the old key once the new APK is
  distributed (old APKs stop OCR-ing at that moment — nothing else breaks).
- [ ] **Restrict the new key in GCP:** API restriction → *Generative Language API* only;
  application restriction → *Android apps* with the release package name + SHA-1
  (verify the Gemini REST endpoint honours it for this key type; if not, keep the
  API-only restriction). Set a **billing budget alert** on the project.
- [ ] Remove the dead `AI_TOOLKIT_GOOGLE_URL` / `AI_TOOLKIT_AUTH_TYPE` /
  `AI_TOOLKIT_PROVIDER` lines from `.env.example` and README (only `AI_TOOLKIT_MODEL`,
  `AI_TOOLKIT_API_KEY`, optional `AI_PROMPT` are read).
- [ ] Revisit if abuse or cost ever shows up: the safer design is a server-side proxy
  with an app header + rate/size limits (the code removed on 2026-09-10 is in git
  history at MDMPI.App `6715105^…` if it is ever wanted back).

---

## Cross-cutting notes & risks

- **Backend coordination required** for items 2 (multiple image uploads), 3, 4, 7,
  8(a), 10, 11 — the sibling `MDMPI.App` ASP.NET backend (`/api4/*`) payloads and the
  Postgres schema (including `_history` tables and triggers) must change in lockstep.
  Never route non-`/api4` traffic to `MDMPI.App`.
- **Local DB migrations** needed for items 2, 4, 5 (if `previousStatus` is stored),
  7, 11 — version bump + `onUpgrade` in `database_helper.dart`; test on both Android
  and Windows (sqflite FFI).
- **Category dispatch is fuzzy string matching** on DB-provided category names in ~5
  places in `request_controller.dart` — items 8 and 10 must keep app constants and the
  server `a_tblFormCategory` rows in lockstep. Hard-coded category IDs (`'4'`, `'6'`,
  `'8'`, `'9'`) are scattered across data managers and deserve a constants home.
- **Known dead/duplicated code to be careful with** (found during this study):
  - `HotlineDirectForm` + `HotlineDirectDataManager.saveRequestFromForm` are dead
    creation paths — hotline creation really runs through the Standard Delivery form.
  - Proof/completion validation duplicated in `standard_delivery_data_manager.dart:785-826`
    and `b_action_button.dart:66-98`.
  - `_validateDeliveryInfo` in `standard_delivery_data_manager.dart:834` is dead; the
    live copy is in `standard_delivery_modal_config.dart:179`.
  - `PullOutModal` constructs its body/footer without passing the injected
    `IPullOutRequestController` (`pull_out_modal.dart:77-79`) — verify the Stock
    Receive modal passes it before adding controller-bound fields to those widgets.

## Suggested sequencing

1. **Quick wins (no backend):** 1, 12, 6.
2. **Decisions needed before coding:** 8 and 10 (pick a shape together), 9 (Driver =
   Courier?), 5 (scope of pause), 3 (does Stock Receive get Add Item too?).
3. **Backend-coupled tracks:** 2 (images) · 3→4 (pull-out items, remarks depends on
   items) · 7 (pick-up categories) · 11 (backload items).

**Open items (1-12 delivered):**

4. **First — backend bug, blocks 14:** 16 (timezone). Verify with the SQL in §16, fix
   the five normalizers + pin `Timezone=Asia/Manila`, repair data, then release.
5. **Quick win (no backend):** 14 (dispatch time in SMS) — self-contained; ship as soon
   as 16 is live so the printed hour is right.
6. **Device work:** 15 (Android inset audit) — needs a physical phone in both nav
   styles; verify Windows desktop is untouched.
6b. **Live map:** 17 (duplicate car markers) — app-only, testable with two requests on
   one courier account; coordinate the WS-relay cache change separately.
7. **Backend-coupled:** 13 (Mode of Shipment) — same three-step rollout as item 10:
   schema migration → backend deploy → app build. Settle the Land status-flow
   question with Logistics before coding.
