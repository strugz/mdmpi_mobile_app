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
| Done | 20 |
| Already in the app before this round | 3 |
| Partly done | 1 |
| Held back | 0 |
| Not started | 9 |
| **Total** | **33** |

Plus two changes not on the checklist: reconciliation invoices stuck outside the Tracker,
and a Light/Dark toggle on Home (see [Outside the checklist](#outside-the-checklist)).

## By status

The same 33 items grouped by where they stand. The number is the item's number in the
sections below, where its details are. Keep both views in step when an item moves.

### Done (20)

| # | Item | Area | Commit |
|---|---|---|---|
| 10 | Make Cheque number optional | Deposit | `63c6d70` |
| 11 | Make Remarks required | Deposit | `63c6d70` |
| 14 | Chips on Remarks (Machine, Reagents, Hold accounts) | Advanced Payments | `63c6d70` |
| 17 | Invoice picking: "Select all" | Reconciliation | `63c6d70` |
| 18 | Invoice picking: PO/SI | Reconciliation | `63c6d70` |
| 28 | SMS message format | SMS | `d049a33` |
| 31 | Dark mode in Collection | Bug Fixes | `63c6d70` |
| 32 | Printer for users | Bug Fixes | `32b50ce` |
| 33 | Debug advanced payment | Bug Fixes | — |
| 7 | Routing of Documents: Accounts and Remarks flow | New Activity | `e0810f1` + MDMPI.App `1ed776e` |
| 8 | Card for pre-collection | Pre-collection | `4cda9c8`, `94da5f0` + MDMPI.App `052a37a` |
| 12 | Account selected by search | Deposit | Deposit accounts commit |
| 13 | Remarks format, one per line: Account - Amount | Deposit | Deposit accounts commit |
| 29 | Outbox SMS sending in Settings | SMS | SMS Outbox commit |
| 16 | Temporary account for advanced payments | Advanced Payments | Temporary account commit + MDMPI.App `5c6e092` |
| 26 | Reconciled list: "Cleared" / "Open" instead of "Closed" | Reconciliation | Reconciliation bucket commit |
| 22 | Keep reconciled accounts in the collection bucket | Reconciliation | Reconciliation bucket commit |
| 27 | Remove "accounts waiting to be acquired" | Reconciliation | Reconciliation bucket commit |
| 25 | Collected through the bucket: move to Settled, remove from Reconciliation | Reconciliation | Reconciliation settled commit |
| 24 | Reconciled invoices pickable by specific invoice | Reconciliation | Pick invoices commit |

### Already in the app before this round (3)

| # | Item | Area |
|---|---|---|
| 9 | Make Bank required | Deposit |
| 15 | Advanced payments visible to all users | Advanced Payments |
| 19 | Multiple pictures in the photo section (Log a step sheet) | Reconciliation |

### Partly done (1)

| # | Item | Area | What is missing |
|---|---|---|---|
| 21 | Log step "Settled", then the user chooses an invoice | Reconciliation | A step the collector picks by hand (needs a backend change) |

### Held back (0)

None. Item 27 was held until 22; both are done.

### Not started (9)

| # | Item | Area |
|---|---|---|
| 1 | Actual Collection: daily entry in Post Actual Collection | Web App |
| 2 | Actual Collection: Reference no. optional | Web App |
| 3 | Targets: different target amount per area | Web App |
| 4 | Dashboard for reviewing all data | Web App |
| 5 | Dashboard: actual target for a selected area | Web App |
| 6 | Dashboard: actual target for all areas combined | Web App |
| 20 | Individual remarks per invoice | Reconciliation |
| 23 | Log activities on other invoices and some reconciled ones | Reconciliation |
| 30 | Add Sir Alex to the contact directory (details pending) | Contact Directory |

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

- [x] 7. Set up flow: Accounts and Remarks (for tracking of activity only). **Done (confirmed
      2026-10-20): phone `e0810f1`, MDMPI.App `1ed776e`.** "Routing of Documents" is on
      the Add field engagement sheet (`routing_documents_form.dart`): one account picked
      from the registry and required Remarks. It is the collector's activity (never counted
      as collected), listed under its own history filter, and texts the Head and Collection
      contacts: "Routed documents: [Account]" / "Note: [Remarks]". It uploads as
      `ROUTING_DOCUMENTS`, an account-level operation added to MDMPI.App (branch
      `collection/routing-documents`): saved as an activity like CWT Pick-up, returned in the
      workspace, activity-only in team reports, and its own legend on the printed calendar.
      An older server answers "Unknown operation" and the row waits in the outbox, so
      MDMPI.App must carry `1ed776e` wherever this app version runs.

## Pre-collection

- [x] 8. Create a card for pre-collection. **Done (confirmed 2026-10-20): phone `4cda9c8`,
      `94da5f0`; MDMPI.App `052a37a`.** `migration_20261020_add_collection_engagement_check.sql`
      must run on the server BEFORE the MDMPI.App build with `052a37a` is deployed.
  - What Pre-Collection is: information for the next scheduled collection. The collector
    records the amount to collect and, when it is a check, the bank, check number and check
    date (the check date is when to collect). It settles nothing: the balance stays, nothing
    counts as collected, and no payment is created.
  - Before this, a Pre-Collection with an amount was treated as a payment: the phone took it
    off the balance and counted it in Collected this Month, and the server created a payment
    and allocation for it. Fixed on both sides (`CollectionOutcome.appliedAmount` on the
    phone; `IsPreCollection` in `CollectionInvoiceRepository.cs`). Typing the amount no longer
    switches the outcome to Collected or Partial; the form reads "Amount to collect" and says
    the balance stays.
  - The server keeps a Pre-Collection's check on the engagement (new `bankname`, `checkno`,
    `checkdate` columns; a collection's check stays on its payment) and returns it in the
    invoice history. Team reports treat Pre-Collection as activity only.
  - The card: a fifth card on Collection Home, alone on a third row at the same size as the
    other four. It counts open invoices whose last outcome is Pre-Collection, acquired or
    back in the bucket, following Filter by Area (an invoice marked for reconciliation is
    left to that card). Tapping it lists the accounts like Past Due; each invoice shows
    "Next collection: ₱50,000.00 · Check BDO 1234567, dated 10-25-2026".
  - Acquiring: an account with a Pre-Collection invoice back in the bucket shows
    **Acquire Account** on the Pre-Collection page; it takes the account as the bucket's own
    Acquire does (its open invoices, with the Acquiring SMS). In the Collection Bucket a
    Pre-Collection invoice is a regular one, so it is listed and bulk-acquired with the
    ticked accounts as before.
  - Limits: a deferral replaces the outcome on the server, so a deferred invoice leaves the
    card at the next download, not at once. Pre-Collections saved before this change that
    carried an amount already have a payment on the server; the phone no longer counts them
    as collected.

## Deposit Process

- [~] 9. Make Bank required. **Already required** (`deposit_form.dart`, `BBankField`).
- [x] 10. Make Cheque number optional. Label reads "Check Number (optional)". The deposit SMS
      leaves a blank cheque out. (`63c6d70`)
- [x] 11. Make Remarks required. "Remarks are required"; blank or spaces-only is refused.
      (`63c6d70`)
- [x] 12. Account is selected by search. **Committed (Deposit accounts change).** Record Deposit has an
      Accounts section: "Add account" opens the client search; each pick adds a line with its
      own amount (an account is listed once; × removes it). At least one account is required.
      The Amount fills with the lines' total until typed by hand; if it then differs, the form
      says what the accounts add up to. The deposit is still recorded against no account and
      settles no invoice (no server change).
- [x] 13. Remarks format, one per line: Account - Amount. **Committed (Deposit accounts
      change).** The
      remarks are written from the lines (`BDepositRemarks`, `deposit_remarks.dart`), shown on
      the form as they will be saved, with an optional note last:
      `Antipolo Doctors Hospital - 25,000.00` / `Ace Diagnostics Corp. - 5,000.00` /
      `Note: Morning run`. The form refuses more than the 500 characters the server keeps
      (about a dozen accounts). The deposit SMS shows each line, in PHP.

## Advanced Payments

- [x] 14. Add chips to the Remarks field (Machine, Reagents, Hold accounts). A chip adds its
      word to Remarks as a comma-separated list; tapping it again takes it out. More chips can
      be added in `advancedPaymentRemarkChips` (`advanced_payment_form.dart`). (`63c6d70`)
- [~] 15. Make advanced payments visible to all users. **Already shared by the server**: the
      workspace returns every unallocated advance, whoever recorded it
      (`CollectionInvoiceRepository.cs:996-1045`). Other phones see a new one only after it
      is uploaded and they download again.
- [x] 16. Allow users to add a temporary account for advanced payments. **Done (2026-10-20): phone
      temporary account commit + MDMPI.App `5c6e092`; needs MDMPI.App deployed.** On Record Advanced Payment, "Not in the
      list? Use a temporary account" asks for the account's name (name only) and records the
      advance under a phone-made code `TMP-<collector>-<yyyyMMddHHmmss>`
      (`temporary_account.dart`). The server registers it under that name. On Home → Advanced
      Payment the advance reads "Temporary account · link to apply" and offers **Link to
      account** instead of Apply: the collector picks the real account by search and the
      advance moves there (phone now; server with the next upload, `LINK_ADVANCE`). It cannot
      be applied to an invoice until linked (blocked on the phone; the server refuses it
      too), and an applied advance can no longer move. A temporary account has no area, so
      it shows under every area. MDMPI.App: `ClientName` on the upload change,
      `LINK_ADVANCE`, `IsTemporaryAccount` (`CollectionInvoiceRepository.cs`); an older
      server answers "Unknown operation" to a link and keeps it in the outbox.

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
- [x] 22. Keep reconciled accounts in the collection bucket (reconciliation works like a
      status, not a removal). **Done (2026-10-20, Reconciliation bucket commit).** An invoice marked Reconciliation
      stays in the bucket with its account, with its "Reconciliation" badge, and counts in
      the account's invoices and the Collection Bucket button
      (`isRegularBucketInvoice` in `collection_activity_controller.dart`). Acquiring the
      account, alone or ticked with others, takes it with the rest and brings the
      account's open case along: taken over from whoever held it, or opened when there is
      none. An invoice whose case ended unpaid (escalated, not completed) is an ordinary
      bucket invoice again; ended cases are not reopened.
- [ ] 23. Let collectors log activities on other invoices plus some of the reconciled
      invoices. Today only the case holder logs (`canLog` in `reconciliation_controller.dart`).
- [x] 24. Keep reconciled invoices pickable by specific invoice. **Done (2026-10-20, Pick invoices
      commit).** On an account's page in the bucket, a long press on an invoice
      starts picking and a tap adds or removes one; the button then reads "Claim N
      Invoices" and takes only those, leaving the rest in the bucket ("Clear" goes back to
      the whole account). A reconciled invoice among the picks brings the account's case
      along, as acquiring the whole account does (`claimInvoices` in
      `collection_activity_controller.dart`). The server already claims per invoice, so
      MDMPI.App needs no change. (`claimReconciliation` is no longer reached from any
      screen since item 22 moved Home → Reconciliation to the Tracker.)
