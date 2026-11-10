# Standard Delivery — One-Scan Fill (Client + Document References + Items)

> Status: **Built 2026-10-15, not yet run on a device.** Every code step in §5 is done on branch
> `feature/one-scan-delivery` (app) and `feature/one-scan-delivery-address` (`MDMPI.App`), with
> `flutter analyze` (no new issues) and `flutter test` (all passing) green. Nothing is committed,
> the migration has **not** been run and nothing is deployed. What is left needs a phone or a
> person: §6.
> **Items are read by on-device OCR only, with no Gemini** (decision 2026-10-15, §8 question 8).
> Tracked as item 28 in [POST_DEMO_REVISIONS_TODO.md](../POST_DEMO_REVISIONS_TODO.md).
> Target: **Android only.** Windows is not pursued for new features. The entry point is hidden
> off Android, and `flutter analyze` and `flutter test` pass.

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
3. **Items**: the same OCR lines go through a new on-device table parser
   (`ItemTableParser`, §4.5). **No Gemini, no network** (decision 2026-10-15). The existing
   **Add Item** button keeps its Gemini scan, untouched.

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
| All other fields, validators and submit | Untouched. `saveRequestFromForm` gains one `deliveryAddress` value (§4.4b A7), which is empty, so the payload is the same as today, unless a scan used the address fallback |
| `DocumentReferenceExtractor`, `InventoryItemRepository`, `defaultAnalysisPrompt`, `.env` `AI_PROMPT` | Untouched. One-scan uses its own extra patterns and its own OCR item parser, and never calls Gemini |

