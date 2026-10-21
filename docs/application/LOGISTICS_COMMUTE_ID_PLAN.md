# Logistics: Commute ID instead of a Trip Ticket Number

Status: **implemented** (2026-10-20), not yet deployed. Run the migration before
shipping the backend.

## Problem

Every Logistics flow that dispatches a driver requires a **Trip Ticket Number**
and a **Vehicle**. Some drivers commute (public transport, no company vehicle),
so they have neither, and the request could not move forward.

## What it does

A **"Commuting (no trip ticket)"** switch sits under every Trip Ticket No input.
Turning it on:

1. asks MDMPI.App for a **Commute ID** (`POST /api4/CommuteId`),
2. writes it into the trip ticket field (read-only, relabelled "Commute ID"),
3. clears and hides the Vehicle field.

Turning it off clears the field so a real trip ticket can be typed. If the same
form flips the switch again, it reuses the ID it already got, so toggling does
not use up numbers. The ID is forgotten when the form resets after a save.

Commute ID format: `yyyyMMdd` + 4-digit daily sequence on the **Manila**
calendar, e.g. `202610200001`. It restarts at `0001` each day.

Decisions (2026-10-20): server-issued, `YYYYMMDD`, daily reset, vehicle check
skipped for commute. Driver is still required; helper stays optional.

## Backend (MDMPI.App)

| Piece | File |
|---|---|
| Counter table (one row per Manila day) | `migration_20261020_add_a_tblcommutecounters.sql` |
| Entity | `MDMPI.App.Core/Logistic/Entities/CommuteCounterModel.cs` |
| Generator | `MDMPI.App.Data/Common/Services/CommuteIdGenerator.cs` (+ `ICommuteIdGenerator`) |
| Endpoint | `MDMPI.App.Api/Controllers/Logistic/CommuteIdController.cs` returns `{ "CommuteID": "…" }` |
| Tests | `MDMPI.App.Tests/Logistic/CommuteIdGeneratorTests.cs`, `Api4RouteCompatibilityTests.cs` |

The generator does one `insert … on conflict do update … returning` statement,
so two drivers asking at the same moment can never get the same number.

The value is stored in the existing trip ticket columns
(`tripticketnumber` / `requesttripticketnumber`, `varchar(50)`): no change to
the request tables or DTOs.

## App

| Piece | File |
|---|---|
| Format check, label, switch state | `lib/features/logistics/helpers/commute_id.dart` (`BCommuteId`, `CommuteTicketToggle`) |
| Repository (`/api4`) | `lib/data/repositories/app_data/commute_id_repository.dart`, registered outside the Firebase guard |
| Response key | `BApiResponse.commuteId` in `api_response_keys.dart` |
| Shared input | `lib/features/logistics/widgets/trip_ticket_input.dart` (`TripTicketInput`) |
| Tests | `test/features/logistics/commute_id_test.dart` |

Wired into every flow that asks for a trip ticket:

| Flow | Input | Vehicle hidden in | Vehicle check skipped in |
|---|---|---|---|
| Standard Delivery / Hotline Direct | `request_modal_body.dart` | `b_mobile.dart` | `standard_delivery_data_manager.dart`, `standard_delivery_modal_config.dart`, `hotline_direct_data_manager.dart` |
| Air/Sea | `air_sea_item_packed_section.dart` | same file | `air_sea_data_manager.dart`, `air_sea_modal_config.dart` |
| Pull Out | `pull_out_modal_body.dart` | same file | `pull_out_data_manager.dart`, `pull_out_modal_config.dart` |
| Stock Receive | `pull_out_form.dart` (create), `pull_out_modal_body.dart` | same files | `pull_out_data_manager.dart` (create), `stock_receive_data_manager.dart` |

The validators skip the vehicle when the trip ticket value
`BCommuteId.isCommuteId(...)`: 12 digits whose first 8 are a real date. Real
trip tickets (`01019`, `12345`) never match. Read-only views
(`b_request_details.dart`, `air_sea_dispatch_info_section.dart`,
`pull_out_modal_body.dart`, `request_modal_body.dart`) label the value
"Commute ID".

## Limits

- **Needs internet when the switch is turned on.** Offline, it shows "Could not
  get a Commute ID" and stays off. The offline placeholder that the outbox would
  replace at upload (in the first plan) was not built.
- A trip ticket typed by hand that happens to look like a Commute ID (12 digits
  starting with a real date) would also skip the vehicle check.

## Rollout

1. Run `migration_20261020_add_a_tblcommutecounters.sql` on the testing Postgres DB.
2. Deploy MDMPI.App.
3. Ship the app build.
