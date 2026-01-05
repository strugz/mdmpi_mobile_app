import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/pull_out_mapper.dart';

class PullOutRepository extends GetxController {
  static PullOutRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/RequestPullOutReturnPickUp';

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

  /// Fetch all pull-out requests.
  /// [forceRefresh] is accepted for API compatibility but currently has no effect
  /// since PullOut doesn't have local DB caching yet.
  Future<List<PullOutModel>> getAll({bool forceRefresh = false}) async {
    try {
      final url = _uri(_resource);
      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        return items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PullOutModel.fromJson(e)
                : PullOutModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw Exception(
          'Failed to load pull-out requests (${response.statusCode})');
    } catch (e, st) {
      _showError('Failed to fetch pull-out list');
      throw Exception('getAll pull-out error: $e\n$st');
    }
  }

  /// Get pull-outs from local DB only (no API call).
  /// Currently just redirects to getAll() since PullOut doesn't have local DB yet.
  /// This method exists for API compatibility with other repositories.
  Future<List<PullOutModel>> getLocalPullOuts() async {
    // TODO: Implement local DB support for pull-out requests
    return await getAll();
  }

  /// Insert a new pull-out request. Set [silent] true to suppress snackbars.
  Future<void> insert(PullOutModel data, {bool silent = false}) async {
    try {
      final dto = PullOutMapper.toInsertDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);

      final response = await _safePost(url, payload);
      if (response.statusCode == 201) {
        _showSuccess('Success saving...', silent: silent);
      } else {
        final msg =
            'Failed to insert pull-out. Status code: ${response.statusCode}';
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

  /// Update an existing pull-out request. Optional [silent] to suppress snackbars.
  Future<void> updatePullOut(PullOutModel data, {bool silent = false}) async {
    try {
      // Use the shared mapper to build the update payload so mapping logic
      // is centralized and reusable.
      final payload = PullOutMapper.toUpdateDto(data);
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
            'Failed to update pull-out. Status code: ${response.statusCode}';
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
            'Failed to update pull-out. Status code: ${response.statusCode}';
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

  /// Cancel a pull-out request. Optional [silent] to suppress snackbars.
  Future<void> cancelPullOutAPI(String requestID, String remarks, String user,
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
            'Failed to cancel pull-out. Status code: ${response.statusCode}';
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
