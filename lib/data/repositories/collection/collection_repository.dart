import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/features/collection/mappers/collection_mapper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Summary of an "Upload All" attempt.
class CollectionUploadResult {
  final int accepted;
  final List<String> rejected; // human-readable "reason" strings

  const CollectionUploadResult({this.accepted = 0, this.rejected = const []});

  int get rejectedCount => rejected.length;
  bool get hasRejections => rejected.isNotEmpty;
}

/// Repository for collection operations.
/// Handles API communication and local database sync for collection items.
///
/// Offline-first pattern:
/// - Read: local DB first if available; if offline or empty, fetch from API
/// - Write: local DB + API (dual-write pattern with server-wins on full refresh)
/// - Pending changes: queued in local table for retry on connectivity restore
class CollectionRepository extends GetxController {
  static CollectionRepository get instance => Get.find();

  // Collection API lives behind /api4 (MDMPI.App backend), resolved the same way
  // as the Logistics repositories via BApiEnvironment.
  static const String _bucketPath = '/api4/Collection/bucket';
  static const String _uploadPath = '/api4/Collection/upload';
  static const String _invoicesPath = '/api4/Collection/invoices';

  /// The signed-in collector's stable code (used for ?collector= and CLAIM).
  String get collectorCode {
    final user = Get.find<UserController>().user.value;
    return user.username.isNotEmpty ? user.username : user.id;
  }

  /// The collector's display name written onto engagements/history.
  String get collectorName {
    final user = Get.find<UserController>().user.value;
    final name = user.fullName.trim();
    return name.isNotEmpty ? name : collectorCode;
  }

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

  /// The bucket endpoint for the signed-in collector (shared pool + own claims).
  Uri _bucketUri() => BApiEnvironment.api4Uri(_bucketPath)
      .replace(queryParameters: {'collector': collectorCode});

  /// Parse an API item list into domain models via the DTO + mapper layer.
  List<CollectionItemModel> _parseItems(List<dynamic> items) {
    final dtos = items
        .map((e) => CollectionItemDto.fromJson(e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e as Map)))
        .toList();
    return CollectionMapper.toDomainModels(dtos);
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
      logDebug('CollectionRepository: Fetching bucket for $collectorCode');
      final response = await _safeGet(_bucketUri());

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        final collectionItems = _parseItems(items);

