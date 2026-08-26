# Collection Feature Overview

This module handles the collection workflow for the mobile app. It covers the following user journey:

- Review assigned collection accounts and invoices
- Assess due dates, repayment status, and account-level history
- Claim / move selected accounts into activity
- Record collection outcomes such as collection, partial collection, follow-up, deposit, and reconciliation
- Track monthly collection totals and recent activity logs

This feature is designed for backend handoff, so the frontend structure is organized around domain models, DTOs, controllers, and repository contracts.

## 1. Folder structure

```text
lib/features/collection/
├── constants/
├── dtos/
│   └── collection_item_dto.dart
├── helpers/
│   ├── collection_status_colors.dart
│   ├── due_date_helper.dart
│   ├── filter_manager.dart
│   └── sync_manager.dart
├── mappers/
│   └── collection_mapper.dart
├── models/
│   ├── collection_item_model.dart
│   └── collection_history_model.dart
├── presentation/
│   ├── controllers/
│   │   ├── collection_activity_controller.dart
│   │   ├── collection_onboarding_controller.dart
│   │   └── total_collected_controller.dart
│   └── pages/
│       ├── activity/
│       ├── area_selection/
│       ├── bucket/
│       ├── calendar/
│       ├── home/
│       ├── onboarding/
│       └── total_collected_month/
└── README.md
```

## 2. Main business flow

### 2.1 Bucket / account review
The app loads a list of collection items from the repository and groups them by client/account. The main screen is built around `CollectionActivityController`.

Relevant responsibilities:

- `bucketItems`: items currently in the collection bucket
- `activityItems`: claimed items that are now in activity mode
- `masterAccountList`: unique list of clients/accounts for filtering
- `selectedBucketIds`: multi-selection for manual claim operations
- `selectedArea`: territory-level filtering

The bucket is the queue for collection work, and account-level summaries are derived from the `client.id` field.

### 2.2 Activity tracking
Once a user claims one or more collection accounts, the system moves them into the activity flow. Activity items include:

- total outstanding amount
- total collected amount
- history record of every interaction
- outcome status (for example `Collected`, `Partially Collected`, `Follow Up`)

Activity screens also support:

- account invoice details
- activity filters
- deposit / CWT / reconciliation tracking
- recent engagement history

### 2.3 Monthly summary and dashboard
The app presents summary values such as:

- actual collection total
- total collected this month
- overdue accounts
- settled / reconciliation / advanced payment counts

These are powered by `TotalCollectedController` and `CollectionHomeScreen`.

## 3. Core data models

### 3.1 `CollectionItemModel`
This is the main frontend domain model.

Key fields:

- `id`: invoice or document identifier
- `client`: `ClientModel` object
- `documentReferences`: list of related document references
- `bankName`: bank associated with payment
- `toBeCollected`: amount still due
- `totalCollected`: amount already collected for that item
- `remarks`: notes for the account/document
- `documentDate`, `postingDate`, `dueDate`: dates used for timeline and overdue logic
- `status`: current collection status
- `lastOutcome`: latest outcome recorded for the item
- `assignedAt`: claim timestamp
- `collectorName`: assigned collector
- `history`: list of `CollectionHistoryModel`

Derived logic:

- `daysPastDue`: numeric overdue calculation
- `isOverdue`: true when `dueDate` is past due

### 3.2 `CollectionHistoryModel`
This represents a single activity record attached to an item or account.

Fields:

- `date`
- `collectorName`
- `status`
- `remarks`
- `totalCollected`
- `bankName`
- `checkNumber`
- `checkDate`
- `purposeOfVisit`

This is the most important structure for the backend because it is how collection updates are recorded over time.

## 4. DTO and mapper contract

The app uses a DTO layer to isolate backend JSON naming from the internal domain model.

- `lib/features/collection/dtos/collection_item_dto.dart`
- `lib/features/collection/mappers/collection_mapper.dart`

### DTO behavior
`CollectionItemDto` expects API response fields like:

```json
{
  "id": "INV-1001",
  "Client": {
    "id": "CUST-01",
    "code": "BP001",
    "name": "PT Example",
    "address": "Jakarta",
    "contact": "0812...",
    "emailAddress": "example@email.com"
  },
  "DocumentReferences": ["DOC-01", "DOC-02"],
  "BankName": "Bank Mandiri",
  "ToBeCollected": 2500000,
  "TotalCollected": 500000,
  "Remarks": "Customer requested postponement",
  "DocumentDate": "2026-08-01",
  "BPCode": "BP001",
  "PostingDate": "2026-08-03",
  "DueDate": "2026-08-20",
  "Status": "",
  "LastOutcome": "Follow Up",
  "AssignedAt": "2026-08-10T08:30:00Z",
  "CollectorName": "Collector A",
  "History": [
    {
      "Date": "2026-08-10T08:30:00Z",
      "CollectorName": "Collector A",
      "Status": "Follow Up",
      "Remarks": "Due follow-up scheduled",
      "TotalCollected": 0,
      "BankName": null,
      "CheckNumber": null,
      "CheckDate": null,
      "PurposeOfVisit": null
    }
  ]
}
```

### Mapper behavior
`CollectionMapper` converts:

- `CollectionItemDto` -> `CollectionItemModel`
- `CollectionItemModel` -> `CollectionItemDto`
- list versions for batch handling

This is the main place where backend field naming differences should be normalized.

