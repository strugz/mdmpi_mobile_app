# Standard Delivery — One-Scan Fill (Client + Document References + Items)

> Status: **Planned** for the week of **2026-10-12 → 2026-10-16**.
> Tracked as item 28 in [POST_DEMO_REVISIONS_TODO.md](../POST_DEMO_REVISIONS_TODO.md).
> Target: **Android only.** Windows is not pursued for new features. Hide the entry point
> off Android and keep `flutter analyze` and `flutter test` passing.

## 1. Goal

Today a requestor fills the Standard Delivery form in three separate passes:

| Part | How it works today |
|---|---|
| Client | Bottom-sheet search (`BFullScreenLoader.showSearchSheet`), typed by hand |
| Document references | `DocumentReferenceScreen` → `SimpleTextScanner` (ML Kit OCR + `DocumentReferenceExtractor`) |
| Items | `ScannedItemsScreen` → `analyzeFileWithAiToolkit` (Gemini) |

The new flow takes **one photo** of the source document (for example a Sales Invoice like the
sample below) and fills all three parts:

1. **Client name + address**: on-device OCR reads the *Customer* block. The text is matched
   against the local client list (`ACCMST_`), and the match must tolerate names that are
   written differently.
2. **Document references**: the same OCR text goes through the extractor already in use
   (`DocumentReferenceExtractor.extractPatterns`), giving `SINo.:`, `DRNo.:`, `PONo.:` and so on.
3. **Items**: the same image goes to the Gemini item analysis that is already deployed
   (`InventoryItemRepository.analyzeFileWithGemini`).

Nothing is saved until the user reviews and taps **Apply**. The form stays fully editable
afterwards.

### Scope rule: additive only (decision 2026-10-09)

The one-scan is **added** to the Standard Delivery request form. **Nothing existing is removed or
changed in behaviour:**

| Existing part | Stays exactly as it is |
|---|---|
| Client Information (`BClientInformation` + search sheet) | Same row, same manual search. One-scan only fills the same `clientInformation` value |
| Document References (`BDocumentReference` → `DocumentReferenceScreen` → `SimpleTextScanner`) | Same button, screen, per-field scanner and add/remove. One-scan only appends to the same `documentReferenceControllers` |
| Add Item (`ScannedItemsScreen`, camera/attach, Gemini, item editing) | Same button and screen. One-scan only merges into the same `scannedInventoryItems` |
| All other fields, validators, submit and `saveRequestFromForm` | Untouched |
| `DocumentReferenceExtractor`, `defaultAnalysisPrompt`, `.env` `AI_PROMPT` | Untouched. One-scan uses its own extra patterns and prompt |

