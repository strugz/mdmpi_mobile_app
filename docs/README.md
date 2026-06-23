# MDMPI Mobile App — Documentation

## Overview

This folder contains application-level and module-level documentation for the MDMPI Mobile App. Application guides are organized by audience; module READMEs describe purpose, architecture, folder structure, data flow, key components, DI registration, and relevant notes.

## Documentation Structure

```
docs/
  README.md                          # This file — documentation index
  application/
    README.md                        # Application documentation landing page
    USER_GUIDE.md                    # Daily app usage guide
    LOGISTICS_ROLE_USER_MANUAL.md    # Logistics user manual by role
    ADMIN_GUIDE.md                   # Operations admin support guide
    DEVELOPER_GUIDE.md               # Developer setup and architecture guide
  modules/
    air-sea/README.md                # Air & Sea logistics module
    air-sea/AIR_SEA_PROVINCIAL_DELIVERY_PLAN.md  # Provincial delivery extension plan
    standard-delivery/README.md      # Standard Delivery logistics module
    standard-delivery/STANDARD_DELIVERY_SIGNATURE_API_STATUS_PLAN.md # Standard Delivery signature sync plan
    standard-delivery/STANDARD_DELIVERY_LOCAL_DB_REWORK_PLAN.md # Standard Delivery local DB rework plan
    pick-up/README.md                # Pick Up logistics module
    pull-out/README.md               # Pull Out / Return logistics module
    hotline-direct/README.md         # Hotline Direct logistics module
    stock-receive/README.md          # Stock Receive logistics module
    request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md # Cross-module request form scanner rollout plan
    backload/BACKLOAD_MODULE_DOCUMENTATION.md # BackLoad logistics module
    authentication/README.md         # Authentication module (Clean Architecture)
    collection/README.md             # Collection department module
    personalization/README.md        # User profile, settings, address module
```

## Logistics Application Documentation

| Audience | Link |
|---|---|
| Logistics documentation landing page | [application/](application/) |
| Logistics Users | [application/USER_GUIDE.md](application/USER_GUIDE.md) |
| Logistics Users by Role | [application/LOGISTICS_ROLE_USER_MANUAL.md](application/LOGISTICS_ROLE_USER_MANUAL.md) |
| Logistics Operations Admins | [application/ADMIN_GUIDE.md](application/ADMIN_GUIDE.md) |
| Logistics Developers | [application/DEVELOPER_GUIDE.md](application/DEVELOPER_GUIDE.md) |

## Module Documentation

| Module | Domain | Status | Link |
|---|---|---|---|
| Air & Sea | Logistics | Active | [modules/air-sea/](modules/air-sea/) |
| Standard Delivery | Logistics | Active | [modules/standard-delivery/](modules/standard-delivery/) |
| Standard Delivery Signature API Status Plan | Logistics | Planned | [modules/standard-delivery/STANDARD_DELIVERY_SIGNATURE_API_STATUS_PLAN.md](modules/standard-delivery/STANDARD_DELIVERY_SIGNATURE_API_STATUS_PLAN.md) |
| Standard Delivery Local DB Rework Plan | Logistics | Planned | [modules/standard-delivery/STANDARD_DELIVERY_LOCAL_DB_REWORK_PLAN.md](modules/standard-delivery/STANDARD_DELIVERY_LOCAL_DB_REWORK_PLAN.md) |
| Pick Up | Logistics | Active | [modules/pick-up/](modules/pick-up/) |
| Pull Out | Logistics | Active | [modules/pull-out/](modules/pull-out/) |
| Hotline Direct | Logistics | Active | [modules/hotline-direct/](modules/hotline-direct/) |
| Stock Receive | Logistics | Active | [modules/stock-receive/](modules/stock-receive/) |
| Request Forms Scanner Rollout Plan | Logistics / Cross-module | Active | [modules/request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](modules/request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md) |
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
