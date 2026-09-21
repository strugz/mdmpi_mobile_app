# Collection Module

## Overview

The Collection module is a department-specific feature for the Collection team within the MDMPI Mobile App. It has grown well past onboarding: roughly 50 Dart files now cover collection activities (advanced payment, CWT pickup, deposit, reconciliation), bucket screens, account invoices, area selection, a calendar and a monthly total. It follows the presentation pattern (`presentation/controllers` + `presentation/pages`) with feature-level `dtos/`, `mappers/`, `models/` and `helpers/` folders — there is **no** `domain/` folder.

## Architecture

### Folder Structure

```
lib/
  features/collection/
    dtos/collection_item_dto.dart
    mappers/collection_mapper.dart
    models/
      collection_item_model.dart
      collection_history_model.dart
    helpers/
      collection_status_colors.dart
      due_date_helper.dart
      filter_manager.dart
      sync_manager.dart                     # Offline sync of pending collections
    presentation/
      controllers/
        collection_onboarding_controller.dart  # Onboarding state management
        collection_activity_controller.dart    # Activity create/list state
        total_collected_controller.dart        # Monthly total
      pages/
        home/                               # CollectionHomeScreen + widgets
        onboarding/                         # CollectionOnBoardingScreen + widgets
        activity/                           # Activity list, detail, batch detail,
                                            #   account invoices, add_activity/
        bucket/                             # Bucket screens
        area_selection/
        calendar/
        total_collected_month/
lib/data/repositories/collection/collection_repository.dart
lib/data/local/dao/collection/
  collection_dao.dart
  collection_pending_dao.dart
```

### Data Flow

```
AppRouter (department = "Collection")
  → CollectionOnBoardingScreen (if not completed)
    → CollectionOnboardingController
      → GetStorage (persists onboarding completion flag)
  → NavigationMenu (after onboarding)
    → Collection Home
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `CollectionOnboardingController` | `features/collection/presentation/controllers/` | Manages onboarding state & completion |
| `CollectionOnBoardingScreen` | `features/collection/presentation/pages/onboarding/` | Onboarding UI |
| `CollectionHomeScreen` | `features/collection/presentation/pages/home/home.dart` | Department home screen |
| `CollectionActivityController` | `features/collection/presentation/controllers/` | Activity create/list state |
| `TotalCollectedController` | `features/collection/presentation/controllers/` | Monthly collected total |
| `CollectionRepository` | `data/repositories/collection/` | Remote/local collection data |
| `SyncManager` | `features/collection/helpers/` | Syncs pending collections when back online |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => CollectionOnboardingController(), fenix: true);  // general_bindings.dart:204
Get.lazyPut(() => CollectionActivityController(), fenix: true);    // :245
Get.lazyPut(() => CollectionRepository(), fenix: true);            // :246
Get.lazyPut(() => SyncManager(), fenix: true);                     // :247
```

### Department Routing

The Collection module is accessed via `AppRouter` when the user's department is
`"Collection"`. Note `app_router.dart:63` lowercases the department before switching, so
the case label is `'collection'`:

```dart
case 'collection':
  final collectionComplete = storage.read('CollectionOnboardingComplete') ?? false;
  if (!collectionComplete) {
    return const CollectionOnBoardingScreen();
  }
  break;
```

### Notes

- There is no `domain/` folder. Data lives in feature-level `dtos/`, `mappers/`, `models/`
  and `helpers/`, with the repository under `data/repositories/collection/` and DAOs under
  `data/local/dao/collection/`.
- Collections captured offline are held by `collection_pending_dao.dart` and flushed by
  `SyncManager`.
- **`a_tblCollectionEngagement` is the one collection table a download may not rewrite.**
  Every other one is a cache of what the server currently says:
  `deleteAllCollectionItems()` truncates the items and their history, and
  `_replaceAccountLevelData` replaces the advance, activity, account-history and target
  tables on each workspace download. Uploading triggers a download, so a collector's own
  engagements used to be erased minutes after they were recorded, and a settled invoice
  took its history with it when the server stopped returning it. The archive is written
  through by `CollectionRepository` on every save path, read by the calendar and by the
  monthly ledger, and `CollectionEngagementDao` deliberately exposes no `clear()` or
  `replaceAll()` so no download path can reach it.
- Engagement stamps are **local ISO-8601**, written only by the repository. Read them with
  `BFormatter.parseLocal` / `localDayKey`, which apply `.toLocal()`: a server stamp with a
  `Z` parses to UTC, and reading its `y/m/d` fields filed every engagement before 08:00 PH
  under the previous day.
- A collector is identified for filtering by `collectorCode` (stable); `collectorName` is
  for display only. Older rows may carry the full name, initials or the literal `'You'`,
  which is what `CollectionRepository.collectorAliases` and the one-shot
  `backfillOwnEngagements()` match against.
- The module uses the same `NavigationMenu` bottom-tab shell as other departments after
  onboarding.
- This is one of the four department types alongside Logistics, Service, and InHouse.
