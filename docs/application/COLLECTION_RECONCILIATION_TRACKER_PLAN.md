# Collection: Reconciliation Tracker

**Status:** Stages 0–5 committed (1b2b321); revision 1 (2026-10-08) in progress; backend not yet deployed · **Started:** 2026-09-28

**Process flow:** [COLLECTION_RECONCILIATION_CASE_FLOW.html](COLLECTION_RECONCILIATION_CASE_FLOW.html)
(open in a browser): every step on the Log sheet, whose turn it creates, and the three endings.

## Why

Reconciliation is a back-and-forth between the Collector and the Account (client) to agree
what is still unpaid. It can take many rounds. Until now the app had one step for it: mark
invoices `Reconciliation` in the Calendar, and acquire them later from the Reconciliation card.
The Tracker logs every step of every round, sets the statuses itself, and always shows the
account's **last activity** before the collector takes the next step.

## Decisions (2026-09-28)

| Question | Decision |
|---|---|
| Platform | In the Collection module plus MDMPI.App (`/api4`) |
| No-response limit | 7 days |
| Proof validated by | The Collector |
| Escalated to | The Collection Head (Settings → My Head), by SMS |
| NOT COMPLETED | Open invoices stay under Reconciliation; to continue, start a **new** case (no reopen) |
| Who logs | Any collector currently holding the account; the case follows the account on acquire |
| Who sees | Every open case goes to every phone (2026-10-08): the next collector to visit the account sees where it stands. Closed cases stay with whoever held, pooled or worked on them |
| Step 9, "send to Accounting" | A "Validated, awaiting posting" list |
| Attachments | Photos in v1 (proof of payment, documents) |

Defaults, to change if the team says otherwise:
- No response counts only while waiting on the Account, flagged from day 7 (7 or more days).
- "Claimed paid, no proof" is flagged only after a proof request.
- Escalation ends the case as ESCALATED; the Head takes it on outside the app.
- Invoices that fall due mid-case are not added to it automatically.
- The SOA amount defaults to the sum of the case's open invoices, and can be edited.

## Data

The status is **worked out from the activity log**. What is stored is the case header, the
invoices fixed when the case opens, and an activity log that is only ever added to. Case status,
invoice status, who acts next and flags come from one pure function, `evaluateReconCase()`
(`lib/features/collection/helpers/reconciliation/recon_rules.dart`). The status columns on the
case are a cached copy for sorting and reports, recalculated on every write.

- **Case:** case_id (`RC-<collector>-<micros>`), account code and name, collector (the current
  holder), date opened and closed, SOA date and amount, and the cached case status, next actor,
  last activity and is-open flag. There is one open case per account.
- **Invoices per case:** invoice no., amount (fixed at opening), current balance and cleared-at
  (from the server), and the invoice status OPEN · CLAIMED PAID · PROOF INVALID · VALIDATED PAID ·
  CLEARED, which is calculated, not stored.
- **Activity log:** activity_id (`RA-<collector>-<micros>`), case, date and time, done by
  (fixed by the type), type, invoice nos., remarks, amount (SOA only), validation result
  (PROOF_VALIDATED only), next action and its due date, attachment refs, recorded by.
- **Attachments:** attachment_id, activity, the photo itself and its upload status.

## Rules

Activity types and who does them:

| Type | Done by | Effect on invoices |
|---|---|---|
| SOA_SENT | Collector | none (records the SOA date and amount); the SOA stage |
| FOLLOW_UP | Collector | none; the Follow up stage (after an SOA; repeatable) |
| COLLECTION_LETTER_SENT | Collector | none; the Collection letter stage (after a follow up; needs a photo; repeatable) |
| DOCUMENT_REQUESTED | Account | none |
| DOCUMENT_PROVIDED | Collector | none |
| PAID_CLAIM | Account | named OPEN / PROOF INVALID invoices → CLAIMED PAID |
| PROOF_REQUESTED | Collector | named (or all claimed without proof) → proof requested |
| PROOF_PROVIDED | Account | named (or all claimed without proof) → proof pending; an unclaimed one counts as claimed |
| PROOF_VALIDATED | Collector | valid → VALIDATED PAID; invalid → PROOF INVALID (stays open) |
| NOTE | Collector | none; does not change whose turn it is |
| CASE_NOT_COMPLETED | Collector | ends the case |
| CASE_ESCALATED | Collector | ends the case; texts the Head |
| PAYMENT_RECORDED | Tracker | none; logged when a collection is saved on a case invoice (the balance comes from the invoice) |
| CASE_RELEASED | Tracker | none; logged on Done Engagement / Defer by the holder: the case has no holder until acquired |
| CASE_ACQUIRED | Tracker | none; logged when a collector acquires the account from Reconciliation: they hold the case |

