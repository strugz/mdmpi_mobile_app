# Study: Duplicate invoices in the Collection Bucket import

**Date:** 2026-10-19
**Question:** In the Import Bucket flow, what happens when the Excel file has the same
invoice (same `Doc. No.`) more than once, or has an invoice that is already in the bucket?
**Status:** Study only. No code changed.

---

## 1. Where the import lives

The import is not in the mobile app. The office runs it in the Collection admin web app,
and the mobile app only downloads the result.

| Step | Code | What it does |
|---|---|---|
| 1. Parse | `mdmpi_collection_web/src/utils/excelParser.js` → `parseExcel()` | Reads the SAP `AR` sheet (or the app template). Drops subtotal rows (no Doc. No.), non-`IN` types (RC/CN/JE) and zero balances. Validates each row. **Does not check for duplicate Doc. No.** |
| 2. Preview | `mdmpi_collection_web/src/views/BucketImportView.vue` | Shows every kept row, duplicates included. The button says "Import N invoice(s)", where N counts the duplicates too. |
| 3. Send | `mdmpi_collection_web/src/api/collectionApi.js` → `importInvoicesChunked()` | Splits the rows into batches of **500** and POSTs each one to `/api4/Collection/invoices/import`, one after another. |
| 4. Save | `MDMPI.App/MDMPI.App.Data/Collection/Repositories/CollectionInvoiceRepository.cs` → `ImportInvoicesAsync()` (line 136) | One transaction per batch. Dedupes on `DocumentId`. Adds invoices only and never updates them. Upserts the client registry. |
| 5. Guard | `migration_20260914_add_collection_tables.sql` | `CONSTRAINT uq_a_tblcollectioninvoice_documentid UNIQUE (documentid)` |
| 6. Mobile | *Download Bucket* (`GET /api4/Collection/bucket`) | Gets the rows the database holds. It never sees the Excel duplicates. |

### How the backend dedupes (per batch)

```
existing = invoices in DB whose DocumentId is in this batch     (exact-case SQL match)
seen     = HashSet(existing ids, case-INSENSITIVE)
for each row in batch (file order):
    upsert client by ClientCode            ← runs for duplicates too
    if seen contains DocumentId:
        if stored invoice exists AND stored P.O. blank AND row has P.O.: fill P.O.
        Skipped += { Reference: DocumentId, Reason: "Duplicate DocumentId" }
        continue
    seen.add(DocumentId); insert invoice; Created++
```

**Rule:** the first row wins, and every later row with the same Doc. No. is skipped.
An invoice already in the database always wins over the file.

---

## 2. Scenarios, verified

Each scenario was run against the real `ImportInvoicesAsync` using the backend test
harness (SQLite in-memory, the same setup as `CollectionInvoiceRepositoryTests`). The probe
test was temporary and has been deleted.

| # | Excel content | Result | Verdict |
|---|---|---|---|
| S1 | Doc `500100` twice in one file, ₱1,000 then ₱2,500 | `Created 1`, `Skipped 1 ("Duplicate DocumentId")`. Stored amount **₱1,000**. The ₱2,500 row is dropped. | ⚠️ No double-billing, but the later row's amount is silently lost |
| S2 | Same Doc No. in two different 500-row batches (or re-importing the same file) | Batch 1 inserts it. Batch 2 finds it in the DB and skips it. Stored amount unchanged. | ✅ Idempotent, so re-running after a failure is safe |
| S3a | Same Doc No. three times with client name "Acme Old", then "Acme New" | One invoice. Client name = **"Acme New"** (last row wins on client fields). | ⚠️ Name comes from a row that was otherwise discarded |
| S3b | Same Doc No.: the 1st row has no P.O., the 2nd row has `PO-77` | Invoice stored with **no P.O.** | ⚠️ P.O. lost. The gap-filler only applies to invoices that were already in the DB before this batch |
| S3c | Same Doc No. under a different BP code (`VIS-9`) | The invoice stays on `NCR-1`. A **client `VIS-9` is still created**, with no invoices. | ⚠️ Orphan client row in the registry |
| S4a | `si-1001` imported, then `SI-1001` in a later batch | **Two invoices created.** | ❌ Duplicate in the bucket. The DB lookup and the UNIQUE constraint are case-sensitive |
| S4b | `SI-2002` and `si-2002` in the same batch | One created, one skipped | Inconsistent with S4a. The in-batch check ignores case |
| — | Invoice already in the bucket and claimed or worked by a collector | Skipped. Balance, assignment and history are untouched. P.O. is filled only if it was blank. | ✅ By design (app owns the running balance) |

