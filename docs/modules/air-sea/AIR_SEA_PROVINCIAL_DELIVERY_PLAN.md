# Air & Sea — Provincial Delivery Extension Plan

## Overview

Extend the Air/Sea module so that after a courier marks an item "Received" at the airline, a **provincial receiver** (authorized person in the destination province) continues the transaction: picks up the item from the airline and delivers it to the final client.

## Current Flow

```
New Request → Getting Supplies Ready → Item Prepared → Item Packed
```

After **Item Packed**, there are three possible paths:

```
Path A:  Item Packed → Endorsed to Guard → Received
Path B:  Item Packed → Dispatch → Drop Off
Path C:  Item Packed → Received
```

All paths converge at a terminal status (Received or Drop Off).

## Extended Flow (Provincial Delivery Leg)

After **Received** or **Drop Off** (item arrives at destination via airline), the provincial leg begins:

```
(Received or Drop Off)
  → Provincial Pick Up        (provincial receiver collects from airline)
    → Provincial In Transit   (en route to final client)
      → Provincial Delivered  (handed off to client, proof captured)
```

`Provincial Delivered` becomes the new terminal status. `Received` and `Drop Off` are no longer terminal — they trigger the provincial leg.

### Full Flow Diagram

```
New Request
  → Getting Supplies Ready
    → Item Prepared
      → Item Packed
          ├─ Path A: Endorsed to Guard → Received ──────┐
          ├─ Path B: Dispatch → Drop Off ───────────────┤
          └─ Path C: Received ──────────────────────────┤
                                                        ▼
                                              Provincial Pick Up
                                                → Provincial In Transit
                                                  → Provincial Delivered

(Any status) → Cancelled
```

---

## Implementation Steps

### 1. Status Constants — `BTexts`

**File:** `lib/base/utils/constants/text_string.dart`

Add:

```dart
static const String statusProvincialPickUp   = 'Provincial Pick Up';
static const String statusProvincialInTransit = 'Provincial In Transit';
static const String statusProvincialDelivered = 'Provincial Delivered';
```

### 2. New Role — `BTexts` + Role Priority

**File:** `lib/base/utils/constants/text_string.dart`

```dart
static const String roleProvincial = 'Provincial';
```

**File:** `lib/features/logistics/screens/air_sea/air_sea_list.dart`

Add to `_rolePriority`:

```dart
BTexts.roleProvincial: 2, // same level as Courier, or adjust as needed
```

Update the dispatch-status force logic to also force `roleProvincial` for provincial statuses.

### 3. Model — `AirSeaModel`

**File:** `lib/features/logistics/models/air_sea_model.dart`

Add fields:

| Field | Type | Description |
|---|---|---|
| `provincialReceiverName` | `String` | Name of the provincial receiver |
| `provincialReceiverSignature` | `String` | Base64 signature |
| `provincialPickUpAt` | `DateTime?` | When picked up from airline |
| `provincialDeliveredTo` | `String` | Final client contact name |
| `provincialDeliveredAt` | `DateTime?` | When delivered to client |
| `provincialRemarks` | `String` | Provincial delivery notes |
| `provincialProofImagePath` | `String` | Proof of delivery image |

Update `copyWith`, `toJson`, `fromJson`, `fromDbJson`.

### 4. DB Schema + Migration

**File:** `lib/data/local/db_schema.dart`

Add columns to `a_tblRequestAirSea`:

```sql
ProvincialReceiverName     TEXT DEFAULT ''
ProvincialReceiverSignature TEXT DEFAULT ''
ProvincialPickUpAt         TEXT DEFAULT ''
ProvincialDeliveredTo      TEXT DEFAULT ''
ProvincialDeliveredAt      TEXT DEFAULT ''
ProvincialRemarks          TEXT DEFAULT ''
ProvincialProofImagePath   TEXT DEFAULT ''
```

**File:** `lib/data/local/database_helper.dart`

Add `ALTER TABLE` migration for existing installs.

### 5. DTOs + Mapper

**Files:**
- `lib/features/logistics/dtos/air_sea/air_sea_dto.dart`
- `lib/features/logistics/dtos/air_sea/air_sea_update_dto.dart`
- `lib/features/logistics/mappers/air_sea_mapper.dart`

Add provincial fields to DTOs. Update mapper to convert between DTO ↔ model ↔ DB columns.

### 6. DAO

**File:** `lib/data/local/dao/air_sea/air_sea_dao.dart`

Update insert/update/select queries to include the new columns.

### 7. Form State — `AirSeaFormState`

**File:** `lib/features/logistics/helpers/air_sea_form_state.dart`

Add:
- `provincialReceiverController` (TextEditingController)
- `provincialDeliveredToController` (TextEditingController)
- `provincialRemarksController` (TextEditingController)
- `provincialSignature` (Rx<Uint8List?>)

Wire into `reset()` and `dispose()`.

