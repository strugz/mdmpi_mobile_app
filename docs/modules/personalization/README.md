# Personalization Module

## Overview

The Personalization module manages user profile, settings, and address features within the MDMPI Mobile App. It provides screens for viewing/editing user profiles, updating display names, managing addresses, and adjusting app settings.

## Architecture

### Folder Structure

```
lib/
  features/personalization/
    controller/                             # NOTE: singular "controller" (known inconsistency)
      user_controller.dart                  # User state management (permanent singleton)
      update_name_controller.dart           # Name update form controller
    models/
      user_model.dart                       # User domain model
    screens/
      profile/
        profile.dart                        # Profile screen
        widgets/                            # Profile UI widgets
      settings/
        settings.dart                       # Settings screen
      address/
        address.dart                        # Address list screen
        add_new_address.dart                # Add address screen
        widget/                             # Address UI widgets
```

### Data Flow

```
UI (ProfileScreen / SettingsScreen)
  → UserController
    → UserRepository (Firebase/API user data)
    → UserMDMPIRepository (MDMPI-specific user data)

UI (Profile Edit)
  → UpdateNameController
    → UserRepository
```

### Key Components

| Component | Location | Purpose |
|---|---|---|
| `UserController` | `features/personalization/controller/` | Central user state (permanent singleton) |
| `UpdateNameController` | `features/personalization/controller/` | Name update form state |
| `UserModel` | `features/personalization/models/` | User domain model |
| `ProfileScreen` | `features/personalization/screens/profile/` | User profile view/edit |
| `SettingsScreen` | `features/personalization/screens/settings/` | App settings |
| `AddNewAddressScreen` | `features/personalization/screens/address/` | Address management |

### DI Registration

Registered in `GeneralBindings`:

```dart
Get.put(UserController(), permanent: true);  // Permanent singleton — always available
Get.lazyPut(() => UpdateNameController(), fenix: true);
```

### Routes

| Route | Page |
|---|---|
| `BRoutes.settings` | `SettingsScreen` |
| `BRoutes.userProfile` | `ProfileScreen` |
| `BRoutes.userAddress` | `AddNewAddressScreen` |

### Data Layer Dependencies

- `UserRepository` (`data/repositories/user/`) — Firebase/API user profile operations
- `UserMDMPIRepository` (`data/repositories/user/`) — MDMPI-specific user data
- `UserInitialController` (`data/controllers/app_data/`) — User initial data
- `UserMdmpiController` (`data/controllers/app_data/`) — MDMPI user data controller

### Notes

- **Folder naming inconsistency (known):** Uses singular `controller/` folder instead of plural `controllers/`. This is a known legacy pattern — do not rename unless explicitly asked.
- `UserController` is registered with `Get.put(permanent: true)` as a true singleton because it holds user state needed across the entire app lifecycle.
- The `UserController` is consumed by many other modules (logistics controllers reference it for `createdBy` fields).
