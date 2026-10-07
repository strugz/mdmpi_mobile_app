---
paths:
  - "docs/**"
  - "qa/**"
  - "AGENTS.md"
  - "CLAUDE.md"
  - ".github/copilot-instructions.md"
---

# Documentation & QA

- `docs/README.md` is the live module-doc index; update it when adding a module doc under
  `docs/modules/<module>/`.
- Collection rollout / stage plans live in `docs/application/` (`COLLECTION_STAGE_*_PLAN.md`).
- QA checklists are generated, not hand-written:
  `dart run bin/generate_module_qa.dart --name "Name" --area <Area> --routes "/route"`.
- Keep `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` in sync. AGENTS.md is the
  source of truth; the other two carry only their agent-specific deltas.
- Docs describe current behaviour. Remove statements about deleted code instead of marking them stale.
