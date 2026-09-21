import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_bank_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';

/// The company bank list.
///
/// Reference data, but read in the field with no guarantee of signal, so it
/// is cached locally and the cache is what the app reads. The network is only
/// ever a refresh.
class BankRepository extends GetxService {
  static BankRepository get instance => Get.find();

  static const Duration _timeout = Duration(seconds: 15);

  /// Live production, like every other non-`/api4` route.
  static Uri get endpoint =>
      Uri.parse('${BApiEnvironment.liveBaseUrl}/api2/DRPMST/banklist');

  CollectionBankDao? _daoInstance;

  Future<CollectionBankDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = CollectionBankDao(db);
    return _daoInstance!;
  }

  /// What is on the device right now. Never hits the network.
  Future<List<BankModel>> cached() async {
    try {
      return (await _dao).getAll();
    } catch (e) {
      logDebug('BankRepository.cached error: $e');
      return const [];
    }
  }

  /// Fetch from the server and replace the cache.
  ///
  /// Failure here is not a problem the collector needs to see: the picker
  /// falls back to whatever was cached, which is the whole reason for the
  /// cache. It is reported through [Result] for callers that do care.
  Future<Result<List<BankModel>>> refresh() async {
    try {
      final response = await http.get(endpoint).timeout(_timeout);

      if (response.statusCode != 200) {
        return Result.failure(
            'Bank list request failed (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return Result.failure('Bank list returned an unexpected shape');
      }

      final banks = <BankModel>[
        for (final row in decoded)
          if (row is Map<String, dynamic>) BankModel.fromJson(row),
      ]
          // A bank with no name is nothing a collector can pick.
          .where((b) => b.label.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (banks.isNotEmpty) {
        await (await _dao).replaceAll(banks);
      }
      return Result.success(banks);
    } catch (e) {
      logDebug('BankRepository.refresh error: $e');
      return Result.failure('Could not reach the bank list');
    }
  }
}
