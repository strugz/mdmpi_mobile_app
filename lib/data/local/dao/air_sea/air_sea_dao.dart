import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_dao.dart';

/// DAO for Air/Sea request local database operations.
class AirSeaDao {
  final Database db;

  AirSeaDao(this.db);

  // Local status map for status progression validation
  static const Map<String, int> _statusStringToInt = {
    'New Request': 1,
    'Getting Supplies Ready': 2,
    'Item Packed': 3,
    'Endorsed to Guard': 4,
    'Received': 5,
    'Cancelled': 99,
  };

  /// Fetch all Air/Sea requests from local database with joined data.
  Future<List<AirSeaModel>> getAirSeaRequests() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM a_tblRequestAirSea
      ORDER BY RequestID DESC
    ''');

    if (maps.isEmpty) return [];

    List<AirSeaModel> airSeaRequests = [];
    for (var map in maps) {
      AirSeaModel airSea = AirSeaModel.fromDbJson(map);

      // Load cancel remarks if cancelled
      if (airSea.status == 'Cancelled') {
        final remarks = await _getRequestRemarks(airSea.id);
        if (remarks != null) {
          airSea = airSea.copyWith(cancelRemarks: remarks);
        }
      }

      // Load client info via ClientDao
      if (airSea.clientId.isNotEmpty) {
        final clientDao = ClientDao(db);
        final client = await clientDao.getById(airSea.clientId);
        if (client != null) {
          airSea = airSea.copyWith(client: client);
        }
      }

      // Fetch Document References
      final docRefs = await _getDocumentReferences(airSea.id);
      airSea = airSea.copyWith(documentReference: docRefs);

      airSeaRequests.add(airSea);
    }

    return airSeaRequests;
  }

  /// Get document references for a specific request.
  Future<List<String>> _getDocumentReferences(String requestId) async {
    final parsedId = int.tryParse(requestId) ?? 0;
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestDocumentReference',
      columns: ['Reference'],
      where: 'RequestID = ?',
      whereArgs: [parsedId],
    );
    return maps.map((m) => m['Reference'] as String).toList();
  }

  /// Get cancel remarks for a specific request.
  Future<CancelRemarksModel?> _getRequestRemarks(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestRemarks',
      where: 'RequestID = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    return CancelRemarksModel(
      requestId: requestId,
      remarks: map['Remarks'] as String? ?? '',
      date: map['Date'] as String? ?? '',
      userUpdated: '',
    );
  }

  /// Insert a single Air/Sea request.
  Future<int> insertAirSea(AirSeaModel airSeaModel) async {
    final parsedId = int.tryParse(airSeaModel.id) ?? airSeaModel.id;

    Map<String, dynamic> airSeaData = {
      'RequestID': parsedId,
      'ClientID': airSeaModel.clientId,
      'ItemCategoryID': airSeaModel.itemCategoryId,
            'MobileID': airSeaModel.mobileId,
      'DatePickUp': airSeaModel.datePickUp,
      'ItemPreparedAt': airSeaModel.itemPreparedAt,
      'ItemPreparedEndAt': airSeaModel.itemPreparedEndAt,
      'PreparedBy': airSeaModel.preparedBy,
      'WaybillNumber': airSeaModel.waybillNumber,
      'ReceivedAt': airSeaModel.receivedAt,
      'ReceivedBy': airSeaModel.receivedBy,
      'Status': airSeaModel.status,
      'Remarks': airSeaModel.remarks,
      'CreatedAt': airSeaModel.createdAt,
      'UpdatedAt': airSeaModel.updatedAt,
    };

    final int requestId = await db.insert(
      'a_tblRequestAirSea',
      airSeaData,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (requestId == 0) {
      await updateAirSea(airSeaModel: airSeaModel);
      return 0;
    }

    // Insert Document References
    if (airSeaModel.documentReference.isNotEmpty) {
      for (String reference in airSeaModel.documentReference) {
        if (reference.isNotEmpty) {
          await db.insert(
            'a_tblRequestDocumentReference',
            {
              'RequestID': parsedId,
              'Reference': reference,
              'RequestCreatedAt': airSeaModel.createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    // Persist client info
    try {
      final client = airSeaModel.client;
      if (client.id.isNotEmpty) {
        await db.insert(
          'ACCMST_',
          client.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {
      // ignore client persistence failures
    }

    return int.tryParse(airSeaModel.id) ?? requestId;
  }

  /// Insert multiple Air/Sea requests in batch.
  Future<void> insertAirSeaRequests(List<AirSeaModel> airSeaModels) async {
    Batch batch = db.batch();

    for (AirSeaModel airSeaModel in airSeaModels) {
      final parsedId = int.tryParse(airSeaModel.id) ?? airSeaModel.id;

      Map<String, dynamic> airSeaData = {
        'RequestID': parsedId,
        'ClientID': airSeaModel.clientId,
        'ItemCategoryID': airSeaModel.itemCategoryId,
                'MobileID': airSeaModel.mobileId,
        'DatePickUp': airSeaModel.datePickUp,
        'ItemPreparedAt': airSeaModel.itemPreparedAt,
        'ItemPreparedEndAt': airSeaModel.itemPreparedEndAt,
        'PreparedBy': airSeaModel.preparedBy,
        'WaybillNumber': airSeaModel.waybillNumber,
        'ReceivedAt': airSeaModel.receivedAt,
        'ReceivedBy': airSeaModel.receivedBy,
        'Status': airSeaModel.status,
        'Remarks': airSeaModel.remarks,
        'CreatedAt': airSeaModel.createdAt,
        'UpdatedAt': airSeaModel.updatedAt,
      };

      batch.insert(
        'a_tblRequestAirSea',
        airSeaData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert document references
      if (airSeaModel.documentReference.isNotEmpty) {
        for (var ref in airSeaModel.documentReference) {
          if (ref.isNotEmpty) {
            // Check if already exists to avoid duplicates
            final List<Map<String, dynamic>> existing = await db.query(
              'a_tblRequestDocumentReference',
              where: 'RequestID = ? AND Reference = ?',
              whereArgs: [parsedId, ref],
              limit: 1,
            );
            if (existing.isEmpty) {
              batch.insert(
                'a_tblRequestDocumentReference',
                {
                  'RequestID': parsedId,
                  'Reference': ref,
                  'RequestCreatedAt': airSeaModel.createdAt,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }

      // Persist client info
      try {
        final client = airSeaModel.client;
        if (client.id.isNotEmpty) {
          batch.insert(
            'ACCMST_',
            client.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (_) {
        // ignore
      }
    }

    await batch.commit(noResult: true);
  }

  /// Update an existing Air/Sea request.
  Future<void> updateAirSea({required AirSeaModel airSeaModel}) async {
    // Fetch current status to validate progression
    final List<Map<String, dynamic>> currentData = await db.query(
      'a_tblRequestAirSea',
      columns: ['Status'],
      where: 'RequestID = ?',
      whereArgs: [airSeaModel.id],
    );

    if (currentData.isEmpty) return;

    final String currentStatusString = currentData.first['Status'] as String;
    final int? currentStatusInt = _statusStringToInt[currentStatusString];
    final int? newStatusInt = _statusStringToInt[airSeaModel.status];

    // Don't allow status regression (except for cancelled)
    if (currentStatusInt != null && newStatusInt != null) {
      if (newStatusInt < currentStatusInt &&
          airSeaModel.status != 'Cancelled') {
        return;
      }
    }

    Map<String, dynamic> airSeaData = {
      'ClientID': airSeaModel.clientId,
      'ItemCategoryID': airSeaModel.itemCategoryId,
            'MobileID': airSeaModel.mobileId,
      'DatePickUp': airSeaModel.datePickUp,
      'ItemPreparedAt': airSeaModel.itemPreparedAt,
      'ItemPreparedEndAt': airSeaModel.itemPreparedEndAt,
      'PreparedBy': airSeaModel.preparedBy,
      'WaybillNumber': airSeaModel.waybillNumber,
      'ReceivedAt': airSeaModel.receivedAt,
      'ReceivedBy': airSeaModel.receivedBy,
      'Status': airSeaModel.status,
      'Remarks': airSeaModel.remarks,
      'CreatedAt': airSeaModel.createdAt,
      'UpdatedAt': airSeaModel.updatedAt,
    };

    await db.update(
      'a_tblRequestAirSea',
      airSeaData,
      where: 'RequestID = ?',
      whereArgs: [airSeaModel.id],
    );
  }

  /// Check if Air/Sea table has any records.
  Future<bool> isAirSeaTableNotEmpty() async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblRequestAirSea',
    );
    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  /// Delete all Air/Sea data (for sync/reset).
  /// Note: This only deletes from a_tblRequestAirSea. The shared support tables
  /// (a_tblRequestDocumentReference, etc.) will cascade delete via foreign keys.
  Future<void> deleteAll() async {
    await db.delete('a_tblRequestAirSea');
  }

  /// Save receiver signature for an Air/Sea request.
  Future<void> saveReceiverSignature(
      String requestId, String signatureBase64) async {
    await db.insert(
      'a_tblRequestReceiverSignature',
      {
        'RequestID': requestId,
        'RequestReceiverSignature': signatureBase64,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve receiver signature for an Air/Sea request.
  Future<String?> getReceiverSignature(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestReceiverSignature',
      columns: ['RequestReceiverSignature'],
      where: 'RequestID = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['RequestReceiverSignature'] as String?;
  }

  /// Get a single Air/Sea request by ID.
  Future<AirSeaModel?> getAirSeaById(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestAirSea',
      where: 'RequestID = ?',
      whereArgs: [requestId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    AirSeaModel airSea = AirSeaModel.fromDbJson(maps.first);

    // Load cancel remarks if cancelled
    if (airSea.status == 'Cancelled') {
      final remarks = await _getRequestRemarks(airSea.id);
      if (remarks != null) {
        airSea = airSea.copyWith(cancelRemarks: remarks);
      }
    }

    // Load client info via ClientDao
    if (airSea.clientId.isNotEmpty) {
      final clientDao = ClientDao(db);
      final client = await clientDao.getById(airSea.clientId);
      if (client != null) {
        airSea = airSea.copyWith(client: client);
      }
    }

    // Fetch Document References
    final docRefs = await _getDocumentReferences(airSea.id);
    airSea = airSea.copyWith(documentReference: docRefs);

    return airSea;
  }

  /// Cancel an Air/Sea request with remarks.
  Future<void> cancelAirSeaWithRemarks({
    required String requestId,
    required String remarks,
    required String date,
  }) async {
    // Update status to Cancelled
    await db.update(
      'a_tblRequestAirSea',
      {
        'Status': 'Cancelled',
        'UpdatedAt': DateTime.now().toIso8601String(),
      },
      where: 'RequestID = ?',
      whereArgs: [requestId],
    );

    // Insert cancel remarks
    await db.insert(
      'a_tblRequestRemarks',
      {
        'RequestID': requestId,
        'Remarks': remarks,
        'Date': date,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
