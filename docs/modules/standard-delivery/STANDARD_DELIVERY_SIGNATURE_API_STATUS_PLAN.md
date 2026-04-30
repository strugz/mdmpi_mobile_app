# Standard Delivery Signature API Status Plan

## Overview

This document focuses exclusively on making receiver signature uploads resilient in the `StandardDeliveryDataManager.updateRequestStatus` flow.

We will scope the work to the signature path only and remove proof-image changes from this first pass. The goal is to ensure captured signatures are durable, visible in the local DB, and retryable when the upload API fails.

## Goal

Make signature upload resilient while keeping the current GetX + repository + local DB architecture unchanged.

## Proposed Direction (signature-only)

Use `a_tblRequestReceiverSignature` as the local source of truth for captured signatures.

When a delivery is completed and a signature exists:

1. persist the signature locally to `a_tblRequestReceiverSignature`
2. add and maintain an `ApiStatus` field on that table
3. attempt the signature upload API
4. update `ApiStatus` according to the upload result

Recommended `ApiStatus` values:

- `Pending`
- `Synced`
- `Failed`

This guarantees the signature is never lost even if the upload API fails. If the signature upload API fails, the signature record MUST exist (or be written) in `a_tblRequestReceiverSignature` and be marked with `ApiStatus = Failed` so it is durable and retryable.

### Transaction separation

Keep the transaction (request) update independent of the signature upload, with the following concrete rule:

- If the transaction update succeeds but the signature upload fails, then **and only then** the signature MUST be persisted in `a_tblRequestReceiverSignature` and marked with `ApiStatus = Failed`. This creates a clear outbox entry for user attention and retry.
- If the transaction update fails (for example due to network or server error), the request should be preserved locally and any captured signature must not be discarded; the signature row may be created or updated by the local persistence phase, but the explicit `Failed` outbox entry only appears when the transaction has already been accepted by the server and the signature upload subsequently fails.

Rationale: this minimizes accidental duplicate outbox items while guaranteeing that a signature is surfaced to users only when the request itself exists on the server.

## Target Behavior (signature-only)

When `newStatus == BTexts.statusDoneDelivery` and the form captured a new signature:

1. keep the captured signature in memory (or saved via the existing temporary media flow) but do NOT create a failed outbox entry yet
2. persist/update the request locally
3. attempt `_repository.updateDelivery(updatedRequest, userInitial)` (transaction sync)
4. attempt signature upload separately
   - success → nothing to persist in outbox (optionally mark Synced)
   - failure → persist the signature into `a_tblRequestReceiverSignature` and set `ApiStatus = Failed` so the app can retry it later
5. surface a clear UI summary indicating request vs signature sync state

## Implementation Plan (signature-only)

### 1. Schema update

**Files:**
- `lib/data/local/db_schema.dart`
- `lib/data/local/database_helper.dart`

Changes:

- add `ApiStatus` to `a_tblRequestReceiverSignature`

Suggested column definition:

```sql
ApiStatus TEXT DEFAULT 'Pending'
```

Follow the project's schema update approach when modifying `db_schema.dart`.

Runtime behavior note:

- On initial local save the signature row should be created with `ApiStatus = 'Pending'`.
- If the transaction update later succeeds but the signature upload fails, the signature row must be updated to `ApiStatus = 'Failed'` (this is the explicit outbox entry case described in the Transaction separation rule).
- When a retry upload succeeds, update the row to `ApiStatus = 'Synced'`.

### 2. DAO and database helpers

**Files:**
- `lib/data/local/dao/standard_delivery/standard_delivery_dao.dart`
- `lib/data/local/database_helper.dart`

Add helper methods (minimal set as requested):

- insert/save signature with `ApiStatus` (insert only)
- delete signature row by `RequestID` (delete only)

Notes:

- Use the existing `getAllReceiverSignatures()` DAO method to list outbox entries for the Signature Outbox UI. If you need to change `ApiStatus` after a transaction result, re-insert the row (REPLACE) with the desired `ApiStatus` value using the insert helper.

### 3. Refactor `updateRequestStatus`

**File:**
- `lib/features/logistics/helpers/standard_delivery_data_manager.dart`

Refactor into phases (signature-only focus):

Phase A — validation and updatedRequest build
- validate delivery inputs
- create `updatedRequest`

Phase B — local persistence
- save/update request locally
- do NOT persist the signature to the outbox yet; keep it available for immediate upload attempt (or save via existing temporary media flow)

Phase C — transaction sync
- attempt `_repository.updateDelivery(updatedRequest, userInitial)`
- on failure keep local row and show pending sync

Phase D — signature sync
- attempt `ImageRepository.instance.uploadFile(... type: 'Signature')`
- on success do nothing further (the signature is uploaded)
- on failure persist the signature into `a_tblRequestReceiverSignature` with `ApiStatus = 'Failed'` (or re-insert if a previous temporary save exists) so it becomes an outbox entry for retry

