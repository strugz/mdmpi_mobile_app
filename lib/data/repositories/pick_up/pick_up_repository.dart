import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/pick_up_mapper.dart';

/// Repository for pick-up request operations.
/// Handles API communication for fetching, creating, updating, and canceling pick-up requests.
class PickUpRepository extends GetxController {
  static PickUpRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/RequestPickUp';

  /// Decodes a dynamic JSON root into a list of items.
  List<dynamic> _decodeRootToList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['items'] is List) return decoded['items'];
      // Fallback: first list value among map values.
      for (final v in decoded.values) {
        if (v is List) return v;
      }
      return const [];
    }
    return const [];
  }

  /// Shows a snackbar unless [silent] is true.
  void _showSuccess(String message, {bool silent = false}) {
    if (!silent) {
      BLoaders.successSnackBar(title: 'Information', message: message);
    }
  }

  void _showError(String message, {bool silent = false}) {
    if (!silent) {
      BLoaders.errorSnackBar(title: 'Error', message: message);
    }
  }

  void _showWarning(String message, {bool silent = false}) {
    if (!silent) {
      BLoaders.warningSnackBar(title: 'Information', message: message);
    }
  }

  /// Performs a GET request with timeout and returns the response.
  Future<http.Response> _safeGet(Uri url) =>
      http.get(url).timeout(const Duration(seconds: 60));

  /// Performs a POST request with timeout.
  Future<http.Response> _safePost(Uri url, Map<String, dynamic> payload) => http
      .post(url,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload))
      .timeout(const Duration(seconds: 60));

  /// Performs a PATCH request with timeout.
  Future<http.Response> _safePatch(
          Uri url, Map<String, dynamic> payload) =>
      http
          .patch(
              url,
              headers: const {
                'Content-Type': 'application/json; charset=UTF-8'
              },
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 60));

  /// Fetch all pick-up requests.
  Future<List<PickUpModel>> getAll() async {
    try {
      final url = _uri(_resource);
      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        return items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PickUpModel.fromJson(e)
                : PickUpModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw Exception(
          'Failed to load pick-up requests (${response.statusCode})');
    } catch (e, st) {
      _showError('Failed to fetch pick-up list');
      throw Exception('getAll pick-up error: $e\n$st');
    }
  }

  /// Insert a new pick-up request. Set [silent] true to suppress snackbars.
  Future<void> insert(PickUpModel data, {bool silent = false}) async {
    try {
      final dto = PickUpMapper.toInsertDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);

      final response = await _safePost(url, payload);
      if (response.statusCode == 200) {
        _showSuccess('Success saving...', silent: silent);
      } else {
        final msg =
            'Failed to insert pick-up. Status code: ${response.statusCode}';
        if (silent) {
          throw Exception(msg);
        } else {
          _showError(msg);
        }
      }
    } on TFormatException catch (_) {
      if (silent) rethrow;
      throw TFormatException();
    } on PlatformException catch (e) {
      if (silent) rethrow;
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Update an existing pick-up request. Optional [silent] to suppress snackbars.
  Future<void> updatePickUp(PickUpModel data, {bool silent = false}) async {
    try {
      // Use the shared mapper to build the update payload so mapping logic
      // is centralized and reusable.
      final dto = PickUpMapper.toUpdateDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);
      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = response.body;
        }
        String message;
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'].toString();
        } else if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'].toString();
        } else if (decoded is String) {
          message = decoded;
        } else {
          message = 'Update processed';
        }
        if (message.toLowerCase().contains('success')) {
          _showSuccess(message, silent: silent);
        } else {
          _showWarning(message, silent: silent);
        }
      } else {
        final msg =
            'Failed to update pick-up. Status code: ${response.statusCode}';
        if (silent) {
          throw Exception(msg);
        } else {
          _showError(msg);
        }
      }
    } on TFormatException catch (_) {
      if (silent) rethrow;
      throw TFormatException();
    } on PlatformException catch (e) {
      if (silent) rethrow;
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Update using a pre-built payload. This allows callers to prepare the
  /// payload (e.g. via a mapper) and send it directly.
  Future<void> updateWithPayload(Map<String, dynamic> payload,
      {bool silent = false}) async {
    try {
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);
      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = response.body;
        }
        String message;
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'].toString();
        } else if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'].toString();
        } else if (decoded is String) {
          message = decoded;
        } else {
          message = 'Update processed';
        }
        if (message.toLowerCase().contains('success')) {
          _showSuccess(message, silent: silent);
        } else {
          _showWarning(message, silent: silent);
        }
      } else {
        final msg =
            'Failed to update pick-up. Status code: ${response.statusCode}';
        if (silent) {
          throw Exception(msg);
        } else {
          _showError(msg);
        }
      }
    } on TFormatException catch (_) {
      if (silent) rethrow;
      throw TFormatException();
    } on PlatformException catch (e) {
      if (silent) rethrow;
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Cancel a pick-up request. Optional [silent] to suppress snackbars.
  Future<void> cancelPickUpAPI(String requestID, String remarks, String user,
      {bool silent = false}) async {
    try {
      final url =
          Uri.parse("${dotenv.env['API_URL']!}$_resource/cancel/$requestID/$user");
      final response = await http
          .patch(url,
              headers: const {
                'Content-Type': 'application/json; charset=UTF-8'
              },
              body: jsonEncode(remarks))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        _showSuccess('Success saving...', silent: silent);
      } else {
        final msg =
            'Failed to cancel pick-up. Status code: ${response.statusCode}';
        if (silent) {
          throw Exception(msg);
        } else {
          _showError(msg);
        }
      }
    } catch (e) {
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }
}