- [x] 25. When a reconciled invoice is collected through the collection bucket, move it to
      Settled and remove it from Reconciliation. **Done (2026-10-20, Reconciliation
      settled commit).** Paid in full through the bucket (one invoice or a batch), it becomes
      Collected: no Reconciliation badge, out of the Reconciliation list and the Home
      count, back in the bucket as settled, with the "Settled · Tracker" line on its case
      timeline; the case completes when every invoice is paid. Partly paid, it stays a
      Reconciliation invoice. One rule decides this for the screen and the copy saved on the
      phone (`CollectionOutcome.statusAfterPayment`); the saved copy used to drop the
      Reconciliation mark on a partial payment, so the badge vanished after a reload.
      MDMPI.App needs no change: its upload recomputes the balance and sets the invoice to
      Collected when it reaches zero, so the next download does not bring "Reconciliation"
      back.
- [x] 26. In the reconciled list, show settled invoices as "Cleared" (not "Closed") and the
      rest as Open (e.g., 3 invoices, 1 settled: 1 Cleared, 2 Open). **Done (2026-10-20, Reconciliation bucket
      commit).** Each case card on the Reconciliation dashboard now counts its invoices as
      "1 Cleared · 2 Open" (settled = validated paid or cleared), on open and ended cases
      alike. An ended case's date reads "Ended <date>" instead of "Closed <date>"
      (`recon_dashboard_screen.dart`). The Open / Closed / All filter is unchanged: it sorts
      cases, not invoices.
