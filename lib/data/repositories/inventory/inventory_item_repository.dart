import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../base/utils/exceptions/format_exceptions.dart';
import '../../../base/utils/exceptions/platform_exceptions.dart';
import '../../../base/utils/constants/api_environment.dart';
import '../../../base/utils/images/document_image.dart';
import '../../../base/utils/popups/loaders.dart';
import '../../../base/utils/result.dart';
import '../../models/inventory_item_model.dart';

/// Repository that calls Google Generative Language (Gemini) directly for
/// receipt OCR and maps the response into a list of [InventoryItemModel].
class InventoryItemRepository extends GetxController {
  static InventoryItemRepository get instance => Get.find();

  /// Default extraction prompt used when `.env` does not define `AI_PROMPT`.
  ///
  /// Covers both documents the scanner is pointed at: the delivery receipt,
  /// whose serials arrive as batch sub-rows, and the printed Stock Issue
  /// Slip, whose serial is a column on the item row itself.
  ///
  /// The slip's REMARKS column is deliberately not extracted: the database
  /// keeps its remarks column for the backend, but the mobile client does not
  /// capture it.
  ///
  /// Every key named here must match the ones parsed by
  /// [InventoryItemModel.fromJson] and [InventoryBatchModel.fromJson]. Keep
  /// this in sync with the `AI_PROMPT` sample in `.env.example`.
  static const String defaultAnalysisPrompt = r'''
You are extracting structured data from a delivery document. It is either (A) a delivery receipt whose item table has the columns Item Code | Description | Warehouse | Qty | Unit, or (B) a Stock Issue Slip whose item table has the columns QTY | UM | PART NO. | ITEM DESCRIPTION | SERIAL NO. | PTN | REMARKS. Decide which one it is from the printed column headers, then apply the matching rules below.
How to read the table. This procedure is mandatory and overrides any impression the example values give:
1. The photo may be rotated or skewed. Establish the printed orientation first, so the column headers read left to right, before reading any value.
2. Read the table ROW BY ROW, never column by column. Fix your attention on one item row, read all of its cells left to right across that single row, emit that row's object, and only then move down to the next row.
3. It is FORBIDDEN to collect a whole column into a list and then pair the lists up by position. That method silently misaligns every row after the first blank cell and is the single most common way this task is failed. If you have gathered values column-wise, discard them and re-read the document row by row.
4. Before emitting, count the entries in the QTY column. Your output array must contain exactly that many objects, in printed top-to-bottom order.
5. For each row, check the horizontal position of every value against the header above it. A value belongs to a key ONLY because it sits under that column. Never infer a key from how a value looks: these documents hold similarly formatted codes in different columns, so format is not evidence of meaning.
6. A blank cell yields "" for that key. It must NEVER pull a value in from a neighbouring column, from the row above, or from the row below. Rows with two or three blanks are normal and must still emit all eight keys.
7. SERIAL NO. and PTN are two distinct columns whose values look alike. SERIAL NO. is immediately to the right of ITEM DESCRIPTION. PTN is immediately to the right of SERIAL NO. and immediately to the left of REMARKS. A row may have a serial and no PTN. Never place a serial into "PTN", and never reuse another row's serial as this row's PTN.
8. "Description" comes only from the ITEM DESCRIPTION column. A PART NO. value, for example one shaped like a word plus a hyphen plus a word, must never appear as a "Description". If a row's description cell looks empty, emit "" rather than borrowing the part number.
9. Do NOT extract the REMARKS column. It exists on the printed slip and is useful only as a landmark for locating PTN. Never return a "Remarks" key, and never let remarks text spill into "PTN" or any other key. A remark is often printed once and centred across several rows, so ignore it wherever it appears.
10. If a cell is genuinely illegible, emit "" for it. Never substitute a value read from anywhere else on the document.
Output rules, both types:
11. Output MUST be a valid JSON array of objects ONLY, with no explanation, no markdown and no code fences.
12. Each object must contain exactly these keys: "Item Code", "Description", "Qty", "Unit", "Part No.", "Serial No.", "PTN", "batch".
13. Use "" for any key whose column the document does not have, or whose cell is blank or unreadable. Use [] for "batch" when there are no batch details. Never use null.
14. "Qty" and "Batch Quantity" must be numbers when parsable, otherwise strings.
15. Preserve "Description" exactly as written.
16. Ignore all header, footer and company information, and any unrelated or misaligned OCR text.
17. Ignore filler text that marks the end of the table, such as "NOTHING FOLLOWS".
18. One printed item row is one object. Never merge two item rows, even when they share an item code or a part number. Continuation lines and batch sub-rows are not item rows; the type-specific rules below say how to fold them in.
19. Return one object per item row, in the printed top-to-bottom order.
20. If no valid rows are found, return an empty JSON array: [].
Rules for type A, delivery receipt (Item Code | Description | Warehouse | Qty | Unit):
21. Only process rows under those columns. Do NOT extract or return the Warehouse column.
22. Item rows may span multiple lines; treat the first line as the main item row containing Item Code, Description, Qty, Unit.
23. Any immediately following lines containing "Batch/Serial #", "Quantity", "Expiry Date" belong to the most recent item. Map "Quantity" to "Batch Quantity".
24. Group all batch entries for one item into its "batch" list. Each element inside "batch" must be an object with exactly these keys: "Batch/Serial #", "Batch Quantity", "Expiry Date". If several batch entries exist under one item, include all of them.
25. This document has no part number, serial number or PTN columns, so return "" for "Part No.", "Serial No." and "PTN". Batch serials belong in "batch" only; never copy one into "Serial No.".
Rules for type B, Stock Issue Slip (QTY | UM | PART NO. | ITEM DESCRIPTION | SERIAL NO. | PTN | REMARKS):
26. Map the columns as QTY to "Qty", UM to "Unit", PART NO. to "Part No.", ITEM DESCRIPTION to "Description", SERIAL NO. to "Serial No." and PTN to "PTN". The REMARKS column is ignored entirely.
27. This document has no item code column, so return "" for "Item Code".
28. This document has no batch sub-rows, so always return "batch": []. The serial belongs in "Serial No." on the item itself.
29. A row may wrap its description onto a second line; join the continuation into the same object rather than creating a new one.
30. PART NO. can be numeric, alphanumeric or hyphenated, and it may be blank on some rows. A blank PART NO. does not mean the row should be skipped or that the description should move left.
Example output for type A:
[ { "Item Code": "ODC0004", "Description": "Control Serum 2, 20 x 5 mL", "Qty": 1.00, "Unit": "BOX", "Part No.": "", "Serial No.": "", "PTN": "", "batch": [ { "Batch/Serial #": "23330939", "Batch Quantity": 1.00, "Expiry Date": "04/21/2026" }, { "Batch/Serial #": "23330940", "Batch Quantity": 1.00, "Expiry Date": "05/21/2026" } ] } ]
Example output for type B. The values are deliberately generic placeholders that show WHERE each column goes, not what real values look like. The second row shows a blank PART NO. and PTN filled with "" and no leftward shift:
[ { "Item Code": "", "Description": "<text from ITEM DESCRIPTION>", "Qty": 1, "Unit": "UNIT", "Part No.": "<text from PART NO.>", "Serial No.": "<text from SERIAL NO.>", "PTN": "<text from PTN>", "batch": [] }, { "Item Code": "", "Description": "<text from ITEM DESCRIPTION>", "Qty": 1, "Unit": "PIECE", "Part No.": "", "Serial No.": "<text from SERIAL NO.>", "PTN": "", "batch": [] } ]''';

