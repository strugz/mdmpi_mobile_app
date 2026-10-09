import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/services/gemini_document_service.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';

/// Reads one file (photo or PDF) with the AI; null-safe stand-in for tests.
typedef VoucherAiReader = Future<Result<List<dynamic>>> Function(File file,
    {required String prompt});

/// The text on a photo, read on the phone, line by line with positions.
typedef VoucherOfflineReader = Future<List<OcrLine>> Function(File file);

/// What one page of a voucher gave.
class VoucherRead {
  const VoucherRead.ai(this.lines)
      : offlineLines = null,
        aiError = null;
  const VoucherRead.offline(this.offlineLines, {this.aiError})
      : lines = const [];

  /// The invoices the AI listed (an AI read).
  final List<VoucherInvoiceLine> lines;

  /// Everything the phone read, with positions (an offline read); the
  /// caller reads its layout and picks the account's invoices out of it.
  final List<OcrLine>? offlineLines;

  /// The offline read as plain text.
  String? get offlineText => offlineLines?.map((l) => l.text).join('\n');

  /// Why the AI was not used.
  final String? aiError;

  bool get isOffline => offlineLines != null;
}

/// Reads the SI / Invoice / Sales Invoice numbers off a client's voucher or
/// off a Sales Invoice itself (meeting of 2026-10-07, item 2), the way the Logistics inventory scanner
/// reads delivery receipts: the file and [defaultVoucherPrompt] go to Gemini
/// through [GeminiDocumentService]. Without a connection, or when the AI
/// fails, a photo is read on the phone instead (ML Kit), and the caller
/// matches its text more cautiously.
class VoucherInvoiceRepository extends GetxController {
  VoucherInvoiceRepository({
    VoucherAiReader? readWithAi,
    VoucherOfflineReader? readOffline,
    String? Function()? envPrompt,
  })  : _readWithAi = readWithAi ?? _gemini,
        _readOffline = readOffline ?? _mlKit,
        _envPrompt = envPrompt ?? _promptFromEnv;

  static VoucherInvoiceRepository get instance => Get.find();

  final VoucherAiReader _readWithAi;
  final VoucherOfflineReader _readOffline;
  final String? Function() _envPrompt;

  /// The voucher extraction prompt; `AI_VOUCHER_PROMPT` in `.env` overrides
  /// it (one line, like `AI_PROMPT`). The keys it names must match
  /// [VoucherInvoiceLine.fromJson].
  static const String defaultVoucherPrompt = r'''
You are reading a document a collector photographs at a customer. It is either (A) a payment document listing the invoices being paid: a check voucher, payment voucher, disbursement voucher, remittance advice or a list of invoices, or (B) a single Sales Invoice or Invoice itself. Your only job is to list the invoice numbers: for (A) every invoice being paid, for (B) the document's own invoice number.
What counts as an invoice number. This is mandatory:
1. Return a number ONLY when the document labels it as an invoice: a column header, a row label or a prefix that reads "SI", "S.I.", "SI No.", "SI#", "SI #", "Sales Invoice", "Sales Invoice No.", "Sales Inv.", "Invoice", "Invoice No.", "Invoice #", "Inv.", "Inv No." or "Inv #", in any letter case.
2. Invoice numbers often sit inside a "Particulars", "Description", "Reference", "Ref. No." or "Details" column, written like "SI#700013390", "SI 700013390", "Inv 97339" or "Payment for SI No. 700013390 / 700013391". Extract every invoice number written there. A list such as "SI 700013390, 391, 392" or "SI 700013390-392" means three invoices only if the document clearly writes them as separate invoices; never invent numbers by expanding a range you cannot see.
3. NEVER return any of these as an invoice number, even when they look similar: purchase order numbers (PO, P.O., P.O. No.), check numbers, check voucher, CV, payment voucher, disbursement voucher or document numbers of the voucher itself, official receipt or acknowledgement receipt numbers (OR, AR), delivery receipt numbers (DR), credit or debit memo numbers, TIN, account numbers, bank reference numbers, phone numbers, dates, amounts, quantities, page numbers.
4. If a number has no invoice label anywhere (no header, no prefix, no row label), do not return it.
5. On a Sales Invoice or Invoice document (B), its own number is printed near the title, usually as "SALES INVOICE No. 240009288", "INVOICE No.", "SI No." or a large number beside the words "Sales Invoice". Return that number once. Do not return the delivery receipt, P.O., terms, customer, TIN or OSCA/PWD numbers printed on the same invoice, and do not return item codes or serial numbers from its item table.
How to read:
6. The photo may be rotated or skewed. Establish the printed orientation first.
7. Read the table row by row. Each invoice belongs to the row it is printed on.
8. Copy each invoice number exactly as printed: keep letters, hyphens and leading zeros; drop only the label itself ("SI#700013390" becomes "700013390", "SI-0097339" becomes "0097339"). Never correct, pad or reformat digits.
9. If a digit is genuinely illegible, still return the number with your best reading; the collector checks every number against their list.
Output rules:
10. Output MUST be a valid JSON array of objects ONLY, with no explanation, no markdown and no code fences.
11. Each object must contain exactly these keys: "Invoice No.", "Label", "Amount".
12. "Label" is the label printed with the number, normalised to one of "SI", "Invoice" or "Sales Invoice" ("S.I." and "SI#" become "SI"; "Inv." becomes "Invoice"). Use "" if unclear.
13. "Amount" is the amount printed on the same row for that invoice, as a number without currency symbols or thousands separators. Use "" when no amount is printed for that invoice alone (for example, only a grand total). On a Sales Invoice (B), use its total amount due.
14. Return each invoice number once, in printed top-to-bottom order, even if it appears twice.
15. If the document lists no invoice numbers, return an empty JSON array: [].
Example output:
[ { "Invoice No.": "700013390", "Label": "SI", "Amount": 21048.87 }, { "Invoice No.": "0097339", "Label": "Sales Invoice", "Amount": "" } ]''';

