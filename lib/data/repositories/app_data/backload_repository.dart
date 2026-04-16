import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_model.dart';

/// Repository for BackLoad records.
///
/// **API-first persistence:** a BackLoad record is always saved to the API
/// first. Only after a successful API response is the record written to the
/// local DB. If the API call fails, nothing is persisted locally.
///
/// The local BackLoad table is only populated when the transaction already
/// has BackLoad history (from the API sync or a successful save).
class BackLoadRepository extends GetxController {
  static BackLoadRepository get instance => Get.find();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // API helpers
  // ---------------------------------------------------------------------------

  String get _baseUrl => '${dotenv.env['API_URL']!}/api4/RequestBackload';

  // ---------------------------------------------------------------------------
  // CREATE — submit a new back-load entry
  // ---------------------------------------------------------------------------

  /// Posts a new BackLoad record to the API first.
  ///
  /// Only after a successful API response is the record written to local DB.
  /// If the API save fails, **nothing** is written to the local BackLoad table.
  ///
  /// Returns [Result.success] with the saved model on success, or
  /// [Result.failure] with an error message on failure.
  ///
  /// [requestId] The original transaction ID.
  /// [remarks]   One of the fixed dropdown values.
  Future<Result<BackLoadModel>> addBackLoad({
    required String requestId,
    required String remarks,
    required String deliveryDate,
  }) async {
    try {
      final payload = jsonEncode({
        'RequestID': requestId,
        'Remarks': remarks,
        'DeliveryDate': deliveryDate
      });

      // Use logDebug instead of print for debug output (project convention)
      logDebug('➡️ BackLoadRepository.addBackLoad POST $_baseUrl');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: payload,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic body = jsonDecode(response.body);


        final BackLoadModel saved = body is Map<String, dynamic>
            ? BackLoadModel.fromJson(body)
            : BackLoadModel(
                backLoadId: '',
                requestId: requestId,
                remarks: remarks,
                dateReported: DateTime.now().toIso8601String(),
                deliveryDate: deliveryDate,
              );

        // Ensure a stable local primary key exists. If API did not return
        // a BackLoadID, generate a unique local id to avoid replace-on-empty-pk
        // collisions (which would make the table appear blank or only hold a
        // single overwritten row). Use requestId + timestamp for uniqueness.
        BackLoadModel toInsert = saved;
        if (toInsert.backLoadId.isEmpty) {
          final generatedId = '${requestId}_${DateTime.now().millisecondsSinceEpoch}';
          toInsert = toInsert.copyWith(backLoadId: generatedId);
        }

        // Persist locally only after API success
        final dao = await _dbHelper.backLoadDao;
        await dao.insert(toInsert);

        return Result.success(toInsert);
      } else {
        return Result.failure(
            'Failed to save back load. Status: ${response.statusCode}');
      }
    } catch (e) {
      logDebug('❌ BackLoadRepository.addBackLoad error: $e');
      return Result.failure(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // READ — fetch back-load data
  // ---------------------------------------------------------------------------

  /// Fetch all BackLoad records from the API and sync to local DB.
  ///
  /// Only transactions that already have BackLoad history on the API will
  /// have corresponding local rows after this sync.
  Future<Result<List<BackLoadModel>>> fetchAllFromApi() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        final List<BackLoadModel> records = [];

        if (body is List) {
          for (final item in body) {
            if (item is Map<String, dynamic>) {
              records.add(BackLoadModel.fromJson(item));
            }
          }
        }

        // Sync to local DB — only records from API are stored
        final dao = await _dbHelper.backLoadDao;
        await dao.deleteAll();
        await dao.insertAll(records);

        logDebug('✅ BackLoadRepository: synced ${records.length} records');
        return Result.success(records);
      } else {
        return Result.failure(
            'Failed to fetch back loads. Status: ${response.statusCode}');
      }
    } catch (e) {
      logDebug('❌ BackLoadRepository.fetchAllFromApi error: $e');
      return Result.failure(e.toString());
    }
  }

  /// Fetch BackLoad records for a specific request from the API.
  Future<Result<List<BackLoadModel>>> fetchByRequestId(String requestId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$requestId'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        final List<BackLoadModel> records = [];

        if (body is List) {
          for (final item in body) {
            if (item is Map<String, dynamic>) {
              records.add(BackLoadModel.fromJson(item));
            }
          }
        } else if (body is Map<String, dynamic>) {
          records.add(BackLoadModel.fromJson(body));
        }

        return Result.success(records);
      } else {
        return Result.success([]);
      }
    } catch (e) {
      logDebug('❌ BackLoadRepository.fetchByRequestId error: $e');
      return Result.failure(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL DB helpers
  // ---------------------------------------------------------------------------

  /// Get all BackLoad entries for a request from local DB.
  Future<List<BackLoadModel>> getLocalByRequestId(String requestId) async {
    final dao = await _dbHelper.backLoadDao;
    return dao.getByRequestId(requestId);
  }

  /// Get the most recent BackLoad entry for a request from local DB.
  Future<BackLoadModel?> getLatestLocalByRequestId(String requestId) async {
    final dao = await _dbHelper.backLoadDao;
    return dao.getLatestByRequestId(requestId);
  }

  /// Get all BackLoad records from local DB.
  Future<List<BackLoadModel>> getAllLocal() async {
    final dao = await _dbHelper.backLoadDao;
    return dao.getAll();
  }
}

