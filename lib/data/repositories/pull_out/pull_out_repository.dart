import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/pull_out_mapper.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pull_out/pull_out_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/api_response_keys.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/b_in_flight_requests.dart';

class PullOutRepository extends GetxController {
  static PullOutRepository get instance => Get.find();

  String get _baseUrl => BApiEnvironment.api4BaseUrl;
  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse("$_baseUrl$path");
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  static const String _resource = '/api4/RequestPullOutReturnPickUp';

  PullOutDao? _daoInstance;

  /// Injects a DAO backed by a test database, bypassing [DatabaseHelper].
  @visibleForTesting
  set daoForTesting(PullOutDao dao) => _daoInstance = dao;

  /// Lazy getter for PullOutDao to avoid late initialization errors.
  /// Initializes the DAO on first access and caches it for subsequent calls.
  Future<PullOutDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = PullOutDao(db);
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

  /// Fetch all pull-out requests and cache them to the local Pull-Out table.
  /// [scope] narrows the fetch server-side via `?dateFilter=`. Offline and
  /// error fallbacks still return the whole local table; the caller's
  /// client-side filter narrows it.
  /// Collapses concurrent identical fetches (paired tabs share this repo).
  final BInFlightRequests _inFlight = BInFlightRequests();

  Future<List<PullOutModel>> getAll({
    bool forceRefresh = false,
    bool allowLocalFallback = true,
    RequestDateScope scope = RequestDateScope.all,
  }) =>
      _inFlight.run(
        'getAll:${scope.wireValue}:$forceRefresh:$allowLocalFallback',
        () => _getAllUncached(
            forceRefresh: forceRefresh,
            allowLocalFallback: allowLocalFallback,
            scope: scope),
      );

  Future<List<PullOutModel>> _getAllUncached({
    required bool forceRefresh,
    required bool allowLocalFallback,
    required RequestDateScope scope,
  }) async {
    try {
      final dao = await _dao;
      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        if (!allowLocalFallback) {
          throw Exception('No internet connection');
        }
        logDebug('PullOutRepository: Offline, returning local data');
        return await dao.getPullOutRequests();
      }

      if (!forceRefresh && await dao.isPullOutTableNotEmpty()) {
        final localData = await dao.getPullOutRequests();
        _syncFromApi(scope);
        return localData;
      }

      final url = _uri(_resource, scope.queryParameters);
      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);

        final requests = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PullOutModel.fromJson(e)
                : PullOutModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        await cacheRequests(requests, scope: scope);