  String get _baseUrl => BApiEnvironment.api4BaseUrl;
  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Calls Google Generative Language (Gemini) directly with the provided [file]
  /// and optional [prompt]. The request body follows the shape:
  /// { contents: [ { parts: [ { inlineData: { mimeType, data } }, { text } ] } ] }
  /// On success returns Result.success(List<InventoryItemModel>), otherwise Result.failure.
  Future<Result<List<InventoryItemModel>>> analyzeFileWithGemini(File file,
      {String? prompt}) async {
    try {
      if (!await file.exists()) {
        return Result.failure('File does not exist: ${file.path}');
      }

      final model =
          dotenv.env['AI_TOOLKIT_MODEL'] ?? dotenv.env['AI_MODEL'] ?? '';
      final apiKey =
          dotenv.env['AI_TOOLKIT_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';

      if (model.isEmpty || apiKey.isEmpty) {
        return Result.failure(
            'AI configuration missing (AI_TOOLKIT_MODEL / AI_TOOLKIT_API_KEY)');
      }

      // The key travels in the x-goog-api-key header, never in the URL, so it
      // does not end up in proxy/CDN/device request logs. (It is still bundled
      // in the APK via .env — see TODO item 18 for the GCP-side restrictions.)
      final googleUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

      // Bake EXIF orientation into the pixels first: the model reads raw
      // pixels, and a rotated table breaks column alignment.
      final prepared = await BDocumentImage.prepare(file);
      final b64 = base64Encode(prepared.bytes);
      final mimeType = prepared.mimeType;
      final envPrompt = dotenv.env['AI_PROMPT']?.trim();
      final promptText = prompt ??
          ((envPrompt != null && envPrompt.isNotEmpty)
              ? envPrompt
              : defaultAnalysisPrompt);

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': b64,
                }
              },
              {
                'text': promptText,
              }
            ]
          }
        ]
      };

      final resp = await http
          .post(Uri.parse(googleUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 120));

      if (resp.statusCode == 400) {
        try {
          final err = jsonDecode(resp.body);
          final details = err['error']?['details'];
          if (details is List) {
            for (final d in details) {
              if (d is Map<String, dynamic>) {
                final reason = d['reason'] as String? ?? '';
                if (reason.toLowerCase().contains('api_key_invalid')) {
                  return Result.failure(
                      'AI API key invalid: verify AI_TOOLKIT_API_KEY and Generative Language API enablement.');
                }
              }
            }
          }
        } catch (_) {}
      }

      if (resp.statusCode != 200) {
        return Result.failure('AI service error: ${resp.statusCode}');
      }

      final decoded = jsonDecode(resp.body);

      String? textContent;

      try {
        if (decoded is Map<String, dynamic>) {
          final candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final first = candidates[0];
            if (first is Map<String, dynamic>) {
              final content = first['content'];
              if (content is Map<String, dynamic>) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final p0 = parts[0];
                  if (p0 is Map<String, dynamic> && p0['text'] is String) {
                    textContent = p0['text'] as String;
                  }
                }
              } else if (content is List && content.isNotEmpty) {
                final c0 = content[0];
                if (c0 is Map<String, dynamic> && c0['parts'] is List) {
                  final parts = c0['parts'] as List;
                  if (parts.isNotEmpty) {
                    final p0 = parts[0];
                    if (p0 is Map<String, dynamic> && p0['text'] is String) {
                      textContent = p0['text'] as String;
                    }
                  }
                }
              }

              if (textContent == null) {
                if (first['output'] is String) {
                  textContent = first['output'] as String;
                } else if (first['text'] is String)
                  textContent = first['text'] as String;
              }
            }
          }
        }
      } catch (_) {}

      final generatedText = (textContent != null && textContent.isNotEmpty)
          ? textContent
          : resp.body;

      List<dynamic>? items;
      try {
        final asJson = jsonDecode(generatedText);
        if (asJson is List) items = asJson;
      } catch (_) {}

      if (items == null) {
        final firstBracket = generatedText.indexOf('[');
        final lastBracket = generatedText.lastIndexOf(']');
        if (firstBracket >= 0 && lastBracket > firstBracket) {
          final arrStr = generatedText.substring(firstBracket, lastBracket + 1);
          try {
            final parsed = jsonDecode(arrStr);
            if (parsed is List) items = parsed;
          } catch (_) {}
        }
      }

      if (items == null) {
        return Result.failure('Failed to parse AI response');
      }

      final parsed = items
          .whereType<dynamic>()
          .map((e) => e is Map<String, dynamic>
              ? InventoryItemModel.fromJson(e)
              : InventoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return Result.success(parsed);
    } catch (e) {
      return Result.failure('Failed to analyze image with AI: $e');
    }
  }

  /// Fetches inventory items from the server.
  ///
  /// - [path] is the endpoint path appended to the base API URL (default: '/api/inventory/items').
  /// - [queryParameters] optional map of query parameters.
  ///
  /// Returns a [Result] containing the parsed list of [InventoryItemModel] on success,
  /// or a failure message on error.
  Future<Result<List<InventoryItemModel>>> fetchItems(String requestId) async {
    try {
      String path = '/api4/Item/request/$requestId';
      var uri = _uri(path);

      final resp = await http.get(uri).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        final body = resp.body;
        BLoaders.errorSnackBar(
            title: 'Fetch Failed',
            message:
                'Server returned ${resp.statusCode}: ${body.isNotEmpty ? body : 'no body'}');
        return Result.failure('Server error: ${resp.statusCode}');
      }

      final decoded = jsonDecode(resp.body);

      List<dynamic>? items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Common keys that might contain the list
        if (decoded['items'] is List) {
          items = decoded['items'] as List<dynamic>;
        } else if (decoded['inventoryItems'] is List) {
          items = decoded['inventoryItems'] as List<dynamic>;
        } else if (decoded['data'] is List) {
          items = decoded['data'] as List<dynamic>;
        }
      }

      if (items == null) {
        // Last resort: try to parse body as a list
        try {
          final alt = jsonDecode(resp.body);
          if (alt is List) items = alt;
        } catch (_) {}
      }

      if (items == null) {
        BLoaders.errorSnackBar(
            title: 'Fetch Parse Error', message: 'Could not parse response');
        return Result.failure('Failed to parse response');
      }

      final parsed = items
          .whereType<dynamic>()
          .map((e) => e is Map<String, dynamic>
              ? InventoryItemModel.fromJson(e)
              : InventoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return Result.success(parsed);
    } on TFormatException catch (_) {
      return Result.failure('Invalid response format');
    } on PlatformException catch (e) {
      return Result.failure(TPlatformException(e.code).message);
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Fetch Error', message: 'An error occurred: $e');
      return Result.failure(e.toString());
    }
  }
}