The three Tracker steps are logged by the app, never picked on the log sheet. They do not
change whose turn it is, do not restart the No-response wait, and do not clear the Next-action
due date (which comes from the collector's own latest step). On the phone a case shows each
invoice's live balance, so a payment counts before it is uploaded (2026-09-28).

An invoice whose balance the server reports as 0 without a validation (paid outside the case) is
CLEARED.

Case status, the first rule that applies:
1. Ended by the collector → NOT COMPLETED / ESCALATED.
2. Every invoice VALIDATED PAID or CLEARED → COMPLETED (automatic).
3. Proof received and not yet validated → UNDER VALIDATION.
4. The last conversation activity was by the Collector → WAITING FOR ACCOUNT; by the Account →
   WAITING FOR COLLECTOR.
5. No activity yet → WAITING FOR COLLECTOR ("Send the SOA").

Stages (case-level, Revision 2): **SOA → Follow up → Collection letter**, in that order. They run
beside the invoices' claim → proof → validate chain and never decide the case status, flags or
closing. A stage is done once its step is logged after the stage before it is done; each step may
be logged again (a re-issued SOA replaces the SOA date and amount; a second letter is a final
demand). A stage step logged out of order (an offline replay) stays on the timeline and takes the
collector's turn, but is not counted and is reported under "Not applied". Follow ups and letters
are collector conversation steps: the case waits on the Account and the No-response wait is not
restarted.

Flags (open cases only):
- **No response:** waiting for the Account for 7 or more days, counted from the first collector
  activity after the Account last acted.
- **Claimed paid, no proof:** proof was requested after the claim and none has come.
- **Next action overdue:** the latest activity's next-action due date is before today. A blank
  date never raises it.

Blocked, by `canAppendReconActivity()`: invoice numbers that aren't in the case, an empty paid
claim, validating when no proof is pending, a follow up before any SOA, a collection letter
before any follow up or without a photo, and any activity once the case has ended.

Days are Philippine calendar days (+08:00) on every device. Aging of open cases runs from the
date opened: 0–7, 8–15, 16–30, 31+ days.

The invoice status `Reconciliation` stays the marker for "in a case": it keeps the invoice out of
the regular bucket (`isReconciliation` in `collection_activity_controller.dart`) and lets it be
acquired from the Reconciliation card.

## Stages

- [x] **0. This document.**
- [x] **1. Pure rules, sample data, tests** (2026-09-28, 57 tests; each status rule has its own). `models/reconciliation/`,
  `helpers/reconciliation/` (rules, validator, clock, summary),
  `test/fixtures/reconciliation/sample_cases.json`, and `test/features/collection/reconciliation/`.
- [x] **2. Backend** (2026-09-28, code and 20 tests in MDMPI.App; **not deployed**). Safe in
  either order: until `migration_20260928_add_collection_reconciliation.sql` has run, uploads
  and the workspace skip the Tracker and its steps are refused (they wait in the outbox). A migration for 4 tables, entities, `RECON_OPEN_CASE` / `RECON_ACTIVITY`
  upload ops (idempotent, one open case per account), the C# rules port checked against the same
  sample file, `ReconCases` in the workspace, and a photo endpoint. **Deploy before any phone build
  that queues these ops.**
- [x] **3. Phone data layer** (2026-09-28, 28 tests). Tables `a_tblCollectionRecon*` in
  `ensureCollectionTables`; `ReconCaseDao` (case, invoices and log, written together) and
  `ReconAttachmentDao`; `ReconCaseMapper` and `hasReconCases` in the workspace parser;
  `ReconciliationRepository` (Result, checked by the rules, queued as RECON_OPEN_CASE /
  RECON_ACTIVITY); `ReconAttachmentSyncService` (photo outbox). A download keeps every step not
  yet uploaded. Nothing uses it on screen yet.
- [x] **4. Screens** (2026-09-28, 17 widget tests). Home → Reconciliation opens the dashboard
  (`/collection/reconciliation`: my cases, oldest last activity first, with status, flags, whose
  turn, open amount; a link to accounts waiting to be acquired). The case screen
  (`/collection/reconciliation/case`) leads with the last activity (Step 1), then invoices and the
  timeline, newest first. The log sheet offers only the steps the rules allow, grouped by who did
  them, with invoices, valid/invalid, SOA amount, remarks, next action and due date, and photos
  (camera on Android, gallery on both); ending a case asks first. Calendar → Reconciliation now
  opens a case and goes to it. "Upload All" flushes the photo outbox.
  Not yet: photos taken on another phone show as placeholders (the server has them).
- [x] **5. Reports and escalation** (2026-09-28, 11 tests). Dashboard → Reports
  (`/collection/reconciliation/reports`): the Summary (total, open, completed, not completed,
  escalated, amount under reconciliation, amount validated paid) and the Aging of open cases
  (0–7, 8–15, 16–30, 31+ days from opening). A collector sees their own cases; the Head sees every
  case on the phone. **Validated, awaiting posting**: each invoice validated paid whose balance
  has not reached zero, with when it was validated and the proof (remarks, photo count); it
  leaves the list once Accounting posts it. Escalating a case texts the Head alone (not the
  Collection contacts): `Reconciliation escalated: [Client]. 1 open invoice, PHP [amount].
  Reason: [remarks]. - MAR` (Android; on Windows the escalation is logged without a text).
- [x] History of closed cases: the workspace download also carries cases the collector logged a
  step on (whoever holds them now), so a paid case stays with everyone who worked it. The
  dashboard lists them behind the **Open / Closed / All** filter (Open by default; closed ones
  newest first, with the closing date). An open case they worked on that someone else holds now
  is not theirs.
- Later: the Accounting list on the collection admin web.

## Revision 1 (2026-10-08)

- [x] **Every open case on every phone.** `GetReconCasesForWorkspaceAsync` (MDMPI.App) sends
  every open case, whoever holds it; closed ones keep the old rule (mine, pooled, or worked on,
  since the cutoff). **Needs a backend deploy** with the Stage 2 migration. On the phone the
  dashboard and the reports have a **My cases / Team** switch (`ReconScope`); a collector starts
  on My cases, the Head on Team. Team cards say who holds the case ("Held by …", or "No holder ·
  waiting to be acquired"). Only the holder logs: on someone else's case the Log button reads
  "Held by … · acquire to log" (`ReconciliationController.canLog`); a released case reads
  "Acquire the account to log a step". The case itself stays readable.
- [x] **Reports enhanced.** Summary adds the open cases by whose turn (one bar, three legends).
  **Needs attention**: the flag counts and the flagged open cases, each leading to its case.
  **Aging** shows the amount per bucket, and a bucket opens to its cases. **Who holds what**
  (Team only): open, flagged, closed and amount per collector (`reconByCollector`). Validated,
  awaiting posting is unchanged.
- [x] **Log a step eases in.** The step's fields grow in and change over in one motion
  (`AnimatedSize` + `AnimatedSwitcher`) instead of the sheet jumping; the error line too.

## Revision 2 (2026-10-09): stages SOA → Follow up → Collection letter

From the Collections meeting of 2026-10-07 (To-Update List, item 3).

- [x] **Rules.** `ReconStage` (`recon_enums.dart`) and `ReconStageProgress` /
  `ReconEvaluation.stages`, `currentStage`, `stageUnlocked` (`recon_evaluation.dart`), counted in
  `evaluateReconCase`. `reconStageLockReason` and the stage checks in `canAppendReconActivity`
  (`recon_validator.dart`); `ReconActivityDraft.attachmentCount`. No schema change: the new types
  are new codes in the existing `type` column. Two sample cases added to
  `sample_cases.json` (`expected.stages` keyed by step wire code, `expected.currentStage`).
- [x] **Screens.** The case screen shows the stage track (done with date and ×count, current
  ringed, later ones locked); tapping an unlocked stage opens the log sheet on its step. The log
  sheet shows locked stage steps as disabled chips with the reason; the letter says its photo is
  required. The Step 1 hint follows the stage while waiting on the Account.
- [ ] **Backend (MDMPI.App, not edited).** Deploy before a phone build that can queue the new
  codes; until then they are refused and wait in the outbox, and older phones drop them on
  download.
  - Accept `ActivityType` `FOLLOW_UP` and `COLLECTION_LETTER_SENT` on the `RECON_ACTIVITY` op
    (no new op, no new payload fields; `DocumentIds` empty, `ReconAmount` and
    `ValidationResult` null). Widen the `ActivityType` column to at least 24 characters in the
    undeployed migration if it is narrower (`COLLECTION_LETTER_SENT` is 22), and add both codes
    to any whitelist or CHECK constraint.
  - Rules port: both are collector conversation steps naming no invoices. Count stages exactly
    as `evaluateReconCase`: a follow up with no earlier SOA adds the warning
    `<activityId>: follow up before any SOA, not counted`; a letter with no earlier counted
    follow up adds `<activityId>: collection letter before any follow up, not counted`. Stages
    never change status, flags or closing. Run the two new fixture cases.
  - Upload checks (mirror `canAppendReconActivity`, ordered by stored `DateTime`, ties by
    `ActivityId`, not by arrival): `FOLLOW_UP` needs an earlier `SOA_SENT`;
    `COLLECTION_LETTER_SENT` needs an earlier `FOLLOW_UP` and a non-empty `AttachmentIds` (ids,
    since the photo upload may come after the op). A retried op with a known `ActivityId` still
    succeeds.
- Later: a PDF letter (attachments are JPEG-only today: the file name, the photo upload's content
  type and the case screen's photo lookup), and a "sent on" date separate from the log time.
