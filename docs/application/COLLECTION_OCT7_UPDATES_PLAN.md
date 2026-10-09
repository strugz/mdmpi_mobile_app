# Collection: To-Update List (meeting of 2026-10-07)

Source: "To-Update List: Collections System (Meeting of Oct 7, 2026)". Six items; this records
what the mobile app does for each, and what the backend (MDMPI.App `/api4`) still needs.
Android is the target (Windows is not pursued for these features).

| # | Item | Where | Status |
|---|---|---|---|
| 1 | Add to Cart for large invoice volumes | App | Done (below) |
| 2 | PO/SI switch; SI search by photo of a voucher | App | Done (below) |
| 3 | Reconciliation: SOA → Follow up → Collection Letter | App + backend | App done; backend spec in [COLLECTION_RECONCILIATION_TRACKER_PLAN.md](COLLECTION_RECONCILIATION_TRACKER_PLAN.md), Revision 2 |
| 4 | Reports: month-end Activity, collectors Summary, Reconciliation detail | App (+ backend gaps) | App done; backend gaps below |
| 5 | Absolute AR on re-upload | Admin web + backend | Not in this repo. The phone already replaces its invoice cache on every download, so an invoice the server stops sending disappears; the collector's own archive and reconciliation cases stay. |
| 6 | Sales view by territory code | — | Future, not in this round |

## 1–2. Cart, voucher scan, PO/SI switch

Decisions (2026-10-09): the cart is per account, on a **claimed** account's invoice list
(Activity), and checks out through the existing batch record (one invoice: its own record). It is
the existing activity selection, not a separate store: session-only, emptied when the account's
screen closes or the batch is saved.

- **PO / SI switch** (bucket and Activity account lists; remembered in GetStorage
  `collection.invoiceViewMode`, default PO). PO: invoices grouped by P.O., each group opens to its
  SIs. SI: a flat SI list, no P.O. on the cards; search then matches the SI and document
  references only (`invoiceMatchesSearch`, one rule for both lists). Shown only when an invoice of
  the account has a P.O.
- **Cart.** Long-press an invoice to start it; taps add and remove; search and the filter stay
  usable while carting. The bar shows "N in cart · ₱total" and **Review cart**: the invoices with
  amounts (remove any), then **Record N invoices**. Select All covers the invoices on screen only.
