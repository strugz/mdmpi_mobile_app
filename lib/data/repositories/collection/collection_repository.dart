import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';

/// Repository for collection operations.
/// Handles API communication and local database sync for collection items.
///
/// Offline-first pattern:
/// - Read: local DB first if available; if offline or empty, fetch from API
/// - Write: local DB + API (dual-write pattern with server-wins on full refresh)
/// - Pending changes: queued in local table for retry on connectivity restore
class CollectionRepository extends GetxController {
  static CollectionRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  // API endpoint for fetching collection items
  static const String _resource = '/api/collection/items';

  CollectionDao? _daoInstance;

  /// Lazy getter for CollectionDao to avoid late initialization errors.
  /// Initializes the DAO on first access and caches it for subsequent calls.
  Future<CollectionDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = CollectionDao(db);
    return _daoInstance!;
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

  /// Performs a GET request with timeout and returns the response.
  Future<http.Response> _safeGet(Uri url) =>
      http.get(url).timeout(const Duration(seconds: 60));

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

  /// Fetch all collection items with local DB + API sync.
  /// Tries local DB first; if empty, fetches from API and caches locally.
  ///
  /// Parameters:
  /// - [forceRefresh]: if true, bypasses local cache and fetches fresh from API
  /// - [silent]: if true, suppresses user-facing messages
  Future<List<CollectionItemModel>> getAll({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    try {
      final dao = await _dao;
      final isConnected = await NetworkManager.instance.isConnected();

      // If offline, return local data only
      if (!isConnected) {
        logDebug('CollectionRepository: Offline, returning local data');
        return await dao.getCollectionItems();
      }

      // If online and not forcing refresh, check if local DB has data
      if (!forceRefresh) {
        final hasLocalData = await dao.hasCollectionItems();
        if (hasLocalData) {
          final localData = await dao.getCollectionItems();
          // Trigger background sync without blocking
          _syncFromApi();
          return localData;
        }
      }

      // Otherwise, fetch from API and cache
      logDebug('CollectionRepository: Fetching from API');
      final url = _uri(_resource);
      final response = await _safeGet(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        final collectionItems = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? CollectionItemModel.fromJson(e)
                : CollectionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Cache to local DB
        try {
          await dao.deleteAllCollectionItems();
          await dao.insertCollectionItems(collectionItems);
          logDebug('CollectionRepository: Cached ${collectionItems.length} items to local DB');
        } catch (dbError) {
          logDebug('CollectionRepository: Failed to cache to local DB: $dbError');
        }

        return collectionItems;
      }

      throw Exception(
          'Failed to load collection items (${response.statusCode})');
    } catch (e, st) {
      logDebug('CollectionRepository.getAll error: $e\n$st');
      // If API fails, try returning local data as fallback
      try {
        final dao = await _dao;
        final localData = await dao.getCollectionItems();
        if (localData.isNotEmpty) {
          logDebug('CollectionRepository: API failed, returning ${localData.length} items from local DB');
          return localData;
        }
      } catch (dbError) {
        logDebug('CollectionRepository: Local DB also failed: $dbError');
      }
      _showError('Failed to fetch collection items', silent: silent);
      throw Exception('getAll collection items error: $e\n$st');
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
        final collectionItems = items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? CollectionItemModel.fromJson(e)
                : CollectionItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (collectionItems.isNotEmpty) {
          final dao = await _dao;
          await dao.deleteAllCollectionItems();
          await dao.insertCollectionItems(collectionItems);
          logDebug('CollectionRepository: Background sync completed, ${collectionItems.length} records');
        }
      }
    } catch (e) {
      logDebug('CollectionRepository: Background sync failed: $e');
      // Silent fail for background sync
    }
  }

  /// Claim items by IDs (move to activity)
  Future<void> claimItemsByIds(List<String> ids, {bool silent = false}) async {
    try {
      final dao = await _dao;
      final now = DateTime.now().toIso8601String();

      // Update local DB first (optimistic)
      for (final id in ids) {
        final item = await dao.getCollectionItemById(id);
        if (item != null) {
          final updated = item.copyWith(
            status: '',
            assignedAt: now,
          );
          await dao.updateCollectionItem(updated);
        }
      }

      _showSuccess('Items claimed successfully', silent: silent);
      logDebug('CollectionRepository: Claimed ${ids.length} items');
    } catch (e) {
      logDebug('CollectionRepository.claimItemsByIds error: $e');
      _showError('Failed to claim items', silent: silent);
      if (!silent) rethrow;
    }
  }

