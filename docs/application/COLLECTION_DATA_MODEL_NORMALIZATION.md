# Collection Data Model — Normalization Design

**Date:** 2026-09-15 · **Status:** APPROVED — staged A→D; recommendations accepted (cache columns, payment-without-allocation, `payment.depositid`). Stages A and B done.
**Scope:** PostgreSQL schema behind `/api4/Collection/*` (`MDMPI.App`), and the mobile
persistence it must serve. Companion to `COLLECTION_PROCESS_FLOW_AND_NARRATIVE.docx`,
`COLLECTION_IMPLEMENTATION_REVISION.md` and `mdmpi_collection_web/docs/SAP_AR_IMPORT_PLAN.md`.

---

## 1. The question

> "Collection only has `a_tblcollectioninvoice` and `a_tblcollectionengagement`. The
> invoice table has many columns — can it be normalized, or is it safe as is? All the
> payment computation for each invoice hangs off it."

**Short answer.** The current schema is a deliberate *minimal mirror of what the mobile app
persisted to SQLite* (invoice + history). It is **safe for the core loop** — download →
acquire → record → settle → upload — and it is what let us ship an end-to-end offline
workflow quickly. It is **not complete or normalized enough** for everything the mobile
design computes about payments, and it has one real modelling defect (§3, P1). The gaps
are fixable **without breaking the mobile app**, because the mobile only sees a JSON
contract that the server can keep stable while normalizing underneath (§5).

---

## 2. What the mobile design actually models

The app has more concepts than two tables. Several exist today **only in memory** on the
phone (lost on restart) and therefore never reached the server:

| Concept | Mobile source | Persisted on phone? | On server? |
|---|---|---|---|
| Invoice (receivable) + running balance | `CollectionItemModel` | ✅ SQLite | ✅ `a_tblcollectioninvoice` |
| Engagement / visit outcome ("history") | `CollectionHistoryModel` | ✅ SQLite | ✅ `a_tblcollectionengagement` |
| Client / account | `ClientModel` (embedded) | ✅ (per invoice) | ✅ `a_tblcollectionclient` |
| **Deposit** (bank deposit → feeds *Actual Collection*) | `saveGlobalActivity(type:'Deposit')`, `invoiceId: null` | ❌ in-memory | ❌ *cannot* upload — engagement needs a `documentid` |
| **CWT Pick-up** (per account) | `saveGlobalActivity` | ❌ in-memory | ❌ |
| **Reconciliation** (marks invoices) | `saveGlobalActivity` + invoice status | ❌ in-memory (status only on invoice) | partial |
| **Advanced Payment** (payment with no invoice yet; later `assignInvoiceToPayment` *creates* the invoice) | `unassignedAdvancedPayments` | ❌ in-memory | ❌ no home |
| **Defer / Clear** (account-level release + reason) | `clientHistory[clientId]` | ❌ in-memory, **not queued** | ❌ (upload op exists, never sent) |
| **Monthly Target** | `TotalCollectedController.targetAmount` | ❌ in-memory | ❌ |
| One cheque paid across several invoices (**Batch**) | `saveBatchActivity` | ✅ as *N* history rows | ✅ as *N* engagement rows (bank/cheque repeated N times) |

Two monthly figures the app computes, and what they *should* derive from:

- **Total Collected (month)** = Σ amounts collected against invoices → *payments*.
- **Actual Collection (month)** = Σ **Deposits** in the month, compared to **Target**.

---

## 3. Problems with the current `a_tblcollectioninvoice` (25 columns, 5 concerns)

```
identity      : collectioninvoiceid, documentid
client snapshot: clientid, clientcode, clientname, clientaddress, clientcontact,
                 clientemail, bpcode, collectorname            ← now duplicates a_tblcollectionclient
invoice master : documentreferences, documentdate, postingdate, duedate, remarks
payment state  : tobecollected, totalcollected, status, lastoutcome, bankname   ← derived / misplaced
workflow       : assignedto, assignedat
audit          : createdat, updatedat, updatedby
```

