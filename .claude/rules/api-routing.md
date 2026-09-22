---
paths:
  - "lib/base/utils/http/**"
  - "lib/base/utils/constants/api_environment.dart"
  - "lib/base/utils/helpers/api_response_keys.dart"
  - "lib/data/repositories/**"
---

# API routing boundary (do not break)

| Prefix            | Backend                                                  | Notes                                                        |
|-------------------|----------------------------------------------------------|--------------------------------------------------------------|
| `/api4/*`         | sibling `MDMPI.App` ASP.NET backend (production-testing) | debug-only overrides `API4_URL_WINDOWS` / `API4_URL_ANDROID` |
| `/api2/*` + rest  | live production backend (`API_URL`)                      | never redirect these to `MDMPI.App`                          |
| `/api3/*`         | **retired**                                              | do not add calls; it served incomplete records and 502'd     |

- Every new endpoint call must state which prefix it uses and why.
- Debug overrides are `kDebugMode`-only. Never let a local override leak into release paths.
- Use `BHttpHelper` / `lib/base/utils/http/http_client.dart`; do not create ad-hoc `Dio` or `http` clients.
- Response key names live in `api_response_keys.dart`; do not scatter string literals.
- A dead or unreachable server must surface as a user-visible message via a `Result` failure, not a hang.
- Read README "API Environments" before changing anything here.