        // Cache to local DB
        try {
          await dao.deleteAllCollectionItems();
          await dao.insertCollectionItems(collectionItems);
          logDebug(
              'CollectionRepository: Cached ${collectionItems.length} items to local DB');
        } catch (dbError) {
          logDebug(
              'CollectionRepository: Failed to cache to local DB: $dbError');
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
          logDebug(
              'CollectionRepository: API failed, returning ${localData.length} items from local DB');
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
      final response = await _safeGet(_bucketUri());

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final items = _decodeRootToList(decoded);
        final collectionItems = _parseItems(items);
        if (collectionItems.isNotEmpty) {
          final dao = await _dao;
          await dao.deleteAllCollectionItems();
          await dao.insertCollectionItems(collectionItems);
          logDebug(
              'CollectionRepository: Background sync completed, ${collectionItems.length} records');
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

      // Update local DB first (optimistic): mark the item claimed by this
      // collector. Server-side first-wins is resolved later at Upload All.
      final name = collectorName;
      for (final id in ids) {
        final item = await dao.getCollectionItemById(id);
        if (item != null) {
          final updated = item.copyWith(
            status: '',
            assignedAt: now,
            collectorName: name,
          );
          await dao.updateCollectionItem(updated);
          await _queueChange('CLAIM', id, {'EngagementDate': now});
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
      final updatedToBeCollected =
          (item.toBeCollected - newlyCollected).clamp(0.0, double.infinity);
      final isFullyPaid = updatedToBeCollected == 0;

      // Create history entry
      final historyEntry = CollectionHistoryModel(
        date: now,
        collectorName: collectorName,
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

      // Queue for end-of-day upload.
      await _queueChange('SAVE_ACTIVITY', id, {
        'EngagementDate': now,
        'Status': status,
        'Remarks': remarks,
        'AmountCollected': newlyCollected,
        'BankName': bankName,
        'CheckNo': checkNumber,
        'CheckDate': checkDate,
        'PurposeOfVisit': purposeOfVisit,
      });

      // Notify the collection head (Android, over cellular — works offline).
      unawaited(_notifySms((sms) => sms.notifyEngagement(
            clientName: item.client.name,
            amountCollected: newlyCollected,
            outcome: status,
            collectorName: collectorName,
            documentReference: item.documentReferences.isNotEmpty
                ? item.documentReferences.first
                : '',
          )));

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
      final name = collectorName;

      String batchClientName = '';
      double batchTotal = 0;
      int batchCount = 0;

      for (final id in ids) {
        final item = await dao.getCollectionItemById(id);
        if (item == null) continue;

        final manualAmount = amounts[id] ?? 0.0;
        if (batchClientName.isEmpty) batchClientName = item.client.name;
        batchTotal += manualAmount;
        batchCount++;
        final itemRemarks = remarks[id] ?? 'Batch Recording';
        final itemStatus = statuses[id] ?? '';

        final updatedTotalCollected = item.totalCollected + manualAmount;
        final updatedToBeCollected =
            (item.toBeCollected - manualAmount).clamp(0.0, double.infinity);
        final isFullyPaid = updatedToBeCollected == 0;

        final historyEntry = CollectionHistoryModel(
          date: now,
          collectorName: name,
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

        await _queueChange('BATCH_ACTIVITY', id, {
          'EngagementDate': now,
          'Status': itemStatus,
          'Remarks': itemRemarks,
          'AmountCollected': manualAmount,
          'BankName': bankName,
          'CheckNo': checkNumber,
          'CheckDate': checkDate,
          'PurposeOfVisit': purposeOfVisit,
        });
      }

      // One summary SMS to the collection head for the batch.
      if (batchCount > 0) {
        unawaited(_notifySms((sms) => sms.notifyBatch(
              clientName: batchClientName,
              invoiceCount: batchCount,
              totalAmount:
                  totalAmountReceived > 0 ? totalAmountReceived : batchTotal,
              collectorName: name,
            )));
      }

      _showSuccess('Batch activity saved successfully', silent: silent);
      logDebug('CollectionRepository: Batch activity saved for ${ids.length} items');

    } catch (e) {
      logDebug('CollectionRepository.saveBatchActivity error: $e');
      _showError('Failed to save batch activity', silent: silent);
      if (!silent) rethrow;
    }
  }

  /// Fire a Collection SMS via [CollectionSmsService], guarded so it is a safe
  /// no-op when the service isn't registered (e.g. unit tests) or SMS fails.
  Future<void> _notifySms(
      Future<void> Function(CollectionSmsService sms) action) async {
    try {
      if (!Get.isRegistered<CollectionSmsService>()) return;
      await action(Get.find<CollectionSmsService>());
    } catch (e) {
      logDebug('CollectionRepository._notifySms error: $e');
    }
  }

  /// Queue one change onto the offline pending queue for end-of-day upload.
  ///
  /// [fields] carries the operation-specific values using the backend
  /// CollectionChangeDto names; Operation/ItemId/CollectorName are added here so
  /// the stored payload is exactly one element of UploadCollectionDto.Changes.
  Future<void> _queueChange(
      String operation, String itemId, Map<String, dynamic> fields) async {
    final change = <String, dynamic>{
      'Operation': operation,
      'ItemId': itemId,
      'CollectorName': collectorName,
      ...fields,
    };
    await Get.find<SyncManager>().queueChange(
      operation: operation,
      payload: jsonEncode(change),
      itemId: itemId,
    );
  }

  /// Upload all queued changes to the backend in one batch (end-of-day).
  ///
  /// Accepted changes are removed from the queue; rejected ones are kept (with an
  /// incremented retry count) so the collector can review or discard them.
  Future<CollectionUploadResult> uploadAll() async {
    final CollectionPendingDao pendingDao =
        await DatabaseHelper.instance.collectionPendingDao;
    final pending = await pendingDao.getPendingChanges();
    if (pending.isEmpty) {
      return const CollectionUploadResult();
    }

    final changes = pending
        .map((p) => jsonDecode(p.payload) as Map<String, dynamic>)
        .toList();

    final body = {
      'CollectorCode': collectorCode,
      'CollectorName': collectorName,
      'Changes': changes,
    };

    final response = await http
        .post(
          BApiEnvironment.api4Uri(_uploadPath),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final rejectedList = (decoded is Map && decoded['Rejected'] is List)
        ? (decoded['Rejected'] as List)
        : const [];

    // Build a set of rejected (operation|itemId) keys and reason strings.
    final rejectedKeys = <String>{};
    final rejectedReasons = <String>[];
    for (final r in rejectedList) {
      if (r is Map) {
        final op = (r['Operation'] ?? '').toString();
        final itemId = (r['ItemId'] ?? '').toString();
        final reason = (r['Reason'] ?? 'Rejected').toString();
        rejectedKeys.add('$op|$itemId');
        rejectedReasons.add('$itemId: $reason');
      }
    }

    final now = DateTime.now().toIso8601String();
    int accepted = 0;
    for (final p in pending) {
      final key = '${p.operation}|${p.itemId}';
      if (rejectedKeys.contains(key)) {
        await pendingDao.updatePendingChange(
          p.copyWith(retryCount: p.retryCount + 1, lastRetryAt: now),
        );
      } else {
        await pendingDao.removePendingChange(p.id!);
        accepted++;
      }
    }

    logDebug(
        'CollectionRepository.uploadAll: accepted=$accepted rejected=${rejectedReasons.length}');
    return CollectionUploadResult(
        accepted: accepted, rejected: rejectedReasons);
  }

  /// Create one bucket invoice on the server (supervisor "Add to Bucket").
  ///
  /// Saved to Postgres first (the source of truth); on success the created item
  /// is also cached locally so it appears in the collector's bucket. Requires
  /// connectivity — adding to the shared bucket is an online action.
  Future<CollectionItemModel?> createInvoice({
    required String clientId,
    required String clientName,
    String clientCode = '',
    String clientAddress = '',
    String clientContact = '',
    String clientEmail = '',
    List<String> documentReferences = const [],
    required double toBeCollected,
    String? bankName,
    String? remarks,
    String? documentDate,
    String? postingDate,
    String? dueDate,
    bool silent = false,
  }) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        _showError('You must be online to add to the bucket', silent: silent);
        return null;
      }

      final payload = {
        'ClientId': clientId,
        'ClientCode': clientCode,
        'ClientName': clientName,
        'ClientAddress': clientAddress,
        'ClientContact': clientContact,
        'ClientEmail': clientEmail,
        'BpCode': clientCode,
        'DocumentReferences': documentReferences,
        'BankName': bankName,
        'ToBeCollected': toBeCollected,
        'Remarks': remarks,
        'DocumentDate': documentDate,
        'PostingDate': postingDate,
        'DueDate': dueDate,
        'CreatedBy': collectorCode,
      };

      final response = await http
          .post(
            BApiEnvironment.api4Uri(_invoicesPath),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final item =
            CollectionMapper.toDomainModel(CollectionItemDto.fromJson(decoded));

        // Cache locally so it shows up in the bucket immediately.
        try {
          final dao = await _dao;
          await dao.insertCollectionItem(item);
        } catch (dbError) {
          logDebug('CollectionRepository.createInvoice cache error: $dbError');
        }

        _showSuccess('Invoice added to bucket', silent: silent);
        return item;
      }

      _showError('Failed to add invoice (${response.statusCode})',
          silent: silent);
      return null;
    } catch (e) {
      logDebug('CollectionRepository.createInvoice error: $e');
      _showError('Failed to add invoice', silent: silent);
      return null;
    }
  }

  /// Force refresh from API, clearing and reloading local cache.
  Future<List<CollectionItemModel>> refreshFromApi(
      {bool silent = false}) async {
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