## 5. Status definitions used by frontend

The frontend currently uses the following status keys:

- `Collected`
- `Partially Collected`
- `Pre-Collection`
- `Follow Up`
- `Customer Unavailable`
- `Refused to Pay`
- `Others`
- `Deposit`
- `CWT Pick-up`
- `Reconciliation`

Important note:

- `Pending` and `On-going` were removed from the visible status set in the UI
- `CollectionStatusColors` keeps the active status names and UI color/icon mapping
- `updatableStatuses` only includes a subset: `Collected`, `Partially Collected`, `Pre-Collection`, and `Others`

This matters for backend validation. The API should not assume the removed statuses are still active in the app.

## 6. Repository contract

Main repository:

- `lib/data/repositories/collection/collection_repository.dart`

The repository is the backend-facing layer and currently exposes the following core operations:

```dart
Future<List<CollectionItemModel>> getAll({bool forceRefresh = false, bool silent = false})
Future<void> claimItemsByIds(List<String> ids, {bool silent = false})
Future<void> saveActivity({
  required String id,
  required String status,
  required String remarks,
  double? totalCollected,
  String? bankName,
  String? checkNumber,
  String? checkDate,
  String? purposeOfVisit,
  bool silent = false,
})
```

### Endpoint expectations
The repository currently uses:

```dart
static const String _resource = '/api/collection/items';
```

And it expects the response JSON root to resolve as either:

- a raw array
- `{ "data": [...] }`
- `{ "items": [...] }`

The backend should return a list of collection item objects that can be mapped by `CollectionItemModel.fromJson()`.

### Offline-first design
The repository is intentionally designed for offline-first behavior:

- local SQLite cache first when offline
- local DB fallback when API fails
- periodic background sync with server refresh logic
- `SyncManager` for queued unsynced changes

This means backend changes should be compatible with an eventually-consistent local-first flow.

## 7. Local sync and pending change handling

There is a sync queue layer for tracking operations that have not yet been transmitted to the API.

Relevant files:

- `lib/features/collection/helpers/sync_manager.dart`
- database DAO under `data/local/dao/collection/`

The sync manager tracks:

- `syncStatus`: `idle`, `syncing`, `failed`, etc.
- `isSyncing`
- `hasPendingChanges`
- `syncErrorMessage`

The intended backend contract is server-side endpoints that accept queued update payloads for collection item changes and history append operations.

## 8. Frontend screens and modules

### Home screen
- `presentation/pages/home/home.dart`
- `[CollectionHomeScreen]`

Displays:

- actual collection total card
- total collected card
- collection bucket button
- summary cards (Settled, Due Date, Reconciliation, Advanced Payment)
- recent activity section

### Bucket screen
- `presentation/pages/bucket/collection_bucket_screen.dart`

Represents the main assignment and review queue.

Used for:

- account grouping
- invoice list per client
- filtering and search
- multi-select claim workflow

### Activity screen
- `presentation/pages/activity/activity.dart`

Represents the post-claim workflow and includes:

- account history
- activity summary
- payment / deposit / reconciliation actions
- detailed record updates

### Onboarding flow
- `presentation/pages/onboarding/onboarding.dart`

Used for explaining the collection process before the main flow starts.

### Monthly summary
- `presentation/pages/total_collected_month/monthly_summary_screen.dart`

Used for monthly analytics by type:

- `Collection`
- `Deposit`

## 9. Backend handoff expectations

For backend implementation, the most important data to support is:

1. Collection item listing
2. Account-level grouping by client ID
3. Invoice-level outstanding and collected amounts
4. History timeline per item/account
5. Status updates and outcome logging
6. Monthly totals and dashboards
7. Claim / assignment tracking
8. Deposit and reconciliation events

### Recommended API structure
The backend should expose at least:

- `GET /api/collection/items` -> returns all active collection items
- `PATCH /api/collection/items/:id` -> updates item fields or collection outcome
- `POST /api/collection/items/:id/history` or equivalent -> appends a new history record
- optional `POST /api/collection/claim` or `PATCH /api/collection/items/claim` -> used for claim assignment flow

### Required response fields
The system relies heavily on these fields:

- `id`
- `Client.id`
- `Client.name`
- `Client.code`
- `DocumentReferences`
- `ToBeCollected`
- `TotalCollected`
- `DueDate`
- `Status`
- `LastOutcome`
- `CollectorName`
- `AssignedAt`
- `History[]`

## 10. Important implementation notes

- The frontend acts as if all collection items are the source of truth for the bucket and activity flow.
- `CollectionRepository` does not currently call a dedicated service layer for each action; it directly performs local DB and HTTP operations.
- `CollectionActivityController` is the main orchestration point for bucket + activity state.
- Several calculations are derived in controllers rather than in the UI, so data contracts should remain stable.
- The app is highly sensitive to field casing and nested object names (`Client`, `History`, `DocumentReferences`, etc.).

## 11. Summary for backend developer

This module is effectively a collection operations dashboard with a structured history model. The backend should treat each collection item as a document/invoice assigned to one client and one collector, with a timeline of activities and outcomes. The frontend expects this data to be stable, filterable, and rich enough to support:

- bucket review
- assignment / claim flow
- outcome updates
- deposit and reconciliation handling
- monthly reporting

If the backend mirrors these structures and preserves the semantics of `History`, `Status`, and `TotalCollected`, the app can be integrated with minimal front-end changes.