  /// Save activity for an item
  Future<void> saveActivity({
    required String id,
    required String status,
    required String remarks,
    double? totalCollected,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async {
    try {
      final dao = await _dao;
      final item = await dao.getCollectionItemById(id);
      if (item == null) {
        throw Exception('Item not found: $id');
      }

       final now = DateTime.now().toIso8601String();
       final newlyCollected = totalCollected ?? 0.0;
       final updatedTotalCollected = item.totalCollected + newlyCollected;
       final updatedToBeCollected = (item.toBeCollected - newlyCollected).clamp(0.0, double.infinity);
          (item.toBeCollected - newlyCollected).clamp(0, double.infinity);
      final isFullyPaid = updatedToBeCollected == 0;

      // Create history entry
      final historyEntry = CollectionHistoryModel(
        date: now,
        collectorName: '',
        status: status,
        remarks: remarks,
        totalCollected: newlyCollected,
        bankName: bankName,
        checkNumber: checkNumber,
        checkDate: checkDate,
        purposeOfVisit: purposeOfVisit,
      );

      // Update item
      final updatedItem = item.copyWith(
        status: isFullyPaid ? 'Collected' : '',
        lastOutcome: status,
        remarks: remarks,
        toBeCollected: updatedToBeCollected,
        totalCollected: updatedTotalCollected,
        history: [...item.history, historyEntry],
        assignedAt: isFullyPaid ? '' : item.assignedAt,
      );

      // Save to local DB
      await dao.updateCollectionItem(updatedItem);

      _showSuccess('Activity saved successfully', silent: silent);
      logDebug('CollectionRepository: Activity saved for $id');
    } catch (e) {
      logDebug('CollectionRepository.saveActivity error: $e');
      _showError('Failed to save activity', silent: silent);
      if (!silent) rethrow;
    }
  }

  /// Save batch activity for multiple items
  Future<void> saveBatchActivity({
    required List<String> ids,
    required Map<String, String> statuses,
    required Map<String, String> remarks,
    required Map<String, double> amounts,
    double totalAmountReceived = 0,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async {
    try {
      final dao = await _dao;
      final now = DateTime.now().toIso8601String();

       for (final id in ids) {
         final item = await dao.getCollectionItemById(id);
         if (item == null) continue;

         final manualAmount = amounts[id] ?? 0.0;
         final itemRemarks = remarks[id] ?? 'Batch Recording';
         final itemStatus = statuses[id] ?? '';

         final updatedTotalCollected = item.totalCollected + manualAmount;
         final updatedToBeCollected =
             (item.toBeCollected - manualAmount).clamp(0.0, double.infinity);
         final isFullyPaid = updatedToBeCollected == 0;

        final historyEntry = CollectionHistoryModel(
          date: now,
          collectorName: '',
          status: itemStatus,
          remarks: itemRemarks,
          totalCollected: manualAmount,
          bankName: bankName,
          checkNumber: checkNumber,
          checkDate: checkDate,
          purposeOfVisit: purposeOfVisit,
        );

        final updatedItem = item.copyWith(
          status: isFullyPaid ? 'Collected' : '',
          lastOutcome: itemStatus,
          remarks: itemRemarks,
          toBeCollected: updatedToBeCollected,
          totalCollected: updatedTotalCollected,
          history: [...item.history, historyEntry],
          assignedAt: isFullyPaid ? '' : item.assignedAt,
        );

        await dao.updateCollectionItem(updatedItem);
      }

      _showSuccess('Batch activity saved successfully', silent: silent);
      logDebug('CollectionRepository: Batch activity saved for ${ids.length} items');
    } catch (e) {
      logDebug('CollectionRepository.saveBatchActivity error: $e');
      _showError('Failed to save batch activity', silent: silent);
      if (!silent) rethrow;
    }
  }

  /// Force refresh from API, clearing and reloading local cache.
  Future<List<CollectionItemModel>> refreshFromApi({bool silent = false}) async {
    return await getAll(forceRefresh: true, silent: silent);
  }

  /// Get collection items from local DB only (no API call).
  Future<List<CollectionItemModel>> getLocalCollectionItems() async {
    final dao = await _dao;
    return await dao.getCollectionItems();
  }

  /// Clear all local collection data.
  Future<void> clearLocalData() async {
    final dao = await _dao;
    await dao.deleteAllCollectionItems();
    logDebug('CollectionRepository: Local data cleared');
  }

  /// Check if local DB has any collection data.
  Future<bool> hasLocalData() async {
    final dao = await _dao;
    return await dao.hasCollectionItems();
  }

  /// Get count of collection items in local DB.
  Future<int> getLocalDataCount() async {
    final dao = await _dao;
    return await dao.getCollectionItemCount();
  }

  /// Debug method: Print local DB statistics.
  Future<void> printLocalDbInfo() async {
    try {
      final dao = await _dao;
      final hasData = await dao.hasCollectionItems();
      final items = await dao.getCollectionItems();

      logDebug('=== Collection Local DB Info ===');
      logDebug('Has data: $hasData');
      logDebug('Total items: ${items.length}');
      if (items.isNotEmpty) {
        logDebug('First item ID: ${items.first.id}');
      }
      logDebug('================================');
    } catch (e) {
      logDebug('CollectionRepository.printLocalDbInfo error: $e');
    }
  }
}