        return requests;
      }
      throw Exception(
          'Failed to load pull-out requests (${response.statusCode})');
    } catch (e, st) {
      logDebug('PullOutRepository.getAll error: $e\n$st');
      if (!allowLocalFallback) {
        throw Exception('getAll pull-out error: $e\n$st');
      }
      try {
        final localData = await getLocalPullOuts();
        if (localData.isNotEmpty) {
          logDebug(
              'PullOutRepository: API failed, returning ${localData.length} local rows');
          return localData;
        }
      } catch (dbError) {
        logDebug('PullOutRepository: Local fallback failed: $dbError');
      }
      throw Exception('getAll pull-out error: $e\n$st');
    }
  }

  /// Writes [requests] to the local cache.
  ///
  /// A full-snapshot fetch ([RequestDateScope.all]) replaces the table
  /// wholesale. A *scoped* fetch only ever saw part of the data, so it upserts
  /// instead — wiping first would erase every other day's rows and break
  /// Local-storage mode and offline. Both insert paths are upserts, so changed
  /// rows still refresh; only server-side deletions linger, and `clearCache()`
  /// / the unscoped fetch still clear those.
  @visibleForTesting
  Future<void> cacheRequests(
    List<PullOutModel> requests, {
    required RequestDateScope scope,
  }) async {
    try {
      final dao = await _dao;
      if (scope == RequestDateScope.all) {
        await dao.deleteAll();
      }
      for (final request in requests) {
        await dao.insertPullOut(request);
      }
      logDebug(
          'PullOutRepository: Cached ${requests.length} pull-out requests to local DB (scope: ${scope.wireValue})');
    } catch (dbError) {
      logDebug('PullOutRepository: Failed to cache to local DB: $dbError');
    }
  }

  Future<void> _syncFromApi(
      [RequestDateScope scope = RequestDateScope.all]) {
    // A foreground fetch for this scope already refreshes the cache; a second
    // GET would be pure duplicate traffic.
    if (_inFlight.isAnyInFlight('getAll:${scope.wireValue}:')) {
      return Future.value();
    }
    return _inFlight.run(
        'sync:${scope.wireValue}', () => _syncFromApiUncached(scope));
  }

  Future<void> _syncFromApiUncached(RequestDateScope scope) async {
    try {
      final url = _uri(_resource, scope.queryParameters);
      final response = await _safeGet(url);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      final items = _decodeRootToList(decoded);
      final requests = items
          .whereType<dynamic>()
          .map((e) => e is Map<String, dynamic>
              ? PullOutModel.fromJson(e)
              : PullOutModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (requests.isEmpty) return;

      await cacheRequests(requests, scope: scope);
      logDebug(
          'PullOutRepository: Background sync completed, ${requests.length} records');
    } catch (e) {
      logDebug('PullOutRepository: Background sync failed: $e');
    }
  }

  /// Get pull-outs from local DB only (no API call).
  Future<List<PullOutModel>> getLocalPullOuts() async {
    final dao = await _dao;
    return await dao.getPullOutRequests();
  }

  /// Clear all local Pull-Out data.
  Future<void> clearLocalData() async {
    final dao = await _dao;
    await dao.deleteAll();
    logDebug('PullOutRepository: Local data cleared');
  }

  /// Insert a new pull-out request to API and local DB.
  ///
  /// When [items] are provided, they are posted to the shared
  /// `POST /api4/Item/request/{id}` endpoint after the request is created —
  /// the insert response carries the new RequestID the item post needs.
  Future<void> insert(PullOutModel data,
      {bool silent = false, List<InventoryItemModel>? items}) async {
    try {
      final dto = PullOutMapper.toInsertDto(data);
      final payload = dto.toJson();
      final url = _uri(_resource);

      logDebug('PullOutRepository.insert payload: ${jsonEncode(payload)}');

      final response = await _safePost(url, payload);
      if (response.statusCode == 201) {
        // Parse response to get the created ID if available
        PullOutModel updatedData = data;
        try {
          final decoded = jsonDecode(response.body);
          final parsedId = BApiResponse.requestId(decoded);
          if (parsedId != null) {
            updatedData = data.copyWith(id: parsedId);
            logDebug('PullOutRepository: Got RequestID from server: $parsedId');
          } else {
            logDebug(
                'PullOutRepository: create response carried no request id; '
                'relying on the refetch. Body: ${response.body}');
          }
        } catch (parseError) {
          logDebug(
              'PullOutRepository: Could not parse RequestID from response: $parseError');
        }

        if (items != null && items.isNotEmpty) {
          if (updatedData.id.isNotEmpty) {
            final itemsSaved =
                await _insertItemsForRequest(updatedData.id, items);
            if (!itemsSaved) {
              _showWarning(
                'Request created, but its items could not be saved. '
                'Please contact support to attach the items.',
              );
            }
          } else {
            _showWarning(
              'Request created, but the server did not return its ID — '
              'items were not saved.',
            );
          }
        }

        // Save to local DB with the correct ID
        try {
          final dao = await _dao;
          await dao.insertPullOut(updatedData);
          logDebug(
              'PullOutRepository: Saved to local DB with ID: ${updatedData.id}');
        } catch (dbError) {
          logDebug('PullOutRepository: Failed to save to local DB: $dbError');
          // Don't fail the whole operation if local DB save fails
        }

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
      logDebug('PullOutRepository.insert error: $e');
      if (silent) {
        rethrow;
      } else {
        _showError('An error occurred: $e');
      }
    }
  }

  /// Post scanned items for a freshly created request to the shared Item
  /// endpoint. Returns true when the server accepted them.
  Future<bool> _insertItemsForRequest(
      String requestId, List<InventoryItemModel> items) async {
    try {
      final url = _uri('/api4/Item/request/$requestId');
      final response = await http
          .post(url,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(items.map((e) => e.toJson()).toList()))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        logDebug(
            'PullOutRepository: Saved ${items.length} items for request $requestId');
        return true;
      }
      logDebug(
          'PullOutRepository: Item insert failed (${response.statusCode}): ${response.body}');
      return false;
    } catch (e) {
      logDebug('PullOutRepository._insertItemsForRequest error: $e');
      return false;
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
      final url = _uri('$_resource/cancel/$requestID/$user');
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