Phase E — final UX summary
- show a single summary message that differentiates request vs signature sync state (see messaging below)

### 4. Retry strategy (signature-only)

**Primary file:**
- `lib/features/logistics/helpers/standard_delivery_data_manager.dart`

Retry sources:

- manual sync action (e.g., Settings or a dedicated "Retry uploads" action)
- `uploadModifiedRequest()` (extend to also retry signature rows)
- connectivity-restored handler (future work)

Retry logic:

1. query signature rows where `ApiStatus != 'Synced'` (use `getAllReceiverSignatures()` or a filtered variant)
2. attempt upload
3. on success delete the signature row from `a_tblRequestReceiverSignature` (outbox cleared)
4. on failure keep the row (it remains visible in Signature Outbox); to change `ApiStatus`, re-insert the row with the new status (REPLACE)

### Signature Outbox (UI)

To make pending signatures visible and actionable, add a developer-facing `SignatureOutbox` widget accessible from the Settings screen (Developer Tools section).

Behavior and responsibilities:

- List signature outbox entries where `ApiStatus != 'Synced'` (show `Failed` and `Pending`).
- Display: Request ID, capturedAt timestamp, `ApiStatus`, retryCount (optional), and a small signature preview/thumbnail.
- Per-row actions: `Retry` (attempt upload), `View` (open full-size preview), `Mark as Ignored` (developer-only).
- Bulk actions: `Retry All` and `Clear All` (both developer-only and require confirmation).

Placement and files:

- Lightweight widget: `lib/features/personalization/widgets/signature_outbox.dart`.
- Optional full page: `lib/features/personalization/screens/settings/signature_outbox_page.dart`.
- Add an entry in the Settings screen (under Developer Tools) to open the outbox widget/page.

Data & control flow:

- The widget queries `a_tblRequestReceiverSignature` via `StandardDeliveryDao` / `DatabaseHelper` to load pending rows.
-- On `Retry`, call `StandardDeliveryDataManager.retryPendingSignatures()` (new helper) or use `ImageRepository.instance.uploadFile(...)`; on successful upload call `deleteReceiverSignatureByRequestId(...)` to remove the outbox entry.
- Show progress and results using `BLoaders` / `BFullScreenLoader` and `BLoaders.successSnackBar` / `BLoaders.errorSnackBar` for feedback.

UX notes:

- Keep the widget minimal: compact ListView with per-row actions is sufficient.
- Hide this widget behind a developer flag so it is not shown in production UI unless explicitly enabled.

## User feedback rules

Preferred messaging examples:

| Scenario | Message |
|---|---|
| Request + signature synced | `Request updated successfully.` |
| Request synced, signature pending/failed | `Request updated. Signature upload is pending and will retry.` |
| Request sync failed (saved locally) | `Request saved locally. It will sync when connection returns.` |

Keep messages succinct and avoid multiple layered snackbars for the same action.

## Logging

Use `logDebug()` for each important step:

- local signature save start/success/fail
- transaction API start/success/fail
- signature API start/success/fail
- retry attempts

## Affected Files (signature-only)

| File | Planned change |
|---|---|
| `lib/features/logistics/helpers/standard_delivery_data_manager.dart` | refactor `updateRequestStatus` to persist signature locally and track `ApiStatus` |
| `lib/data/local/db_schema.dart` | add `ApiStatus` to `a_tblRequestReceiverSignature` |
| `lib/data/local/database_helper.dart` | expose helpers for signature save/status updates |
| `lib/data/local/dao/standard_delivery/standard_delivery_dao.dart` | add read/write helpers for signature rows and status queries |
| `lib/data/repositories/image/image_repository.dart` | keep upload API usage; make upload errors explicit so the calling code can update `ApiStatus` |

## Recommended Delivery Order

1. add `ApiStatus` to `a_tblRequestReceiverSignature`
2. add local DB helper methods for signature sync state
3. refactor `updateRequestStatus` to save signature locally first and update `ApiStatus` after upload attempts
4. extend `uploadModifiedRequest()` (or add a dedicated retry action) to retry signature uploads
5. improve UI messaging and logs

## Open Decisions (signature-only)

1. Should `ApiStatus` use text values (`Pending`, `Synced`, `Failed`) or integer flags?
2. Retry policy: should failures remain `Failed`, or be re-marked `Pending` before each retry attempt?
3. Where to surface a manual retry action in the app (Settings > Developer Tools or a visible "Retry uploads" option)?

## Recommendation

Proceed with the signature-table change first. This yields the most reliability improvement with minimal changes:

- reuses existing local storage (`a_tblRequestReceiverSignature`)
- makes signature sync state visible and queryable
- avoids losing captured signatures
- enables safe retries without blocking transaction updates

Once signature sync is stable, consider applying the same pattern to proof images if desired.






