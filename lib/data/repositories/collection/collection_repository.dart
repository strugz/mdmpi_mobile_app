import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_activity_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_advance_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_account_history_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_engagement_dao.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_workspace_parser.dart';
import 'package:mdmpi_mobile_app/features/collection/mappers/collection_mapper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
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
  static const String _workspacePath = '/api4/Collection/workspace';

  /// The client registry (a_tblcollectionclient), searched by code or name.
  /// `/api4`: served by MDMPI.App like every other Collection call.
  static const String _clientsPath = '/api4/Collection/clients';

  /// Bumped every time the local cache is replaced from the server, so
  /// controllers can reload the lists they keep in memory.
  final RxInt localDataVersion = 0.obs;

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

  /// One-call download: bucket + advances + deposits/activities + account
  /// history + targets (Stage C3).
  Uri _workspaceUri() => BApiEnvironment.api4Uri(_workspacePath)
      .replace(queryParameters: {'collector': collectorCode});

  /// Search the existing clients in the registry (a_tblcollectionclient) by
  /// code or name, first [limit] matches in name order.
  ///
  /// Every client SAP has imported, not only those with an invoice in this
  /// collector's bucket — a CWT pick-up is often at an account with nothing
  /// open. Online only: a failure (offline, timeout, server error) comes back
  /// as a [Result.failure], and the picker falls back to the accounts already
  /// on the phone.
  Future<Result<List<ClientModel>>> searchClientRegistry(String term,
      {int limit = 25}) async {
    try {
      final uri = BApiEnvironment.api4Uri(_clientsPath, {
        if (term.trim().isNotEmpty) 'search': term.trim(),
        'page': '1',
        'pageSize': '$limit',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Result.failure('Client search failed (${response.statusCode})');
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map ? decoded['Items'] : null;
      if (items is! List) return Result.success(const []);
      return Result.success([
        for (final m in items.whereType<Map>())
          if ((m['ClientCode']?.toString() ?? '').trim().isNotEmpty)
            _registryClient(Map<String, dynamic>.from(m)),
      ]);
    } catch (e) {
      logDebug('CollectionRepository.searchClientRegistry error: $e');
      return Result.failure('Client search is unavailable offline');
    }
  }

  /// A registry row as the app's client. In this app a Collection client's
  /// id and code are both the registry's ClientCode (the workspace sends it
  /// as ACCMID and ACCMSC alike), so a picked client uploads like any other.
  static ClientModel _registryClient(Map<String, dynamic> m) {
    String s(String k) => (m[k]?.toString() ?? '').trim();
    final code = s('ClientCode');
    final name = s('ClientName');
    return ClientModel(
      id: code,
      code: code,
      name: name.isEmpty ? code : name,
      address: s('ClientAddress'),
      contact: s('ClientContact'),
      emailAddress: s('ClientEmail'),
    );
  }

  /// Download the collector's workspace and replace the local cache with it.
  ///
  /// Returns the items, or null when the server could not be reached. Falls back
  /// to the bucket-only endpoint for servers that predate `/workspace`, in which
  /// case the account-level tables are left untouched.
  Future<List<CollectionItemModel>?> _downloadAndCache() async {
    final dao = await _dao;

    try {
      final response = await _safeGet(_workspaceUri());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final ws = CollectionWorkspaceParser.parse(decoded);

          await dao.deleteAllCollectionItems();
          await dao.insertCollectionItems(ws.items);
          await _replaceAccountLevelData(ws);
          // Rebuild the archive's copied half now, from the invoices already
          // in memory, so the month's total is current by the time the
          // screens hear about the download — not after they have re-read
          // every invoice and started the rebuild themselves.
          await _backfill(items: ws.items);

          localDataVersion.value++;
          // The rebuild above is for this version; the listeners' own call
          // to backfillOwnEngagements has nothing left to do.
          _archiveBackfilledAt = localDataVersion.value;
          logDebug(
              'CollectionRepository: workspace cached — ${ws.items.length} items, '
              '${ws.advances.length} advances, ${ws.activities.length} activities, '
              '${ws.accountHistory.length} history, ${ws.targets.length} targets');
          return ws.items;
        }
      } else {
        logDebug(
            'CollectionRepository: workspace returned ${response.statusCode}, falling back to bucket');
      }
    } catch (e) {
      logDebug(
          'CollectionRepository: workspace fetch failed ($e), falling back to bucket');
    }

    // Older backend: bucket only.
    final response = await _safeGet(_bucketUri());
    if (response.statusCode != 200) return null;
    final items = _parseItems(_decodeRootToList(jsonDecode(response.body)));
    await dao.deleteAllCollectionItems();
    await dao.insertCollectionItems(items);
    localDataVersion.value++;
    return items;
  }

  /// Server wins for the account-level tables on download (the caller has already
  /// ensured there is no un-uploaded work to lose).
  Future<void> _replaceAccountLevelData(CollectionWorkspace ws) async {
    final helper = DatabaseHelper.instance;
    await (await helper.collectionAdvanceDao).replaceAll(ws.advances);
    await (await helper.collectionActivityDao).replaceAll(ws.activities);
    await (await helper.collectionAccountHistoryDao)
        .replaceAll(ws.accountHistory);
    await (await helper.collectionTargetDao).replaceAll(ws.targets);
  }

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

      // Otherwise, fetch the workspace from the server and cache it
      logDebug('CollectionRepository: Fetching workspace for $collectorCode');
      final collectionItems = await _downloadAndCache();
      if (collectionItems != null) {
        return collectionItems;
      }

      throw Exception('Failed to load collection items');
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

  /// Background sync from the server (non-blocking).
  ///
  /// Skipped while there are un-uploaded changes: a server-wins refresh would
  /// otherwise revert local balances/claims until the next Upload All (the same
  /// protection the explicit Download Bucket action has).
  Future<void> _syncFromApi() async {
    try {
      final pending = await Get.find<SyncManager>().getPendingChangeCount();
      if (pending > 0) {
        logDebug(
            'CollectionRepository: $pending pending changes — background sync skipped');
        return;
      }
      await _downloadAndCache();
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

      // And to the archive, which the refresh cannot touch. Same `now` as the
      // queued change, so the two agree about when this happened.
      await _archive(
        kind: 'INVOICE',
        engagedAt: now,
        itemId: id,
        clientId: item.client.id,
        clientName: item.client.name,
        status: status,
        remarks: remarks,
        amount: newlyCollected,
        bankName: bankName,
        checkNumber: checkNumber,
        checkDate: checkDate,
        purposeOfVisit: purposeOfVisit,
      );

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

      // Gathered through the loop and committed once. The batch shares one
      // `now`, and the itemId differs per row, so the keys still differ.
      final archived = <CollectionEngagementRecord>[];

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

        final record = _engagementRecord(
          kind: 'INVOICE',
          engagedAt: now,
          itemId: id,
          clientId: item.client.id,
          clientName: item.client.name,
          status: itemStatus,
          remarks: itemRemarks,
          amount: manualAmount,
          bankName: bankName,
          checkNumber: checkNumber,
          checkDate: checkDate,
          purposeOfVisit: purposeOfVisit,
        );
        if (record != null) archived.add(record);

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

      await _archiveAll(archived);

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
      logDebug(
          'CollectionRepository: Batch activity saved for ${ids.length} items');
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
    String? poNumber,
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
        // Customer P.O.; the backend trims and stores null for blank.
        'PoNumber': poNumber,
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

  // ===========================================================================
  // Stage C2 — account-level concepts (Deposit, CWT, Reconciliation, Advanced
  // Payment, Defer/Clear, Target). Each write goes to SQLite AND the upload queue
  // so it survives a restart and reaches the server at end of day.
  // ===========================================================================

  String _nowStamp() => DateTime.now().toIso8601String();

  // ===========================================================================
  // The engagement archive
  //
  // Every write path below also records what the collector did into
  // a_tblCollectionEngagement, which no download path may rewrite. The
  // repository is the only writer: the controller used to stamp its own
  // 'yyyy-MM-dd HH:mm' alongside the ISO stamp written here, and two stamps for
  // one engagement would mean two archive keys for it — exactly the duplication
  // the key is derived to prevent.
  // ===========================================================================

  /// Bumped whenever an engagement is archived, so a controller can reload the
  /// archive with one `ever` instead of a re-read at each of seven save sites —
  /// which is also the version that cannot drift when an eighth is added.
  final RxInt ownEngagementVersion = 0.obs;

  /// Record one engagement in the archive.
  ///
  /// Awaited after the primary write and wrapped in its own try/catch: losing
  /// the archive copy is a blank day on the calendar, while letting it throw
  /// would cost the collector the engagement itself.
  Future<void> _archive({
    required String kind,
    required String engagedAt,
    String itemId = '',
    String clientId = '',
    String clientName = '',
    String status = '',
    String remarks = '',
    double amount = 0,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    List<String> documentIds = const [],
  }) async {
    try {
      final record = _engagementRecord(
        kind: kind,
        engagedAt: engagedAt,
        itemId: itemId,
        clientId: clientId,
        clientName: clientName,
        status: status,
        remarks: remarks,
        amount: amount,
        bankName: bankName,
        checkNumber: checkNumber,
        checkDate: checkDate,
        purposeOfVisit: purposeOfVisit,
        documentIds: documentIds,
      );
      if (record == null) return;
      final dao = await DatabaseHelper.instance.collectionEngagementDao;
      await dao.upsert(record);
      ownEngagementVersion.value++;
    } catch (e) {
      logDebug('CollectionRepository._archive error: $e');
    }
  }

  /// Archive a batch in one transaction. A batch engagement can cover a whole
  /// account, and one commit beats one round trip per invoice.
  Future<void> _archiveAll(List<CollectionEngagementRecord> records) async {
    if (records.isEmpty) return;
    try {
      final dao = await DatabaseHelper.instance.collectionEngagementDao;
      await dao.upsertAll(records);
      ownEngagementVersion.value++;
    } catch (e) {
      logDebug('CollectionRepository._archiveAll error: $e');
    }
  }

  /// Builds the record, or null when [engagedAt] is not a date we can file
  /// under a day. A row the calendar could not place used to disappear into a
  /// bare `catch`; here it is counted out loud.
  CollectionEngagementRecord? _engagementRecord({
    required String kind,
    required String engagedAt,
    String itemId = '',
    String clientId = '',
    String clientName = '',
    String status = '',
    String remarks = '',
    double amount = 0,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    List<String> documentIds = const [],
    String source = CollectionEngagementRecord.sourceLocal,
  }) {
    final engagedOn = BFormatter.localDayKey(engagedAt);
    if (engagedOn == null) {
      logDebug('CollectionRepository: engagement not archived, '
          'unreadable date "$engagedAt" ($kind)');
      return null;
    }
    final subjectId = itemId.isEmpty ? clientId : itemId;
    return CollectionEngagementRecord(
      localRef: CollectionEngagementRecord.buildLocalRef(
        kind: kind,
        subjectId: subjectId,
        engagedAt: engagedAt,
      ),
      collectorCode: collectorCode,
      collectorName: collectorName,
      kind: kind,
      itemId: itemId,
      clientId: clientId,
      clientName: clientName,
      engagedAt: engagedAt,
      engagedOn: engagedOn,
      status: status,
      remarks: remarks,
      amount: amount,
      bankName: bankName,
      checkNumber: checkNumber,
      checkDate: checkDate,
      purposeOfVisit: purposeOfVisit,
      documentIds: documentIds,
      createdAt: _nowStamp(),
      source: source,
    );
  }

  /// Every name this collector's own work may already be filed under.
  ///
  /// The legacy tables were written with three different identities over time —
  /// the repository wrote the full name, the controller wrote initials, and one
  /// card special-cased the literal 'You'. Matching all of them is what lets
  /// the backfill recognise a collector's own history; new rows carry
  /// [collectorCode] and need none of this.
  Set<String> get collectorAliases {
    final user = Get.find<UserController>().user.value;
    return {
      collectorCode,
      user.fullName,
      user.initials,
      'You',
    }.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
  }

  /// Rebuild the copied half of the archive from what the cache tables say
  /// now.
  ///
  /// Without it the archive starts empty and a collector who has been working
  /// for weeks opens a blank calendar. It can only rescue what the refresh has
  /// not already erased, so it is a floor, not a recovery.
  ///
  /// It used to run once ever, guarded by "is the archive empty", and its rows
  /// then lived forever alongside the collector's own. That made the archive
  /// unfalsifiable: collection data deleted on the server stayed in the month's
  /// total with nothing left to explain it. So the copies are now marked
  /// [CollectionEngagementRecord.sourceServer], dropped and rewritten on each
  /// load, and the archive's copied half tracks the server while its recorded
  /// half is still untouchable.
  ///
  /// Only history from before [_archiveWatermark] — the day this archive
  /// started — is copied. Anything after it was recorded by this device and is
  /// already in the archive as its own row, so the cut is what keeps a
  /// re-import from landing a second copy of work the collector did here. The
  /// cut is by day, so the copy can miss part of the day the archive began;
  /// that day is the one day where both halves could describe the same visit.
  ///
  /// A download runs it itself, on the invoices it just parsed and before
  /// [localDataVersion] announces them; this call then finds the archive
  /// already current for that version and returns at once.
  Future<void> backfillOwnEngagements() async {
    if (_archiveBackfilledAt == localDataVersion.value) return;
    await _backfill();
  }

  /// The [localDataVersion] the archive's copied half was last rebuilt for.
  int _archiveBackfilledAt = -1;

  /// [items], when the caller already holds the fresh cache, saves reading
  /// several thousand invoices back out of SQLite — the slowest step here,
  /// and it sat between a download finishing and "Collected this Month"
  /// showing the month's collections.
  Future<void> _backfill({List<CollectionItemModel>? items}) async {
    try {
      final helper = DatabaseHelper.instance;
      final engDao = await helper.collectionEngagementDao;

      final watermark = await _archiveWatermark();

      final aliases = collectorAliases;
      bool mine(String name) => aliases.contains(name.trim().toLowerCase());

      final records = <CollectionEngagementRecord>[];
      var skipped = 0;

      void add(CollectionEngagementRecord? r) {
        if (r == null) {
          skipped++;
        } else if (r.engagedOn.compareTo(watermark) < 0) {
          // engagedOn is yyyy-MM-dd, fixed width and already normalised to the
          // local day, so a plain string compare is a date compare. engagedAt
          // is not: it carries whatever shape the server sent.
          records.add(r);
        }
      }

      // The account-history table has no name column, so a deferral copied
      // from it would be archived nameless and the calendar card would have a
      // blank headline. The invoices know their account; remember the name
      // per client while walking them, and add the office and advance rows'
      // names too so an account with no invoice left still gets one.
      final namesByClient = <String, String>{};
      void learn(String clientId, String name) {
        if (clientId.isNotEmpty && name.isNotEmpty) {
          namesByClient.putIfAbsent(clientId, () => name);
        }
      }

      final cached = items ?? await (await _dao).getCollectionItems();
      for (final item in cached) {
        learn(item.client.id, item.client.name);
      }
      final activities = await (await helper.collectionActivityDao).getAll();
      for (final a in activities) {
        learn(a.clientId, a.clientName);
      }
      final advances = await (await helper.collectionAdvanceDao).getAll();
      for (final a in advances) {
        learn(a.clientId, a.clientName);
      }

      for (final item in cached) {
        for (final h in item.history) {
          if (!mine(h.collectorName)) continue;
          add(_engagementRecord(
            kind: 'INVOICE',
            engagedAt: h.date,
            itemId: item.id,
            clientId: item.client.id,
            clientName: item.client.name,
            status: h.status,
            remarks: h.remarks,
            amount: h.totalCollected,
            bankName: h.bankName,
            checkNumber: h.checkNumber,
            checkDate: h.checkDate,
            purposeOfVisit: h.purposeOfVisit,
            source: CollectionEngagementRecord.sourceServer,
          ));
        }
      }

      for (final h
          in await (await helper.collectionAccountHistoryDao).getAll()) {
        if (!mine(h.collectorName)) continue;
        add(_engagementRecord(
          kind: 'ACCOUNT',
          engagedAt: h.date,
          clientId: h.clientId,
          clientName: namesByClient[h.clientId] ?? '',
          status: h.reason,
          remarks: h.remarks,
          source: CollectionEngagementRecord.sourceServer,
        ));
      }

      for (final a in activities) {
        if (!mine(a.collectorName)) continue;
        add(_engagementRecord(
          kind: 'OFFICE',
          engagedAt: a.date,
          clientId: a.clientId,
          clientName: a.clientName,
          status: a.type,
          remarks: a.remarks,
          amount: a.amount,
          bankName: a.bankName,
          checkNumber: a.checkNumber,
          documentIds: a.documentIds,
          source: CollectionEngagementRecord.sourceServer,
        ));
      }

      for (final a in advances) {
        if (!mine(a.collectorName)) continue;
        add(_engagementRecord(
          kind: 'ADVANCE',
          engagedAt: a.date,
          itemId: a.externalRef,
          clientId: a.clientId,
          clientName: a.clientName,
          status: 'Advanced Payment',
          remarks: a.remarks,
          amount: a.amount,
          source: CollectionEngagementRecord.sourceServer,
        ));
      }

      // Old copies out and new ones in as one transaction: the records are
      // all built first, so no reader ever finds the copied half missing.
      final removed = await engDao.replaceServerCopies(records);
      _archiveBackfilledAt = localDataVersion.value;
      // Also when nothing is written, because dropping the old copies is
      // itself a change the calendar and the month's total must see —
      // otherwise deleted data stays on screen until the next restart.
      if (records.isNotEmpty || removed > 0) ownEngagementVersion.value++;
      logDebug('CollectionRepository: archive refreshed — '
          '${records.length} copied from the server cache, $removed stale '
          'copies dropped, watermark $watermark'
          '${skipped > 0 ? ", $skipped skipped with no readable date" : ""}');
    } catch (e) {
      logDebug('CollectionRepository.backfillOwnEngagements error: $e');
    }
  }

  /// The day this device's archive started, as yyyy-MM-dd.
  ///
  /// Set once, the first time the archive is built, and per collector: two
  /// collectors sharing a device have their own cut. Everything from before it
  /// can only have come from the server; everything after it this device
  /// recorded itself.
  Future<String> _archiveWatermark() async {
    final box = GetStorage();
    final key = 'collection.archiveWatermark.$collectorCode';
    final stored = box.read<String>(key);
    if (stored != null && stored.isNotEmpty) return stored;

    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await box.write(key, day);
    return day;
  }

  /// The signed-in collector's own engagements.
  ///
  /// Reports its failure, unlike [loadOfficeActivities] and friends which fall
  /// back to an empty list: a blank calendar with no explanation is the bug
  /// this whole table exists to fix, so it must not be able to fail quietly.
  Future<Result<List<CollectionEngagementRecord>>> loadOwnEngagements({
    String? yearMonth,
  }) async {
    try {
      final dao = await DatabaseHelper.instance.collectionEngagementDao;
      final rows = yearMonth == null
          ? await dao.getAll(collectorCode)
          : await dao.getForMonth(
              collectorCode: collectorCode, yearMonth: yearMonth);
      return Result.success(rows);
    } catch (e) {
      logDebug('CollectionRepository.loadOwnEngagements error: $e');
      return Result.failure('Could not read your engagements: $e');
    }
  }

  /// Release an account's invoices back to the bucket.
  ///
  /// [reason] null = Clear Engagement (no history); non-null = Deferred Engagement,
  /// recorded once per account locally and uploaded per invoice (the server keeps a
  /// single account-level entry). Persists the release so a restart does not show
  /// the invoices as still claimed.
  Future<CollectionAccountHistoryRecord?> releaseInvoices({
    required String clientId,
    required List<CollectionItemModel> releasedInvoices,
    String? reason,
    String remarks = '',
  }) async {
    try {
      final dao = await _dao;
      final now = _nowStamp();
      final op = reason == null ? 'CLEAR' : 'DEFER';

      for (final inv in releasedInvoices) {
        await dao.updateCollectionItem(inv);
        await _queueChange(op, inv.id, {
          'ClientCode': clientId,
          'EngagementDate': now,
          if (reason != null) 'Status': reason,
          if (reason != null) 'Remarks': remarks,
        });
      }

      if (reason == null) return null;

      final record = CollectionAccountHistoryRecord(
        clientId: clientId,
        date: now,
        reason: reason,
        remarks: remarks,
        collectorName: collectorName,
      );
      final histDao = await DatabaseHelper.instance.collectionAccountHistoryDao;
      final id = await histDao.insert(record);

      // A deferral is field work and belongs on the calendar. The CLEAR branch
      // returned above and archives nothing: clearing an engagement is not one.
      //
      // The row names the account and lists the invoices it released. Without
      // the name the card had a blank header; without the invoices a
      // reconciliation on one of them could not be folded into this outcome
      // (see CollectionActivityController.reconciliationMerge). The name
      // comes from a released invoice, else from any stored invoice of the
      // account: a deferral with nothing to release still names who refused.
      await _archive(
        kind: 'ACCOUNT',
        engagedAt: now,
        clientId: clientId,
        clientName: releasedInvoices.isNotEmpty
            ? releasedInvoices.first.client.name
            : await _clientNameFor(clientId),
        status: reason,
        remarks: remarks,
        documentIds: [for (final inv in releasedInvoices) inv.id],
      );

      logDebug(
          'CollectionRepository: released ${releasedInvoices.length} invoices for $clientId ($op)');
      return CollectionAccountHistoryRecord(
        id: id,
        clientId: record.clientId,
        date: record.date,
        reason: record.reason,
        remarks: record.remarks,
        collectorName: record.collectorName,
      );
    } catch (e) {
      logDebug('CollectionRepository.releaseInvoices error: $e');
      return null;
    }
  }

  /// The account's name as any stored invoice of it gives it, or '' when
  /// none is stored. Only for the archive, which must never throw.
  Future<String> _clientNameFor(String clientId) async {
    try {
      final items = await (await _dao).getCollectionItems();
      for (final item in items) {
        if (item.client.id == clientId && item.client.name.isNotEmpty) {
          return item.client.name;
        }
      }
    } catch (e) {
      logDebug('CollectionRepository._clientNameFor error: $e');
    }
    return '';
  }

  /// Record an office activity (Deposit / CWT Pick-up / Reconciliation).
  ///
  /// [updatedInvoices] lets Reconciliation persist the invoices it marked. The
  /// queue ItemId is the activity's own local ref so rejections match uniquely
  /// and the server never mistakes it for an invoice number.
  Future<CollectionActivityRecord?> saveOfficeActivity({
    required String type,
    required String clientId,
    required String clientName,
    double amount = 0,
    String? bankName,
    String? checkNumber,
    String remarks = '',
    List<String> documentIds = const [],
    List<CollectionItemModel> updatedInvoices = const [],
  }) async {
    try {
      final now = _nowStamp();
      final localRef = 'ACT-${DateTime.now().millisecondsSinceEpoch}';
      final record = CollectionActivityRecord(
        type: type,
        clientId: clientId,
        clientName: clientName,
        date: now,
        amount: amount,
        bankName: bankName,
        checkNumber: checkNumber,
        remarks: remarks,
        documentIds: documentIds,
        collectorName: collectorName,
        localRef: localRef,
      );

      final actDao = await DatabaseHelper.instance.collectionActivityDao;
      final id = await actDao.insert(record);

      // Reconciliation is archived too. Which kinds a screen shows is that
      // screen's decision, and the controller already makes it; dropping the
      // row here would take the decision away from every future reader.
      await _archive(
        kind: 'OFFICE',
        engagedAt: now,
        clientId: clientId,
        clientName: clientName,
        status: type,
        remarks: remarks,
        amount: amount,
        bankName: bankName,
        checkNumber: checkNumber,
        documentIds: documentIds,
      );

      if (updatedInvoices.isNotEmpty) {
        final dao = await _dao;
        for (final inv in updatedInvoices) {
          await dao.updateCollectionItem(inv);
        }
      }

      // A reconciliation is read on the calendar and in Field Engagement
      // through the invoice, not through the OFFICE row above (the controller
      // hides that one). Until now the only invoice-level trace was the
      // history entry inside the cached item, which the next download
      // replaced with the server's copy; once the collector collected the
      // invoice, nothing was left to say it had been reconciled. A field
      // outcome writes its own INVOICE row; so does this now.
      if (type.trim().toLowerCase() == 'reconciliation') {
        for (final inv in updatedInvoices) {
          await _archive(
            kind: 'INVOICE',
            engagedAt: now,
            itemId: inv.id,
            clientId: inv.client.id,
            clientName: inv.client.name,
            status: 'Reconciliation',
            remarks: remarks,
          );
        }
      }

      await _queueChange(_operationForActivity(type), localRef, {
        'ClientCode': clientId,
        'ActivityType': type,
        'EngagementDate': now,
        'AmountCollected': amount,
        'BankName': bankName,
        'CheckNo': checkNumber,
        'Remarks': remarks,
        'DocumentIds': documentIds,
      });

      logDebug('CollectionRepository: saved $type for $clientId');
      return record.copyWith(id: id);
    } catch (e) {
      logDebug('CollectionRepository.saveOfficeActivity error: $e');
      return null;
    }
  }

  String _operationForActivity(String type) {
    switch (type.trim().toLowerCase()) {
      case 'deposit':
        return 'DEPOSIT';
      case 'cwt pick-up':
      case 'cwt pickup':
        return 'CWT_PICKUP';
      case 'reconciliation':
        return 'RECONCILIATION';
      default:
        return 'OFFICE_ACTIVITY';
    }
  }

  /// Record an Advanced Payment (no invoice yet). The device-generated
  /// externalRef is what the server keys the advance on.
  Future<CollectionAdvanceRecord?> saveAdvance({
    required String clientId,
    required String clientName,
    required double amount,
    String remarks = '',
  }) async {
    try {
      final now = _nowStamp();
      final record = CollectionAdvanceRecord(
        externalRef: 'AP-${DateTime.now().millisecondsSinceEpoch}',
        clientId: clientId,
        clientName: clientName,
        amount: amount,
        date: now,
        remarks: remarks,
        collectorName: collectorName,
      );
      final advDao = await DatabaseHelper.instance.collectionAdvanceDao;
      await advDao.upsert(record);

      await _archive(
        kind: 'ADVANCE',
        engagedAt: now,
        itemId: record.externalRef,
        clientId: clientId,
        clientName: clientName,
        status: 'Advanced Payment',
        remarks: remarks,
        amount: amount,
      );

      await _queueChange('ADVANCED_PAYMENT', record.externalRef, {
        'ClientCode': clientId,
        'ExternalRef': record.externalRef,
        'EngagementDate': now,
        'AmountCollected': amount,
        'Remarks': remarks,
      });

      logDebug(
          'CollectionRepository: saved advance ${record.externalRef} for $clientId');
      return record;
    } catch (e) {
      logDebug('CollectionRepository.saveAdvance error: $e');
      return null;
    }
  }

  /// Under half a centavo is agreement, not float left over.
  static const double _floatTolerance = 0.005;

  /// Assign an advance to an invoice (creating the invoice locally, as the app
  /// does). The server creates the invoice if new and allocates the advance.
  /// An advance larger than the invoice keeps its excess as float.
  ///
  /// [appliedAt] is the collection date the collector chose. An advance is
  /// float until applied, and the date decides which month's Collected this
  /// Month it lands in, so it — not the moment of tapping Assign — is the
  /// engagement's stamp, here and on the server. [appliedAmount] is what went
  /// onto the invoice (never more than it was due), matching its history.
  Future<bool> assignAdvance({
    required CollectionAdvanceRecord advance,
    required CollectionItemModel newInvoice,
    required double amountDue,
    required String dueDate,
    required String appliedAt,
    required double appliedAmount,
  }) async {
    try {
      final dao = await _dao;
      await dao.insertCollectionItem(newInvoice);

      final advDao = await DatabaseHelper.instance.collectionAdvanceDao;
      // What the invoice did not need stays float under Advanced Payment, on
      // the same advance, for the next invoice. The server does the same: it
      // allocates min(unallocated, balance) and leaves the rest unallocated.
      final excess = advance.amount - appliedAmount;
      if (excess > _floatTolerance) {
        await advDao.keepRemainder(advance.externalRef, excess);
      } else {
        await advDao.markAssigned(advance.externalRef, newInvoice.id);
      }

      await _archive(
        kind: 'INVOICE',
        engagedAt: appliedAt,
        itemId: newInvoice.id,
        clientId: advance.clientId,
        clientName: advance.clientName,
        status: 'Advanced Payment Applied',
        remarks: advance.remarks,
        amount: appliedAmount,
      );

      await _queueChange('ASSIGN_ADVANCE', newInvoice.id, {
        'ClientCode': advance.clientId,
        'ExternalRef': advance.externalRef,
        'EngagementDate': appliedAt,
        'AmountDue': amountDue,
        'DueDate': dueDate,
        'Remarks': advance.remarks,
      });

      logDebug(
          'CollectionRepository: assigned ${advance.externalRef} to ${newInvoice.id}');
      return true;
    } catch (e) {
      logDebug('CollectionRepository.assignAdvance error: $e');
      return false;
    }
  }

  /// Persist the monthly target (yyyy-MM) and queue it for upload.
  Future<void> setTarget(String yearMonth, double amount) async {
    try {
      final tDao = await DatabaseHelper.instance.collectionTargetDao;
      await tDao.set(yearMonth, amount);
      await _queueChange('SET_TARGET', yearMonth, {
        'YearMonth': yearMonth,
        'TargetAmount': amount,
      });
    } catch (e) {
      logDebug('CollectionRepository.setTarget error: $e');
    }
  }

  Future<double?> getTarget(String yearMonth) async {
    try {
      final tDao = await DatabaseHelper.instance.collectionTargetDao;
      return await tDao.get(yearMonth);
    } catch (e) {
      logDebug('CollectionRepository.getTarget error: $e');
      return null;
    }
  }

  Future<List<CollectionActivityRecord>> loadOfficeActivities() async {
    try {
      return await (await DatabaseHelper.instance.collectionActivityDao)
          .getAll();
    } catch (e) {
      logDebug('CollectionRepository.loadOfficeActivities error: $e');
      return const [];
    }
  }

  Future<List<CollectionAdvanceRecord>> loadUnassignedAdvances() async {
    try {
      return await (await DatabaseHelper.instance.collectionAdvanceDao)
          .getUnassigned();
    } catch (e) {
      logDebug('CollectionRepository.loadUnassignedAdvances error: $e');
      return const [];
    }
  }

  Future<List<CollectionAccountHistoryRecord>> loadAccountHistory() async {
    try {
      return await (await DatabaseHelper.instance.collectionAccountHistoryDao)
          .getAll();
    } catch (e) {
      logDebug('CollectionRepository.loadAccountHistory error: $e');
      return const [];
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
