# MDMPI Mobile App — Documentation

## Overview

This folder contains application-level and module-level documentation for the MDMPI Mobile App. Application guides are organized by audience; module READMEs describe purpose, architecture, folder structure, data flow, key components, DI registration, and relevant notes.

## Documentation Structure

```
docs/
  README.md                          # This file — documentation index
  POST_DEMO_REVISIONS_TODO.md        # Post-demo revisions log (2026-09) — all 12 items delivered
  CODEX_TO_CLAUDE_TRANSITION.md      # One-time Codex -> Claude Code migration notes (2026-08)
  WEBSOCKET_DISCONNECT_HANDLING.md   # WebSocket disconnect/reconnect contract
  application/
    README.md                        # Application documentation landing page
    USER_GUIDE.md                    # Daily app usage guide
    LOGISTICS_ROLE_USER_MANUAL.md    # Logistics user manual by role
    ANDROID_LOGISTICS_WORKFLOW_PRESENTATION.md # Android workflow presentation and training
    ADMIN_GUIDE.md                   # Operations admin support guide
    DEVELOPER_GUIDE.md               # Developer setup and architecture guide
    LOGISTICS_PROCESS_FLOW_AND_NARRATIVE.docx # ISO / QMS Logistics process flow and user narrative (Word)
    COLLECTION_PROCESS_FLOW_AND_NARRATIVE.docx # ISO / QMS Collection process flow and user narrative (Word)
  modules/
    air-sea/README.md                # Air / Sea / Land logistics module (base + HD tabs)
    air-sea/HISTORY_MODEL_PLAN.md    # Superseded history-model plan (see banner in file)
    standard-delivery/README.md      # Standard Delivery logistics module
    pick-up/README.md                # Pick Up logistics module
    pull-out/README.md               # Pull Out / Return logistics module
    hotline-direct/README.md         # Hotline Direct logistics module
    stock-receive/README.md          # Stock Receive logistics module
    request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md # Cross-module request form scanner rollout plan
    inventory_item/INVENTORY_ITEM_MODULE_DOCUMENTATION.md # Inventory item controller and view widget
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
| Android Workflow Training | [application/ANDROID_LOGISTICS_WORKFLOW_PRESENTATION.md](application/ANDROID_LOGISTICS_WORKFLOW_PRESENTATION.md) |
| Logistics Operations Admins | [application/ADMIN_GUIDE.md](application/ADMIN_GUIDE.md) |
| Logistics Developers | [application/DEVELOPER_GUIDE.md](application/DEVELOPER_GUIDE.md) |
| ISO / QMS Documentation (Logistics) | [application/LOGISTICS_PROCESS_FLOW_AND_NARRATIVE.docx](application/LOGISTICS_PROCESS_FLOW_AND_NARRATIVE.docx) |
| ISO / QMS Documentation (Collection) | [application/COLLECTION_PROCESS_FLOW_AND_NARRATIVE.docx](application/COLLECTION_PROCESS_FLOW_AND_NARRATIVE.docx) |

## Module Documentation

| Module | Domain | Status | Link |
|---|---|---|---|
| Post-Demo Revisions TO DO | Logistics / Cross-module | Complete (12/12) | [POST_DEMO_REVISIONS_TODO.md](POST_DEMO_REVISIONS_TODO.md) |
| Codex to Claude Code transition | Tooling | Historical (2026-08) | [CODEX_TO_CLAUDE_TRANSITION.md](CODEX_TO_CLAUDE_TRANSITION.md) |
| WebSocket disconnect handling | Cross-cutting | Active | [WEBSOCKET_DISCONNECT_HANDLING.md](WEBSOCKET_DISCONNECT_HANDLING.md) |
| Air / Sea / Land | Logistics | Active | [modules/air-sea/](modules/air-sea/) |
| Air / Sea / Land History Model Plan | Logistics | Superseded | [modules/air-sea/HISTORY_MODEL_PLAN.md](modules/air-sea/HISTORY_MODEL_PLAN.md) |
| Standard Delivery | Logistics | Active | [modules/standard-delivery/](modules/standard-delivery/) |
| Pick Up | Logistics | Active | [modules/pick-up/](modules/pick-up/) |
| Pull Out | Logistics | Active | [modules/pull-out/](modules/pull-out/) |
| Hotline Direct | Logistics | Active | [modules/hotline-direct/](modules/hotline-direct/) |
| Stock Receive | Logistics | Active | [modules/stock-receive/](modules/stock-receive/) |
| Request Forms Scanner Rollout Plan | Logistics / Cross-module | Active | [modules/request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md](modules/request-forms/INVENTORY_SCANNER_ROLLOUT_PLAN.md) |
| Inventory Item | Logistics / Cross-module | Active | [modules/inventory_item/](modules/inventory_item/) |
| BackLoad | Logistics | Active | [modules/backload/](modules/backload/) |
| Authentication | Cross-cutting | Active | [modules/authentication/](modules/authentication/) |
| Collection | Collection | Active | [modules/collection/](modules/collection/) |
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
