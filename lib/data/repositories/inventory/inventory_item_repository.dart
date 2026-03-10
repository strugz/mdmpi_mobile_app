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
}

