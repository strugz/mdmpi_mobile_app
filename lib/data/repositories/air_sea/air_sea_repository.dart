import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_status_stages_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/air_sea_mapper.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/air_sea/air_sea_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';

/// Repository for Air/Sea request operations.
/// Handles API communication and local database sync for Air/Sea requests.
class AirSeaRepository extends GetxController {
  static AirSeaRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/RequestAirSea';

  AirSeaDao? _daoInstance;

  /// Lazy getter for AirSeaDao to avoid late initialization errors.
  /// Initializes the DAO on first access and caches it for subsequent calls.
  Future<AirSeaDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = AirSeaDao(db);
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

  /// Fetch all Air/Sea requests with local DB + API sync.
  /// Tries local DB first; if empty, fetches from API and caches locally.
  Future<List<AirSeaModel>> getAll({bool forceRefresh = false}) async {
    try {
      final dao = await _dao;
      final isConnected = await NetworkManager.instance.isConnected();

      // If offline, return local data only
      if (!isConnected) {
        return await dao.getAirSeaRequests();
      }

      if (!forceRefresh) {
        final hasLocalData = await dao.isAirSeaTableNotEmpty();
        if (hasLocalData) {
          final localData = await dao.getAirSeaRequests();
          _syncFromApi();
          return localData;
        }
      }
      final url = _uri(_resource);

      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);

        final airSeaRequests = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? AirSeaModel.fromJson(e)
                : AirSeaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Cache to local DB
        try {
          await dao.deleteAll();
          await dao.insertAirSeaRequests(airSeaRequests);
          logDebug(
              'AirSeaRepository: Cached ${airSeaRequests.length} Air/Sea requests to local DB');
        } catch (dbError) {
          logDebug('AirSeaRepository: Failed to cache to local DB: $dbError');
        }

        return airSeaRequests;
      }

