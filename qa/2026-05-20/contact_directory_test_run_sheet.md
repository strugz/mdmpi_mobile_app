# Contact Directory – Execution Summary / Test Run Sheet

## Overview

This document is intended for **test execution tracking** of the Contact Directory module. It complements:

- [`contact_directory_qa_test_document.md`](contact_directory_qa_test_document.md)

Use this sheet during manual QA execution to record observed results, defect references, execution blockers, and overall sign-off readiness.

## Module Details

| Field | Details |
|---|---|
| Module Name | Contact Directory |
| Reference QA Document | [`contact_directory_qa_test_document.md`](contact_directory_qa_test_document.md) |
| Test Run Date | `[YYYY-MM-DD]` |
| Build / Version | `[Build Number / Commit / APK / IPA]` |
| Environment | `[QA / Staging / UAT]` |
| Platforms Covered | Android, iOS |
| Primary Tester | `[Tester Name]` |
| Secondary Review | `[Reviewer Name]` |
| Execution Status | Planned / In Progress / Completed |

## Execution Summary

| Summary Metric | Count |
|---|---:|
| Total Planned Test Cases | 10 |
| Passed | 0 |
| Failed | 0 |
| Blocked | 0 |
| Not Run | 10 |
| Pass Rate (%) | 0 |

## Test Run Tracker

| Test Case ID | Scenario Summary | Platform | Tester | Execution Date | Actual Result | Status | Severity | Defect ID / Link | Remarks |
|---|---|---|---|---|---|---|---|---|---|
| `CD-001` | Open Contact Directory from Settings | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-002` | Loading state and empty-state behavior | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-003` | Add contact using directory search and auto-fill | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-004` | Required-field validation in add-contact form | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-005` | Search no-results behavior | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-006` | Manual add contact without directory selection | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-007` | Saved contact rendering and persistence | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-008` | Delete confirmation cancel and confirm flow | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-009` | Error handling for local-operation failures | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |
| `CD-010` | Repeated add/delete cycles and UI stability | `[Android/iOS]` | `[Tester Name]` | `[YYYY-MM-DD]` | `TBD during execution` | Not Run | N/A | `[Defect ID if any]` | |

## Defect Summary

| Defect ID | Title | Severity | Priority | Status | Affected Platform | Notes |
|---|---|---|---|---|---|---|
| `[BUG-001]` | `[Short defect title]` | `[Critical/Major/Medium/Low]` | `[High/Medium/Low]` | `[Open/In Progress/Fixed/Closed]` | `[Android/iOS/Both]` | |

## Blockers / Risks

| Type | Description | Impact | Owner | Status |
|---|---|---|---|---|
| Environment | `[Example: local DB reset issue prevents persistence validation]` | `[High/Medium/Low]` | `[Owner]` | `[Open/Resolved]` |
| Test Data | `[Example: no CNTMST directory options available in QA]` | `[High/Medium/Low]` | `[Owner]` | `[Open/Resolved]` |

## Platform Comparison Notes

| Area | Android Observation | iOS Observation | Result |
|---|---|---|---|
| Screen entry | | | |
| Add-contact bottom sheet | | | |
| Keyboard handling | | | |
| Delete confirmation | | | |
| Persistence after reopen | | | |

## Sign-Off Checklist

- [ ] All critical test cases executed
- [ ] All failed cases logged with defect references
- [ ] Android execution completed
- [ ] iOS execution completed
- [ ] No release-blocking defects remain open
- [ ] Module ready for QA sign-off

## Final Sign-Off

| Field | Details |
|---|---|
| QA Recommendation | Go / No-Go / Conditional Go |
| Signed Off By | `[QA Lead / Tester Name]` |
| Sign-Off Date | `[YYYY-MM-DD]` |
| Final Remarks | `[Summary of module quality, risks, and retest needs]` |

