# MDMPI Mobile App Logistics Documentation

This folder contains practical Logistics Department documentation for the MDMPI Mobile App. It sits above the module documentation in `docs/modules/` and is organized by audience.

## Audience Guides

| Audience | Guide | Use this when |
|---|---|---|
| Logistics Users | [User Guide](USER_GUIDE.md) | You create, view, update, deliver, or monitor Logistics requests. |
| Logistics Users by Role | [Role-Based User Manual](LOGISTICS_ROLE_USER_MANUAL.md) | You need to know what each Logistics role can do. |
| Android Workflow Training | [Workflow Presentation](ANDROID_LOGISTICS_WORKFLOW_PRESENTATION.md) | You need presentation-ready process diagrams, role matrices, and exercises. |
| Logistics Operations Admins | [Admin Guide](ADMIN_GUIDE.md) | You support Logistics users, local sync, request data refresh, outboxes, and troubleshooting. |
| Logistics Developers | [Developer Guide](DEVELOPER_GUIDE.md) | You maintain or extend Logistics request modules, data flows, and support tooling. |

## Logistics Scope

The app supports Android and Windows targets. Logistics documentation should assume both targets unless a workflow is explicitly platform-specific.

This documentation focuses on:

- Logistics authentication and onboarding context.
- Logistics navigation: Home, Request, Location, and Settings.
- Request categories: Standard Delivery, Pull Out / Return, Pick Up, Air / Sea / Land, Air / Sea / Land HD, Hotline Direct, Stock Receive, and BackLoad.
- Role-based user workflows for Request, Release, Courier, Provincial, HD, Viewer, and Admin users.
- Request list usage, filtering, creation, status updates, cancellation, proof capture, and delivery location workflows.
- Logistics support tools: Upload Data, Hard Reset Refresh, Realtime Location Saver, Contact Directory, Local Storage Viewer, Signature Outbox, and Image Outbox.
- Developer architecture for Logistics controllers, repositories, DAOs, mappers, routes, and bindings.

## Out of Scope for This Guide

Collection, Service, and InHouse are mentioned only where they affect shared routing or app startup. Their user workflows are not documented here.

## Related Logistics Documentation

- [Module Documentation Index](../README.md)
- [Standard Delivery Module](../modules/standard-delivery/README.md)
- [Air / Sea / Land Module](../modules/air-sea/README.md)
- [Pick Up Module](../modules/pick-up/README.md)
- [Pull Out / Return Module](../modules/pull-out/README.md)
- [Hotline Direct Module](../modules/hotline-direct/README.md)
- [Stock Receive Module](../modules/stock-receive/README.md)
- [BackLoad Module](../modules/backload/BACKLOAD_MODULE_DOCUMENTATION.md)
- [Role-Based User Manual](LOGISTICS_ROLE_USER_MANUAL.md)
- [Android Logistics Workflow Presentation](ANDROID_LOGISTICS_WORKFLOW_PRESENTATION.md)
- [Local Storage Data Viewer README](../../lib/features/logistics/screens/data_test/README.md)

## Maintenance Notes

- Keep visible labels aligned with Logistics screens and Settings tools.
- Keep admin instructions explicit about developer/debug tools.
- Keep developer guidance aligned with `.github/copilot-instructions.md`, `AGENTS.md`, and Logistics module docs.
- When adding new Logistics docs, link them from this file and from `docs/README.md`.
