import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/images/document_image.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';

/// Sends a document photo (or PDF) and an extraction prompt to Google's
/// Gemini and returns the JSON array the prompt asks for.
///
/// Shared by the Logistics inventory scanner (`InventoryItemRepository`) and
/// the Collection voucher scan; each caller owns its prompt and maps the
/// array into its own model. Model and key come from `.env`
/// (`AI_TOOLKIT_MODEL` / `AI_TOOLKIT_API_KEY`, falling back to `AI_MODEL` /
/// `API_KEY`). The key travels in the `x-goog-api-key` header, never in the
/// URL, so it does not end up in proxy or device request logs.
class GeminiDocumentService {
  GeminiDocumentService({http.Client? client, Map<String, String>? env})
      : _client = client,
        _env = env;

  final http.Client? _client;
  final Map<String, String>? _env;

  Map<String, String> get _config {
    if (_env != null) return _env;
    try {
      return dotenv.env;
    } catch (_) {
      return const {};
    }
  }

  /// The prompt's JSON array, or a failure the screen can show.
  Future<Result<List<dynamic>>> extractJsonArray(File file,
      {required String prompt}) async {
    try {
      if (!await file.exists()) {
        return Result.failure('File does not exist: ${file.path}');
      }

      final env = _config;
      final model = env['AI_TOOLKIT_MODEL'] ?? env['AI_MODEL'] ?? '';
      final apiKey = env['AI_TOOLKIT_API_KEY'] ?? env['API_KEY'] ?? '';
      if (model.isEmpty || apiKey.isEmpty) {
        return Result.failure(
            'AI configuration missing (AI_TOOLKIT_MODEL / AI_TOOLKIT_API_KEY)');
      }

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
          'models/$model:generateContent');

      // Bake EXIF orientation into the pixels first: the model reads raw
      // pixels, and a rotated table breaks column alignment.
      final prepared = await BDocumentImage.prepare(file);
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': prepared.mimeType,
                  'data': base64Encode(prepared.bytes),
                }
              },
              {'text': prompt},
            ]
          }
        ]
      });
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      };
      final resp = await (_client?.post(url, headers: headers, body: body) ??
              http.post(url, headers: headers, body: body))
          .timeout(const Duration(seconds: 120));

      if (resp.statusCode == 400 && _isInvalidKey(resp.body)) {
        return Result.failure(
            'AI API key invalid: verify AI_TOOLKIT_API_KEY and Generative '
            'Language API enablement.');
      }
      if (resp.statusCode != 200) {
        return Result.failure('AI service error: ${resp.statusCode}');
      }

      final items = parseJsonArray(generatedText(resp.body));
      return items == null
          ? Result.failure('Failed to parse AI response')
          : Result.success(items);
    } catch (e) {
      return Result.failure('Failed to analyze image with AI: $e');
    }
  }

  static bool _isInvalidKey(String body) {
    try {
      final details = jsonDecode(body)['error']?['details'];
      return details is List &&
          details.any((d) =>
              d is Map &&
              (d['reason'] as String? ?? '')
                  .toLowerCase()
                  .contains('api_key_invalid'));
    } catch (_) {
      return false;
    }
  }

  /// The model's text out of a `generateContent` response (the first
  /// candidate's first part), or the body itself when it has another shape.
  static String generatedText(String body) {
    try {
      final decoded = jsonDecode(body);
      final candidates = decoded is Map ? decoded['candidates'] : null;
      final first =
          candidates is List && candidates.isNotEmpty ? candidates[0] : null;
      if (first is Map) {
        final content = first['content'];
        final parts = content is Map
            ? content['parts']
            : (content is List && content.isNotEmpty
                ? content[0]['parts']
                : null);
        if (parts is List && parts.isNotEmpty && parts[0]['text'] is String) {
          return parts[0]['text'] as String;
        }
        if (first['output'] is String) return first['output'] as String;
        if (first['text'] is String) return first['text'] as String;
      }
    } catch (_) {}
    return body;
  }

  /// The JSON array in [text]: the whole text, or the span from its first
  /// `[` to its last `]` (models sometimes wrap it in prose or a code fence).
  static List<dynamic>? parseJsonArray(String text) {
    try {
      final whole = jsonDecode(text);
      if (whole is List) return whole;
    } catch (_) {}
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start < 0 || end <= start) return null;
    try {
      final inner = jsonDecode(text.substring(start, end + 1));
      return inner is List ? inner : null;
    } catch (_) {
      return null;
    }
  }
}
