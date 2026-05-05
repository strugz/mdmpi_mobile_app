import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/document_reference_dao.dart';

class RequestDao {
  final Database db;

  RequestDao(this.db);

  // Local status map (kept locally to avoid circular imports)
  static const Map<String, int> _statusStringToInt = {
    'New Request': 1,
    'Getting Supplies Ready': 2,
    'Item Prepared': 3,
    'For Delivery': 4,
    'Delivered': 5,
  };

  Future<List<StandardDeliveryModel>> getRequests() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        r.*, 
        m.MobileName
      FROM a_tblRequest AS r
      LEFT JOIN a_tblMobile AS m ON r.MobileID = m.MobileID
      ORDER BY r.RequestID DESC
    ''');

    if (maps.isEmpty) return [];

    List<StandardDeliveryModel> requests = [];
    for (var map in maps) {
      StandardDeliveryModel request = StandardDeliveryModel.fromDbJson(map);

      // Load cancel remarks if cancelled
      if (request.status == BTexts.statusCancelled) {
        final remarks = await _getRequestRemarks(request.id);
        if (remarks != null) request.cancelRemarks = remarks;
      }

      // Load client info via ClientDao (tries ACCMST_ then DLRMST)
      if (request.clientId.isNotEmpty) {
        final clientDao = ClientDao(db);
        final client = await clientDao.getById(request.clientId);
        if (client != null) request.client = client;
      }

      // Fetch Document References via DocumentReferenceDao
      final docDao = DocumentReferenceDao(db);
      request.documentReference = await docDao.getByRequestId(request.requestID);

      requests.add(request);
    }

    return requests;
  }

  Future<int> insertRequest(StandardDeliveryModel requestModel) async {
    // Prepare data for a_tblRequest
    final parsedId = int.tryParse(requestModel.id) ?? requestModel.id;
    Map<String, dynamic> requestData = {
      'RequestID': parsedId,
      'RequestClientID': requestModel.clientId,
      'RequestShippingMethod': requestModel.shippingMethod,
      'RequestDeliveryTerms': requestModel.deliveryTerms,
      'RequestDeliveryDate': requestModel.deliveryDate,
      'RequestPreference': requestModel.preference,
      'RequestStatus': requestModel.status,
      'RequestBy': requestModel.requestBy,
      'RequestCreatedBy': requestModel.createdBy,
      'RequestCreatedAt': requestModel.createdAt,
      'RequestItemPreparedBy': requestModel.itemPreparedBy,
      'RequestDeliveredBy': requestModel.deliveredBy,
      'RequestItemPreparedAt': requestModel.itemPreparedAt,
      'RequestItemPreparedEndAt': requestModel.itemPreparedEndAt,
      'RequestDeliveredAt': requestModel.deliveredAt,
      'RequestDeliveredEndAt': requestModel.deliveredEndAt,
      'LocationStartedAt': requestModel.locationStartedAt,
      'LocationEndAt': requestModel.locationEndAt,
      'MobileID': requestModel.mobileID ?? 0,
      'RequestDriverHelper': requestModel.helper,
      'Receiver': requestModel.receiver,
      'RecipientContactDetails': requestModel.recipientContactDetails,
      'TripTicketNumber': requestModel.tripTicketNumber,
      'ItemCategoryID': requestModel.itemCategoryID,
      'FormCategoryID': requestModel.formCategoryID,
    };

    final int requestId = await db.insert('a_tblRequest', requestData, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (requestId == 0) {
      await updateRequest(requestModel: requestModel);
      return 0;
    }

    // Insert cancel remarks if present (store remark and update status)
    if (requestModel.cancelRemarks.remarks.isNotEmpty) {
      await _insertRemark(parsedId.toString(), requestModel.cancelRemarks.remarks, requestModel.cancelRemarks.date);
      await db.update('a_tblRequest', {'RequestStatus': requestModel.status}, where: 'RequestID = ?', whereArgs: [parsedId]);
    }

    // Insert Document References
    if (requestModel.documentReference.isNotEmpty) {
      for (String reference in requestModel.documentReference) {
        if (reference.isNotEmpty) {
          final docDao = DocumentReferenceDao(db);
          await docDao.insert(parsedId.toString(), reference, requestModel.createdAt);
        }
      }
    }

    // Persist client info for this single request as well
    try {
      final client = requestModel.client;
      if (client.id.isNotEmpty) {
        await db.insert('ACCMST_', client.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {
      // ignore client persistence failures for single insert
    }

    return int.tryParse(requestModel.id) ?? requestId;
  }

  Future<void> insertRequests(List<StandardDeliveryModel> requestModels) async {
    Batch batch = db.batch();
    for (StandardDeliveryModel requestModel in requestModels) {
      // Prepare DB-mapped row (Request-prefixed keys)
      final parsedId = int.tryParse(requestModel.id) ?? requestModel.id;
      Map<String, dynamic> requestData = {
        'RequestID': parsedId,
        'RequestClientID': requestModel.clientId,
        'RequestShippingMethod': requestModel.shippingMethod,
        'RequestDeliveryTerms': requestModel.deliveryTerms,
        'RequestDeliveryDate': requestModel.deliveryDate,
        'RequestPreference': requestModel.preference,
        'RequestStatus': requestModel.status,
        'RequestBy': requestModel.requestBy,
        'RequestCreatedBy': requestModel.createdBy,
        'RequestCreatedAt': requestModel.createdAt,
        'RequestItemPreparedBy': requestModel.itemPreparedBy,
        'RequestDeliveredBy': requestModel.deliveredBy,
        'RequestItemPreparedAt': requestModel.itemPreparedAt,
        'RequestItemPreparedEndAt': requestModel.itemPreparedEndAt,
        'RequestDeliveredAt': requestModel.deliveredAt,
        'RequestDeliveredEndAt': requestModel.deliveredEndAt,
       'LocationStartedAt': requestModel.locationStartedAt,
       'LocationEndAt': requestModel.locationEndAt,
       'MobileID': requestModel.mobileID ?? 0,
       'RequestDriverHelper': requestModel.helper,
       'Receiver': requestModel.receiver,
       'RecipientContactDetails': requestModel.recipientContactDetails,
       'TripTicketNumber': requestModel.tripTicketNumber,
       'ItemCategoryID': requestModel.itemCategoryID,
       'FormCategoryID': requestModel.formCategoryID,
       };

       batch.insert('a_tblRequest', requestData, conflictAlgorithm: ConflictAlgorithm.replace);

      // Also insert document references into their table
      if (requestModel.documentReference.isNotEmpty) {
        for (var ref in requestModel.documentReference) {
          if (ref.isNotEmpty) {
            // Skip inserting if an entry with the same RequestID and Reference already exists
            final List<Map<String, dynamic>> existing = await db.query(
              'a_tblRequestDocumentReference',
              where: 'RequestID = ? AND Reference = ?',
              whereArgs: [parsedId, ref],
              limit: 1,
            );
            if (existing.isEmpty) {
              batch.insert('a_tblRequestDocumentReference', {
                'RequestID': parsedId,
                'Reference': ref,
                'RequestCreatedAt': requestModel.createdAt,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Also persist client info (ACCMST_) so client lookup later can find the client
      // Use ClientModel.toJson() and replace on conflict to keep latest data
      try {
        final client = requestModel.client;
        if (client.id.isNotEmpty) {
          batch.insert('ACCMST_', client.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (_) {
        // ignore if client is missing or malformed; we don't want batch to fail entirely
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateRequest({required StandardDeliveryModel requestModel}) async {
    // Fetch the current status of the request
    final List<Map<String, dynamic>> currentRequestData = await db.query('a_tblRequest', columns: ['RequestStatus'], where: 'RequestID = ?', whereArgs: [requestModel.requestID]);

    if (currentRequestData.isEmpty) return;

    final String currentStatusString = currentRequestData.first['RequestStatus'] as String;
    final int? currentStatusInt = _statusStringToInt[currentStatusString];
    final int? newStatusInt = _statusStringToInt[requestModel.status];

    if (currentStatusInt != null && newStatusInt != null) {
      if (newStatusInt < currentStatusInt) return;
    }

    Map<String, dynamic> requestData = {
      'RequestClientID': requestModel.clientId,
      'RequestShippingMethod': requestModel.shippingMethod,
      'RequestDeliveryTerms': requestModel.deliveryTerms,
      'RequestDeliveryDate': requestModel.deliveryDate,
      'RequestPreference': requestModel.preference,
      'RequestStatus': requestModel.status,
      'RequestBy': requestModel.requestBy,
      'RequestCreatedBy': requestModel.createdBy,
      'RequestItemPreparedBy': requestModel.itemPreparedBy,
      'RequestDeliveredBy': requestModel.deliveredBy,
      'RequestCreatedAt': requestModel.createdAt,
      'RequestItemPreparedAt': requestModel.itemPreparedAt,
      'RequestItemPreparedEndAt': requestModel.itemPreparedEndAt,
      'RequestDeliveredAt': requestModel.deliveredAt,
      'RequestDeliveredEndAt': requestModel.deliveredEndAt,
      'LocationStartedAt': requestModel.locationStartedAt,
      'LocationEndAt': requestModel.locationEndAt,
      'MobileID': requestModel.mobileID,
      'RequestDriverHelper': requestModel.helper,
      'Receiver': requestModel.receiver,
      'TripTicketNumber': requestModel.tripTicketNumber,
      'ItemCategoryID': requestModel.itemCategoryID,
      'FormCategoryID': requestModel.formCategoryID,
    };

    await db.update('a_tblRequest', requestData, where: 'RequestID = ?', whereArgs: [requestModel.id]);

    // NOTE: media (signature/image) persistence is handled via saveRequestMedia()
    // which is invoked by the caller (StandardDeliveryDataManager) to centralize upload
    // and local-save logic. This keeps updateRequest focused on the main row.
  }

  Future<bool> isRequestTableNotEmpty() async {
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM a_tblRequest');
    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  Future<void> deleteAll() async {
    await db.delete('a_tblRequest');
    await db.delete('a_tblRequestDocumentReference');
    await db.delete('a_tblRequestReceiverSignature');
    await db.delete('a_tblRequestImage');
  }

  /// --- Receiver signature / image helpers ---
  /// Returns the base64 signature string stored for a request, or null if none.
  Future<String?> getReceiverSignatureByRequestId(dynamic requestID) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestReceiverSignature',
      columns: ['RequestReceiverSignature'],
      where: 'RequestID = ?',
      whereArgs: [parsedId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final value = maps.first['RequestReceiverSignature'] as String?;
    return value == null || value.isEmpty ? null : value;
  }

  /// Returns the base64 image string stored for a request, or null if none.
  Future<String?> getRequestImageByRequestId(dynamic requestID) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestImage',
      columns: ['RequestImage'],
      where: 'RequestID = ?',
      whereArgs: [parsedId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final value = maps.first['RequestImage'] as String?;
    return value == null || value.isEmpty ? null : value;
  }

  Future<bool> hasRequestImage(dynamic requestID) async {
    final img = await getRequestImageByRequestId(requestID);
    return img != null;
  }

  /// Return all receiver signature rows (RequestID, RequestReceiverSignature)
  // getAllReceiverSignatures moved to SignatureDao

  /// Return all request image rows (RequestID, RequestImage)
  Future<List<Map<String, dynamic>>> getAllRequestImages() async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestImage');
    return maps;
  }

  /// Persist signature and/or image for a request.
  /// If a non-empty signature is provided, it will be inserted into
  /// `a_tblRequestReceiverSignature` (REPLACE on conflict). Same for image.
  Future<void> saveRequestMedia({required dynamic requestID, String? signature, String? image}) async {
    final parsedId = int.tryParse(requestID.toString()) ?? requestID;
    if (signature != null && signature.isNotEmpty) {
      await db.insert(
        'a_tblRequestReceiverSignature',
        {'RequestID': parsedId, 'RequestReceiverSignature': signature},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (image != null && image.isNotEmpty) {
      await db.insert(
        'a_tblRequestImage',
        {'RequestID': parsedId, 'RequestImage': image},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // insertReceiverSignature and deleteReceiverSignatureByRequestId moved to SignatureDao

  // Remarks helpers
  Future<int> _insertRemark(String requestID, String remarks, String date) async {
    return await db.insert('a_tblRequestRemarks', {'RequestID': requestID, 'Remarks': remarks, 'Date': date}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CancelRemarksModel?> _getRequestRemarks(String requestID) async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestRemarks', where: 'RequestID = ?', whereArgs: [requestID], orderBy: 'Date DESC');
    if (maps.isEmpty) return null;
    return CancelRemarksModel.fromJson(maps.first);
  }

  Future<bool> _isRequestRemarkExisting(String requestID) async {
    final List<Map<String, dynamic>> maps = await db.query('a_tblRequestRemarks', where: 'RequestID = ?', whereArgs: [requestID], limit: 1);
    return maps.isNotEmpty;
  }

  /// Public: insert a remark and update request status atomically
  Future<int> cancelRequestWithRemarks({
    required String requestID,
    required String remarks,
    required String newStatus,
  }) async {
    final nowString = DateTime.now().toString();
    return await db.transaction((txn) async {
      await txn.insert(
        'a_tblRequestRemarks',
        {'RequestID': requestID, 'Remarks': remarks, 'Date': nowString},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return await txn.update(
        'a_tblRequest',
        {'RequestStatus': newStatus},
        where: 'RequestID = ?',
        whereArgs: [int.tryParse(requestID) ?? requestID],
      );
    });
  }

  /// Public: get latest remark for a request (throws if none found to mimic previous behavior)
  Future<CancelRemarksModel> getRequestRemarks(String requestID) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestRemarks',
      where: 'RequestID = ?',
      whereArgs: [requestID],
      orderBy: 'Date DESC',
    );
    if (maps.isEmpty) throw Exception('No remarks found for request ID: $requestID');
    return CancelRemarksModel.fromJson(maps.first);
  }

  /// Public: check existence of a remark
  Future<bool> isRequestRemarkExisting(String requestID) async {
    return await _isRequestRemarkExisting(requestID);
  }
}