- **Scan SI** (decided 2026-10-09): the purpose is to select invoices in the account's list
  without hunting for them. **Scan** on a claimed account's list asks for a photo (Android),
  a gallery image or a file (image or PDF) of the client's **voucher** (check / payment voucher,
  remittance list) or of a **Sales Invoice** itself. Gemini reads it with the voucher prompt
  (`VoucherInvoiceRepository.defaultVoucherPrompt`, overridable with `AI_VOUCHER_PROMPT`): only
  numbers labelled SI / S.I. / Invoice / Inv. / Sales Invoice (also inside Particulars or
  Reference text, or a Sales Invoice's own number), never P.O., check, CV/voucher, OR/AR, DR,
  TIN, account, date or amount numbers; JSON keys `"Invoice No."`, `"Label"`, `"Amount"`.
  The matching open invoices are **ticked right in the list** (cart mode, scrolled to the first),
  and a banner says "N selected from scan · M not found: …". **Details** opens *Scanned
  Invoices* (laid out like the Logistics *Scanned Items*): every number read, ✅ / ⚠ / ✖ against
  the account, the printed amount for checking only (never fills payment fields), correct or
  remove a number, Capture / Attach more pages, then **Select N invoices** back in the list.
  Without a connection, or when Gemini fails, a photo is read on the phone (ML Kit): only the
  account's invoices (and plain numbers of the same length) are listed, flagged "read offline";
  a PDF needs a connection. Leaving the account with voucher invoices in the cart asks first;
  the scan list is cleared with the cart.
- **Two camera options** (2026-10-09). The Scan sheet offers **Scan with camera** (pages read on
  the phone, works without internet) and **Scan with AI** (pages read by Gemini, most accurate,
  needs internet; falls back to the phone's reading if the AI cannot be reached). Gallery and
  file picks are read by the AI with the same fallback. The cart's review button and screen are
  named **Review Invoice**.
- **Document scanner** (2026-10-09). Both camera options open Google's ML Kit document scanner
  (`google_mlkit_document_scanner`, Android, runs on the phone): it finds the paper's edges,
  crops, straightens and cleans each page, up to 5 pages per scan; every page is read and the
  invoices on all of them are selected with one banner. Cancelling it scans nothing. Where it
  cannot start (no Google Play services, or its module not downloaded yet and no connection)
  the plain camera is used instead. The scanner asks for no camera permission of its own.
- **Selected on top** (2026-10-09). Every selected invoice (scanned or ticked by hand) sits in a
  collapsible **Selected (N) · ₱total** group at the top of the account's list, open by default
  and opened again after each scan (the list scrolls to it); unticking one puts it back among the
  rest, which keep their P.O. grouping or flat SI list below. P.O. groups are no longer forced
  open while selecting, since no tick can hide in them.
- **Online re-read** (2026-10-09). Every page read on the phone (no connection, the AI failed,
  or Scan with camera) is copied into the app's `voucher_rereads/` folder and queued in
  `a_tblCollectionVoucherReread` with the invoices the phone found. `VoucherRereadService`
  (registered at start, like the photo outbox) re-reads queued pages with the AI on app start,
  when the connection returns, when the app is resumed, and right after a page is queued; a page
  waits while offline, while the account's invoices are not loaded yet, or after an AI error (up
  to 10 tries). Open invoices the AI finds that the phone missed raise a local notification
  ("Voucher re-read online: 1 more invoice found for …") and a banner on the account's list,
  "Online re-read found N more invoices: …", whose **Select** ticks them (marked from voucher).
  The page copy is deleted once read; rows and pages older than a week are dropped.
- **Offline reading** (2026-10-09). Without the AI the phone's ML Kit text is read **by layout**
  (`VoucherLayoutReader`, lines with positions from `ITextRecognitionService.processImageLines`):
  a number counts as an invoice when it follows an SI / Invoice / Sales Invoice label on its line
  (the label reaches over the numbers and "/ , and" after it, and stops at any other word, an
  amount or a date) or sits in the column under an "SI No." / "Invoice No." header (not "Invoice
  Date" or "Amount"); a number after P.O., check, CV, OR/AR/DR (capitals or dotted), TIN or
  account never counts. Labelled numbers are matched like the AI's, plus **near matches**: one
  character off a single open invoice of the same length (after O/0, I/1, S/5, B/8 fixes, five
  characters at least) is selected as **"Close match, check the number"**; one off two invoices is
  not guessed. Unlabelled numbers count only when they are an open invoice exactly.
- **Shared Gemini call.** `lib/data/services/gemini_document_service.dart` holds the request,
  the key header and the JSON-array extraction; the Logistics `InventoryItemRepository` and
  the voucher scan both use it. `ScannerActionRow` (Capture / Attach File) now takes plain
  callbacks, so both scanners share it. Voucher photos go to Google Gemini, as Logistics
  receipts already do.

Code: `helpers/invoice_search.dart`, `helpers/voucher_si_matcher.dart` (matcher and
`ScannedInvoiceClassifier`), `models/scanned_invoice.dart`, the cart section of
`CollectionActivityController`, `VoucherScanController`,
`lib/data/repositories/collection/voucher_invoice_repository.dart`,
`presentation/widgets/invoice_view_toggle.dart`, `pages/activity/invoice_cart_screen.dart`,
`pages/activity/scanned_invoices_screen.dart`, `pages/activity/widgets/voucher_file_picker.dart`.
Tests: `test/features/collection/voucher_si_matcher_test.dart`, `invoice_cart_test.dart`,
`scanned_invoices_test.dart`, `test/data/services/gemini_document_service_test.dart`.

Open: check the prompt and photo quality (90 %, 2400 px) on real client vouchers.

## 4. Reports (Settings → Reports)

Decisions (2026-10-09): CSV only; the user picks **Save CSV** (Android's "Save as" dialog through
`file_picker`, no storage permission) or **Share CSV** (`share_plus`). The CSV has a UTF-8 BOM
(Excel reads names and ₱), CRLF line ends, and formula-looking text cells prefixed with `'`.

- **Activity report** (`/collection/reports/activity`): the signed-in collector's month from their
  own archive (`CollectionRepository.loadOwnEngagements`, the permanent `a_tblCollectionEngagement`
  rows, including work not yet uploaded), plus the reconciliation steps they logged themselves
  (the app's own Payment/Released/Acquired steps are left out). Totals: collected (only
  `CollectionOutcome.countsAsCollected`), engagements, visits (distinct day + client), settled
  invoices (`CollectionOutcome.settlesInvoice`), recon steps.
- **Collectors summary** (`/collection/reports/collectors`): a collector sees their own row; the
  Head also gets every teammate from `/api4/Collection/team/engagements` for the month. Recon
  counts (open, flagged, closed, steps logged) come from the cases on the phone. A feed failure
  keeps the own row and says so.
- **Reconciliation detail** (`/collection/reports/reconciliation`, also from Reconciliation
  reports' app bar): one row per invoice of each case, My cases / Team and Open / Closed / All,
  with status, stage (SOA, follow-up count and last date, letter count and last date), flags and
  amounts. Case-level amounts are on the case's first row only, so a spreadsheet sum does not
  double-count.

Code: `lib/data/models/report_table.dart` (the rows the screen and the CSV share),
`lib/base/utils/helpers/csv_writer.dart` (`BCsv`, `BReportFileName`),
`lib/data/services/report_export_service.dart`, builders in
`lib/features/collection/helpers/reports/`, `CollectionReportsController`, screens in
`presentation/pages/reports/`. Tests: `test/base/utils/csv_writer_test.dart`,
`test/features/collection/reports/`.

### Backend gaps (team feed, not edited)

Teammates' rows are approximate until the feed carries more. In order of value:

1. **`GET /api4/Collection/team/summary?month=yyyy-MM`**: per collector: collected, engagements,
   visits, settled invoices, recon open/closed/flagged/steps. Replaces items 2–5 for this report
   and avoids downloading a month of rows just to count them.
2. A per-row **settled** flag (or balance after) on `team/engagements`: today a teammate's
   settled count is "status Collected", which misses invoices paid off in instalments.
3. **`EngagedAt`** (ISO with offset) next to `Date`, so times show and day grouping matches.
4. The archive **kind** (INVOICE / ACCOUNT / OFFICE / ADVANCE) so visits are exact.
5. A server-side **counts-as-collected** boolean (or one status vocabulary: the feed says
   "Partial Payment", the phone "Partially Collected").
6. Reconciliation steps per collector, or the summary in (1): closed cases of other collectors
   may not all be on the phone.
