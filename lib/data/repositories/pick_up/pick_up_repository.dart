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
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pick_up/pick_up_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Repository for pick-up request operations.
/// Handles API communication and local database sync for pick-up requests.
class PickUpRepository extends GetxController {
  static PickUpRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/RequestPickUp';

  PickUpDao? _daoInstance;

  /// Lazy getter for PickUpDao to avoid late initialization errors.
  /// Initializes the DAO on first access and caches it for subsequent calls.
  Future<PickUpDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = PickUpDao(db);
    return _daoInstance!;
  }

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

  /// Fetch all pick-up requests with local DB + API sync.
  /// Tries local DB first; if empty, fetches from API and caches locally.
  Future<List<PickUpModel>> getAll({bool forceRefresh = false}) async {
    try {
      final dao = await _dao;
      final isConnected = await NetworkManager.instance.isConnected();

      // If offline, return local data only
      if (!isConnected) {
        logDebug('PickUpRepository: Offline, returning local data');
        return await dao.getPickUps();
      }

      // If online and not forcing refresh, check if local DB has data
      if (!forceRefresh) {
        final hasLocalData = await dao.isPickUpTableNotEmpty();
        if (hasLocalData) {
          final localData = await dao.getPickUps();
          // Trigger background sync without blocking
          _syncFromApi();
          return localData;
        }
      }

      // Otherwise, fetch from API and cache
      logDebug('PickUpRepository: Fetching from API');
      final url = _uri(_resource);
      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        final pickUps = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PickUpModel.fromJson(e)
                : PickUpModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        // Cache to local DB
        try {
          await dao.deleteAll();
          await dao.insertPickUps(pickUps);
          logDebug('PickUpRepository: Cached ${pickUps.length} pick-ups to local DB');
        } catch (dbError) {
          logDebug('PickUpRepository: Failed to cache to local DB: $dbError');
        }

        return pickUps;
      }

      throw Exception(
          'Failed to load pick-up requests (${response.statusCode})');
    } catch (e, st) {
      logDebug('PickUpRepository.getAll error: $e\n$st');
      // If API fails, try returning local data as fallback
      try {
        final dao = await _dao;
        final localData = await dao.getPickUps();
        if (localData.isNotEmpty) {
          logDebug('PickUpRepository: API failed, returning ${localData.length} items from local DB');
          return localData;
        }
      } catch (dbError) {
        logDebug('PickUpRepository: Local DB also failed: $dbError');
      }
      _showError('Failed to fetch pick-up list');
      throw Exception('getAll pick-up error: $e\n$st');
    }
  }

  /// Background sync from API (non-blocking)
  Future<void> _syncFromApi() async {
    try {
      final url = _uri(_resource);
      final response = await _safeGet(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        final pickUps = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PickUpModel.fromJson(e)
                : PickUpModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (pickUps.isNotEmpty) {
          final dao = await _dao;
          await dao.deleteAll();
          await dao.insertPickUps(pickUps);
          logDebug('PickUpRepository: Background sync completed, ${pickUps.length} records');
        }
      }
    } catch (e) {
      logDebug('PickUpRepository: Background sync failed: $e');
      // Silent fail for background sync
    }
  }

  /// Insert a new pick-up request to API and local DB.
  Future<void> insert(PickUpModel data, {bool silent = false}) async {
    try {
      final dto = PickUpMapper.toInsertDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);

      final response = await _safePost(url, payload);
      if (response.statusCode == 200) {
        // Parse response to get the created ID if available
        PickUpModel updatedData = data;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('RequestID')) {
            updatedData = data.copyWith(id: decoded['RequestID'].toString());
            logDebug('PickUpRepository: Got RequestID from server: ${updatedData.id}');
          }
        } catch (parseError) {
          logDebug('PickUpRepository: Could not parse RequestID from response: $parseError');
        }

        // Save to local DB with the correct ID
        try {
          final dao = await _dao;
          await dao.insertPickUp(updatedData);
          logDebug('PickUpRepository: Saved to local DB with ID: ${updatedData.id}');
        } catch (dbError) {
          logDebug('PickUpRepository: Failed to save to local DB: $dbError');
          // Don't fail the whole operation if local DB save fails
        }

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
      logDebug('PickUpRepository.insert error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Update an existing pick-up request in API and local DB.
  Future<void> updatePickUp(PickUpModel data, {bool silent = false}) async {
    try {
      final dto = PickUpMapper.toUpdateDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);

      if (response.statusCode == 200) {
        // Update local DB
        try {
          final dao = await _dao;
          await dao.updatePickUp(pickUpModel: data);
          logDebug('PickUpRepository: Update successful, saved to local DB');
        } catch (dbError) {
          logDebug('PickUpRepository: Failed to update local DB: $dbError');
        }

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
      logDebug('PickUpRepository.updatePickUp error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Update using a pre-built payload and sync to local DB.
  Future<void> updateWithPayload(Map<String, dynamic> payload,
      {bool silent = false}) async {
    try {
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);

      if (response.statusCode == 200) {
        // Try to reconstruct model from payload to update local DB
        try {
          final model = PickUpModel.fromJson(payload);
          final dao = await _dao;
          await dao.updatePickUp(pickUpModel: model);
          logDebug('PickUpRepository: Payload update successful, saved to local DB');
        } catch (e) {
          logDebug('PickUpRepository: Could not update local DB from payload: $e');
        }

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
      logDebug('PickUpRepository.updateWithPayload error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Cancel a pick-up request via API and update local DB.
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
        // Update local DB to mark as cancelled
        try {
          // We need to fetch the full model to update it properly
          // For now, trigger a full refresh
          await getAll(forceRefresh: true);
          logDebug('PickUpRepository: Cancel successful, refreshed local DB');
        } catch (e) {
          logDebug('PickUpRepository: Could not update local DB after cancel: $e');
        }

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
      logDebug('PickUpRepository.cancelPickUpAPI error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Force refresh from API, clearing and reloading local cache.
  Future<List<PickUpModel>> refreshFromApi() async {
    return await getAll(forceRefresh: true);
  }

  /// Get pick-ups from local DB only (no API call).
  Future<List<PickUpModel>> getLocalPickUps() async {
    final dao = await _dao;
    return await dao.getPickUps();
  }

  /// Clear all local pick-up data.
  Future<void> clearLocalData() async {
    final dao = await _dao;
    await dao.deleteAll();
    logDebug('PickUpRepository: Local data cleared');
  }

  /// Check if local DB has any pick-up data.
  Future<bool> hasLocalData() async {
    final dao = await _dao;
    return await dao.isPickUpTableNotEmpty();
  }

  /// Get count of pick-ups in local DB.
  Future<int> getLocalDataCount() async {
    final dao = await _dao;
    final pickUps = await dao.getPickUps();
    return pickUps.length;
  }

  /// Debug method: Print local DB statistics.
  Future<void> printLocalDbInfo() async {
    try {
      final dao = await _dao;
      final hasData = await dao.isPickUpTableNotEmpty();
      final pickUps = await dao.getPickUps();

      logDebug('=== Pick-Up Local DB Info ===');
      logDebug('Has data: $hasData');
      logDebug('Total records: ${pickUps.length}');

      if (pickUps.isNotEmpty) {
        logDebug('First record ID: ${pickUps.first.id}');
        final statusMap = <String, int>{};
        for (final p in pickUps) {
          final status = p.status ?? 'Unknown';
          statusMap[status] = (statusMap[status] ?? 0) + 1;
        }
        logDebug('Status breakdown: $statusMap');
      }
      logDebug('=============================');
    } catch (e) {
      logDebug('PickUpRepository.printLocalDbInfo error: $e');
    }
  }
}

