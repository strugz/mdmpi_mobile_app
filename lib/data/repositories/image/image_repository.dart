import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import "package:http_parser/http_parser.dart" show MediaType;

import '../../../base/utils/exceptions/format_exceptions.dart';
import '../../../base/utils/exceptions/platform_exceptions.dart';
import '../../../base/utils/popups/loaders.dart';

/// Repository responsible for image upload/download operations.
class ImageRepository extends GetxController {
  static ImageRepository get instance => Get.find();

  /// Upload a file (Signature or Image proof) for a request using multipart/form-data.
  /// Sends form fields: `Image` (file), `RequestID`, `Type`.
  Future<void> uploadFile({
    required String requestId,
    required String base64Image,
    required String type,
  }) async {
    try {
      final parts = base64Image.split(',');
      final payload = parts.length > 1 ? parts.last : base64Image;
      final Uint8List bytes = base64Decode(payload);

      final baseUrl = dotenv.env['API_URL'] ?? '';
      final uri = Uri.parse("$baseUrl/api4/request/upload-image");
      final multipart = http.MultipartRequest('POST', uri);

      multipart.fields['RequestID'] = requestId;
      multipart.fields['Type'] = type; // e.g. "Signature"

      final filename = '${requestId}_$type.png';
      multipart.files.add(http.MultipartFile.fromBytes(
        'Image',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'png'),
      ));

      final streamed = await multipart.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        BLoaders.successSnackBar(title: 'Information', message: 'File uploaded');
      } else {
        BLoaders.errorSnackBar(
            title: 'Upload Failed',
            message:
                'Failed to upload file. Status: ${response.statusCode}. Body: ${response.body}');
      }
    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Upload Error', message: 'An error occurred: $e');
    }
  }

  /// Download a file from a full URL and return raw bytes.
  Future<Uint8List> getFileFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file. Status: ${response.statusCode}');
      }
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Download Error', message: 'An error occurred: $e');
      rethrow;
    }
  }

  /// Download a file by API endpoint path (e.g. '/api4/request/download-image') and optional query parameters.
  /// Returns raw bytes of the response body when successful.
  Future<Uint8List> getFileFromApi({
    required String endpoint,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final base = dotenv.env['API_URL'] ?? '';
      var uri = Uri.parse('$base$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file. Status: ${response.statusCode}');
      }
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Download Error', message: 'An error occurred: $e');
      rethrow;
    }
  }
}

