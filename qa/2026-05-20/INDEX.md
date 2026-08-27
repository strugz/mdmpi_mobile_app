# QA Document Index – 2026-05-20

## Overview

This folder contains the QA documents created on **2026-05-20** for the MDMPI Mobile App. The documents are organized for manual execution, release sign-off, and future automation mapping.

## Folder

- `qa/2026-05-20/`

## Contents Summary

| Category | File | Purpose |
|---|---|---|
| Template | [`feature_module_qa_template.md`](feature_module_qa_template.md) | Reusable QA document template for any future module or feature |
| Master Document | [`feature_specific_qa_test_document.md`](feature_specific_qa_test_document.md) | Combined QA document covering multiple real app modules |
| Release Tracker | [`RELEASE_EXECUTION_SUMMARY.md`](RELEASE_EXECUTION_SUMMARY.md) | Release-wide execution tracker for all standalone QA documents in this dated batch |
| Authentication | [`login_qa_test_document.md`](login_qa_test_document.md) | Standalone QA test document for Login |
| Home / Dashboard | [`home_qa_test_document.md`](home_qa_test_document.md) | Standalone QA test document for the Home landing screen and dashboard |
| Navigation | [`navigation_menu_qa_test_document.md`](navigation_menu_qa_test_document.md) | Standalone QA test document for the bottom navigation shell |
| Request Hub | [`request_screen_qa_test_document.md`](request_screen_qa_test_document.md) | Standalone QA test document for the Request screen, categories, filters, and FAB behavior |
| Settings | [`settings_qa_test_document.md`](settings_qa_test_document.md) | Standalone QA test document for Settings and related utility flows |
| Settings Utility | [`realtime_location_saver_qa_test_document.md`](realtime_location_saver_qa_test_document.md) | Standalone QA test document for the Realtime Location Saver setting |
| Logistics | [`standard_delivery_request_qa_test_document.md`](standard_delivery_request_qa_test_document.md) | Standalone QA test document for Standard Delivery Request |
| Logistics | [`standard_delivery_list_qa_test_document.md`](standard_delivery_list_qa_test_document.md) | Standalone QA test document for Standard Delivery List |
| Logistics | [`hotline_direct_request_qa_test_document.md`](hotline_direct_request_qa_test_document.md) | Standalone QA test document for Hotline Direct Request |
| Logistics | [`pull_out_request_qa_test_document.md`](pull_out_request_qa_test_document.md) | Standalone QA test document for Pull Out Request |
| Logistics | [`air_sea_request_qa_test_document.md`](air_sea_request_qa_test_document.md) | Standalone QA test document for Air/Sea Request |
| Logistics | [`air_sea_list_qa_test_document.md`](air_sea_list_qa_test_document.md) | Standalone QA test document for Air/Sea List |
| Logistics | [`pick_up_request_qa_test_document.md`](pick_up_request_qa_test_document.md) | Standalone QA test document for Pick Up Request |
| Logistics | [`stock_receive_qa_test_document.md`](stock_receive_qa_test_document.md) | Standalone QA test document for Stock Receive |
| Personalization / Local Data | [`contact_directory_qa_test_document.md`](contact_directory_qa_test_document.md) | Standalone QA test document for Contact Directory |
| Test Run Sheet | [`contact_directory_test_run_sheet.md`](contact_directory_test_run_sheet.md) | Execution summary and test run tracker for the Contact Directory module |
| Developer Tool | [`local_storage_viewer_qa_test_document.md`](local_storage_viewer_qa_test_document.md) | Standalone QA test document for the Local Storage Viewer debug tool |
| Developer Tool | [`signature_outbox_qa_test_document.md`](signature_outbox_qa_test_document.md) | Standalone QA test document for the Signature Outbox debug tool |

## Suggested Execution Order

| Order | Module | File |
|---:|---|---|
| 1 | Login | [`login_qa_test_document.md`](login_qa_test_document.md) |
| 2 | Home | [`home_qa_test_document.md`](home_qa_test_document.md) |
| 3 | Navigation Menu | [`navigation_menu_qa_test_document.md`](navigation_menu_qa_test_document.md) |
| 4 | Request Screen | [`request_screen_qa_test_document.md`](request_screen_qa_test_document.md) |
| 5 | Settings | [`settings_qa_test_document.md`](settings_qa_test_document.md) |
| 6 | Realtime Location Saver | [`realtime_location_saver_qa_test_document.md`](realtime_location_saver_qa_test_document.md) |
| 7 | Standard Delivery Request | [`standard_delivery_request_qa_test_document.md`](standard_delivery_request_qa_test_document.md) |
| 8 | Standard Delivery List | [`standard_delivery_list_qa_test_document.md`](standard_delivery_list_qa_test_document.md) |
| 9 | Hotline Direct Request | [`hotline_direct_request_qa_test_document.md`](hotline_direct_request_qa_test_document.md) |
| 10 | Pull Out Request | [`pull_out_request_qa_test_document.md`](pull_out_request_qa_test_document.md) |
| 11 | Air/Sea Request | [`air_sea_request_qa_test_document.md`](air_sea_request_qa_test_document.md) |
| 12 | Air/Sea List | [`air_sea_list_qa_test_document.md`](air_sea_list_qa_test_document.md) |
| 13 | Pick Up Request | [`pick_up_request_qa_test_document.md`](pick_up_request_qa_test_document.md) |
| 14 | Stock Receive | [`stock_receive_qa_test_document.md`](stock_receive_qa_test_document.md) |
| 15 | Contact Directory | [`contact_directory_qa_test_document.md`](contact_directory_qa_test_document.md) |
| 16 | Contact Directory Test Run Sheet | [`contact_directory_test_run_sheet.md`](contact_directory_test_run_sheet.md) |
| 17 | Local Storage Viewer | [`local_storage_viewer_qa_test_document.md`](local_storage_viewer_qa_test_document.md) |
| 18 | Signature Outbox | [`signature_outbox_qa_test_document.md`](signature_outbox_qa_test_document.md) |

## Coverage Notes

- All standalone QA documents use markdown tables and automation-ready test case IDs.
- `RELEASE_EXECUTION_SUMMARY.md` is the release-level tracker for execution status, pass/fail counts, blockers, defects, and final QA sign-off across the dated QA batch.
- The set includes positive testing, negative testing, UI testing, validation testing, navigation testing, performance testing, and error-handling coverage where applicable.
- `stock_receive_qa_test_document.md` reflects the **current placeholder implementation** of the Stock Receive form.
- `contact_directory_qa_test_document.md` is based on the current local-data and CRUD behavior exposed by the app.
- `local_storage_viewer_qa_test_document.md` covers the current developer-facing SQLite inspection and cleanup workflow, including table switching, row deletion, and clear-table actions.
- `contact_directory_test_run_sheet.md` is intended for execution tracking and defect logging, not for defining new test cases.
- `signature_outbox_qa_test_document.md` and `local_storage_viewer_qa_test_document.md` cover developer-facing tools that should remain hidden from production users.

## Maintenance Notes

- Add newly generated QA files for this date to this index to keep the folder discoverable.
- If additional modules are created later for the same date batch, append them under the same table structure.
- Keep execution results inside the individual QA documents unless a separate release summary is requested.