| # | Problem | Why it matters |
|---|---|---|
| **P1** | **No `originalamount`.** `tobecollected` is mutated in place on every payment. | After the first payment the SAP *Balance Due at import* is gone from the row. "Invoice was 112,000, collected 50,000, balance 62,000" is only reconstructable by summing engagements — fragile, and impossible if any engagement is discarded. This is the one genuine defect. |
| **P2** | **Payment is not a first-class entity.** A cheque covering 3 invoices = 3 engagement rows each repeating bank / cheque no. / cheque date. | Can't answer "what did cheque #123 total?", can't reconcile which cheques were **deposited**, can't model an advance (payment with no invoice). Payment-per-invoice is exactly the computation the user flagged as central. |
| **P3** | **Engagement requires `documentid` (NOT NULL, FK).** | Deposit, CWT Pick-up and Advanced Payment are account-level / standalone (`invoiceId: null` in the app) → **they can't be uploaded at all today.** |
| **P4** | **Client snapshot columns** duplicate `a_tblcollectionclient` (Phase 2); address/contact/email are always empty from SAP. | Redundant storage; two places to be wrong. |
| **P5** | `bankname` on the **invoice**. | Bank is a property of a *payment* (cheque), not of the receivable. |
| **P6** | `documentreferences` is a CSV in one column. | Repeating group (1NF). Low impact for SAP (it's just the Doc. No.), but it's a smell. |
| **P7** | **Monthly Target** persisted nowhere. | Collector's target resets on app restart. |
| **P8** | Defer / Clear reasons are in-memory and **never queued** for upload. | Account-level history is lost; supervisors can't see why an account was released. |
| **P9** | `status` / `lastoutcome` are derived caches with no single rule. | Fine as caches, but they must be *recomputed*, never edited directly. |

**Verdict:** "safe as is" for recording per-invoice collections; **not safe** as the system of
record for payments, deposits, advances, targets, or auditing original amounts.

---

## 4. Target model (normalized)

```
a_tblcollectionclient            (exists)  client/account registry
        │ 1
        │
        │ n
a_tblcollectioninvoice           (slimmed) the receivable  ── originalamount preserved
        │ 1                                                   balance = original − Σ allocations
        │ n
a_tblcollectionpaymentallocation (NEW)     payment → invoice, amount   ◄── the join that
        │ n                                                                 answers "payment of
        │ 1                                                                 each invoice"
a_tblcollectionpayment           (NEW)     one cash/cheque received (receipt)
        │ n                                unallocated remainder = ADVANCED PAYMENT
        │ 1 (nullable)
a_tblcollectiondeposit           (NEW)     bank deposit of payments  → Actual Collection
a_tblcollectionengagement        (refocused) visit / outcome log; documentid NULLABLE
                                           (NULL + clientcode = account-level Defer/Clear)
a_tblcollectionactivity          (NEW)     CWT Pick-up, Reconciliation (office activities)
a_tblcollectiontarget            (NEW)     monthly target per collector
```

### 4.1 Tables

**`a_tblcollectioninvoice`** — *the receivable only*
| column | note |
|---|---|
| `documentid` PK | SAP Doc. No. (natural key; drop the surrogate) |
| `clientcode` FK → client | replaces the 8 snapshot columns |
| **`originalamount`** numeric | **NEW.** SAP *Balance Due* at import. Never mutated. |
| `postingdate`, `duedate`, `documentdate` | from SAP |
| `remarks` | |
| `status` | Open · Partial · Collected · Reconciliation — **recomputed** from allocations |
| `assignedto`, `assignedat` | claim/acquire state |
| `source` | `'SAP'` / `'MANUAL'` (web import vs. Add-to-Bucket vs. advance-assign) |
| `createdat`, `updatedat`, `updatedby` | |
| *(cache, optional)* `balance`, `totalcollected` | derived; refreshed by the service when allocations change — never edited directly |

**`a_tblcollectionpayment`** — *one receipt*
`paymentid` PK · `clientcode` FK · `collectorcode` · `paymentdate` · `method` (Cash/Cheque) ·
`bankname` · `checkno` · `checkdate` · `totalamount` · `remarks` · `depositid` FK NULL ·
`createdat`.
An **Advanced Payment is simply a payment whose allocations sum to less than `totalamount`**
— no separate table. `assignInvoiceToPayment` becomes "insert an allocation" (creating the
invoice first if it doesn't exist).

**`a_tblcollectionpaymentallocation`** — *how a payment splits across invoices*
`allocationid` PK · `paymentid` FK · `documentid` FK · `amount`.
Constraint: Σ `amount` per payment ≤ `payment.totalamount`. A **batch cheque** = 1 payment
+ N allocations (bank/cheque stored **once**).

**`a_tblcollectionengagement`** — *the visit/outcome log the app shows as History*
`engagementid` PK · `documentid` FK **NULL** · `clientcode` FK · `collectorcode` ·
`engagementdate` · `outcome` (Collected · Partially Collected · Pre-Collection · Others ·
Follow Up · Customer Unavailable · Refused to Pay · Cleared) · `remarks` ·
`purposeofvisit` · `paymentid` FK NULL · `createdat`.
`documentid = NULL` + `clientcode` ⇒ **account-level** entry (Defer / Clear). A payment
outcome links to its `paymentid` instead of repeating bank/cheque columns.

**`a_tblcollectiondeposit`** — *bank deposit* (feeds **Actual Collection**)
`depositid` PK · `collectorcode` · `depositdate` · `bankname` · `referenceno` ·
`totalamount` · `remarks` · `createdat`. Payments point at it via `payment.depositid`.

**`a_tblcollectionactivity`** — *other office activities*
`activityid` PK · `activitytype` (CWT Pick-up · Reconciliation) · `clientcode` FK ·
`collectorcode` · `activitydate` · `remarks` · `createdat`.
Reconciliation additionally sets `invoice.status = 'Reconciliation'` on the chosen invoices.

**`a_tblcollectiontarget`** — *monthly target*
`collectorcode` · `yearmonth` (e.g. `2026-09`) · `targetamount` · PK (`collectorcode`,`yearmonth`).

### 4.2 Every app computation, derived from the model

| App figure | Derivation |
|---|---|
| Invoice **balance** (`toBeCollected`) | `originalamount − Σ allocation.amount` for that `documentid` |
| Invoice **totalCollected** | `Σ allocation.amount` |
| Invoice **status** | balance = 0 → *Collected*; 0 < collected < original → *Partial*; else *Open* (or *Reconciliation* flag) |
| **History[]** shown per invoice | engagements for `documentid` (+ payment details via `paymentid`) |
| **Total Collected (month)** | `Σ allocation.amount` where `payment.paymentdate` in month |
| **Actual Collection (month)** | `Σ deposit.totalamount` where `depositdate` in month |
| **Advanced payments outstanding** | `Σ (payment.totalamount − Σ its allocations)` where > 0 |
| **Target vs Actual** | `target.targetamount` vs Actual Collection |
| Account-level history (Defer/Clear) | engagements with `documentid IS NULL` for `clientcode` |

Nothing is computed from a mutable column any more; `originalamount` is the only money
figure that is *stored as fact*, everything else is a sum.

### 4.3 Old → new column map

| current `a_tblcollectioninvoice` column | destination |
|---|---|
| `clientid, clientcode, clientname, clientaddress, clientcontact, clientemail, bpcode, collectorname` | **drop**; `clientcode` FK stays → `a_tblcollectionclient` |
| `tobecollected` | → `originalamount` (backfill = `tobecollected + totalcollected`); balance derived |
| `totalcollected`, `lastoutcome` | derived (optional cache) |
| `bankname` | → `a_tblcollectionpayment.bankname` |
| `documentreferences` | keep for now (SAP = Doc. No.); optional child table later |
| `status`, `assignedto`, `assignedat`, dates, `remarks`, audit | stay |

---

## 5. Why this does **not** break the mobile app

The phone only consumes **`GET /bucket` → `CollectionItemDto`** (`id, Client{}, ToBeCollected,
TotalCollected, Status, History[]…`) and produces **`POST /upload` → `CollectionChangeDto`**.
Both are *server-shaped*. The server can normalize its storage and keep emitting exactly the
same JSON by computing `ToBeCollected`/`TotalCollected`/`History[]` from the new tables.
The mobile's SQLite remains a flat *worklist cache* — it does not need to mirror the server's
normal form.

Upload operations map cleanly:

| upload op (today) | normalized write |
|---|---|
| `SAVE_ACTIVITY` (one invoice, amount, bank/cheque) | 1 payment + 1 allocation + 1 engagement(paymentid) |
| `BATCH_ACTIVITY` (N invoices, one cheque) | **1 payment + N allocations** + N engagements — bank/cheque stored once |
| `CLAIM` / `DEFER` / `CLEAR` | invoice `assignedto`; Defer/Clear → account-level engagement (`documentid NULL`) |
| *new* `OFFICE_ACTIVITY` Deposit | 1 deposit (+ link selected payments) |
| *new* `OFFICE_ACTIVITY` CWT / Reconciliation | 1 activity (+ invoice status for Reconciliation) |
| *new* `ADVANCED_PAYMENT` | 1 payment with no allocation |
| *new* `ASSIGN_ADVANCE` | 1 allocation (create invoice with `source='MANUAL'` if new) |
| *new* `SET_TARGET` | upsert target |

---

## 6. Migration strategy — staged, additive first (recommended)

A big-bang rewrite would touch the schema, the import, the upload contract and the phone at
once. Instead:

| Stage | Change | Breaking? |
|---|---|---|
| **A. Additive schema** ✅ DONE 2026-09-15 (`migration_20260915_collection_normalization_stage_a.sql`; 142 tests) | Add `payment`, `paymentallocation`, `deposit`, `activity`, `target` tables. Add `invoice.originalamount` (backfill `= tobecollected + totalcollected`) and `invoice.source`. Make `engagement.documentid` **nullable**, add `engagement.clientcode`, `engagement.paymentid`. Keep all existing columns. | **No** |
| **B. Write-through on the server** ✅ DONE 2026-09-15 (`migration_20260915_collection_normalization_stage_b.sql` data backfill; 146 tests) | Existing upload ops now also write payment/allocation; `GET /bucket` computes balance/history from the normalized tables. Mobile JSON **unchanged**. Old cache columns kept in sync. | **No** |
| **C. Close the mobile gaps** — detailed sub-plan: `COLLECTION_NORMALIZATION_STAGE_C_PLAN.md` (phases C1–C4) | Add the new upload ops (Deposit, CWT, Reconciliation, Advanced Payment, Assign-Advance, Set-Target) **and wire Defer/Clear to the queue**. Persist office activities, advances and target to **SQLite** (today in-memory → lost on restart). SMS on deposit optional. | Additive on mobile |
| **D. Drop redundancy** — plan: `COLLECTION_NORMALIZATION_STAGE_D_PLAN.md` (proposed 2026-09-15) | Drop the 5 client-snapshot columns and `bankname` from the invoice, and `bankname/checkno/checkdate` from the engagement; add the `clientcode` FK; keep `bpcode`, `collectorname` and the cache columns (recompute function added); keep the identity PK. | Schema only; contract unchanged |

Stages A–B are backend-only and can ship independently of the phone. Stage C is where the
mobile finally persists the concepts it currently loses on restart — that is a **correctness
fix worth doing regardless of normalization.**

---

## 7. Impact on work already done

- **SAP import (web, Phases 3–4):** unchanged input. Backend maps *Balance Due* →
  `originalamount` (and today's `tobecollected`). Dedupe on `documentid` unchanged.
- **Client table (Phase 2):** becomes the *only* place client data lives (Stage D removes
  the invoice snapshot columns).
- **History trigger** on the invoice: keep; extend to `payment` and `paymentallocation`
  (money movements are what auditors ask about).
- **Mobile:** no change for Stages A–B; Stage C adds queue operations + SQLite tables for
  the in-memory concepts.

---

## 8. Decisions to confirm before implementation

1. **Cache or derive?** Keep `balance`/`totalcollected` as **server-maintained cache
   columns** (fast bucket reads, recomputed on every allocation change) — *recommended* —
   or drop them and compute on read.
2. **Staged (A→D) vs big-bang.** *Recommended: staged*, shipping A+B first.
3. **Advanced Payment as payment-without-allocation** (*recommended*, no extra table) vs a
   dedicated table.
4. **Deposit ↔ payment link:** payments carry `depositid` (recommended) vs a deposit-line
   table. The former is simpler and matches "these cheques went in this deposit".
5. Keep the `documentreferences` CSV for now, or normalize to a child table in Stage D.

---

## 9. Out of scope (for this design)
- Re-importing SAP to *refresh* balances (still insert-only + dedupe; see
  `SAP_AR_IMPORT_PLAN.md` §6).
- Any ACCMST_ linkage (separate data, no shared key).
- Multi-currency, VAT/withholding math (CWT is recorded as an activity, not computed).
