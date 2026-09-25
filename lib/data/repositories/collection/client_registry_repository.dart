import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_client_dao.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The client registry (the server's a_tblcollectionclient): every client SAP
/// has imported, not only those with an invoice in the collector's bucket.
///
/// Cached locally like the bank list, and the cache is what the account
/// picker reads: the picker used to ask the server on every keystroke and
/// sat empty while it waited. The network is a refresh, run behind the
/// collector after a download; and a live search only while nothing is
/// cached yet.
class ClientRegistryRepository extends GetxService {
  static ClientRegistryRepository get instance => Get.find();

  /// `/api4`: served by MDMPI.App like every other Collection call.
  static const String _path = '/api4/Collection/clients';

  /// The server's page-size ceiling for this endpoint.
  static const int _pageSize = 200;

  /// A safety stop for a server that never reports the last page.
  static const int _maxPages = 200;

  static const Duration _timeout = Duration(seconds: 20);

  CollectionClientDao? _daoInstance;

  Future<CollectionClientDao> get _dao async {
    if (_daoInstance != null) return _daoInstance!;
    final db = await DatabaseHelper.instance.database;
    _daoInstance = CollectionClientDao(db);
    return _daoInstance!;
  }

  /// Search the cached registry. Never hits the network.
  Future<List<ClientModel>> searchCached(String term) async {
    try {
      return (await _dao).search(term);
    } catch (e) {
      logDebug('ClientRegistryRepository.searchCached error: $e');
      return const [];
    }
  }

  /// How many clients are cached; 0 until the first refresh lands.
  Future<int> cachedCount() async {
    try {
      return (await _dao).count();
    } catch (e) {
      logDebug('ClientRegistryRepository.cachedCount error: $e');
      return 0;
    }
  }

  /// Download the whole registry, page by page, and replace the cache.
  ///
  /// Resolves to how many clients were cached. A failure leaves the old
  /// cache in place: the picker keeps working on what it had.
  Future<Result<int>> refresh() async {
    try {
      final all = <ClientModel>[];
      for (var page = 1; page <= _maxPages; page++) {
        final result = await _page('', page: page, pageSize: _pageSize);
        if (result.isFailure) return Result.failure(result.error);
        final (clients, total) = result.value;
        all.addAll(clients);
        if (clients.length < _pageSize || all.length >= total) break;
      }
      if (all.isNotEmpty) await (await _dao).replaceAll(all);
      logDebug('ClientRegistryRepository: cached ${all.length} clients');
      return Result.success(all.length);
    } catch (e) {
      logDebug('ClientRegistryRepository.refresh error: $e');
      return Result.failure('Could not refresh the client list');
    }
  }

  /// Search the server directly, for the moment before anything is cached.
  Future<Result<List<ClientModel>>> searchOnline(String term,
      {int limit = 25}) async {
    final result = await _page(term, page: 1, pageSize: limit);
    return result.isSuccess
        ? Result.success(result.value.$1)
        : Result.failure(result.error);
  }

  /// One page of `GET /api4/Collection/clients`: the clients and the total.
  Future<Result<(List<ClientModel>, int)>> _page(String term,
      {required int page, required int pageSize}) async {
    try {
      final uri = BApiEnvironment.api4Uri(_path, {
        if (term.trim().isNotEmpty) 'search': term.trim(),
        'page': '$page',
        'pageSize': '$pageSize',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return Result.failure('Client list request failed '
            '(${response.statusCode})');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return Result.success((const [], 0));
      final items = decoded['Items'];
      final total = (decoded['Total'] as num?)?.toInt() ?? 0;
      if (items is! List) return Result.success((const [], total));
      return Result.success(([
        for (final m in items.whereType<Map>())
          if ((m['ClientCode']?.toString() ?? '').trim().isNotEmpty)
            fromRegistryJson(Map<String, dynamic>.from(m)),
      ], total));
    } catch (e) {
      logDebug('ClientRegistryRepository._page error: $e');
      return Result.failure('The client list is unavailable offline');
    }
  }

  /// A registry row as the app's client. In this app a Collection client's
  /// id and code are both the registry's ClientCode (the workspace sends it
  /// as ACCMID and ACCMSC alike), so a picked client uploads like any other.
  static ClientModel fromRegistryJson(Map<String, dynamic> m) {
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
}