  String get _prompt {
    final env = _envPrompt()?.trim();
    return env != null && env.isNotEmpty ? env : defaultVoucherPrompt;
  }

  /// The AI's reading alone, with no fallback: the online re-read of a page
  /// the phone read first.
  Future<Result<List<VoucherInvoiceLine>>> readWithAi(File file) async {
    final ai = await _readWithAi(file, prompt: _prompt);
    return ai.isSuccess
        ? Result.success(VoucherInvoiceLine.listFrom(ai.value))
        : Result.failure(ai.error);
  }

  /// Reads one page: AI first, the phone's own reading as the fallback (a
  /// PDF has no fallback). With [useAi] false (Scan with camera) the phone
  /// reads it straight away, which works without a connection.
  Future<Result<VoucherRead>> read(File file, {bool useAi = true}) async {
    if (!useAi) return _readOnPhone(file, aiError: null);
    final ai = await _readWithAi(file, prompt: _prompt);
    if (ai.isSuccess) {
      return Result.success(
          VoucherRead.ai(VoucherInvoiceLine.listFrom(ai.value)));
    }
    logDebug('VoucherInvoiceRepository: AI read failed (${ai.error}); '
        'reading on the phone');
    return _readOnPhone(file, aiError: ai.error);
  }

  Future<Result<VoucherRead>> _readOnPhone(File file,
      {required String? aiError}) async {
    if (file.path.toLowerCase().endsWith('.pdf')) {
      return Result.failure(aiError == null
          ? 'A PDF is read by the AI only; use Scan with AI, or a photo.'
          : 'The voucher could not be read: $aiError. '
              'A PDF needs a connection; try again online, or take a photo.');
    }
    try {
      final lines = await _readOffline(file);
      if (lines.every((l) => l.text.trim().isEmpty)) {
        return Result.failure('No text could be read. Hold the voucher flat, '
            'fill the frame, and try again in good light.');
      }
      return Result.success(VoucherRead.offline(lines, aiError: aiError));
    } catch (e) {
      logDebug('VoucherInvoiceRepository: offline read failed: $e');
      return Result.failure(
          'The voucher could not be read${aiError == null ? '' : ': $aiError'}.');
    }
  }

  static Future<Result<List<dynamic>>> _gemini(File file,
          {required String prompt}) =>
      (Get.isRegistered<GeminiDocumentService>()
              ? Get.find<GeminiDocumentService>()
              : GeminiDocumentService())
          .extractJsonArray(file, prompt: prompt);

  // The shared recogniser stays open for the next scan.
  static Future<List<OcrLine>> _mlKit(File file) =>
      Get.find<ITextRecognitionService>()
          .processImageLines(InputImage.fromFilePath(file.path));

  static String? _promptFromEnv() {
    try {
      return dotenv.env['AI_VOUCHER_PROMPT'];
    } catch (_) {
      return null;
    }
  }
}