### What the operator sees

- The success snackbar says *"Added X new invoice(s)."*
- The summary says *"Y already in the bucket (skipped)"* and lists up to 15 references.

In-file duplicates are counted as "already in the bucket" even when they were never there
before this import. In the summary they look the same as a normal month-to-month overlap,
so nothing tells the office that the Excel file itself had repeated rows.

### What collectors see

Nothing goes wrong on the mobile side. The database holds one row per `DocumentId`
(apart from the S4 case-variant hole), so *Download Bucket* returns each invoice once.

---

## 3. Findings

| ID | Severity | Finding |
|---|---|---|
| F1 | **Medium** | **Repeated Doc. No. with different balances loses money silently.** Only the first row's `Balance Due` is kept. If SAP ever exports one invoice as several rows (installment / split due dates, or a re-pasted section), the bucket under-states what is owed, and the only trace is a "skipped" line that looks like a normal re-import. |
| F2 | Medium | **Misleading summary.** In-file duplicates and real already-in-bucket rows share one reason (`"Duplicate DocumentId"`) and one label ("already in the bucket"). The preview also counts duplicates in "Import N invoice(s)". |
| F3 | Low | **Case-variant Doc. No. makes two invoices** across batches or months (S4a). SAP Doc. Nos are numeric, so this only hits the manual template (`SI-1001`-style ids). |
| F4 | Low | **Client fields from discarded rows still apply**: last-row-wins on name/address/contact (S3a), and an orphan client for a conflicting BP code (S3c). |
| F5 | Low | **P.O. on a later duplicate row is lost** when the first occurrence is new in this batch (S3b). |
| ✅ | — | **No double entries.** The UNIQUE constraint plus the dedupe mean the same numeric Doc. No. never becomes two invoices. Re-running after a mid-import failure is safe (batches already saved are skipped). |
| ✅ | — | **Invoices already worked by collectors are never overwritten** by a new file. |

---

## 4. Recommendations (if we act on this)

In priority order. Each is small and self-contained.

1. **Flag duplicates in the preview (admin web, `excelParser.js`).** After parsing, group
   kept rows by `DocumentId` (trimmed, upper-cased). For each group with more than one row:
   - *identical rows* (same code and amount) → mark extras as a warning, "Duplicate row in
     file, will be skipped", and exclude them from the import count;
   - *conflicting rows* (different amount or BP code) → mark as an **error** so the office
     must fix the file. Optionally offer "Sum balances" for genuine installment splits,
     *only if the business confirms that is what such rows mean*.

   Add a `duplicateRows` counter to `stats`. This alone closes F1, F2 and F5 for the
   operator.
2. **Separate the reasons (backend + web).** Return `"Duplicate in file"` versus
   `"Already in bucket"` from `ImportInvoicesAsync` (an in-batch hit is one whose id is
   absent from `existingById`), and show two counts in `BucketImportView.vue`.
3. **Case-normalise Doc. No. (backend).** Upper-case `DocumentId` in `BuildInvoiceEntity`
   and in the `incomingIds` lookup, or compare with `lower(documentid)`. This closes F3.
   Before deploying, check production for existing case-variant pairs.
4. **Skip client upsert for duplicates that conflict (backend).** Upsert the client only for
   rows that are inserted or already belong to that client. This closes F4.
5. **Add backend tests** for S1, S3 and S4 in
   `MDMPI.App.Tests/Collection/CollectionInvoiceRepositoryTests.cs`. Today only the
   cross-import case (S2) is covered (`ReImport_RefreshesClientName_ButSkipsExistingInvoices`).

### Open question for the business

Does the SAP AR export ever list **one invoice on more than one row** (installments, partial
due dates)? If yes, F1 is a real money issue and recommendation 1 must decide between
*sum* and *reject*. If no, duplicates only come from copy/paste mistakes, and *reject with
a clear message* is enough.
