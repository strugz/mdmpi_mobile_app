import 'package:sqflite/sqflite.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_dao.dart';

/// DAO for Pull-Out request local database operations.
class PullOutDao {
  final Database db;

  PullOutDao(this.db);

  /// Fetch all Pull-Out requests from local database with joined data.
  Future<List<PullOutModel>> getPullOutRequests() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM a_tblRequestPullOutReturnPickUp
      ORDER BY RequestID DESC
    ''');

    if (maps.isEmpty) return [];

    List<PullOutModel> pullOutRequests = [];
    for (var map in maps) {
      PullOutModel pullOut = PullOutModel.fromDbJson(map);

      // Load cancel remarks if cancelled
      if (pullOut.requestStatus == 'Cancelled') {
        final remarks = await _getRequestRemarks(pullOut.id);
        if (remarks != null) {
          pullOut = pullOut.copyWith(cancelRemarks: remarks);
        }
      }

      // Load client info via ClientDao
      if (pullOut.clientId.isNotEmpty) {
        final clientDao = ClientDao(db);
        final client = await clientDao.getById(pullOut.clientId);
        if (client != null) {
          pullOut = pullOut.copyWith(client: client);
        }
      }

      // Fetch Document References
      final docRefs = await _getDocumentReferences(pullOut.id);
      pullOut = pullOut.copyWith(documentReference: docRefs);

      pullOutRequests.add(pullOut);
    }

    return pullOutRequests;
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

  /// Insert a single Pull-Out request.
  Future<int> insertPullOut(PullOutModel pullOutModel) async {
    final parsedId = int.tryParse(pullOutModel.id) ?? pullOutModel.id;

    Map<String, dynamic> pullOutData = {
      'RequestID': parsedId,
      'ClientID': pullOutModel.clientId,
      'ClientContactPerson': pullOutModel.clientContactPerson,
      'FormCategoryID': pullOutModel.formCategoryId,
      'ItemCategoryID': pullOutModel.itemCategoryId,
      'IRRFNumber': pullOutModel.irrfNumber,
      'IRRFDate': pullOutModel.irrfDate,
      'ReasonForReturn': pullOutModel.reasonForReturn,
      'ReleasedBy': pullOutModel.releasedBy,
      'PullOutDate': pullOutModel.pullOutDate,
      'PullOutDateStartAt': pullOutModel.pullOutDateStartAt,
      'PullOutDateEndAt': pullOutModel.pullOutDateEndAt,
      'RequestStatus': pullOutModel.requestStatus,
      'TripTicketNumber': pullOutModel.tripTicketNumber,
      'Driver': pullOutModel.driver,
      'Helper': pullOutModel.helper,
      'MobileID': pullOutModel.mobileID,
      'MobileName': pullOutModel.mobileName,
      'CreatedAt': pullOutModel.createdAt,
      'UpdatedAt': pullOutModel.updatedAt,
      'CreatedBy': pullOutModel.createdBy,
      'RequestedBy': pullOutModel.requestedBy,
    };

    final int requestId = await db.insert(
      'a_tblRequestPullOutReturnPickUp',
      pullOutData,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (requestId == 0) {
      await updatePullOut(pullOutModel: pullOutModel);
      return 0;
    }

    // Insert Document References
    if (pullOutModel.documentReference.isNotEmpty) {
      for (String reference in pullOutModel.documentReference) {
        if (reference.isNotEmpty) {
          await db.insert(
            'a_tblRequestDocumentReference',
            {
              'RequestID': parsedId,
              'Reference': reference,
              'RequestCreatedAt': pullOutModel.createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    // Persist client info
    try {
      final client = pullOutModel.client;
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

    return int.tryParse(pullOutModel.id) ?? requestId;
  }

  /// Insert multiple Pull-Out requests in batch.
  Future<void> insertPullOutRequests(List<PullOutModel> pullOutModels) async {
    Batch batch = db.batch();

    for (PullOutModel pullOutModel in pullOutModels) {
      final parsedId = int.tryParse(pullOutModel.id) ?? pullOutModel.id;

      Map<String, dynamic> pullOutData = {
        'RequestID': parsedId,
        'ClientID': pullOutModel.clientId,
        'ClientContactPerson': pullOutModel.clientContactPerson,
        'FormCategoryID': pullOutModel.formCategoryId,
        'ItemCategoryID': pullOutModel.itemCategoryId,
        'IRRFNumber': pullOutModel.irrfNumber,
        'IRRFDate': pullOutModel.irrfDate,
        'ReasonForReturn': pullOutModel.reasonForReturn,
        'ReleasedBy': pullOutModel.releasedBy,
        'PullOutDate': pullOutModel.pullOutDate,
        'PullOutDateStartAt': pullOutModel.pullOutDateStartAt,
        'PullOutDateEndAt': pullOutModel.pullOutDateEndAt,
        'RequestStatus': pullOutModel.requestStatus,
        'TripTicketNumber': pullOutModel.tripTicketNumber,
        'Driver': pullOutModel.driver,
        'Helper': pullOutModel.helper,
        'MobileID': pullOutModel.mobileID,
        'MobileName': pullOutModel.mobileName,
        'CreatedAt': pullOutModel.createdAt,
        'UpdatedAt': pullOutModel.updatedAt,
        'CreatedBy': pullOutModel.createdBy,
        'RequestedBy': pullOutModel.requestedBy,
      };

      batch.insert(
        'a_tblRequestPullOutReturnPickUp',
        pullOutData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert document references
      if (pullOutModel.documentReference.isNotEmpty) {
        for (String reference in pullOutModel.documentReference) {
          if (reference.isNotEmpty) {
            batch.insert(
              'a_tblRequestDocumentReference',
              {
                'RequestID': parsedId,
                'Reference': reference,
                'RequestCreatedAt': pullOutModel.createdAt,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }

      // Persist client info
      try {
        final client = pullOutModel.client;
        if (client.id.isNotEmpty) {
          batch.insert(
            'ACCMST_',
            client.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (_) {
        // ignore client persistence failures
      }
    }

    await batch.commit(noResult: true);
  }

  /// Update an existing Pull-Out request.
  Future<int> updatePullOut({required PullOutModel pullOutModel}) async {
    final parsedId = int.tryParse(pullOutModel.id) ?? pullOutModel.id;

    Map<String, dynamic> pullOutData = {
      'ClientID': pullOutModel.clientId,
      'ClientContactPerson': pullOutModel.clientContactPerson,
      'FormCategoryID': pullOutModel.formCategoryId,
      'ItemCategoryID': pullOutModel.itemCategoryId,
      'IRRFNumber': pullOutModel.irrfNumber,
      'IRRFDate': pullOutModel.irrfDate,
      'ReasonForReturn': pullOutModel.reasonForReturn,
      'ReleasedBy': pullOutModel.releasedBy,
      'PullOutDate': pullOutModel.pullOutDate,
      'PullOutDateStartAt': pullOutModel.pullOutDateStartAt,
      'PullOutDateEndAt': pullOutModel.pullOutDateEndAt,
      'RequestStatus': pullOutModel.requestStatus,
      'TripTicketNumber': pullOutModel.tripTicketNumber,
      'Driver': pullOutModel.driver,
      'Helper': pullOutModel.helper,
      'MobileID': pullOutModel.mobileID,
      'MobileName': pullOutModel.mobileName,
      'UpdatedAt': pullOutModel.updatedAt,
      'CreatedBy': pullOutModel.createdBy,
      'RequestedBy': pullOutModel.requestedBy,
    };

    return await db.update(
      'a_tblRequestPullOutReturnPickUp',
      pullOutData,
      where: 'RequestID = ?',
      whereArgs: [parsedId],
    );
  }

  /// Delete all Pull-Out requests.
  Future<int> deleteAll() async {
    return await db.delete('a_tblRequestPullOutReturnPickUp');
  }

  /// Check if the Pull-Out table is not empty.
  Future<bool> isPullOutTableNotEmpty() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM a_tblRequestPullOutReturnPickUp',
    );
    final count = result.first['count'] as int?;
    return count != null && count > 0;
  }
}