**The request form screens are not changed at all.** One-scan starts from a **Scan Document**
button on Home (Android only; a button inside the Standard Delivery form was tried and removed
on 2026-10-15). Edits to existing files are limited to **new members** (new methods or optional
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
| Details row | `SITE SURVEY, INSTALLATION & TESTING OF BECKMAN COULTER CHEMISTRY ANALYZER DXC700AU`, Qty 1, PC | item (OCR table parser, §4.5) |
| Header | `MARSMAN DRYSDALE MEDICAL PRODUCTS, INC`, Makati address | **must be ignored**: this is us, the issuer |

### Sample catalogue (photos of 2026-10-15)

Seven phone photos, kept **outside the repo** in `MDMPIMobileApp/Picture Testing/one_scan/`. Any
OCR fixtures made from them go in `test/fixtures/one_scan/` and stay **git-ignored** (customer
names, phone numbers and signatures). Tests that read them must `skip` when the files are absent,
so `flutter test` still passes on a clean checkout and in CI.

S1–S7 arrived first; S8–S10 (a Sales Invoice, its Delivery Receipt and a Reagents Issue Slip)
later the same day. **None is sideways**, so the rotation retry (§4.1) still has no real sample.

| # | File | Document type | Customer block | Address | References on the paper | Item table columns | Photo quality |
|---|---|---|---|---|---|---|---|
| S1 | `IMG_20261015_102536.jpg` | Inventory Transfer **Request** (ITR, system-printed) | `Business Partner:` label, name on the **next line**: `DLR-190   Galinato Clinic and Hospital` (prefix + name on one row), then TIN / Tel / Fax / Email / Contact Person / Business Style | `Address:` label, value on the **next line**: `Villamor, Esperanza Sultran Kudarat PHILIPPINES` (paper misspells *Sultan*) | `ITR No.:` `810003448` (value on the line **below** the label, in a 3-column header with two dates) | Item Code \| Description \| From Warehouse \| Warehouse \| Qty \| Unit \| Unit Price \| Total. 1 row, description wraps 3 lines | Good. Upright, flat, sharp. Red "WAREHOUSE-MDMPI / RECEIVED BY" stamp and a handwritten signature over the footer |
| S2 | `IMG_20261015_102557.jpg` | **Stock Issue Slip** (pre-printed carbon form, green copy) | `DELIVERED TO:` label, name on the **same row**: `QUEZON CITY GENERAL HOSPITAL` (no prefix) | `ADDRESS:` same row: `Seminary Road, Project 8 , Quezon City` | `No.` `00611` (red, printed, no "SIS" next to it), `REF DOC:` overprinted by `RF Dated:` (unreadable) | QTY \| UM \| PART NO. \| ITEM DESCRIPTION \| SERIAL NO. \| PTN \| REMARKS. 2 typed rows + 3 **handwritten** rows | Fair. Coloured paper, blue typed and handwritten ink, misaligned carbon over-typing, a white correction patch across row 4, signature over the footer. Landscape, upright |
| S3 | `IMG_20261015_102624.jpg` | Inventory Transfer (IT, system-printed) | Same layout as S1: `Business Partner:` → `DLR-190   Galinato Clinic and Hospital` | Same as S1 | `IT No.:` `750005578` (value below the label); `Transfer Request No.: ITR 810003436` | Item Code \| Description \| From Warehouse \| Warehouse \| Qty \| Unit. 1 row | Fair. Faint, slightly blurred print and a slight skew. Comments mention `AR26-239` |
| S4 | `IMG_20261015_102652.jpg` | **Acknowledgement Receipt** (pre-printed form, R80) | `CUSTOMER NAME` label, name on the **next line**, centred: `CHONG HUA HOSPITAL- MANDAUE` | **None** on the form | `NO.` `AR26-240` (grey box); `REQUESTED THROUGH` `POR107564` | QTY \| TAG/PART NO \| DESCRIPTION \| LOT/SERIAL NO \| EXPIRY DATE \| TAKEN FROM (UNIT, SERIAL NO). 1 row, serial handwritten | Good. Small tilt; another document shows through the paper (faint "SALES ORDER" ghost text) |
| S5 | `IMG_20261015_102837.jpg` | **Materials Issuance Slip** (pre-printed form) | **None.** Only the handwritten remark `@ SLMCGC` (likely St. Luke's Medical Center Global City) | None | `MIS No.` printed but **blank** | SERIAL / PART NO. \| DESCRIPTION \| QUANTITY. 2 rows, all **handwritten** capitals | Good photo, but nothing to match: no client, no reference. Header is misprinted `MARSMAN DRYDALE` |
| S6 | `IMG_20261015_102858.jpg` | **Return / Pull Out Slip** (R85) | `Returned by:` in a dark header bar; name in a table cell **below**: `CLINICA MANILA`, with `Contact Person` `MAAM BABES` beside it | `Address` column in the same table row: `2ND FLOOR , SM MEGAMALL BLDG. A` | `Pull Out/Return Slip No.` `MA26-355`; `SI No.` `N/A`; `DR No.` `SIS#00595` | Quantity \| UOM \| Part No. \| Description \| Lot/Serial No. \| Property Tag. 7 rows | Fair. Many signatures over the lower half. This is an **inbound** (pull-out) document, not a delivery |
| S7 | `IMG_20261015_103038.jpg` | **Goods Issue** (GI, system-printed) | **None.** The client appears only in Comments: `PHILIPPINE-CHINESE CHARITABLE ASSOCIATION` | None | `GI No.:` `760006490` (value below the label); `Reference No.:` `IT750005302` | Item Code \| Description \| Warehouse \| Qty \| Unit. 1 row | Fair. Faint print, signature over the footer |

| S8 | `IMG_20261015_135300.jpg` | **Sales Invoice** (system-printed, blue copy) | `Customer:` label, name on the **next line**: `RAD-028   University of Cebu Medical Center, Inc.` | `Address:` next line: `Ouano Avenue City South Special Economic PHILIPPINES` | `SI No.:` `700014676` (below), `PO No.:` `40405A` (below, beside `PO Date:`), `Delivery Receipt:` `DR 690014676` | Description \| GL Account \| Qty \| Unit \| Account Name \| Amount. 3 **service** rows, each description and account name wrapping onto a second line | Good. Coloured paper, upright. A totals block (Total Sales, VAT, Withholding) sits right of the Comments |
| S9 | `IMG_20261015_135627.jpg` | **Delivery Receipt** (same order as S8) | Same as S8: `Customer:` → `RAD-028   University of Cebu Medical Center, Inc.` | Same as S8 | `DR No.:` `690014676` (below), `PO No.:` `40405A`, `Sales Order No.:` `SO 670009557` | Description \| GL Account \| Account Name \| Amount. **No Qty or Unit column**: every item gets quantity 1, flagged to check | Good. A folded corner hides part of the logo |
| S10 | `IMG_20261015_135917.jpg` | **Reagents Issue Slip** (R81, pre-printed form) | `ISSUED TO:` label, **handwritten** name on the same row: `RITE-TECH MEDICAL FOR QMC` | None | `ISSUE SLIP NO.:` `IS26-344` (bare code). Handwritten `PR NO.` / `PO NO.` (`RT-2026-0526-062-QMC`, PO ticked) | ITEM NO. \| PART NO. \| DESCRIPTION \| QUANTITY \| UOM \| SERIAL / LOT NO. \| EXPIRY. 3 **handwritten** rows | Fair. All values handwritten; another document shows through the paper |

All ten are upright (EXIF orientation 0 or 1), 2290–3150 px on the long edge, 1.1–3.8 MB. The §4.1 retry downscale (long edge about 1600 px) would roughly halve them.


### Which document belongs to which request (decision 2026-10-15)

Each document type is used only for certain request forms:

| Document | Standard Delivery | Air/Sea/Land | Air/Sea | Hotline Direct | Pull Out |
|---|:-:|:-:|:-:|:-:|:-:|
| Stock Issue Slip | ✓ | ✓ | ✓ | | |
| Inventory Transfer Request | | ✓ | ✓ | | |
| Inventory Transfer | | ✓ | ✓ | | |
| Acknowledgement Receipt | | | ✓ | ✓ | |
| Materials Issuance Slip | | ✓ | ✓ | | |
| Return / Pull Out Slip | | | | | ✓ |
| Goods Issue | ✓ | ✓ | ✓ | | |
| Sales Invoice | ✓ | ✓ | ✓ | | |
| Delivery Receipt | ✓ | ✓ | ✓ | | |
| Reagents Issue Slip | ✓ | | | ✓ | |

"Air/Sea" in this list is the app's **Air / Sea / Land HD** form; "Air/Sea/Land" is
**Air / Sea / Land**; "Pull out" is **Pull Out / Return** (confirmed 2026-10-15).

**Scan first (decision 2026-10-15): the document picks the form.** A **Scan Document** button
on **Home**, in the header under "New request" and above the form tiles (Android; shown when
the user may create at least one request; moved there from the Request screen on request,
2026-10-15), takes one photo. The scan reads the document's title (`DeliveryDocumentType`), and the review sheet
gets a **Request** row offering only the forms that document belongs to *and* the user's role
may create (same rule as the + button: Air / Sea / Land HD needs the HD role, Hotline Direct
the Request or Courier role, the rest the Request role). With one choice it is already
selected; Apply waits for a choice. Apply fills the shared form state and opens that form
through `RequestFormNavigator` (the same path as the home grid), with the items screen on top
when items were added. An unreadable title offers every form the user may create.

All five forms keep client, references and items in `StandardDeliveryController.formState`
(Hotline Direct opens the Standard Delivery page; Air / Sea / Land (HD) and Pull Out bind to
it too), so one apply serves all of them. **Since 2026-10-15 the Air/Sea forms save items too**
([LOGISTICS_AIR_SEA_ITEMS_PLAN.md](LOGISTICS_AIR_SEA_ITEMS_PLAN.md), TODO item 29), so a scan
keeps its items on every form (`ScanFormTarget.takesItems`).

There is **no scan button inside the forms** (removed 2026-10-15): Home is the one entry
point, and the Request choice only offers forms the document belongs to. The controller still
supports a fixed target with a mismatch **warning** (Apply still works, decision 2026-10-15)
for a later in-form entry point. Helper: `lib/features/logistics/helpers/scan/scan_form_target.dart`.

**What the catalogue changes in the design** (checked against the current
`DocumentReferenceExtractor`; applied in §4.2 and §4.3):

- **Client labels seen:** `Business Partner` (S1, S3), `DELIVERED TO` (S2), `CUSTOMER NAME` (S4),
  `Returned by` (S6, inside a table). §4.3's list (`Customer`, `Sold To`, `Deliver To`, …) found
  only S4's. Add `Business Partner`, `Delivered To` and `Customer Name`. S5 and S7 have no client
  block at all, so they always open the pre-filled search (or an empty one).
- **Prefix:** `DLR-190` fits the §4.3 prefix rule (`^[A-Z]{2,4}-?\d{2,5}\b`), like `NCR-414`.
- **Issuer header variants:** `MARSMAN DRYSDALE MEDICAL PRODUCTS, INC`, `Marsman Drysdale Medical
  Products, Inc.`, the misprint `MARSMAN DRYDALE`, two Makati address spellings (`2231 G/F Molave
  Bldg Chino Roces Ave. Bangkal, City of Makati` and `G/F Molave Bldg., 2231 Chino Roces Avenue,
  Makati City`), and the `WAREHOUSE-MDMPI` stamp. Matching `MARSMAN` alone catches all three header
  spellings.
- **References the current extractor gets:** S3 `ITNo.:750005578`, S6 `SIS#:00595`, S7
  `GINo.:760006490`, S4/S6 bare `AR26-240` / `MA26-355`.
- **References it misses or gets wrong** (one-scan extras to consider for §4.2, extractor stays
  untouched):
  - S1 `ITR No.: 810003448`: no ITR label exists today.
  - S2 `No. 00611` under "STOCK ISSUE SLIP": the SIS pattern needs `SIS#`, so this is missed.
  - S7 `Reference No.: IT750005302`: an IT number with no "IT No." label.
  - S2: the bare-code pattern has no word boundary, so it takes `FA26-0609` (a property tag) and
    would also take `CS26-09742` out of `ACS26-09742`. **False positive.**
  - S3: the bare code comes from the Comments (`AR26-239`, a related AR), not from the header.
- **Comments can name a different contact** than the header (S1/S3: `Contact name: Deo Glenn
  Reyes` vs `Contact Person: Mr. Tito V. Reyes`). Header extraction must stop at `Comments`.
- **Item tables differ per type** (seven different column sets above, two with handwritten rows).
  The OCR item parser (§4.5) takes its column titles from this table.

---

## 2. Current building blocks (reuse, don't rebuild)

| Concern | Existing code |
|---|---|
| Form screen | `lib/features/logistics/screens/request_forms/widgets/standard_delivery_form.dart` (`StandardDelivery`) |
| Form controller | `lib/features/logistics/controllers/standard_delivery_controller.dart`: `updateRequestClientInformation(client)` (~:420), `addDocumentReferenceField()` (~:401), `pickAndAnalyzeFromCamera` / `pickAndAnalyzeFromFile` / `analyzeFileWithAiToolkit` (~:465–:710), `_mergeScannedItems` |
| Form state | `lib/features/logistics/helpers/standard_delivery_form_state.dart`: `clientInformation`, `documentReferenceControllers`, `scannedInventoryItems` |
| OCR | `ITextRecognitionService` (`processImage`, `processImageLines → List<OcrLine>` with bounding boxes) / `GoogleMlKitTextRecognizer` |
| Doc-ref parser | `ITextExtractor` / `DocumentReferenceExtractor` (`lib/common/services/abstracts/i_text_extractor.dart`) |
| Items (existing Add Item, **not used by one-scan**) | `InventoryItemRepository.analyzeFileWithGemini` → `GeminiDocumentService.extractJsonArray` |
| Item model | `InventoryItemModel` (`itemCode, description, qty, unit, partNo, serialNo, ptn, batches`). One-scan builds these directly from OCR columns |
| Layout reading | `VoucherLayoutReader` (Collection) already reads labels and columns from `OcrLine` boxes; same approach for the item table. `BDocumentImage.prepare` fixes EXIF rotation |
| Item merge | `InventoryItemMerger.merge` (mergeKey = partNo \| itemCode \| serialNo) |
| Client data | `ACCMST_` (`ACCMID`, `ACCMSC` code, `ACCMNM` name, `ACCMAD` address…), `ClientDao.search`, `ClientController.allClient` (whole list already in memory) |
| Fuzzy helpers | **None yet.** `VoucherSiMatcher.canonical` has OCR-confusion swaps (O/0, I/l/1, S/5, B/8) worth reusing |

---

## 3. User flow

```
Home (header, under "New request")
  └─ [ Scan Document ]  (Android only; shown when the user may create a request)
       ├─ Camera  / Gallery
       ▼
  Review sheet: Request (forms this document belongs to) · Client · Refs · Items
       ▼ Apply
  The chosen request form opens, already filled (old flow below kept for reference)
       ▼
  Progress sheet (three rows, each ticks independently)
       ✓ Client ........ read "U.S. Department of Veterans Affairs", 5 candidates (confirm next)
       ✓ References .... SI 700014535 · DR 690014535 · PO 358-C64033-A
       ✓ Items ......... 2 rows read from the table (check them next)
       ▼
  Review sheet
       Client:   tap to confirm one of the top 5 (best first)  or  [search, pre-filled]
                 (nothing is pre-selected; Apply stays disabled until a client is tapped
                  or the user taps "Skip client")
       Refs:     chips with checkboxes (uncheck to drop one)
       Items:    "2 items found", which opens the existing ScannedItemsScreen to check and edit
                 (rows the parser was unsure of are flagged; "No item table found" when none)
       [ Apply ]   [ Cancel ]
```

- **The client is never auto-selected** (decision 2026-10-09). The scan only *ranks* candidates;
  the user must always tap the client to confirm it, even for a learned alias or an exact name
  match. "Skip client" applies the references and items and leaves the client field as it was.
- **All three parts come from the same on-device OCR pass** (under 2 s, no network), so the
  progress sheet ticks them together. On Apply, items merge into `scannedInventoryItems` with
  `InventoryItemMerger`, and a snackbar says "N items added from scan".
- **Items are always reviewed.** OCR misreads (handwritten rows, faint print), so the items go
  to the existing `ScannedItemsScreen` for checking, the same as Add Item results today.
- **Scanning again** (multi-page invoices or a second document): references are added and de-duplicated,
  items merge with `InventoryItemMerger`, and the client is only set if it is empty. If the scan finds a *different*
  client than the one already picked, the app asks: "Replace client X with Y?"
- **Images only.** ML Kit cannot read a PDF, so one-scan offers Camera and Gallery only. A PDF
  still goes through the existing **Add Item** (Gemini) and the manual client and reference
  controls, all unchanged.

---

## 4. Design

### 4.1 One image, one OCR pass, three readers

```
Image (camera/gallery)
  └─► BDocumentImage.prepare (fix rotation) ──► ML Kit processImageLines
           ├─► ClientHeaderExtractor  ─► ClientMatcher (local DB + aliases)
           ├─► DocumentReferenceExtractor.extractPatterns + OneScanReferencePatterns
           └─► ItemTableParser  ─► List<InventoryItemModel>
```

Everything is on-device and offline. No Gemini call (decision 2026-10-15).

**Rotation (optimized, review 2026-10-15).** The sample was shot sideways. Three full ML Kit
passes (0°, 90°, 270°) one after another on a full-resolution camera image can take 3–5 s on
mid-range Android phones. To avoid that:

1. **Pass 1 (always):** OCR the image after `BDocumentImage.prepare` (EXIF rotation fixed at no
   extra cost). In most photos this is the only pass.
2. **Retry only when pass 1 found nothing useful:** zero document references, no client
   header (no `Customer`/`Sold To`/… label) **and** no item table header. If any was found, keep
   pass 1, even when it is incomplete. A partial result is better than an extra 1–2 s.
3. **Estimate the orientation instead of trying both sides.** ML Kit's `TextLine` already returns
   `angle` and `cornerPoints` (`google_mlkit_text_recognition` 0.15.1), even when the words
   come out garbled. Take the median `angle` of pass-1 lines (or the reading direction from the
   corner points when `angle` is null):
   - About +90° → retry at 270°. About −90° → retry at 90°. About 180° → retry at 180°.
   - About 0°, or too few lines to tell → skip the retry (the photo is upright but unreadable;
     a retake prompt beats more passes).
   This makes it **at most one retry**, not two.
4. **Retry on a downscaled copy** (long edge about 1600 px). Use the full image only for pass 1.
   Label and number text on an A4/letter invoice stays readable at that size.
5. **Pass 1's reading is never thrown away.** If the retry also finds nothing, show the
   reading that found more text, plus "Couldn't read the client or references. Try a straighter
   photo", with a **Retake** button.
6. **Timing is logged** (`logDebug("[OneScan] ocr pass1=…ms retry=…ms angle=…")`). The device run (§6)
   checks the targets: **pass 1 ≤ 1.5 s, worst case with retry ≤ 2.5 s** on a
   mid-range phone.

Items come from the same pass, so a retry that fixes the client and references fixes the item
table too.

**Code impact (additive):** `OcrLine` gets two optional named fields, `angle` and `cornerPoints`
(default `null`, so the existing `OcrLine(text, box)` calls and the per-field scanner are
unchanged). `GoogleMlKitTextRecognizer.processImageLines` fills them from `TextLine`. The angle
math lives in a new pure helper `BOcrOrientation.estimate(List<OcrLine>) → 0/90/180/270 or null`,
with unit tests.
**Verify on the device run (§6):** with the sideways sample, check that ML Kit returns lines with
`angle` ≈ ±90 for sideways text, and not just an empty result. If it returns nothing usable,
fall back to one 90° retry, then one 270° retry, both on the downscaled copy and stopping at the
first that finds a label.

### 4.2 Document references (the current extractor, plus one-scan extras)

- Keep the current output format (`SINo.:700014535`) so everything downstream is unchanged.
- **Extra pattern, one-scan only:** `Delivery Receipt\s*:?\s*DR\s*(\d+)` → `DRNo.:`. The sample
  prints `DR 690014535` without a "No.", which the current `\bDR + _noSep` pattern misses. It goes in
  a new `OneScanReferencePatterns` that runs **after** the existing `extractPatterns`, and the
  results are merged and de-duplicated. `DocumentReferenceExtractor` itself is not edited, so the
  existing per-field scanner behaves exactly as today.
- **SI, DR and PO below their labels** (S8, S9): `SI No.:` / `DR No.:` with `Posting Date:`
  and `Due Date:` printed between label and number, and `PO No.:` beside `PO Date:` (the shared
  extractor would read `PONo.:PO`). One-scan takes the first number after the label and drops
  any reference whose value has no digit.
- **Candidates from the sample catalogue (§1)**, also one-scan only. Each needs a decision on its
  output label before it is built, because these labels are new to the form:
  - `ITR No.` + value on the next line (S1). There is no ITR label in the form today.
  - `STOCK ISSUE SLIP … No. nnnnn` → `SIS#:nnnnn` (S2). The current SIS pattern needs `SIS#`.
  - `Reference No.: IT nnn` → `ITNo.:nnn` (S7).
  - The bare-code pattern (`[A-Z]{2}\d{2}-\d{3,}`) matches property tags (`FA26-0609`) and the
    inside of `ACS26-09742` on S2. One-scan should drop a bare code that sits in the item table
    (by `OcrLine` box) or that is preceded by a letter.
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
5. Fallback with no "Customer" label: try, in order, `Business Partner` (IT/ITR, S1/S3),
   `Delivered To` (SIS, S2), `Customer Name` (AR, S4, name on the next line), `Issued To`
   (Reagents Issue Slip, S10, handwritten on the same row), `Sold To`,
   `Deliver To`, `Ship To`, `Client`, `Consignee`. `Returned by` (S6) is a pull-out document and
   is not used for Standard Delivery. The labels come from the sample catalogue (§1); extend the
   list as more samples arrive.
6. Stop the search at `Comments` / `Remarks` / `Details`. Comments repeat the client name and a
   different contact person (S1, S3), and on GI (S7) they are the only place the client appears.
   Reading names from Comments is **not** in scope.
7. **How a value is read** (as built): the text after the label on the same OCR line; else the
   parts to its right on the same row; else the row below. Parts of one row are joined left to
   right, each compared with the one before it (so a tilted row is followed), and stop at a gap
   wider than 6 line heights (a column break) or at another label (`TIN`, `Tel`, `Date`, `Ref`,
   any text ending in `:`, …). A value read from below must start near the label's column and,
   when the label is in the left half of the page, in the left half too. That keeps right-column
   titles such as `INVENTORY TRANSFER REQUEST` and `ORIGINAL` out. The name takes one row; the
   address up to two. The address is looked for only when a client label was found.

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

**What the review sheet shows** (start value, tuned on the device run in §6). In every case
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
- **Persistence: checked in code 2026-10-15. As planned, the fallback is lost after submit.**
  - **App → backend:** `POST /api4/request` sends `StandardDeliveryMapper.toInsertDto`, which
    carries **only `requestClientID`**. There is no client object and no address field.
    (`StandardDeliveryModel.toJson`'s `'Client'` block is not used on this path.)
  - **Backend:** `InsertRequestDto` has only `RequestClientID`, and `RequestStandardModel` stores
    only the FK. On every read (`RequestRepository` insert response and list/get),
    `PopulateClientsAsync` re-fetches the client by id through `ClientLookupRepository` from the
    master `ACCMST`. So the request always shows the **master** address, which for these clients
    is blank or N/A.
  - **Effect:** the scanned fallback is visible on the form and in the *creation* SMS (it is
    built from the local model). It disappears from the saved request, the list after refresh,
    other devices, later status SMS and the delivery screens. The creation SMS and the stored
    request would disagree.
- **Decision 2026-10-15: option A. Store a per-request delivery address.** (Options B, form-only,
  and C, reuse a free-text field, were rejected. Writing the address into the master `ACCMST` is
  not allowed: that table belongs to the production `/api2` side.) Details are in §4.4b.

- **Device check (§6 step 5, after the testing backend is migrated and deployed):** create a
  request using the fallback, save, pull to refresh, then open it on a second device **and** on
  a phone still running the previous app version. Check the request details, the courier and
  delivery screens, the Request Transport route destination, and the status SMS. The scanned
  address must appear everywhere.

### 4.4b Per-request delivery address (option A)

**Facts from code** (2026-10-15):
- The request table is `a_tblrequeststandarddelivery`, shared by Standard Delivery and Hotline
  Direct. Its history table is `a_tblrequeststandarddeliveryhistory`, filled by
  `trg_requeststandarddelivery_history_fn()`. That function lists its columns explicitly in
  the INSERT, UPDATE and DELETE branches.
- EF maps each property to its lower-cased name (`PostgreSqlAppDbContext`,
  `SetColumnName(property.Name.ToLowerInvariant())`), so `DeliveryAddress` maps to `deliveryaddress`.
- The API does not set `UnmappedMemberHandling`, so an unknown JSON property is ignored. A new
  app build talking to an old backend therefore does not fail.
- About 10 app screens read `request.client.address` directly: request details, modal header,
  dispatcher, backload, the Air/Sea / Pick Up / Pull Out headers, the SMS, and **Request
  Transport, which uses it as the map route destination**. Today that geocodes the literal
  text "N/A" for these clients, because it only falls back to the name when the address is `''`.
- The local cache table `a_tblRequest` stores only `RequestClientID` (DB version 21) and
  resolves the client from `ACCMST_`. Without a local column, the override would be lost offline.

**Approach:** store the address on the request, and make the **data layer** return the client
with that address. Every existing screen then shows the right address with no UI edits.

#### Backend (`MDMPI.App`)

| # | Change | Notes |
|---|---|---|
| B1 | **Migration** `MDMPI.App/migration_20261015_add_standard_delivery_address.sql` (**written 2026-10-15, not yet run**) | `ALTER TABLE public.a_tblrequeststandarddelivery ADD COLUMN IF NOT EXISTS deliveryaddress character varying(500) NULL;` and the same on `a_tblrequeststandarddeliveryhistory`. Then `CREATE OR REPLACE FUNCTION public.trg_requeststandarddelivery_history_fn()`, re-created **in full** from `mdmpi_app_db_schema.sql` with `deliveryaddress` added to **all three branches** (`NEW.` for INSERT/UPDATE, `OLD.` for DELETE). Otherwise the value is silently dropped from history, which is the same trap the `shippingmethod` migration documents. Wrap it in `BEGIN/COMMIT`, make it re-runnable, and end with an `information_schema.columns` check query. Nullable with no default, so it is metadata-only (no table rewrite) |
| B2 | `mdmpi_app_db_schema.sql` (**done 2026-10-15**) | Add the column to both tables and the trigger function, so a fresh schema matches |
| B3 | `RequestStandardModel` + `RequestStandardHistoryModel` | `public string? DeliveryAddress { get; set; }` |
| B4 | `InsertRequestDto` | `[JsonPropertyName("requestDeliveryAddress")] public string? RequestDeliveryAddress`. In `RequestRepository` insert: trim it, store empty as `NULL`, reject over 500 characters with 400 |
| B5 | `RequestStandardDto` (read) | `DeliveryAddress`, set at both mapping sites in `RequestRepository` (list/get ~:133–:154 and insert response ~:206–:227) |
| B6 | **Override for every app version** | After `PopulateClientsAsync`, if `DeliveryAddress` is non-empty, replace `item.Client` with a **copy** of the looked-up `ACCMSTDto` whose address is `DeliveryAddress`. **It must be a copy:** `GetByIdsAsync` returns one shared DTO per client id, so changing it in place would leak one request's address into every other request for the same client. With this, phones still on the old app version also see the scanned address |
| B7 | `UpdateRequestDto` / PATCH | **Unchanged.** The address is set once at creation, and status updates never touch it |

#### App (`mdmpi_mobile_app`), additive only

| # | Change | Notes |
|---|---|---|
| A1 | `standard_delivery_insert_dto.dart` | Optional `requestDeliveryAddress`. `put(...)` writes it only when non-null, so requests without a fallback send exactly the same JSON as today |
| A2 | `StandardDeliveryModel` | New `String deliveryAddress` (default `''`), plus `copyWith` / `fromJson` / `toJson` / `fromDbJson` |
| A3 | `StandardDeliveryMapper.toInsertDto` | `requestDeliveryAddress: m.deliveryAddress.isNotEmpty ? m.deliveryAddress : null` |
| A4 | `StandardDeliveryMapper.fromDto` + `fromDbJson` | Read `deliveryAddress`. If it is non-empty, set `client` to a copy with `address = deliveryAddress`. This is a defensive repeat of B6 (it changes nothing when the backend already applied it) and also covers the local cache |
| A5 | Local DB | `a_tblRequest` gets `RequestDeliveryAddress TEXT`. DB **version 21 → 22**, `onUpgrade` runs `ALTER TABLE a_tblRequest ADD COLUMN RequestDeliveryAddress TEXT`. Saved on cache write and read back in `fromDbJson`. Review with `db-schema-auditor` |
| A6 | Form state | New `Rx<({String clientId, String address})?> scannedFallbackAddress`, set by `confirmClient` **only** when §4.4a picked the scanned address, and cleared in `reset()` |
| A7 | `saveRequestFromForm` | One added argument: `deliveryAddress` = the fallback **only if** its `clientId` equals the client currently selected. If the user later changes the client through the normal search, the fallback is ignored with no listener needed. With no scan, it is `''`, the same as today |
| A8 | Screens | **No edits.** They keep reading `client.address`, which now carries the delivery address. Request Transport routes to the scanned address instead of geocoding "N/A" |

**Deploy order (lockstep, like `shippingmethod`):**
1. Run B1 on the testing Postgres.
2. Deploy the backend (B3–B6).
3. Ship the app build.

Old apps keep working: they never send the field, so their rows stay `NULL`, and B6 still shows
them the scanned address on new rows. A new app on an old backend also works: the field is
ignored, and you are back to option B behaviour.

**Tests:**
- App: `standard_delivery_mapper_test.dart`:
  - The insert JSON has no `requestDeliveryAddress` key when the address is empty.
  - It has the key when set.
  - `fromDto` overrides the address when it is set and keeps the master address when it is empty.
- App: a DB test for the 21 → 22 upgrade and a `fromDbJson` round-trip.
- App: a data-manager test showing the fallback is dropped when the selected client id differs.
- Backend: manual. Run the migration's check query, then insert one request with the address and
  one without. Check `GET /api4/request` for both, plus another request for the **same client**
  without an address, to prove B6 doesn't leak. Then check a history row after a status PATCH.


**Learning (fixes repeat mismatches):** when the user confirms a client for a scanned name
(any confirmation, including from the pre-filled search), save `normalize(ocrName) → ACCMID` in `CLIENT_ALIAS_`. The next scan of the same
customer is ranked first with a "Used before" tag. It still needs a tap to confirm. If the user later picks someone else for an existing alias,
the alias is updated. Aliases are stored per device for now. Syncing them to the server is a
later option (§8).

**Performance:** `ClientController.allClient` is already in memory. Normalize and tokenize each
client **once**, lazily on the first scan, and cache it. Build an inverted token index so
only clients sharing at least one significant token (or the first 3 letters) are scored. If the
list is larger than ~5k rows, run the matching in `compute()` so the UI stays responsive.

**Cache invalidation and memory (review 2026-10-15).** The normalized-token cache and the inverted
index (`ClientTokenIndex`) must be rebuilt whenever the client list changes. Constraints found in code:

- `allClient` is an `RxList` refreshed **in place** with `assignAll` (`fetchClientFromDb`,
  `hardResetClients` in `client_controller.dart`), so the list *object* never changes and an
  identity check can't detect a refresh.
- `ClientController` is `lazyPut(..., fenix: true)`, so it can be disposed and recreated. A
  long-lived `ever(allClient, …)` listener held by the matcher would keep the old controller
  alive (a leak) **and** miss updates on the new instance.

The plan therefore uses a **pull-based fingerprint with no listeners**:

1. At each scan, resolve the list fresh with `Get.find<ClientController>().allClient`. **Never
   store the controller or the list in a field.**
2. Compute a cheap fingerprint: `length` + `Object.hashAll` over `id|name|address` of every client
   (O(n) string hashing, a few ms for ~5k rows, far cheaper than re-normalizing). This catches
   a master sync, a hard reset, a background pull and a recreated controller, including edits
   to a name or address that keep the same row count.
3. If the fingerprint differs from the cached one, **drop the old index and rebuild lazily**
   (in `compute()` when large). The rebuilt index is tagged with the fingerprint taken
   **before** the build. If the list changed during the build, the result is discarded and
   rebuilt on the next scan. A stale index is never used.
4. The index keeps only what scoring needs: `ACCMID` + normalized tokens + token→ids map.
   **No `ClientModel` references**, so a refreshed list's old objects can be garbage-collected.
   The client shown in the review sheet is looked up fresh from `allClient` by `ACCMID`.
5. **Lifetime:** the index lives in `ClientMatcher`, owned by the scan service.
   `DeliveryDocumentScanController.onClose()` calls `matcher.clearCache()`, so the memory is
   freed when the user leaves the Standard Delivery form. The next visit rebuilds once, which
   takes about 100 ms for ~5k clients.
6. **Aliases after a sync:** an alias whose `ACCMID` is no longer in the list is skipped while
   ranking and deleted from `CLIENT_ALIAS_` in the background, so it can't point at a removed
   client.
7. `ClientController` is **not edited**. No version counter or hooks are added (additive-only rule).

Tests (`client_matcher_test.dart`, `client_token_index_test.dart`):
- Changing a name or address in place rebuilds the index.
- `assignAll` with the same length but different content rebuilds it.
- An unchanged list reuses it (build count stays 1).
- A list that changes during the build discards the result.
- `clearCache()` empties it.
- A stale alias is skipped.

### 4.5 Items: on-device OCR table parser (decision 2026-10-15)

`ItemTableParser.parse(List<OcrLine>) → ItemTableReading { items, unsure, headerFound }`, pure
Dart in `lib/features/logistics/helpers/scan/item_table_parser.dart`, tested with hand-made lines
like the header extractor. It reads the same OCR lines as §4.3, so it adds no extra OCR pass.

1. **Find the header row.** Group lines into rows (same y-overlap rule as §4.3). The header row
   is the one with the most known column titles, at least two, one of which is a description
   column. Column titles come from the sample catalogue (§1), matched longest first and
   case-insensitive:

   | Field on `InventoryItemModel` | Titles |
   |---|---|
   | `description` | `Description`, `Item Description` |
   | `qty` | `Qty`, `Quantity` |
   | `unit` | `Unit`, `UM`, `UOM` |
   | `itemCode` | `Item Code` |
   | `partNo` | `Part No.`, `Tag/Part No`, `Serial / Part No.` (MIS: one shared column → `partNo`) |
   | `serialNo` | `Serial No.`, `Lot/Serial No` |
   | `ptn` | `PTN`, `Property Tag` |
   | `serialNo` (also) | `Serial / Lot No.` (Reagents Issue Slip) |
   | *ignored* | `Unit Price`, `Price`, `Total`, `Amount` (also cut off as `Amoun`), `From Warehouse`, `Warehouse`, `Remarks`, `Expiry Date`, `Expiry`, `Taken From`, `GL Account`, `Account Name`, `Item No.` (row number) |

   After the device run (IT sample): titles tolerate OCR slips (`ltem Code`, `Oty`, `Unlt`)
   and stray letters from shaded header rows; the column boundary left of Description sits
   near the code column, because description text starts well before its centred title.

   `Unit Price` is matched before `Unit`, so it is never read as the unit.
2. **Columns** are bounded by the midpoints between neighbouring header titles. Each body
   part goes to the column that holds its horizontal centre.
3. **Body rows** are the rows below the header, up to the first of `Comments`, `Remarks`,
   `Total`, `Prepared By`, `Received`, or the end of the page.
4. **One row = one item** when it has a description. A number in an ignored column (GL
   account, amount, `SVC103`) always starts a new row: the Delivery Receipt (S9) has no
   quantity or code column at all. A row with only a description, within
   1.5 line heights of the item above, continues that item's description (S1's three-line
   `Optic Bench / WBC Chamber Assy w/ Pre-Screened Hgb Led (OPN:RXH60021)`). A description-only
   row further away (`SR: JRQ` on S2) is dropped and logged. Rows without a description (AR's
   `UNIT | SERIAL NO` sub-header, empty ruled rows) are skipped.
5. **Quantity:** `1.00` → 1; OCR slips `l`, `I`, `|` → `1`. A missing or unreadable quantity
   becomes 1, and the item goes in `unsure` so the review screen flags it.
6. **Unsure items** (flagged for the user, never dropped): quantity defaulted, description
   shorter than 3 characters, or a row whose parts straddle two columns.
7. **No header found** → no items, and the review sheet says "No item table found. Use Add
   Item". The existing Add Item (Gemini) is unchanged.
8. The parser outputs `InventoryItemModel`, so `InventoryItemMerger` and `ScannedItemsScreen`
   need no change.
9. **Batch sub-rows** (Sales Invoice with `Batch/Serial #  Quantity  Expiry Date` under each
   item, PRC sample of 2026-10-15) follow Add Item's own rules (`InventoryItemRepository`
   prompt, rules 23–25): every dated row after that sub-header belongs to the item above as an
   `InventoryBatchModel` (serial, `Quantity` → batch quantity, expiry as printed). A batch
   serial never goes into the item's `Serial No.`; a missing batch quantity flags the item.
10. **Tilt** is levelled first (`BOcrOrientation.deskew`), for every reader. Learned from the
    first real in-app capture (2026-10-15, kept as a git-ignored fixture and, with personal text
    replaced, as `capture_si_700014771_test.dart`):
    - the tilt is uneven (level on the left, ~2.5° on the right), so it is fitted as growing
      across the page (slope = a + b·x, weighted by line length);
    - ML Kit reports most short lines perfectly flat; those are ignored for the fit;
    - tilted lines get boxes up to twice their text height, so rows are grouped by line
      **middles**, not box overlap (`OcrRows`), in the item parser and the client header alike;
    - references are read from ML Kit's block order **and** the page's reading order
      (`OneScanReferencePatterns.fromLines`), so `Delivery Receipt:` meets `DR 690014771`;
    - OCR slips handled: `D8/06/2027` (date), `.00` (a single batch then takes the item
      quantity, flagged), `NCR.326` (prefix), `Addres:`, `Dellvery Recelpt:`, `BÖTTLE`.

**Known limits:** ML Kit's Latin model reads printed text well and handwriting poorly. S2's
three handwritten rows and S5's handwritten slip may come out partly wrong; the user fixes them
on the review screen. The SI layout (`Description | GL Account | Qty | Unit | Account Name |
Amount`) is covered by the title table but has no real sample yet.

---

## 5. Implementation order (repo convention)

**Model → DTO/Mapper → Repository → Service → Controller → Binding → UI.** No new route is
needed: the flow uses sheets and the existing `ScannedItemsScreen`.

| # | Layer | File (new unless noted) | Notes |
|---|---|---|---|
| 1 | Utils | `lib/base/utils/b_string_similarity.dart` (**done 2026-10-15**) | `levenshtein`, `jaroWinkler`, `tokenSetRatio`. Pure, fully unit-tested |
| 2 | Utils | `lib/base/utils/b_name_normalizer.dart` (**done 2026-10-15**) | `normalize`, `scoringTokens`, `scoringKey`, abbreviation and stop-word tables. Reuse the OCR swap table idea from `VoucherSiMatcher` |
| 3 | Model | `lib/features/logistics/models/scan/scanned_client_header.dart` (**done 2026-10-15**) | `label, prefix, name, address, rawLines`, plus `hasLabel` (feeds the §4.1 retry rule) and `hasName`. `prefix` is logged only, never matched |
| 4 | Model | `lib/features/logistics/models/scan/client_match_result.dart` | `ClientMatchResult { kind: alias/exact/fuzzy/none, best, candidates[{client, score}] }` |
| 5 | Model | `lib/features/logistics/models/scan/delivery_document_scan_result.dart` | header, match, refs, `ItemTableReading items` (items + unsure + headerFound), warnings |
| 6 | DB | `db_schema.dart` (edit): `CLIENT_ALIAS_ (ALIAS TEXT PRIMARY KEY, ACCMID TEXT NOT NULL, UPDATED_AT TEXT)`. (The planned `ACCMST_(ACCMNM COLLATE NOCASE)` index was dropped: the client search uses `LIKE '%q%'`, which cannot use it.) | Bump the DB version and add an `onUpgrade` step in `database_helper.dart`. Ask `db-schema-auditor` to review it |
| 7 | DAO | `lib/data/local/dao/common/client_alias_dao.dart` | `findByAlias`, `upsert`, `deleteForClient` |
| 8 | Repository | `lib/data/repositories/client/client_alias_repository.dart` | Returns `Result<T>` |
| 9 | Helper | `lib/features/logistics/helpers/scan/client_header_extractor.dart` (**done 2026-10-15**) | Works on `List<OcrLine>` (§4.3). Rotation retry is not here: it belongs to the service (step 13) |
| 10 | Helper | `lib/features/logistics/helpers/scan/client_matcher.dart` | §4.4. Takes the client list + alias repo. Pure scoring is separated so it can be unit-tested |
| 11 | Helper | `lib/features/logistics/helpers/scan/one_scan_reference_patterns.dart` (new) | `Delivery Receipt: DR nnn` and any other one-scan-only patterns. Runs after the untouched `extractPatterns` |
| 12 | Helper | `lib/features/logistics/helpers/scan/item_table_parser.dart` (new) + `models/scan/item_table_reading.dart` | §4.5. Pure, works on `List<OcrLine>`. `InventoryItemRepository` is **not** edited |
| 13 | Service | `lib/features/logistics/services/i_delivery_document_scan_service.dart` + `delivery_document_scan_service.dart` | Orchestrates §4.1: prepare → OCR pass 1 → (one estimated-angle retry only if no refs, no client header and no item header, §4.1) → header + refs + items → match. No network. Returns `Result<DeliveryDocumentScanResult>` |
| 14 | Controller | `lib/features/logistics/controllers/delivery_document_scan_controller.dart` | Scan state (`isScanning`, per-part status), `applyToForm(StandardDeliveryController)`, `confirmClient(client, ocrName)` → saves the alias and applies the address rule (§4.4a) via `BClientAddress.resolve` |
| 15 | Controller | `standard_delivery_controller.dart` (edit) | **Add only:** `appendDocumentReferences(List<String>)` (de-duplicating) and a public `mergeScannedItems(List<InventoryItemModel>)` that calls the existing `_mergeScannedItems`. No existing method is changed. **Don't** grow the scan logic inside this controller |
| 16 | Binding | `general_bindings.dart` (edit) | `Get.lazyPut<IDeliveryDocumentScanService>(…, fenix: true)` **after** `ITextRecognitionService`, `ITextExtractor`, `ClientController`. Register `ClientAliasDao/Repository` and `DeliveryDocumentScanController` too |
| 17 | UI | `lib/features/logistics/screens/common/scan/b_scan_first_action.dart` + `scan_source_sheet.dart` | Home header button (Android only, role-gated). **No form screen is edited** (the in-form button was removed 2026-10-15) |
| 18 | UI | `…/scan/document_scan_progress_sheet.dart`, `…/scan/document_scan_review_sheet.dart`, `…/scan/client_match_picker.dart` | `Obx` only around the status rows. Pad the bottom once with `SafeArea(top: false)` on the sheet's outermost bottom widget |
| 19 | UI | `full_screen_loader.dart` `showSearchSheet` (edit, additive) | **Add** an optional `initialQuery` parameter (default `null` = today's behaviour) for the pre-filled fallback. Nothing else changes. The `Obx` refresh bug is follow-up F1 (§10) |

Logging uses `logDebug()` only. Log the match path and score, e.g. `"[OneScan] client matched via fuzzy 0.93 (2nd 0.71) → ACCMID=…"`, to help tune thresholds.

---

## 6. Build status and what is left (2026-10-15)

**Built** (all §5 steps, plus the developer dump tool):

| Area | Files |
|---|---|
| Pure helpers | `lib/base/utils/b_string_similarity.dart`, `b_name_normalizer.dart`, `b_ocr_orientation.dart`, `b_client_address.dart` |
| Readers | `lib/features/logistics/helpers/scan/client_header_extractor.dart`, `item_table_parser.dart`, `one_scan_reference_patterns.dart`, `client_token_index.dart`, `client_matcher.dart`, `ocr_line_dump.dart` |
| Models | `lib/features/logistics/models/scan/` (`scanned_client_header`, `client_match_result`, `item_table_reading`, `delivery_document_scan_result`) |
| Data | `CLIENT_ALIAS_` (`ensureOneScanTables`, kept out of the version-bump rebuild), DB v22 with `a_tblRequest.RequestDeliveryAddress`, `ClientAliasDao`, `ClientAliasRepository` |
| Service / controller | `lib/features/logistics/services/(i_)delivery_document_scan_service.dart`, `controllers/delivery_document_scan_controller.dart`; `StandardDeliveryController` gains `appendDocumentReferences` and `mergeScannedItems` only |
| UI | `screens/common/scan/` (button, review sheet, progress, client picker); the Home header button (`home_header.dart`, `home.dart`); no form screen edited; `showSearchSheet` gains optional `initialQuery` / `onClientSelected` |
| Delivery address (A1–A8) | insert DTO, read DTO, model, mapper, local DAO, form state, data manager |
| Developer tool | Settings > Developer Tools > **Dump OCR lines** (Android), `screens/data_test/ocr_dump_page.dart` |
| Backend (B3–B6) | `MDMPI.App`: entity + history entity `DeliveryAddress`, `InsertRequestDto.RequestDeliveryAddress` (400 over 500 chars), `RequestStandardDto.DeliveryAddress`, both read sites, `RequestRepository.WithDeliveryAddress` (copy, never in place). 6 new xUnit tests pass. Two `RequestRepositoryUpdateValidationTests` fail on `master` too (pre-existing) |

**Where the build differs from the design above:**

- Pass 1 reads the photo with `InputImage.fromFilePath`, which applies EXIF rotation itself, so
  `BDocumentImage.prepare` is not run first (it would cost a full decode and re-encode). The
  retry copy is rotated and shrunk to 1600 px with the `image` package in an isolate.
- The client search is pre-filled with the **first distinctive word** of the scanned name
  (`Galinato`), not the whole name. The search matches by "contains", so `Galinato Clinic and
  Hospital` would find nothing against `GALINATO CLINIC & HOSPITAL`. Matches are loaded before
  the sheet opens, because its list is not reactive (F1).
- Items are checked **after Apply**: Apply merges them and opens the existing
  `ScannedItemsScreen`, so the user always reviews them there.
- New reference labels from the catalogue: `ITRNo.:` (ITR, and "Transfer Request No.: ITR …"),
  `SIS#:` for the Stock Issue Slip `No. nnnnn`, `ITNo.:` for "Reference No.: IT…". **`ITRNo.:` is a
  label the form has not had before; confirm it is wanted.**
- **Document scanner first (2026-10-15).** On Android, Scan Document offers **Scan document**
  first: Google's on-device ML Kit document scanner (`BDocumentScanner`, shared with the
  Collection voucher scan) finds the page edges, corrects the perspective and flattens a bent
  page before OCR, and can import a gallery photo the same way. Where it cannot run (no Play
  services, module not downloaded), a plain camera photo is taken instead. "Take a photo" and
  "Pick from gallery" stay, read as taken. Deskew also fits a tilt that changes down the page
  (`slope = a + b·x + c·y`) for curved photos.
- **References are per document type** (`DeliveryDocumentType.referenceLabels`): an Inventory
  Transfer keeps only its IT No. and ITR No., a Sales Invoice its SI, DR and PO, and so on; codes
  typed into the Comments (`AR26-239`) are dropped. Acknowledgement Receipt, Reagents Issue Slip,
  Materials Issuance Slip, Return / Pull Out Slip and unknown titles keep every reference.
- **Client fallback:** when no name is read under a customer label (a misread label), the header
  rows left of centre and above the item table are matched against the client list, coded rows
  (`DLR-190 …`) first; one is taken only on a strong match (`ClientMatchResult.strongScore`, or an
  exact / alias match). The user still confirms.
- `InventoryItemMerger` merges items whose part number, item code and serial are all empty. Two
  scanned rows with none of the three (rare) collapse into one; the merger is untouched
  (additive rule).

**Left, needs a phone or a person** (nothing here can be done from the PC):

1. **Device run.** Install a debug build, then Settings > Developer Tools > Dump OCR lines on the
   7 sample photos. Copy the JSON files to `test/fixtures/one_scan/` (git-ignored) and fill in
   each file's `expected` block. `one_scan_fixtures_test.dart` then checks them.
2. **Check the ML Kit angle** on a sideways photo (§4.1) and the timings in the `[OneScan]` log
   (pass 1 ≤ 1.5 s, with retry ≤ 2.5 s).
3. **Scan each sample** with the Scan Document button and tune `ClientMatchResult.listScore`
   (0.60) against the real client list.
4. **Backend, in this order:** run `migration_20261015_add_standard_delivery_address.sql` on the
   testing Postgres (after its pre-check), then deploy the `MDMPI.App` branch, then ship the app.
   The backend build **must not** go out before the migration: EF now selects `deliveryaddress`.
5. **Device check for the address (§4.4a):** create a request with the fallback, refresh, open it
   on a second phone and on one with the old app, and check details, courier screens, Request
   Transport and the status SMS.
6. QA checklist: `dart run bin/generate_module_qa.dart --name "Standard Delivery One-Scan" --area Logistics --routes "/standard-delivery"`.
7. More samples: at least one **Sales Invoice**, one **Delivery Receipt** and one **sideways** photo.

## 7. Tests

| Test file | Covers |
|---|---|
| `test/base/utils/b_ocr_orientation_test.dart` | Median angle → 0/90/180/270; null/too-few lines → no retry; corner-point fallback when `angle` is null |
| `test/base/utils/b_string_similarity_test.dart` (**done 2026-10-15**) | Levenshtein/Jaro-Winkler known values, token-set order and missing-word cases, one-to-one token pairing |
| `test/base/utils/b_name_normalizer_test.dart` (**done 2026-10-15**) | `U.S. Dept. of Veterans Affairs` ≡ `US DEPARTMENT OF VETERANS AFFAIRS`, `St. Luke's Med. Ctr.`, `&`/AND, stop words, OCR digit slips only inside words, sample names (§1) |
| `test/features/logistics/helpers/scan/client_header_extractor_test.dart` (**done 2026-10-15**, hand-made lines from the §1 catalogue) | All 7 samples + the SI: same-line, same-row and next-row layouts, prefix strip, issuer ignored (incl. `DRYDALE`), Comments ignored, wrapped address, tilted row, label with no value. Re-run against the device OCR dumps once they exist |
| `test/features/logistics/helpers/scan/client_matcher_test.dart` (incl. index cache) | All 3 steps rank correctly, alias ranks above fuzzy, 0.60 list-vs-search cut-off, result never pre-selects a client |
| `test/features/logistics/helpers/scan/item_table_parser_test.dart` | All seven column sets from §1 and the SI layout; multi-line description joined; `Unit Price` not read as unit; `SR: JRQ` dropped; AR sub-header skipped; qty `1.00`/`l`/missing; unsure flags; no header → no items |
| `test/features/logistics/helpers/scan/one_scan_reference_patterns_test.dart` | `Delivery Receipt: DR 690014535`, TIN lines not matched, PO with dashes, merge with `extractPatterns` without duplicates |
| `test/features/logistics/delivery_address_test.dart` | A1–A7: no key in the insert JSON without a fallback, key with one, API/DTO/local reads override the address on a copy, form state only for the same client |
| `test/features/logistics/controllers/delivery_document_scan_controller_test.dart` | Never pre-selects; confirm applies the address rule and saves the alias; apply fills client, ticked refs, items; skip; replace-client check |
| `test/features/logistics/helpers/scan/one_scan_fixtures_test.dart` | Device OCR dumps in `test/fixtures/one_scan/` (git-ignored); skipped when there are none |
| `test/document_reference_extractor_test.dart` (existing) | Must still pass **unchanged**, proving the existing scanner is unaffected |
| `test/features/logistics/screens/scan_first_action_test.dart` | Home's Scan Document is hidden off Android; the source sheet offers camera and gallery |
| `test/data/local/client_alias_dao_test.dart` (also: survives the rebuild, v22 column, index) | upsert/find/replace via sqflite FFI |
| `test/base/utils/b_client_address_test.dart` | saved address wins; scanned used for `''`, spaces, `none`, `NA`, `n/a`, `N/A`; no scanned address → keep saved; `ACCMST_` untouched |
| `test/features/logistics/services/delivery_document_scan_service_test.dart` | Fake OCR: no retry when pass 1 finds a ref, a client header or an item header; exactly one retry otherwise; client, refs and items come from the same pass; no Gemini or network call is made |

---

## 8. Open questions

1. ~~Is `NCR-414` the same as `ACCMSC`?~~ **Answered 2026-10-09: no.** It is stripped from the
   name and ignored; matching uses name + address only (§4.4).
2. ~~Auto-select vs. always confirm?~~ **Answered 2026-10-09: always confirm, no auto-select.**
   The scan only ranks candidates (§3, §4.4).
3. ~~Address?~~ **Answered 2026-10-09:** use the client's saved address and ignore the scanned one,
   unless the saved address is blank / none / NA / N/A. Then use the scanned address (§4.4a).
4. **Sales Invoice items** are often services ("Site survey, installation & testing…"). Should
   those still go in as delivery items?
   *As built:* every table row with a description becomes an item; the user can untick "Items"
   on the review sheet or delete rows on the items screen.
5. Which document types must one-scan support in week 1: SI only, or also DR, SIS and IT/GI?
   The sample set (§1) has ITR, IT, GI, SIS, AR, MIS and a Return/Pull Out slip, but **no SI or
   DR**. MIS (S5) and GI (S7) have no client block; the Return/Pull Out slip (S6) is inbound and
   belongs to the Pull Out form. Suggested week-1 set from what is on hand: **SIS, IT/ITR and AR**
   for client + references, with SI/DR added once a sample of each arrives.
   **Answered 2026-10-15** by the document-to-request table in §1: Standard Delivery takes the
   Stock Issue Slip, Goods Issue, Sales Invoice, Delivery Receipt and Reagents Issue Slip. Other
   types get a warning on the review sheet.
6. ~~Fallback address persistence?~~ **Answered 2026-10-15: option A.** A per-request
   `deliveryaddress` column, backend override and app support, all additive (§4.4b).
7. **Shared aliases:** later, should learned aliases sync to the server so every device
   benefits? That needs a new `/api4` endpoint and table in `MDMPI.App`, which is out of scope this week.
8. ~~Items: Gemini or OCR only?~~ **Answered 2026-10-15: OCR only.** One-scan reads items with
   an on-device table parser (§4.5) and never calls Gemini. The existing Add Item keeps its
   Gemini scan. One day was added to the schedule for the parser (§6).

## 9. Risks

| Risk | Mitigation |
|---|---|
| Sideways or skewed photos break the OCR row grouping | `BDocumentImage.prepare` + at most one retry at the angle estimated from ML Kit line angles (§4.1); same-row detection uses y-overlap, not exact line order |
| Wrong client picked | No auto-select: the user always taps to confirm; candidates show the address next to the name to tell similar names apart; match path logged |
| OCR misreads item rows (handwriting, faint print, carbon over-typing) | Items always go to `ScannedItemsScreen` for review; unsure rows are flagged, never dropped; Add Item (Gemini) is still there for hard documents |
| An item table layout the parser does not know | Column titles from the §1 catalogue, extended as samples arrive; no header → "No item table found", client and references still apply |
| OCR retries make the scan slow (3–5 s for three passes) | Retry only when nothing useful was found, at most one retry at the estimated angle, on a downscaled copy; timings logged and checked on the device run (§4.1, §6) |
| Large client list makes matching slow | Cached normalization + token index + `compute()` |
| Fallback address lost after submit (backend re-reads `ACCMST` by id) | Option A (§4.4b): `deliveryaddress` column + trigger in all three branches, migration before backend deploy, backend override on a **copied** client DTO, local DB v22 column |
| Backend override leaks one request's address into other requests for the same client | B6 copies the shared `ACCMSTDto` and never mutates it; the manual test covers a second request for the same client |
| Stale or leaked client cache after a master sync | Pull-based fingerprint check at each scan, no listeners or stored controller refs; index holds ids only and is cleared in `onClose` (§4.4) |
| DB migration on existing installs | Additive table + indexes only; reviewed by `db-schema-auditor`; tested via the FFI DAO test |

## 10. Follow-ups found while planning (separate, not part of this change)

These are existing bugs. Per the additive-only rule they are **not** touched here. Each would be
its own small change after one-scan ships.

| # | Where | Bug |
|---|---|---|
| F1 | `BFullScreenLoader.showSearchSheet` (`full_screen_loader.dart`) | The result `ListView` is not wrapped in `Obx`, so the client list may not refresh after a search is submitted |
| F2 | `DocumentReferenceScreen` | When the first OCR match is a duplicate, the tapped field stays empty |
| F3 | `DocumentReferenceExtractor` | Misses `Delivery Receipt: DR nnn` (no "No."). One-scan covers it with its own pattern; adding it to the shared extractor would also help the per-field scanner |
