import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../base/utils/exceptions/format_exceptions.dart';
import '../../../base/utils/exceptions/platform_exceptions.dart';
import '../../../base/utils/popups/loaders.dart';
import '../../../base/utils/result.dart';
import '../../models/inventory_item_model.dart';

/// Repository that calls the external Gemini OCR endpoint and maps the
/// response into a list of [InventoryItemModel].
class InventoryItemRepository extends GetxController {
  static InventoryItemRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? 'https://inventory.mdmpi.com.ph';
  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Uploads [file] using multipart/form-data with form key `imageFile`.
  /// Returns a Result containing a list of parsed [InventoryItemModel] on success,
  /// or a failure message on error.
  Future<Result<List<InventoryItemModel>>> analyzeFile(File file) async {
    try {
      if (!await file.exists()) {
        return Result.failure('File does not exist: ${file.path}');
      }

      final uri = _uri('/api4/Gemini/analyze-file');
      final multipart = http.MultipartRequest('POST', uri);

      // Try to guess content type from file extension; default to application/octet-stream.
      final lower = file.path.toLowerCase();
      MediaType contentType;
      if (lower.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (lower.endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (lower.endsWith('.pdf')) {
        contentType = MediaType('application', 'pdf');
      } else {
        contentType = MediaType('application', 'octet-stream');
      }

      final fileStream = await http.MultipartFile.fromPath(
        'imageFile',
        file.path,
        contentType: contentType,
      );

      multipart.files.add(fileStream);

      // Send with a generous timeout
      final streamed = await multipart.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        final body = response.body;
        BLoaders.errorSnackBar(
            title: 'OCR Failed',
            message: 'Server returned ${response.statusCode}: ${body.isNotEmpty ? body : 'no body'}');
        return Result.failure('Server error: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      // Prefer structured inventoryItems array if available
      List<dynamic>? items;
      if (decoded is Map<String, dynamic>) {
        if (decoded['inventoryItems'] is List) {
          items = decoded['inventoryItems'] as List<dynamic>;
        } else if (decoded['content'] is String) {
          final content = decoded['content'] as String;
          // Attempt to extract JSON block from markdown fences if present
          String candidate = content;
          final fenceStart = content.indexOf('```');
          if (fenceStart >= 0) {
            final afterFence = content.substring(fenceStart + 3);
            final fenceEnd = afterFence.indexOf('```');
            if (fenceEnd >= 0) {
              candidate = afterFence.substring(0, fenceEnd).trim();
              // remove optional leading 'json' token
              if (candidate.startsWith('json')) {
                candidate = candidate.substring(4).trim();
              }
            }
          }

          // Try to find the first '[' .. ']' block in candidate
          final firstBracket = candidate.indexOf('[');
          final lastBracket = candidate.lastIndexOf(']');
          if (firstBracket >= 0 && lastBracket > firstBracket) {
            final arrStr = candidate.substring(firstBracket, lastBracket + 1);
            try {
              final parsed = jsonDecode(arrStr);
              if (parsed is List) items = parsed;
            } catch (_) {
              // ignore parse error, fallback below
            }
          }
        }
      }

      if (items == null) {
        // Last resort: try to parse response body as a list
        try {
          final alt = jsonDecode(response.body);
          if (alt is List) items = alt;
        } catch (_) {
          // ignore
        }
      }

      if (items == null) {
        BLoaders.errorSnackBar(
            title: 'OCR Parse Error', message: 'Could not parse OCR response');
        return Result.failure('Failed to parse OCR response');
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
      BLoaders.errorSnackBar(title: 'OCR Error', message: 'An error occurred: $e');
      return Result.failure(e.toString());
    }
  }

  /// Calls Google Generative Language (Gemini) directly with the provided [file]
  /// and optional [prompt]. The request body follows the shape:
  /// { contents: [ { parts: [ { inlineData: { mimeType, data } }, { text } ] } ] }
  /// On success returns Result.success(List<InventoryItemModel>), otherwise Result.failure.
  Future<Result<List<InventoryItemModel>>> analyzeFileWithGemini(File file, {String? prompt}) async {
    try {
      if (!await file.exists()) {
        return Result.failure('File does not exist: ${file.path}');
      }

      final model = dotenv.env['AI_TOOLKIT_MODEL'] ?? dotenv.env['AI_MODEL'] ?? '';
      final apiKey = dotenv.env['AI_TOOLKIT_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';

      if (model.isEmpty || apiKey.isEmpty) {
        return Result.failure('AI configuration missing (AI_TOOLKIT_MODEL / AI_TOOLKIT_API_KEY)');
      }

      final googleUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);

      String mimeTypeFromPath(String path) {
        final ext = path.split('.').last.toLowerCase();
        switch (ext) {
          case 'png':
            return 'image/png';
          case 'jpg':
          case 'jpeg':
            return 'image/jpeg';
          case 'pdf':
            return 'application/pdf';
          default:
            return 'application/octet-stream';
        }
      }

      final mimeType = mimeTypeFromPath(file.path);
      final promptText = prompt ?? dotenv.env['AI_PROMPT'] ?? 'Analyze this image and return the results as structured JSON.';

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
          .post(Uri.parse(googleUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode(requestBody))
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
                  return Result.failure('AI API key invalid: verify AI_TOOLKIT_API_KEY and Generative Language API enablement.');
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
                if (first['output'] is String) textContent = first['output'] as String;
                else if (first['text'] is String) textContent = first['text'] as String;
              }
            }
          }
        }
      } catch (_) {}

      final generatedText = (textContent != null && textContent.isNotEmpty) ? textContent : resp.body;

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
}
