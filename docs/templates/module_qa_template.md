# {MODULE_NAME} — QA Addendum

Reference: See global QA plan in docs/QA_TEST_PLAN.md for shared scope, environments, devices, and policies. This addendum only contains module-specific details.

1. Module Overview
- Area: {AREA}
- Routes/Entry Points: {ROUTES}
- Feature Flag (if any): {FLAG}
- Owner: {OWNER}

2. Scope
- In-scope for this module only; relies on shared services (auth, permissions, notifications) as per global plan.

3. Risks/Assumptions
- {RISKS}

4. Data/Accounts
- {DATA_DEPENDENCIES}

5. Test Scenarios (Module-specific)
- See docs/modules/{MODULE_SLUG}/test_cases_{MODULE_SLUG}.csv for seeded cases.
- When ready, optionally merge into master: docs/test_cases_index.csv

6. Entry/Exit Criteria
- Entry: Feature implemented behind flag (if applicable); test data seeded.
- Exit: P0/P1 module cases green; no blockers; no regressions per smoke.

Notes
- Avoid touching completed modules. If integration is required, wrap with FeatureGuard(flag: '{FLAG}').

