---
paths:
  - "lib/features/collection/**"
  - "lib/data/repositories/collection/**"
  - "test/features/collection/**"
---

# Collection department module

- Layout: `models/`, `dtos/`, `mappers/`, `helpers/`, `presentation/{controllers,pages,widgets}`.
  `domain/` is an intentionally empty scaffold; do not add a domain layer without a plan doc.
- Repository: `lib/data/repositories/collection/collection_repository.dart`.
- Active planning docs: `docs/application/COLLECTION_STAGE_E_PLAN.md` and
  `COLLECTION_STAGE_E2_PLAN.md`. Read the current stage plan before changing activity, calendar,
  or engagement flows, and tick items there as they land.
- Activity forms (`presentation/pages/activity/add_activity/*_form.dart`) share
  `activity_type_modal.dart` and `engagement_invoice_picker.dart`; extend those rather than
  duplicating pickers per form.
- Tests for this module live in `test/features/collection/`; add one per new form or widget.
