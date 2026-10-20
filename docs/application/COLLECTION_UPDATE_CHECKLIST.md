# Collection — Update Checklist (deployment and training session)

> Source: `mdmpi-app-collection-update-checklist.docx`, compiled from the Collection
> deployment and training session (received 2026-10-19). Each item keeps the wording of
> the checklist, then the status and what was found or changed. **This file is the basis
> for the Collection revision work: update it as items land.**
>
> Repos: **mobile** `mdmpi_mobile_app` · **backend** `MDMPI.App` (Postgres, `/api4/Collection/*`)
> · **web** `mdmpi_collection_web` (admin import / clients / reports / actual collection).
>
> Work is on branch `collection/revisions-group-a`, **committed, not pushed**, and **not yet
> checked on a phone**:
>
> - `63c6d70` Collection: Revisions round 1, reconciliation cases, and dark mode
> - `d049a33` Collection: SMS messages one fact per line, each number labelled
>
> `flutter analyze` adds no issues; `flutter test` passes except the five failures that were
> already there before this work (`ai_agent_test`, `pull_out_model_from_json_test`,
> `request_dao_insert_test`, `widget_test`).
>
> Legend: `[x]` done · `[~]` partly done, or already in the app before this round ·
> `[-]` held back on purpose · `[ ]` not started.

## Summary (updated 2026-10-20)

| Status | Count |
|---|---|
| Done | 9 |
| Already in the app before this round | 3 |
| Partly done | 2 |
| Held back | 1 |
| Not started | 18 |
| **Total** | **33** |