The only change to the form screen is **one new "Scan Document" button** at the top (Android
only). Edits to existing files are limited to **new members** (new methods or optional
parameters with defaults that keep today's behaviour) and DI registrations. Pre-existing bugs
found while planning are listed in §10 as separate follow-ups and are **not** fixed in this change.

### Sample document (Sales Invoice, photographed sideways)

| Field on paper | Value | Feeds |
|---|---|---|
| Customer (prefix) | `NCR-414` | **not** the client code (confirmed 2026-10-09). Stripped from the name and not used for matching |
| Customer (name) | `U.S. Department of Veterans Affairs` | client match |
| Address | `1501 Roxas Boulevard, Pasay City PHILIPPINES` | ranking tie-breaker; **shown on the form only when the client's saved address is blank / none / N/A** (§4.4a) |
| SI No. | `700014535` | `SINo.:700014535` |
| PO No. | `358-C64033-A` | `PONo.:358-C64033-A` |
| Delivery Receipt | `DR 690014535` | `DRNo.:690014535` (**needs a new pattern**, see §4.2) |
| Details row | `SITE SURVEY, INSTALLATION & TESTING OF BECKMAN COULTER CHEMISTRY ANALYZER DXC700AU`, Qty 1, PC | item (Gemini) |
| Header | `MARSMAN DRYSDALE MEDICAL PRODUCTS, INC`, Makati address | **must be ignored**: this is us, the issuer |

---

## 2. Current building blocks (reuse, don't rebuild)

| Concern | Existing code |
|---|---|
| Form screen | `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart` (`StandardDelivery`) |
| Form controller | `lib/features/logistics/controllers/standard_delivery_controller.dart`: `updateRequestClientInformation(client)` (~:420), `addDocumentReferenceField()` (~:401), `pickAndAnalyzeFromCamera` / `pickAndAnalyzeFromFile` / `analyzeFileWithAiToolkit` (~:465–:710), `_mergeScannedItems` |
| Form state | `lib/features/logistics/helpers/standard_delivery_form_state.dart`: `clientInformation`, `documentReferenceControllers`, `scannedInventoryItems` |
| OCR | `ITextRecognitionService` (`processImage`, `processImageLines → List<OcrLine>` with bounding boxes) / `GoogleMlKitTextRecognizer` |
| Doc-ref parser | `ITextExtractor` / `DocumentReferenceExtractor` (`lib/common/services/abstracts/i_text_extractor.dart`) |
| AI items | `InventoryItemRepository.analyzeFileWithGemini` → `GeminiDocumentService.extractJsonArray` (image rotation fixed by `BDocumentImage.prepare`) |
| Item merge | `InventoryItemMerger.merge` (mergeKey = partNo \| itemCode \| serialNo) |
| Client data | `ACCMST_` (`ACCMID`, `ACCMSC` code, `ACCMNM` name, `ACCMAD` address…), `ClientDao.search`, `ClientController.allClient` (whole list already in memory) |
| Fuzzy helpers | **None yet.** `VoucherSiMatcher.canonical` has OCR-confusion swaps (O/0, I/l/1, S/5, B/8) worth reusing |

---

## 3. User flow

```
Standard Delivery form
  └─ [ Scan Document ]  (new button at the top, above Client Information; Android only)
       ├─ Camera  / Gallery          (reuse ScannerActionRow pattern)
       ▼
  Progress sheet (three rows, each ticks independently)
       ✓ Client ........ read "U.S. Department of Veterans Affairs", 5 candidates (confirm next)
       ✓ References .... SI 700014535 · DR 690014535 · PO 358-C64033-A
       ⏳ Items ......... analyzing (Gemini, up to ~2 min)
       ▼
  Review sheet
       Client:   tap to confirm one of the top 5 (best first)  or  [search, pre-filled]
                 (nothing is pre-selected; Apply stays disabled until a client is tapped
                  or the user taps "Skip client")
       Refs:     chips with checkboxes (uncheck to drop one)
       Items:    "1 item found", which opens the existing ScannedItemsScreen to edit
       [ Apply ]   [ Cancel ]
```

- **The client is never auto-selected** (decision 2026-10-09). The scan only *ranks* candidates;
  the user must always tap the client to confirm it, even for a learned alias or an exact name
  match. "Skip client" applies the references and items and leaves the client field as it was.
- **Client and references are quick** (on-device, under 2 s), so they apply as soon as the user
  confirms. **Items arrive later.** When Gemini finishes, they merge into
  `scannedInventoryItems`, and a snackbar says "N items added from scan". The user can keep
  working on the form in the meantime.
- **Scanning again** (multi-page invoices or a second document): references are added and de-duplicated,
  items merge with `InventoryItemMerger`, and the client is only set if it is empty. If the scan finds a *different*
  client than the one already picked, the app asks: "Replace client X with Y?"
- **PDF from file:** ML Kit needs an image, so for a PDF only the Gemini item part runs,
  and the sheet says "Client and references couldn't be read from a PDF". Optional later:
  the Gemini fallback in §4.4.

---

## 4. Design

### 4.1 One image, two pipelines in parallel

```
File (camera/gallery)
  ├─► BDocumentImage.prepare (fix rotation)  ──► ML Kit processImageLines
  │        ├─► ClientHeaderExtractor  ─► ClientMatcher (local DB + aliases)
  │        └─► DocumentReferenceExtractor.extractPatterns
  └─► analyzeFileWithGemini(file, prompt: oneScanItemsPrompt)   (async, slower)
```

**Rotation:** the sample was shot sideways. Run OCR on the prepared image. If it finds no
known label (`Customer`, `SI No`, `PO No`, `Delivery Receipt`), retry at 90° and 270°, and
keep the orientation with the most label hits. This costs at most two extra on-device passes.

### 4.2 Document references (the current extractor, plus one-scan extras)

- Keep the current output format (`SINo.:700014535`) so everything downstream is unchanged.
- **Extra pattern, one-scan only:** `Delivery Receipt\s*:?\s*DR\s*(\d+)` → `DRNo.:`. The sample
  prints `DR 690014535` without a "No.", which the current `\bDR + _noSep` pattern misses. It goes in
  a new `OneScanReferencePatterns` that runs **after** the existing `extractPatterns`, and the
  results are merged and de-duplicated. `DocumentReferenceExtractor` itself is not edited, so the
  existing per-field scanner behaves exactly as today.
- **Check against our own header:** "VAT Reg TIN" and "TIN: 000-000-000" must not match any
  label. Add a unit test for this.
- One-scan adds references through a **new** `appendDocumentReferences(List<String>)` that
  de-duplicates first, then fills empty fields, then adds new ones. `DocumentReferenceScreen`
  keeps its own logic (its duplicate-first-match bug is follow-up F2 in §10).

### 4.3 Client: header extraction

`ClientHeaderExtractor` (pure Dart, uses `OcrLine` boxes):

1. Find the line that matches `^Customer\s*:?`. The name is the text **to the right on the same
   row** (overlapping y-range) or on the **next line(s)**. The next label stops the search:
   `TIN | Tel | Fax | Email | Contact Person | Address`.
2. Strip a leading prefix token `^[A-Z]{2,4}-?\d{2,5}\b` (`NCR-414`). It is **not** the client code
   (`ACCMSC`), so it is kept only as `prefix` for logging and never used to match. The rest → `name`.
3. Find `^Address\s*:?`. Take the text to the right or below until the next label or the
   "Details" table → `address`.
4. **Ignore the issuer:** drop any candidate that matches `MARSMAN|DRYSDALE` or the Makati/Chino Roces
   header address. These come from a constant list in the extractor.
5. Fallback with no "Customer" label (DR / SIS layouts): try `Sold To`, `Deliver To`,
   `Ship To`, `Client`, `Consignee`. Gather the labels from the sample documents (§6, Mon).

Output: `ScannedClientHeader { prefix?, name?, address?, rawLines }`.

### 4.4 Client: matching when names differ (the hard part)

The OCR name often differs from `ACCMNM`. Examples: `U.S. Dept. of Veterans Affairs` vs
`US DEPARTMENT OF VETERANS AFFAIRS`, `St. Luke's Med. Ctr.` vs `ST LUKES MEDICAL CENTER INC`,
or OCR noise like `0` for `O`. The invoice carries **no usable client code** (the `NCR-414`
prefix is not `ACCMSC`), so matching relies on **name and address only**. `ClientMatcher` runs
these steps to **rank** candidates. It never selects a client by itself: every result goes to the
review sheet, where the user must tap to confirm (decision 2026-10-09).

| # | Step | Rule | Result |
|---|---|---|---|
| 1 | **Learned alias** | `normalize(ocrName)` found in new `CLIENT_ALIAS_` table | ranked first, tagged "Used before" (score 1.0) |
| 2 | **Normalized exact** | `normalize(ocrName) == normalize(ACCMNM)` | ranked first, tagged "Exact name" |
| 3 | **Fuzzy score** | blended score over all clients (below) | candidate list or search (below) |

**`normalize()`** (`BNameNormalizer`): upper case, fix OCR digit-for-letter swaps inside word tokens (`0→O`, `1→I`, `5→S`, `8→B`;
names are mostly letters), `&`→`AND`, remove punctuation (`U.S.`→`US`,
`ST.`→`ST`), collapse spaces, expand abbreviations (`DEPT→DEPARTMENT`, `MED→MEDICAL`,
`CTR/CNTR→CENTER`, `HOSP→HOSPITAL`, `UNIV→UNIVERSITY`, `GEN→GENERAL`, `PHILS/PHIL→PHILIPPINES`,
`STO→SANTO`, `STA→SANTA`, `CORP→CORPORATION`, `CO→COMPANY`). Then drop low-value tokens
(`INC, CORPORATION, COMPANY, LTD, THE, OF, AND, PHILIPPINES`), but only for scoring. The full
name is kept for display.

**Fuzzy score** (`BStringSimilarity`, no new package needed; about 80 lines):

```
score = 0.45 * tokenSetRatio(nameA, nameB)      // order-insensitive, handles missing words
      + 0.35 * jaroWinkler(joinedA, joinedB)    // OCR typos, prefix-weighted
      + 0.20 * addressScore                     // city/street token overlap; 0 if no address
```

`tokenSetRatio` compares tokens with per-token tolerance: two tokens count as equal when their
Levenshtein distance is at most 1 for tokens of 5+ characters. This handles `VETERANS`/`VETERAMS`.

**What the review sheet shows** (start value tuned on Friday against real samples). In every case
nothing is pre-selected, and the user must tap a client:

| Condition | Behaviour |
|---|---|
| top ≥ **0.60** (or an alias/exact hit) | Show the **top 5 candidates**, best first, with name, address and a match label (Used before / Exact name / Strong / Possible). Plus "Search instead". |
| otherwise / no name read | Open the normal client search sheet **pre-filled** with the OCR name. |

### 4.4a Client address rule (decision 2026-10-09)

After the user confirms a client:

- **Use the client's saved address** (`ACCMAD` from `ACCMST_`) and **ignore the scanned address**.
- **Exception:** if the saved address is *missing*, use the scanned address instead. Missing means
  it is empty or whitespace, or it is `NONE`, `NA` or `N/A` when trimmed and compared
  case-insensitively. (`ClientModel.empty()` defaults to `'N/A'`, so this also covers that.)
  If the scan read no address either, keep the saved value.
- The fallback applies **to this request only**. It goes on a *copy* of the client
  (`ClientModel` with `address` replaced) that is put into `formState.clientInformation`.
  **`ACCMST_` is never written:** the next hard reset or sync would overwrite it anyway, and
  the master list belongs to the backend.
- On the review sheet, a client using the fallback shows "Address from scanned document" under
  the address, so the user knows where it came from.
- The scanned address still feeds the ranking score (§4.4) whichever address ends up on the form.
- Put the rule in a small pure helper, `BClientAddress.resolve(savedAddress, scannedAddress)`,
  in `lib/base/utils/`. Unit-test it.
- **Check on Thursday:** the request already serializes the whole client (`'Client':
  client.toJson()`, including `ACCMAD`, in `standard_delivery_model.dart` `toJson`). Confirm on
  the device that a request created with a fallback address shows that address after saving and
  re-opening. If the backend re-reads the address from its own client table instead, the
  fallback will only be visible on the form. Raise that before shipping.

**Learning (fixes repeat mismatches):** when the user confirms a client for a scanned name
(any confirmation, including from the pre-filled search), save `normalize(ocrName) → ACCMID` in `CLIENT_ALIAS_`. The next scan of the same
customer is ranked first with a "Used before" tag. It still needs a tap to confirm. If the user later picks someone else for an existing alias,
the alias is updated. Aliases are stored per device for now. Syncing them to the server is a
later option (§8).

**Performance:** `ClientController.allClient` is already in memory. Normalize and tokenize each
client **once**, lazily on the first scan, and cache it. Build an inverted token index so
only clients sharing at least one significant token (or the first 3 letters) are scored. If the
list is larger than ~5k rows, run the matching in `compute()` so the UI stays responsive.

### 4.5 Items: Gemini prompt for invoices

`defaultAnalysisPrompt` knows **Delivery Receipt** and **Stock Issue Slip** layouts only. The
one-scan path passes an explicit `prompt` to `analyzeFileWithGemini`. This bypasses the `.env`
`AI_PROMPT` override, so the existing items screen is unaffected. The prompt extends the
default with:

- A **Sales Invoice** layout: columns `Description | GL Account | Qty | Unit | Account Name | Amount`.
  Map `Description` → `Description` (multi-line descriptions joined into one), `Qty`, `Unit`.
  `Item Code` is empty when absent. **Ignore** GL Account, Account Name and Amount.
- Do not output header, totals, VAT or "Details" rows as items.
- Same JSON array shape, so `InventoryItemModel.fromJson` and the merger stay unchanged.

Keep the prompt in a const in `InventoryItemRepository` (e.g. `oneScanAnalysisPrompt`), with
optional `.env` `AI_ONE_SCAN_PROMPT` to tune it without a rebuild. Add that key to
`.env.example` and to the CI `.env` injection.

> Optional fallback (stretch, not in the base scope): if OCR gets no client name, ask Gemini in
> the *same* call to also return a header object. The response then becomes
> `{ "customer": {...}, "items": [...] }`. This changes the parse shape, so keep it behind its
> own prompt and parser and don't touch `extractJsonArray`.

---

## 5. Implementation order (repo convention)

**Model → DTO/Mapper → Repository → Service → Controller → Binding → UI.** No new route is
needed: the flow uses sheets and the existing `ScannedItemsScreen`.

| # | Layer | File (new unless noted) | Notes |
|---|---|---|---|
| 1 | Utils | `lib/base/utils/b_string_similarity.dart` | `levenshtein`, `jaroWinkler`, `tokenSetRatio`. Pure, fully unit-tested |
| 2 | Utils | `lib/base/utils/b_name_normalizer.dart` | `normalize`, `scoringTokens`, abbreviation and stop-word tables. Reuse the OCR swap table idea from `VoucherSiMatcher` |
| 3 | Model | `lib/features/logistics/models/scan/scanned_client_header.dart` | `prefix, name, address, rawLines` (`prefix` is logged only, never matched) |
| 4 | Model | `lib/features/logistics/models/scan/client_match_result.dart` | `ClientMatchResult { kind: alias/exact/fuzzy/none, best, candidates[{client, score}] }` |
| 5 | Model | `lib/features/logistics/models/scan/delivery_document_scan_result.dart` | header, match, refs, `Future<Result<List<InventoryItemModel>>> items`, warnings |
| 6 | DB | `db_schema.dart` (edit): `CLIENT_ALIAS_ (ALIAS TEXT PRIMARY KEY, ACCMID TEXT NOT NULL, UPDATED_AT TEXT)`. Also add `CREATE INDEX … ON ACCMST_(ACCMNM COLLATE NOCASE)` | Bump the DB version and add an `onUpgrade` step in `database_helper.dart`. Ask `db-schema-auditor` to review it |
| 7 | DAO | `lib/data/local/dao/common/client_alias_dao.dart` | `findByAlias`, `upsert`, `deleteForClient` |
| 8 | Repository | `lib/data/repositories/client/client_alias_repository.dart` | Returns `Result<T>` |
| 9 | Helper | `lib/features/logistics/helpers/scan/client_header_extractor.dart` | Works on `List<OcrLine>` (§4.3) |
| 10 | Helper | `lib/features/logistics/helpers/scan/client_matcher.dart` | §4.4. Takes the client list + alias repo. Pure scoring is separated so it can be unit-tested |
| 11 | Helper | `lib/features/logistics/helpers/scan/one_scan_reference_patterns.dart` (new) | `Delivery Receipt: DR nnn` and any other one-scan-only patterns. Runs after the untouched `extractPatterns` |
| 12 | Repository | `inventory_item_repository.dart` (edit) | **Add** `oneScanAnalysisPrompt` + `AI_ONE_SCAN_PROMPT` env override. `defaultAnalysisPrompt` and `AI_PROMPT` stay as they are |
| 13 | Service | `lib/features/logistics/services/i_delivery_document_scan_service.dart` + `delivery_document_scan_service.dart` | Orchestrates §4.1: prepare → OCR (rotation retry) → header + refs → match. Starts the Gemini future in parallel. Returns `Result<DeliveryDocumentScanResult>` |
| 14 | Controller | `lib/features/logistics/controllers/delivery_document_scan_controller.dart` | Scan state (`isScanning`, per-part status), `applyToForm(StandardDeliveryController)`, `confirmClient(client, ocrName)` → saves the alias and applies the address rule (§4.4a) via `BClientAddress.resolve` |
| 15 | Controller | `standard_delivery_controller.dart` (edit) | **Add only:** `appendDocumentReferences(List<String>)` (de-duplicating) and a public `mergeScannedItems(List<InventoryItemModel>)` that calls the existing `_mergeScannedItems`. No existing method is changed. **Don't** grow the scan logic inside this controller |
| 16 | Binding | `general_bindings.dart` (edit) | `Get.lazyPut<IDeliveryDocumentScanService>(…, fenix: true)` **after** `ITextRecognitionService`, `ITextExtractor`, `GeminiDocumentService`, `InventoryItemRepository`, `ClientController`. Register `ClientAliasDao/Repository` and `DeliveryDocumentScanController` too |
| 17 | UI | `lib/features/logistics/screens/common/scan/b_scan_document_button.dart` | Shown only when `Platform.isAndroid`. Inserted at the top of `StandardDelivery`. **This is the only edit to the form screen;** every existing widget stays in place and order below it |
| 18 | UI | `…/scan/document_scan_progress_sheet.dart`, `…/scan/document_scan_review_sheet.dart`, `…/scan/client_match_picker.dart` | `Obx` only around the status rows. Pad the bottom once with `SafeArea(top: false)` on the sheet's outermost bottom widget |
| 19 | UI | `full_screen_loader.dart` `showSearchSheet` (edit, additive) | **Add** an optional `initialQuery` parameter (default `null` = today's behaviour) for the pre-filled fallback. Nothing else changes. The `Obx` refresh bug is follow-up F1 (§10) |

Logging uses `logDebug()` only. Log the match path and score, e.g. `"[OneScan] client matched via fuzzy 0.93 (2nd 0.71) → ACCMID=…"`, to help tune thresholds.

---

## 6. Week schedule (2026-10-12 → 2026-10-16)

| Day | Work | Done when |
|---|---|---|
| **Mon 10-12** | **Collect samples first.** Get 15–20 real documents (SI, DR, SIS, IT/GI, several clients, some known to be named differently from `ACCMST_`). Add a debug-only "Dump OCR lines" action under Developer Tools that saves `OcrLine` text + boxes as JSON fixtures in `test/fixtures/one_scan/`. Write down how each sample's customer name differs from `ACCMNM`. Build steps 1–2 (similarity + normalizer) with tests | Fixtures committed; normalizer/similarity tests pass |
| **Tue 10-13** | Steps 3, 9, 11: header extractor with rotation retry, new DR pattern, issuer exclusion. Tests run against Monday's fixtures | Every fixture yields the right name/address (prefix stripped) and references |
| **Wed 10-14** | Steps 4, 6–8, 10: alias table + migration + DAO/repo, `ClientMatcher` ranking. Tests: alias ranked first, normalized exact (incl. OCR digit swaps in names), fuzzy ranking, low score → search, and the matcher never returns a "selected" client | The right client is in the top 5 for ≥ 95% of fixtures and is #1 for ≥ 85% |
| **Thu 10-15** | Steps 5, 12–19: Gemini one-scan prompt (check on the sample SI), service, controller, bindings, button, progress/review sheets, the address rule plus its save/re-open check (§4.4a) | End-to-end on a device: one photo fills client, references and items |
| **Fri 10-16** | Run all samples on a device and tune thresholds. Test sideways photos, low light and PDFs. `flutter analyze` + `flutter test`. QA checklist: `dart run bin/generate_module_qa.dart --name "Standard Delivery One-Scan" --area Logistics --routes "/standard-delivery"` (check the route name). Update this doc and item 28 | Analyze/test pass, QA checklist done, demo-ready APK |

**Buffer:** if Thursday slips, ship client + references first (fast, on-device) and leave items
on the existing separate **Add Item** button. Item scanning already works on its own.

---

## 7. Tests

| Test file | Covers |
|---|---|
| `test/b_string_similarity_test.dart` | Levenshtein/Jaro-Winkler known values, token-set order and missing-word cases |
| `test/b_name_normalizer_test.dart` | `U.S. Dept. of Veterans Affairs` ≡ `US DEPARTMENT OF VETERANS AFFAIRS`, `St. Luke's Med. Ctr.`, `&`/AND, stop words |
| `test/client_header_extractor_test.dart` | Sample SI fixture (same-row and next-row layouts), issuer header ignored, missing Customer label |
| `test/client_matcher_test.dart` | All 3 steps rank correctly, alias ranks above fuzzy, 0.60 list-vs-search cut-off, result never pre-selects a client |
| `test/one_scan_reference_patterns_test.dart` | `Delivery Receipt: DR 690014535`, TIN lines not matched, PO with dashes, merge with `extractPatterns` without duplicates |
| `test/document_reference_extractor_test.dart` (existing) | Must still pass **unchanged**, proving the existing scanner is unaffected |
| `test/standard_delivery_form_additive_test.dart` | Widget test: Client Information, Add Document Reference and Add Item are all still present, and the Scan Document button is shown only on Android |
| `test/client_alias_dao_test.dart` | upsert/find/replace via sqflite FFI |
| `test/b_client_address_test.dart` | saved address wins; scanned used for `''`, spaces, `none`, `NA`, `n/a`, `N/A`; no scanned address → keep saved; `ACCMST_` untouched |
| `test/delivery_document_scan_service_test.dart` | Fake OCR + fake Gemini: refs/client complete while items are still pending; Gemini failure doesn't lose client/refs |

---

## 8. Open questions (ask before or on Monday)

1. ~~Is `NCR-414` the same as `ACCMSC`?~~ **Answered 2026-10-09: no.** It is stripped from the
   name and ignored; matching uses name + address only (§4.4).
2. ~~Auto-select vs. always confirm?~~ **Answered 2026-10-09: always confirm, no auto-select.**
   The scan only ranks candidates (§3, §4.4).
3. ~~Address?~~ **Answered 2026-10-09:** use the client's saved address and ignore the scanned one,
   unless the saved address is blank / none / NA / N/A. Then use the scanned address (§4.4a).
4. **Sales Invoice items** are often services ("Site survey, installation & testing…"). Should
   those still go in as delivery items?
5. Which document types must one-scan support in week 1: SI only, or also DR, SIS and IT/GI?
6. **Shared aliases:** later, should learned aliases sync to the server so every device
   benefits? That needs a new `/api4` endpoint and table in `MDMPI.App`, which is out of scope this week.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Sideways or skewed photos break the OCR row grouping | `BDocumentImage.prepare` + 90/270 retry; same-row detection uses y-overlap, not exact line order |
| Wrong client picked | No auto-select: the user always taps to confirm; candidates show the address next to the name to tell similar names apart; match path logged |
| Gemini slow or failing | Items run async and separately; client and references are never blocked; error shown with a Retry |
| `.env` `AI_PROMPT` override silently changes behaviour | One-scan passes its own prompt; `AI_ONE_SCAN_PROMPT` documented in `.env.example` and in the CI injection |
| Large client list makes matching slow | Cached normalization + token index + `compute()` |
| DB migration on existing installs | Additive table + indexes only; reviewed by `db-schema-auditor`; tested via the FFI DAO test |

## 10. Follow-ups found while planning (separate, not part of this change)

These are existing bugs. Per the additive-only rule they are **not** touched here. Each would be
its own small change after one-scan ships.

| # | Where | Bug |
|---|---|---|
| F1 | `BFullScreenLoader.showSearchSheet` (`full_screen_loader.dart`) | The result `ListView` is not wrapped in `Obx`, so the client list may not refresh after a search is submitted |
| F2 | `DocumentReferenceScreen` | When the first OCR match is a duplicate, the tapped field stays empty |
| F3 | `DocumentReferenceExtractor` | Misses `Delivery Receipt: DR nnn` (no "No."). One-scan covers it with its own pattern; adding it to the shared extractor would also help the per-field scanner |