      throw Exception(
          'Failed to load Air/Sea requests (${response.statusCode})');
    } catch (e, st) {
      logDebug('AirSeaRepository.getAll error: $e\n$st');
      // If API fails, try returning local data as fallback
      try {
        final dao = await _dao;
        final localData = await dao.getAirSeaRequests();
        if (localData.isNotEmpty) {
          logDebug(
              'AirSeaRepository: API failed, returning ${localData.length} items from local DB');
          return localData;
        }
      } catch (dbError) {
        logDebug('AirSeaRepository: Local DB also failed: $dbError');
      }
      _showError('Failed to fetch Air/Sea list');
      throw Exception('getAll Air/Sea error: $e\n$st');
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
        final airSeaRequests = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? AirSeaModel.fromJson(e)
                : AirSeaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (airSeaRequests.isNotEmpty) {
          final dao = await _dao;
          await dao.deleteAll();
          await dao.insertAirSeaRequests(airSeaRequests);
          logDebug(
              'AirSeaRepository: Background sync completed, ${airSeaRequests.length} records');
        }
      }
    } catch (e) {
      logDebug('AirSeaRepository: Background sync failed: $e');
      // Silent fail for background sync
    }
  }

  /// Insert a new Air/Sea request to API and local DB.
  Future<void> insert(AirSeaModel data, {bool silent = false}) async {
    try {
      final dto = AirSeaMapper.toInsertDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);

      final response = await _safePost(url, payload);
      if (response.statusCode == 201) {
        // Parse response to get the created ID if available
        AirSeaModel updatedData = data;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('RequestID')) {
            updatedData = data.copyWith(id: decoded['RequestID'].toString());
            logDebug(
                'AirSeaRepository: Got RequestID from server: ${updatedData.id}');
          }
        } catch (parseError) {
          logDebug(
              'AirSeaRepository: Could not parse RequestID from response: $parseError');
        }

        // Save to local DB with the correct ID
        try {
          final dao = await _dao;
          await dao.insertAirSea(updatedData);
          logDebug(
              'AirSeaRepository: Saved to local DB with ID: ${updatedData.id}');
        } catch (dbError) {
          logDebug('AirSeaRepository: Failed to save to local DB: $dbError');
          // Don't fail the whole operation if local DB save fails
        }

        _showSuccess('Success saving...', silent: silent);
      } else {
        final msg =
            'Failed to insert Air/Sea request. Status code: ${response.statusCode}';
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
      logDebug('AirSeaRepository.insert error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Update an existing Air/Sea request in API and local DB.
/*
  Future<void> updateAirSea(AirSeaModel data, String actionBy, {bool silent = false}) async {
    try {
      final dto = AirSeaMapper.toUpdateDto(data, actionBy);
      final payload = dto.toJson();
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);
      if (response.statusCode == 200) {
        // Update local DB
        try {
          final dao = await _dao;
          await dao.updateAirSea(airSeaModel: data);
          logDebug('AirSeaRepository: Update successful, saved to local DB');
        } catch (dbError) {
          logDebug('AirSeaRepository: Failed to update local DB: $dbError');
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
            'Failed to update Air/Sea request. Status code: ${response.statusCode}';
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
      logDebug('AirSeaRepository.updateAirSea error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }
*/

  /// Update using a pre-built payload and sync to local DB.
  Future<void> updateWithPayload(Map<String, dynamic> payload,
      {bool silent = false}) async {
    try {
      final url = _uri(_resource);
      final response = await _safePatch(url, payload);

      if (response.statusCode == 200) {
        // Try to reconstruct model from payload to update local DB
        try {
          final model = AirSeaModel.fromJson(payload);
          final dao = await _dao;
          await dao.updateAirSea(airSeaModel: model);
          logDebug(
              'AirSeaRepository: Payload update successful, saved to local DB');
        } catch (e) {
          logDebug(
              'AirSeaRepository: Could not update local DB from payload: $e');
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
            'Failed to update Air/Sea request. Status code: ${response.statusCode}';
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
      logDebug('AirSeaRepository.updateWithPayload error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Cancel an Air/Sea request via API and update local DB.
  Future<void> cancelAirSeaAPI(String requestID, String remarks, String user,
      {bool silent = false}) async {
    try {
      final url = Uri.parse(
          "${dotenv.env['API_URL']!}$_resource/cancel/$requestID/$user");
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
          logDebug('AirSeaRepository: Cancel successful, refreshed local DB');
        } catch (e) {
          logDebug(
              'AirSeaRepository: Could not update local DB after cancel: $e');
        }

        _showSuccess('Success saving...', silent: silent);
      } else {
        final msg =
            'Failed to cancel Air/Sea request. Status code: ${response.statusCode}';
        if (silent) {
          throw Exception(msg);
        } else {
          _showError(msg);
        }
      }
    } catch (e) {
      logDebug('AirSeaRepository.cancelAirSeaAPI error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Force refresh from API, clearing and reloading local cache.
  Future<List<AirSeaModel>> refreshFromApi() async {
    return await getAll(forceRefresh: true);
  }

  /// Get Air/Sea requests from local DB only (no API call).
  Future<List<AirSeaModel>> getLocalAirSeaRequests() async {
    final dao = await _dao;
    return await dao.getAirSeaRequests();
  }

  /// Fetch status/history stages for a request from the remote API.
  ///
  /// Uses the inventory endpoint: https://inventory.mdmpi.com.ph/api4/requestairsea/history/{requestId}
  /// Returns an empty list on failure or when offline (and shows a user-visible
  /// message unless [silent] is true).
  Future<List<AirSeaStatusStagesModel>> fetchHistoryByRequestId(
      String requestId,
      {bool silent = false}) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        _showWarning('Offline: cannot fetch request history', silent: silent);
        return <AirSeaStatusStagesModel>[];
      }

      final url = Uri.parse(
          'https://inventory.mdmpi.com.ph/api4/requestairsea/history/$requestId');

      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);

        final history = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? AirSeaStatusStagesModel.fromJson(e)
                : AirSeaStatusStagesModel.fromJson(
                    Map<String, dynamic>.from(e)))
            .toList();

        logDebug(
            'AirSeaRepository: Fetched ${history.length} history items for $requestId');
        return history;
      }

      final msg = 'Failed to fetch request history (${response.statusCode})';
      if (!silent) _showError(msg);
      logDebug('AirSeaRepository.fetchHistoryByRequestId: $msg');
      return <AirSeaStatusStagesModel>[];
    } catch (e, st) {
      logDebug('AirSeaRepository.fetchHistoryByRequestId error: $e\n$st');
      if (!silent) _showError('Failed to fetch request history');
      return <AirSeaStatusStagesModel>[];
    }
  }

  /// Get a single Air/Sea request by ID from local DB.
  Future<AirSeaModel?> getLocalById(String requestId) async {
    final dao = await _dao;
    return await dao.getAirSeaById(requestId);
  }

  /// Clear all local Air/Sea data.
  Future<void> clearLocalData() async {
    final dao = await _dao;
    await dao.deleteAll();
    logDebug('AirSeaRepository: Local data cleared');
  }

  /// Check if local DB has any Air/Sea data.
  Future<bool> hasLocalData() async {
    final dao = await _dao;
    return await dao.isAirSeaTableNotEmpty();
  }

  /// Get count of Air/Sea requests in local DB.
  Future<int> getLocalDataCount() async {
    final dao = await _dao;
    final requests = await dao.getAirSeaRequests();
    return requests.length;
  }

  /// Debug method: Print local DB statistics.
  Future<void> printLocalDbInfo() async {
    try {
      final dao = await _dao;
      final hasData = await dao.isAirSeaTableNotEmpty();
      final requests = await dao.getAirSeaRequests();

      logDebug('=== Air/Sea Local DB Info ===');
      logDebug('Has data: $hasData');
      logDebug('Total records: ${requests.length}');

      if (requests.isNotEmpty) {
        logDebug('First record ID: ${requests.first.id}');
        final statusMap = <String, int>{};
        for (final r in requests) {
          final status = r.status.isNotEmpty ? r.status : 'Unknown';
          statusMap[status] = (statusMap[status] ?? 0) + 1;
        }
        logDebug('Status breakdown: $statusMap');
      }
      logDebug('=============================');
    } catch (e) {
      logDebug('AirSeaRepository.printLocalDbInfo error: $e');
    }
  }

  /// Endorse Air/Sea request to guard with signature capture.
  ///
  /// Captures guard information and signature when items need to be handed
  /// off to security/authorized personnel.
  ///
  /// [requestId] The request ID to endorse
  /// [endorsedTo] Name of the guard/authorized person
  /// [signatureBase64] Base64 encoded signature of the guard
  /// [remarks] Optional notes about the endorsement
  /// [silent] If true, suppresses UI notifications
  Future<bool> endorseToGuard({
    required String requestId,
    required String endorsedTo,
    required String signatureBase64,
    String? remarks,
    bool silent = false,
  }) async {
    try {
      final userController = Get.find<UserController>();
      final currentUser = userController.user.value;

      // 1. Upload signature first if connected
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected && signatureBase64.isNotEmpty) {
        try {
          await ImageRepository.instance.uploadFile(
            requestId: requestId,
            base64Image: signatureBase64,
            type: 'endorsement_signature',
          );
          logDebug('AirSeaRepository: Endorsement signature uploaded');
        } catch (e) {
          logDebug('AirSeaRepository: Failed to upload signature: $e');
          // Continue anyway, signature upload is not critical
        }
      }

      // 2. Prepare update payload
      final now = DateTime.now();
      final payload = {
        'RequestID': requestId,
        'EndorsedTo': endorsedTo,
        'EndorsedAt': now.toIso8601String(),
        'EndorsedBy': currentUser.initial,
        'Status': 'Endorsed to Guard',
        'Remarks': remarks ?? '',
        'UpdatedAt': now.toIso8601String(),
      };

      // 3. Update via API if connected
      if (isConnected) {
        final url = _uri(_resource);
        final response = await _safePatch(url, payload);

        if (response.statusCode != 200) {
          final msg = 'Failed to endorse. Status: ${response.statusCode}';
          if (!silent) _showError(msg);
          return false;
        }

        logDebug('AirSeaRepository: Endorsement successful via API');
      }

      // 4. Update local database
      try {
        final dao = await _dao;
        final existing = await dao.getAirSeaById(requestId);

        if (existing != null) {
          final updated = existing.copyWith(
            status: 'Endorsed to Guard',
            remarks: remarks ?? existing.remarks,
            updatedAt: now.toString(),
          );

          await dao.updateAirSea(airSeaModel: updated);
          logDebug('AirSeaRepository: Local DB updated after endorsement');
        }
      } catch (e) {
        logDebug('AirSeaRepository: Failed to update local DB: $e');
      }

      if (!silent) {
        _showSuccess('Request endorsed to $endorsedTo successfully');
      }

      return true;
    } on TFormatException catch (_) {
      if (!silent) _showError('Format error during endorsement');
      return false;
    } on PlatformException catch (e) {
      if (!silent) _showError('Platform error: ${e.message}');
      return false;
    } catch (e) {
      logDebug('AirSeaRepository.endorseToGuard error: $e');
      if (!silent) _showError('Failed to endorse: $e');
      return false;
    }
  }

  /// Mark Air/Sea request as received with waybill number.
  ///
  /// Records final receipt of items with waybill tracking and optional
  /// receiver signature.
  ///
  /// [requestId] The request ID to mark as received
  /// [waybillNumber] Waybill/tracking number for the shipment
  /// [signatureBase64] Optional base64 encoded signature of receiver
  /// [remarks] Optional notes about the receipt
  /// [silent] If true, suppresses UI notifications
  Future<bool> receiveRequest({
    required String requestId,
    required String waybillNumber,
    String? signatureBase64,
    String? remarks,
    bool silent = false,
  }) async {
    try {
      final userController = Get.find<UserController>();
      final currentUser = userController.user.value;

      // 1. Upload optional receiver signature if provided
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected &&
          signatureBase64 != null &&
          signatureBase64.isNotEmpty) {
        try {
          await ImageRepository.instance.uploadFile(
            requestId: requestId,
            base64Image: signatureBase64,
            type: 'receiver_signature',
          );
          logDebug('AirSeaRepository: Receiver signature uploaded');
        } catch (e) {
          logDebug('AirSeaRepository: Failed to upload receiver signature: $e');
          // Continue anyway
        }
      }

      // 2. Prepare update payload
      final now = DateTime.now();
      final payload = {
        'RequestID': requestId,
        'WaybillNumber': waybillNumber,
        'ReceivedAt': now.toIso8601String(),
        'ReceivedBy': currentUser.initial,
        'Status': 'Received',
        'Remarks': remarks ?? '',
        'UpdatedAt': now.toIso8601String(),
      };

      // 3. Update via API if connected
      if (isConnected) {
        final url = _uri(_resource);
        final response = await _safePatch(url, payload);

        if (response.statusCode != 200) {
          final msg =
              'Failed to mark as received. Status: ${response.statusCode}';
          if (!silent) _showError(msg);
          return false;
        }

        logDebug('AirSeaRepository: Marked as received via API');
      }

      // 4. Update local database
      try {
        final dao = await _dao;
        final existing = await dao.getAirSeaById(requestId);

        if (existing != null) {
          final updated = existing.copyWith(
            waybillNumber: waybillNumber,
            status: 'Received',
            remarks: remarks ?? existing.remarks,
            updatedAt: now.toString(),
          );

          await dao.updateAirSea(airSeaModel: updated);
          logDebug('AirSeaRepository: Local DB updated after receipt');
        }
      } catch (e) {
        logDebug('AirSeaRepository: Failed to update local DB: $e');
      }

      if (!silent) {
        _showSuccess('Request marked as received with waybill $waybillNumber');
      }

      return true;
    } on TFormatException catch (_) {
      if (!silent) _showError('Format error during receipt');
      return false;
    } on PlatformException catch (e) {
      if (!silent) _showError('Platform error: ${e.message}');
      return false;
    } catch (e) {
      logDebug('AirSeaRepository.receiveRequest error: $e');
      if (!silent) _showError('Failed to mark as received: $e');
      return false;
    }
  }
}