### 8. Controller — `AirSeaController` / `AirSeaDataManager`

**Files:**
- `lib/features/logistics/controllers/air_sea_controller.dart`
- `lib/features/logistics/helpers/air_sea_data_manager.dart`

Add methods:
- `updateProvincialPickUp()` — sets status to `Provincial Pick Up`, saves receiver name + signature + timestamp.
- `updateProvincialInTransit()` — sets status to `Provincial In Transit`.
- `updateProvincialDelivery()` — sets status to `Provincial Delivered`, saves delivered-to + timestamp + proof image + remarks.

Each builds `AirSeaUpdateDto`, calls repository, refreshes list.

### 9. Modal Config — `AirSeaModalConfig.resolve()`

**File:** `lib/features/logistics/helpers/air_sea_modal_config.dart`

- Remove `statusReceived` and `statusDropOff` from terminal/view-only guard so they become actionable for `roleProvincial`.
- Add config entries for the provincial role:

| Current Status | Next Status | Button Label | Required Fields |
|---|---|---|---|
| Received | Provincial Pick Up | "Confirm Pick Up" | Receiver name, signature |
| Drop Off | Provincial Pick Up | "Confirm Pick Up" | Receiver name, signature |
| Provincial Pick Up | Provincial In Transit | "Start Transit" | — |
| Provincial In Transit | Provincial Delivered | "Confirm Delivery" | Delivered-to, proof image, remarks (optional) |

Both `Received` (Path A/C) and `Drop Off` (Path B) serve as entry points into the provincial leg.

### 10. UI Widgets

**New files under** `lib/features/logistics/screens/air_sea/widgets/`:

- `air_sea_provincial_pick_up_section.dart` — receiver name input + signature capture.
- `air_sea_provincial_delivery_section.dart` — client contact input + delivery timestamp + proof image upload + remarks.

**Update:** `air_sea_modal.dart` — conditionally show provincial sections based on status.

### 11. Status Colors — `StatusColorMapper`

**File:** `lib/features/logistics/helpers/status_color_mapper.dart`

Add entries:

| Status | Suggested Color |
|---|---|
| Provincial Pick Up | Teal |
| Provincial In Transit | Indigo |
| Provincial Delivered | Dark Green |

### 12. List Screen Guards — `air_sea_list.dart`

**File:** `lib/features/logistics/screens/air_sea/air_sea_list.dart`

- Update `onLongPress` guard: replace `statusReceived` with `statusProvincialDelivered` as the terminal status.
- Add provincial status force logic (similar to dispatch force for Courier).

### 13. Filter Manager

**File:** `lib/features/logistics/helpers/air_sea_filter_manager.dart`

Add the three new statuses to the available filter options.

---

## Decisions Needed Before Implementation

| # | Question | Recommendation |
|---|---|---|
| 1 | New `roleProvincial` or reuse existing role? | **New role** — distinct actor, cleaner separation |
| 2 | API field names for provincial columns? | Confirm with backend team before DTO work |
| 3 | Can provincial receiver see full request history? | Yes (read-only for prior statuses) |
| 4 | Is proof image required for Provincial Delivered? | Recommend required |
| 5 | Should provincial statuses appear in existing filter chips? | Yes, appended to the filter list |

---

## Testing

- **DAO:** Round-trip read/write for new columns
- **Mapper:** Provincial field mapping DTO ↔ model
- **Controller:** Status transition logic (Received → Provincial Pick Up → In Transit → Delivered)
- **QA checklist:** Generate via `dart run bin/generate_module_qa.dart --name "Air Sea Provincial" --area Logistics --routes "/air-sea"`

---

## File Change Summary

| File | Change |
|---|---|
| `text_string.dart` | Add 3 status constants + 1 role constant |
| `air_sea_model.dart` | Add 7 provincial fields |
| `db_schema.dart` | Add 7 columns to `a_tblRequestAirSea` |
| `database_helper.dart` | Add ALTER TABLE migration |
| `air_sea_dto.dart` | Add provincial fields |
| `air_sea_update_dto.dart` | Add provincial fields |
| `air_sea_mapper.dart` | Map provincial fields |
| `air_sea_dao.dart` | Update queries |
| `air_sea_form_state.dart` | Add provincial form controllers |
| `air_sea_controller.dart` | Add 3 provincial update methods |
| `air_sea_data_manager.dart` | Support provincial updates |
| `air_sea_modal_config.dart` | Add provincial role configs |
| `air_sea_modal.dart` | Show provincial sections |
| `air_sea_list.dart` | Update guards + role priority |
| `air_sea_filter_manager.dart` | Add provincial statuses to filters |
| `status_color_mapper.dart` | Add 3 color entries |
| **New:** `air_sea_provincial_pick_up_section.dart` | Pick-up UI |
| **New:** `air_sea_provincial_delivery_section.dart` | Delivery UI |

