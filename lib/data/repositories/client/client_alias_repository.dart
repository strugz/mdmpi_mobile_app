import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_alias_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

/// Learned client aliases for the Standard Delivery one-scan, stored on this
/// device only (plan §4.4, §8 question 7). Local SQLite, no Firebase.
class ClientAliasRepository extends GetxController {
  ClientAliasRepository({Future<ClientAliasDao> Function()? dao})
      : _dao = dao ?? (() => DatabaseHelper.instance.clientAliasDao);

  final Future<ClientAliasDao> Function() _dao;

  /// The client id confirmed for [alias] before, or null when there is none.
  Future<Result<String?>> clientFor(String alias) async {
    if (alias.isEmpty) return Result.success(null);
    try {
      return Result.success(await (await _dao()).findByAlias(alias));
    } catch (e) {
      logDebug('[OneScan] alias lookup failed: $e');
      return Result.failure('Could not read the client alias: $e');
    }
  }

  /// Remembers that [alias] is [clientId], replacing an earlier choice.
  Future<Result<void>> remember(String alias, String clientId) async {
    if (alias.isEmpty || clientId.isEmpty) return Result.success(null);
    try {
      await (await _dao()).upsert(alias, clientId);
      return Result.success(null);
    } catch (e) {
      logDebug('[OneScan] alias save failed: $e');
      return Result.failure('Could not save the client alias: $e');
    }
  }

  /// Forgets [alias] (its client is no longer in the client list).
  Future<Result<void>> forget(String alias) async {
    try {
      await (await _dao()).deleteAlias(alias);
      return Result.success(null);
    } catch (e) {
      logDebug('[OneScan] alias delete failed: $e');
      return Result.failure('Could not delete the client alias: $e');
    }
  }
}
