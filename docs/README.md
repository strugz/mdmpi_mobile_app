# MDMPI Mobile App — Documentation

## Overview

This folder contains module-level documentation for the MDMPI Mobile App. Each module README describes the module's purpose, architecture, folder structure, data flow, key components, DI registration, and relevant notes.

## Documentation Structure

```
docs/
  README.md                          # This file — documentation index
  modules/
    air-sea/README.md                # Air & Sea logistics module
    standard-delivery/README.md      # Standard Delivery logistics module
    pick-up/README.md                # Pick Up logistics module
    pull-out/README.md               # Pull Out / Return logistics module
    hotline-direct/README.md         # Hotline Direct logistics module
    stock-receive/README.md          # Stock Receive logistics module
    backload/BACKLOAD_MODULE_DOCUMENTATION.md # BackLoad logistics module
    authentication/README.md         # Authentication module (Clean Architecture)
    collection/README.md             # Collection department module
    personalization/README.md        # User profile, settings, address module
```

## Module Documentation

| Module | Domain | Status | Link |
|---|---|---|---|
| Air & Sea | Logistics | Active | [modules/air-sea/](modules/air-sea/) |
| Standard Delivery | Logistics | Active | [modules/standard-delivery/](modules/standard-delivery/) |
| Pick Up | Logistics | Active | [modules/pick-up/](modules/pick-up/) |
| Pull Out | Logistics | Active | [modules/pull-out/](modules/pull-out/) |
| Hotline Direct | Logistics | Active | [modules/hotline-direct/](modules/hotline-direct/) |
| Stock Receive | Logistics | Active | [modules/stock-receive/](modules/stock-receive/) |
| BackLoad | Logistics | Planned | [modules/backload/](modules/backload/) |
| Authentication | Cross-cutting | Active | [modules/authentication/](modules/authentication/) |
| Collection | Collection | Early Dev | [modules/collection/](modules/collection/) |
| Personalization | Cross-cutting | Active | [modules/personalization/](modules/personalization/) |

## Module Relationships

### Logistics Sub-Module Sharing

- **Standard Delivery ↔ Hotline Direct**: Hotline Direct reuses `StandardDeliveryModel`, `StandardDeliveryRepository`, and `StandardDeliveryFormState`. It is filtered by the `FormCategoryType.hotlineDirect` category.
- **Pull Out ↔ Stock Receive**: Stock Receive reuses `PullOutModel`, `PullOutRepository`, and `PullOutFormState`. It is filtered by the `FormCategoryType.stockReceive` category.

### Cross-Cutting Dependencies

- **UserController** (Personalization) is consumed by all logistics controllers for `createdBy` fields.
- **AuthenticationRepository** handles app-level auth state and redirects to `AppRouter`.
- **AppRouter** routes users to department-specific onboarding (Logistics, Collection, Service, InHouse).

## Conventions

- Documentation files use **SCREAMING_SNAKE_CASE** when creating detailed module docs (e.g., `AIR_SEA_MODULE_DOCUMENTATION.md`).
- Module READMEs (this level) use standard `README.md` naming.
- QA checklists are kept in the `qa/` folder at project root, not in `docs/`.