Plus two changes not on the checklist: reconciliation invoices stuck outside the Tracker,
and a Light/Dark toggle on Home (see [Outside the checklist](#outside-the-checklist)).

## Web App

- [ ] 1. Actual Collection: add a daily entry in Post Actual Collection. Today the server
      stamps the entry with today's date (`CollectionActualRepository.cs:58`) and there is
      no date field. Needs DTO, repository and view changes (`views/ActualCollectionView.vue`).
- [ ] 2. Actual Collection: make Reference no. optional. It is required in three places: the
      web rule (`ActualCollectionView.vue:195-201`), the backend `Validate`
      (`CollectionActualRepository.cs:180-181`), and the database (`referenceno` NOT NULL plus
      a unique index). Needs a migration, and the duplicate check must skip blanks.
- [ ] 3. Targets: support a different target amount per area. Today there is one team target
      per month (`PUT /targets`, `TeamTargetDto`). Areas exist only on mobile, as client-code
      prefixes (`collection_area.dart`). Needs an area column on targets and on actuals.
- [ ] 4. Dashboard: build a dashboard for reviewing all data. None exists; the closest is
      `ReportsView.vue`.
- [ ] 5. Dashboard: when a specific area is set, show the actual target for that area.
      Depends on 3.
- [ ] 6. Dashboard: add an option to view the actual target as a whole (all areas
      combined). Depends on 3.

## New Activity: Routing of Documents

- [ ] 7. Set up flow: Accounts and Remarks (for tracking of activity only). Add it to the
      activity picker (`activity_type_modal.dart`); it can reuse `ClientPickerField`. Likely
      needs a new upload change type, or an extension of `OFFICE_ACTIVITY`, on the backend.

## Pre-collection

- [ ] 8. Create a card for pre-collection. The `Pre-Collection` status exists; Home tiles are
      built in `home.dart`.

## Deposit Process

- [~] 9. Make Bank required. **Already required** (`deposit_form.dart`, `BBankField`).
- [x] 10. Make Cheque number optional. Label reads "Check Number (optional)". The deposit SMS
      leaves a blank cheque out. (`63c6d70`)
- [x] 11. Make Remarks required. "Remarks are required"; blank or spaces-only is refused.
      (`63c6d70`)
- [ ] 12. Account is selected by search. The deposit has no account today (`clientId: ''`);
      `ClientPickerField` can be reused.
- [ ] 13. Remarks format, one per line: Account - Amount. Today Remarks is free text.

## Advanced Payments

- [x] 14. Add chips to the Remarks field (Machine, Reagents, Hold accounts). A chip adds its
      word to Remarks as a comma-separated list; tapping it again takes it out. More chips can
      be added in `advancedPaymentRemarkChips` (`advanced_payment_form.dart`). (`63c6d70`)
- [~] 15. Make advanced payments visible to all users. **Already shared by the server**: the
      workspace returns every unallocated advance, whoever recorded it
      (`CollectionInvoiceRepository.cs:996-1045`). Other phones see a new one only after it
      is uploaded and they download again.
- [ ] 16. Allow users to add a temporary account for advanced payments. The picker selects
      only existing registry clients today.

## Reconciliation

- [x] 17. Invoice picking: add "Select all". On the Reconciliation form picker
      (`engagement_invoice_picker.dart`) and the case's Log a step sheet
      (`recon_log_activity_sheet.dart`). It reads "Clear" when everything is picked and shows
      only when there are two or more invoices. (`63c6d70`)
- [x] 18. Invoice picking: add PO/SI. Each invoice reads "SI …", with the PO underneath when
      the phone knows it. On the log sheet the PO comes from the invoices downloaded to the
      phone; a case invoice not on the phone shows the amount only. (`63c6d70`)
- [~] 19. Forms: allow multiple pictures in the photo section. **Already in** the Log a step
      sheet. The Deposit, Advanced Payment and CWT forms have no photo section; confirm
      whether they need one.
- [ ] 20. Update invoices: individual remarks per invoice. The batch update already has a
      remark per invoice; a reconciliation log step has one remark shared by every invoice.
- [~] 21. Add log step "Settled", after which the user chooses an invoice. **Partly:** a
      paid-off invoice gets a "Settled · Tracker" line on its case timeline, worked out on
      the phone (see Outside the checklist). There is no step the collector picks by hand,
      because the server rejects unknown step types; a hand-picked step needs a backend change.
- [ ] 22. Keep reconciled accounts in the collection bucket (reconciliation works like a
      status, not a removal). Today an invoice marked Reconciliation is excluded from the
      bucket (`isRegularBucketInvoice` in `collection_activity_controller.dart`).
- [ ] 23. Let collectors log activities on other invoices plus some of the reconciled
      invoices. Today only the case holder logs (`canLog` in `reconciliation_controller.dart`).
- [ ] 24. Keep reconciled invoices pickable by specific invoice. Today acquiring takes every
      reconciliation invoice of the account (`claimReconciliation`).
- [~] 25. When a reconciled invoice is collected through the collection bucket, move it to
      Settled and remove it from Reconciliation. **Partly:** it gets the Settled line on the
      timeline, and the case completes when every invoice is paid. It is not yet removed
      from Reconciliation.
- [ ] 26. In the reconciled list, show settled invoices as "Cleared" (not "Closed") and the
      rest as Open (e.g., 3 invoices, 1 settled: 1 Cleared, 2 Open). "Closed" is the
      dashboard filter and the "Closed <date>" line (`reconciliation_controller.dart`,
      `recon_dashboard_screen.dart`). Invoice statuses already read Open / Cleared.
- [-] 27. Remove the "1 account waiting to be acquired" item. **Held:** that card is
      currently the only way into acquiring reconciliation accounts. Remove it together with
      22, which gives the replacement path.

## SMS

- [x] 28. Fix the SMS message format so receivers can understand each SMS more easily.
      (`d049a33`) Every message now leads with what happened and to whom on the first line
      (so the notification preview still says it), then one labelled line per fact, and the
      collector's initials on the last line. Several invoices are listed one per line with
      their amounts; several acquired accounts are numbered with a Total. Line breaks are
      GSM-7, so each part stays 160 characters. Builders: `collection_sms_service.dart`.
      See [SMS formats](#sms-formats) for every message.
- [ ] 29. Add Outbox SMS sending in Settings. There is no SMS outbox today; sends go through
      an in-memory queue in `collection_sms_service.dart`. Settings already has the
      Signature, Image and Collection Upload outboxes.

## Contact Directory

- [ ] 30. Add Sir Alex to the contact directory. **Need:** contact details. Contacts are
      added in the app (Settings → Contact Directory); this may need no code.

## Bug Fixes

- [x] 31. Fix dark mode in the mdmpi-app collection. (`63c6d70`) The app follows the phone's
      light/dark setting, but only the light Collection theme was installed, so a dark phone
      drew Collection's white cards and fields on the app's black theme. Collection now has a
      dark palette and theme (`BCollectionPalette.dark`, `BCollectionTheme.dark` in
      `collection_theme.dart`); light renders unchanged. Settings follows it too. Logistics is
      unaffected.
- [x] 32. Fix printer for users. Done in `32b50ce` (Collection: Print the Calendar month as a
      PDF for reimbursement).
- [x] 33. Debug advanced payment. Done (confirmed 2026-10-20).

## Outside the checklist

- [x] Reconciliation invoices stuck outside the Tracker (raised 2026-10-20, `63c6d70`).
      Invoices marked "Reconciliation" with no tracker case: marked before the Tracker
      existed, or while the server held their case back. Acquiring them moved them to the
      collector's Activity and took over no case, so they were in neither the bucket nor the
      Tracker. Changed:
  - Any invoice the collector **holds** that is marked Reconciliation but in no case gets a
    case opened, one per account, on load, download and acquire
    (`openMissingReconCases` in the controller, `openMissingCases` in
    `reconciliation_repository.dart`). Only the holder's phone does it, so two phones never
    open a case for the same account (the server allows one open case per account).
  - Acquiring a reconciliation account always lands on a case.
  - A paid-off invoice shows "Settled · Tracker" on the case timeline (`timelineEntries` in
    `recon_case_screen.dart`). Nothing is uploaded for it; every phone works out the same
    line. The invoice list keeps "Cleared" / "Validated paid".
  - Limits: an account that already has an open case does not take extra marked invoices
    (a case cannot add invoices); invoices of an ended case are left alone; an auto-opened
    case is un-uploaded work, so Download asks for Upload All first.
  - **Open:** if the production server lacks the Tracker tables
    (`migration_20260928_add_collection_reconciliation.sql`), it holds every case back
    ("Reconciliation is not available on the server yet"). Check that it ran.
- [x] Light/Dark toggle on Collection Home (requested 2026-10-20, `63c6d70`). A sun/moon
      button in the Home header's upper right (`theme_mode_toggle.dart`). The choice is kept
      on the phone (`collection.themeMode`) and beats the phone's setting; until the collector
      first taps it, Collection follows the phone. Logistics is unaffected.

## SMS formats

Every message goes to the Head and the Collection contacts, except Reconciliation escalated
(Head only). The collector's initials close each one (`- MAR` below). Amounts are
"PHP 1,234.56", never "₱" (one peso sign would cut each SMS part from 160 characters to 70).

1. **Acquiring Account** (one account; reconciliation lists every number):

   ```
   Now handling: Abbott Laboratories
   1 PO, 1 invoice
   Balance: PHP 112,000.00
   - MAR
   ```

   ```
   Now handling for reconciliation: Amka Trading
   POs: 1, 2, 3, 4, 5
   Invoices: a, b, c, d, e
   Balance: PHP 118,139.87
   - MAR
   ```

   Several accounts in one acquire make one numbered message:

   ```
   Now handling 3 accounts
   1. Alexis Yu Best Care Pharmacy
   5 POs, 6 invoices, PHP 95,198.18
   2. Ace Diagnostics Corp.
   1 PO, 1 invoice, PHP 20,000.00
   3. Accuteqs Diagnostics Corp.
   4 POs, 6 invoices, PHP 155,972.41
   Total: PHP 271,170.59
   - MAR
   ```

2. **Saving Engagement** (Collected or Partially Collected only):

   ```
   Collected: Accusure Medical Enterprises
   Amount: PHP 121,208.04
   Invoice: 700013392
   PO: 2026-0328
   Check: BDO 4588255, dated 09-28-2026
   - MAR
   ```

   ```
   Partial payment: Metro Globe
   Amount: PHP 6,251.50
   Invoices:
   700011347 - PHP 6,001.00
   700011348 - PHP 250.50
   PO: PO-88
   - MAR
   ```

3. **Defer Account:**

   ```
   Postponed: Metro Globe
   Reason: Follow Up - Signatory out
   - MAR
   ```

4. **Clear Engagement:**

   ```
   Done: Metro Globe
   - MAR
   ```

5. **Adding Deposit** (Check and Note lines left out when blank):

   ```
   Deposited: PHP 526,664.00
   Bank: BDO
   Check: 1254897
   Note: Morning run
   - MAR
   ```

6. **CWT Pick-Up:**

   ```
   Picked up CWT: Bacolod Adventist
   Note: 2307 picked up
   - MAR
   ```

7. **Reconciliation escalated** (Head only):

   ```
   Reconciliation escalated: Allied Care Experts (ACE) Medical Center - Bohol, Inc.
   Open: 1 invoice, PHP 276,995.00
   Reason: No proof after three follow-ups
   - MAR
   ```

## Waiting on information

- Item 19: whether Deposit / Advanced Payment / CWT need a photo section.
- Item 30: Sir Alex's contact details.
