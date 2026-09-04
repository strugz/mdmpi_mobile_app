import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_dao.dart';

/// DAO for pick-up request local database operations.
class PickUpDao {
  final Database db;

  PickUpDao(this.db);

  // Local status map for status progression validation
  static const Map<String, int> _statusStringToInt = {
    'New Request': 1,
    'Item Prepared': 2,
    'Item Packed': 3,
    'Received': 4,
    'Cancelled': 99,
  };

  /// Fetch all pick-up requests from local database with joined data.
  Future<List<PickUpModel>> getPickUps() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM a_tblRequestPickUp
      ORDER BY RequestID DESC
    ''');

    if (maps.isEmpty) return [];

    List<PickUpModel> pickUps = [];
    for (var map in maps) {
      PickUpModel pickUp = PickUpModel.fromDbJson(map);

      // Load cancel remarks if cancelled
      if (pickUp.status == 'Cancelled') {
        final remarks = await _getRequestRemarks(pickUp.id);
        if (remarks != null) {
          pickUp = pickUp.copyWith(remarks: remarks.remarks);
        }
      }

      // Load client info via ClientDao
      if (pickUp.clientId.isNotEmpty) {
        final clientDao = ClientDao(db);
        final client = await clientDao.getById(pickUp.clientId);
        if (client != null) {
          pickUp = pickUp.copyWith(client: client);
        }
      }

      // Fetch Document References
      final docRefs = await _getDocumentReferences(pickUp.id);
      pickUp = pickUp.copyWith(documentReference: docRefs);

      pickUps.add(pickUp);
    }

    return pickUps;
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

  /// Insert a single pick-up request.
  Future<int> insertPickUp(PickUpModel pickUpModel) async {
    final parsedId = int.tryParse(pickUpModel.id) ?? pickUpModel.id;

    Map<String, dynamic> pickUpData = {
      'RequestID': parsedId,
      'ClientID': pickUpModel.clientId,
      'ItemCategoryID': pickUpModel.itemCategoryId,
      'ItemCategoryIDs': pickUpModel.itemCategoryIds.join(','),
      'ItemCategoryName': pickUpModel.itemCategory.name,
      'PreparedBy': pickUpModel.preparedBy,
      'ItemPreparedAt': pickUpModel.itemPreparedAt,
      'ItemPreparedEndAt': pickUpModel.itemPreparedEndAt,
      'DatePickUp': pickUpModel.datePickUp,
      'Remarks': pickUpModel.remarks,
      'Status': pickUpModel.status,
      'ReleasedBy': pickUpModel.releasedBy,
      'ReceivedBy': pickUpModel.receivedBy,
      'CreatedBy': pickUpModel.createdBy,
      'CreatedAt': pickUpModel.createdAt,
      'UpdatedAt': pickUpModel.updatedAt,
    };

    final int requestId = await db.insert(
      'a_tblRequestPickUp',
      pickUpData,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (requestId == 0) {
      await updatePickUp(pickUpModel: pickUpModel);
      return 0;
    }

    // Insert Document References
    if (pickUpModel.documentReference.isNotEmpty) {
      for (String reference in pickUpModel.documentReference) {
        if (reference.isNotEmpty) {
          await db.insert(
            'a_tblRequestDocumentReference',
            {
              'RequestID': parsedId,
              'Reference': reference,
              'RequestCreatedAt': pickUpModel.createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    // Persist client info
    try {
      final client = pickUpModel.client;
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

    return int.tryParse(pickUpModel.id) ?? requestId;
  }

  /// Insert multiple pick-up requests in batch.
  Future<void> insertPickUps(List<PickUpModel> pickUpModels) async {
    Batch batch = db.batch();

    for (PickUpModel pickUpModel in pickUpModels) {
      final parsedId = int.tryParse(pickUpModel.id) ?? pickUpModel.id;

      Map<String, dynamic> pickUpData = {
        'RequestID': parsedId,
        'ClientID': pickUpModel.clientId,
        'ItemCategoryID': pickUpModel.itemCategoryId,
        'ItemCategoryIDs': pickUpModel.itemCategoryIds.join(','),
        'ItemCategoryName': pickUpModel.itemCategory.name,
        'PreparedBy': pickUpModel.preparedBy,
        'ItemPreparedAt': pickUpModel.itemPreparedAt,
        'ItemPreparedEndAt': pickUpModel.itemPreparedEndAt,
        'DatePickUp': pickUpModel.datePickUp,
        'Remarks': pickUpModel.remarks,
        'Status': pickUpModel.status,
        'ReleasedBy': pickUpModel.releasedBy,
        'ReceivedBy': pickUpModel.receivedBy,
        'CreatedBy': pickUpModel.createdBy,
        'CreatedAt': pickUpModel.createdAt,
        'UpdatedAt': pickUpModel.updatedAt,
      };

      batch.insert(
        'a_tblRequestPickUp',
        pickUpData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert document references
      if (pickUpModel.documentReference.isNotEmpty) {
        for (var ref in pickUpModel.documentReference) {
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
                  'RequestCreatedAt': pickUpModel.createdAt,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }

      // Persist client info
      try {
        final client = pickUpModel.client;
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

  /// Update an existing pick-up request.
  Future<void> updatePickUp({required PickUpModel pickUpModel}) async {
    // Fetch current status to validate progression
    final List<Map<String, dynamic>> currentData = await db.query(
      'a_tblRequestPickUp',
      columns: ['Status'],
      where: 'RequestID = ?',
      whereArgs: [pickUpModel.id],
    );

    if (currentData.isEmpty) return;

    final String currentStatusString = currentData.first['Status'] as String;
    final int? currentStatusInt = _statusStringToInt[currentStatusString];
    final int? newStatusInt = _statusStringToInt[pickUpModel.status];

    // Don't allow status regression (except for cancelled)
    if (currentStatusInt != null && newStatusInt != null) {
      if (newStatusInt < currentStatusInt && pickUpModel.status != 'Cancelled') {
        return;
      }
    }

    Map<String, dynamic> pickUpData = {
      'ClientID': pickUpModel.clientId,
      'ItemCategoryID': pickUpModel.itemCategoryId,
      'ItemCategoryIDs': pickUpModel.itemCategoryIds.join(','),
      'ItemCategoryName': pickUpModel.itemCategory.name,
      'PreparedBy': pickUpModel.preparedBy,
      'ItemPreparedAt': pickUpModel.itemPreparedAt,
      'ItemPreparedEndAt': pickUpModel.itemPreparedEndAt,
      'DatePickUp': pickUpModel.datePickUp,
      'Remarks': pickUpModel.remarks,
      'Status': pickUpModel.status,
      'ReleasedBy': pickUpModel.releasedBy,
      'ReceivedBy': pickUpModel.receivedBy,
      'CreatedBy': pickUpModel.createdBy,
      'CreatedAt': pickUpModel.createdAt,
      'UpdatedAt': pickUpModel.updatedAt,
    };

    await db.update(
      'a_tblRequestPickUp',
      pickUpData,
      where: 'RequestID = ?',
      whereArgs: [pickUpModel.id],
    );
  }

  /// Check if pick-up table has any records.
  Future<bool> isPickUpTableNotEmpty() async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblRequestPickUp',
    );
    if (result.isNotEmpty) {
      final count = result.first['count'] as int?;
      return count != null && count > 0;
    }
    return false;
  }

  /// Delete all pick-up data (for sync/reset).
  /// Note: This only deletes from a_tblRequestPickUp. The shared support tables
  /// (a_tblRequestDocumentReference, etc.) will cascade delete via foreign keys.
  Future<void> deleteAll() async {
    await db.delete('a_tblRequestPickUp');
  }

  /// Save receiver signature for a pick-up request.
  Future<void> saveReceiverSignature(String requestId, String signatureBase64) async {
    await db.insert(
      'a_tblRequestReceiverSignature',
      {
        'RequestID': int.tryParse(requestId) ?? 0,
        'RequestReceiverSignature': signatureBase64,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get receiver signature for a pick-up request.
  Future<String?> getReceiverSignature(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestReceiverSignature',
      columns: ['RequestReceiverSignature'],
      where: 'RequestID = ?',
      whereArgs: [int.tryParse(requestId) ?? 0],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['RequestReceiverSignature'] as String?;
  }

  /// Save proof image for a pick-up request.
  Future<void> saveProofImage(String requestId, String imageBase64) async {
    await db.insert(
      'a_tblRequestImage',
      {
        'RequestID': int.tryParse(requestId) ?? 0,
        'RequestImage': imageBase64,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get proof image for a pick-up request.
  Future<String?> getProofImage(String requestId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'a_tblRequestImage',
      columns: ['RequestImage'],
      where: 'RequestID = ?',
      whereArgs: [int.tryParse(requestId) ?? 0],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['RequestImage'] as String?;
  }
}