- [x] 27. Remove the "1 account waiting to be acquired" item. **Done (2026-10-20, Reconciliation bucket
      commit).** Gone from the Reconciliation dashboard (`recon_dashboard_screen.dart`);
      the bucket acquires those accounts now (22).

## SMS

- [x] 28. Fix the SMS message format so receivers can understand each SMS more easily.
      (`d049a33`) Every message now leads with what happened and to whom on the first line
      (so the notification preview still says it), then one labelled line per fact, and the
      collector's initials on the last line. Several invoices are listed one per line with
      their amounts; several acquired accounts are numbered with a Total. Line breaks are
      GSM-7, so each part stays 160 characters. Builders: `collection_sms_service.dart`.
      See [SMS formats](#sms-formats) for every message.
- [x] 29. Add Outbox SMS sending in Settings. **Committed (SMS Outbox commit).** Revised on
      2026-10-20 to background sending (feature request "Background Automated SMS Delivery &
      Daily Outbox Reset"):
  - Every Collection SMS is saved to the SMS Outbox (`a_tblCollectionSmsOutbox`,
    `collection_sms_outbox_dao.dart`) and sent from it **in the background, one message and
    one recipient at a time**. No sending view, no "Message Sent!", no warning dialogs, no
    Messages-app hand-off: the collector's screen closes with its usual "Saved" message and
    the work goes on.
  - **Retries by itself:** a message the phone could not send (no signal, no SIM, SMS
    permission off) is tried again after 1, 2, 5, 10, then every 15 minutes, up to 10 tries,
    while the app runs; anything left waiting goes out when the app next opens or comes back
    to the front. A message the phone accepted but never confirmed is **not** sent again by
    itself (it could text the Head twice); the phone now has 30 seconds to confirm (it was 3
    while the screen waited).
  - **SMS permission:** Android's own prompt, at most once per app run (again when the app
    comes back to the front). Refused, the messages wait in the Outbox with "SMS permission
    is off".
  - **Daily reset:** the Outbox shows the day's messages. At 00:00 (and at start-up) the
    previous days' sent messages are cleared; ones not sent yet stay until they go out or
    are discarded.
  - Settings → **SMS Outbox** (Android): "Not sent yet" first (Sending, Retrying · try N,
    Failed, Not confirmed, Nobody to text) with **Send now** (every original number not
    confirmed) and **Discard**, and **Send all now**; then "Sent today". The Settings row
    says how many are not sent yet.
  - **Resend a sent SMS:** each message under "Sent today" has **Resend**. After asking, it
    sends the same text again to all its original recipients, in the background (e.g. the
    Head says it never arrived); a number that fails this time is retried by itself. Shows
    "Last sent" once a message has gone more than once.
  - The outbox can never stop a message: if it cannot be written, the SMS is sent once,
    quietly, as before.
  - Limit: sending runs while the app is running (open or in the background); a phone that
    has closed the app sends what is waiting the next time it opens.

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
   Check: BDO 4588255
   Check Date: 09-28-2026
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

5. **Adding Deposit** (each account on its own line; Check and Note left out when blank):

   ```
   Deposited: PHP 30,000.00
   Deposited At Bank: BDO
   Check: 1254897
   Antipolo Doctors Hospital - PHP 25,000.00
   Ace Diagnostics Corp. - PHP 5,000.00
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

8. **Routing of Documents:**

   ```
   Routed documents: Antipolo Doctors Hospital
   Note: SOA and 2307 delivered
   - MAR
   ```

## Waiting on information

- Item 19: whether Deposit / Advanced Payment / CWT need a photo section.
- Item 30: Sir Alex's contact details.
