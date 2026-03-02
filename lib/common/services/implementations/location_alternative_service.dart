import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/location_alternative_service.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/local/dao/standard_delivery/location_alternative_dao.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/location_alternative_model.dart';

/// Implementation of location alternative management service
class LocationAlternativeService extends ILocationAlternativeService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Helper method to convert dynamic requestId to int
  int _parseRequestId(dynamic requestId) {
    if (requestId is int) return requestId;
    if (requestId is String) return int.tryParse(requestId) ?? 0;
    return 0;
  }

  @override
  Future<int> saveLocationAlternative(LocationAlternativeModel model) async {
    try {
      final db = await _dbHelper.database;
      final id = await LocationAlternativeDAO.insert(db, model);
      logDebug('✓ Location alternative saved (ID: $id) for request ${model.requestId}');
      return id;
    } catch (e) {
      logDebug('✗ Error saving location alternative: $e');
      rethrow;
    }
  }

  @override
  Future<List<LocationAlternativeModel>> getLocationAlternativesByRequestId(
    dynamic requestId,
  ) async {
    try {
      final intRequestId = _parseRequestId(requestId);
      final db = await _dbHelper.database;
      final alternatives = await LocationAlternativeDAO.getByRequestId(db, intRequestId);
      logDebug('✓ Retrieved ${alternatives.length} location alternatives for request $intRequestId');
      return alternatives;
    } catch (e) {
      logDebug('✗ Error retrieving location alternatives: $e');
      return [];
    }
  }

  @override
  Future<LocationAlternativeModel?> getLatestLocationAlternative(
    dynamic requestId,
  ) async {
    try {
      final intRequestId = _parseRequestId(requestId);
      final db = await _dbHelper.database;
      final alternative = await LocationAlternativeDAO.getLatestByRequestId(db, intRequestId);
      if (alternative != null) {
        logDebug('✓ Retrieved latest location alternative for request $intRequestId');
      }
      return alternative;
    } catch (e) {
      logDebug('✗ Error retrieving latest location alternative: $e');
      return null;
    }
  }

  @override
  Future<int> deleteLocationAlternativesByRequestId(dynamic requestId) async {
    try {
      final intRequestId = _parseRequestId(requestId);
      final db = await _dbHelper.database;
      final count = await LocationAlternativeDAO.deleteByRequestId(db, intRequestId);
      logDebug('✓ Deleted $count location alternatives for request $intRequestId');
      return count;
    } catch (e) {
      logDebug('✗ Error deleting location alternatives: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteLocationAlternativeById(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await LocationAlternativeDAO.deleteById(db, id);
      logDebug('✓ Deleted location alternative ID: $id');
      return count;
    } catch (e) {
      logDebug('✗ Error deleting location alternative: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasLocationAlternatives(dynamic requestId) async {
    try {
      final intRequestId = _parseRequestId(requestId);
      final db = await _dbHelper.database;
      final count = await LocationAlternativeDAO.countByRequestId(db, intRequestId);
      return count > 0;
    } catch (e) {
      logDebug('✗ Error checking location alternatives: $e');
      return false;
    }
  }

  @override
  Future<int> clearAllLocationAlternatives() async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete('a_tblLocationAlternative');
      logDebug('✓ Cleared all location alternatives ($count records)');
      return count;
    } catch (e) {
      logDebug('✗ Error clearing location alternatives: $e');
      rethrow;
    }
  }
}
