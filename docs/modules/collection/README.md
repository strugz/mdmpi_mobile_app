# Collection Module

## Overview

The Collection module is a department-specific feature for the Collection team within the MDMPI Mobile App. It is currently in **early development** with onboarding and a placeholder home screen. The module follows the same presentation pattern as authentication (presentation layer with controllers and pages) but has an empty domain layer.

## Architecture

### Folder Structure

```
lib/
  features/collection/
    domain/                                 # Empty — reserved for future entities/use cases
    presentation/
      controllers/
        collection_onboarding_controller.dart  # Onboarding state management
      pages/
        home/
          home.dart                         # Collection home screen
          widgets/                          # Home screen widgets
        onboarding/
          onboarding.dart                   # Collection onboarding screen
          widgets/                          # Onboarding widgets
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
| `CollectionHome` | `features/collection/presentation/pages/home/` | Department home screen |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.lazyPut(() => CollectionOnboardingController(), fenix: true);
```

### Department Routing

The Collection module is accessed via `AppRouter` when the user's department is `"Collection"`:

```dart
case 'Collection':
  final collectionComplete = storage.read('CollectionOnboardingComplete') ?? false;
  if (!collectionComplete) {
    return const CollectionOnBoardingScreen();
  }
  break;
```

### Notes

- The `domain/` folder is empty — no entities, repositories, or use cases have been defined yet.
- The module uses the same `NavigationMenu` bottom-tab shell as other departments after onboarding.
- This is one of the four department types alongside Logistics, Service, and InHouse.
- Future development will add collection-specific features, controllers, and data layers.
