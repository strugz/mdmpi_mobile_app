import 'dart:math' as math;

import 'package:mdmpi_mobile_app/base/utils/b_client_address.dart';
import 'package:mdmpi_mobile_app/base/utils/b_name_normalizer.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// One client, normalized once for scoring. Holds the id only, never the
/// [ClientModel], so a refreshed client list can be garbage-collected.
class IndexedClient {
  const IndexedClient({
    required this.id,
    required this.normalized,
    required this.tokens,
    required this.key,
    required this.addressTokens,
  });

  final String id;
  final String normalized;
  final List<String> tokens;
  final String key;

  /// Empty when the saved address is missing (blank / N/A).
  final List<String> addressTokens;
}

/// The client list normalized and indexed for one-scan matching (plan §4.4
/// "Performance" and "Cache invalidation"). Built from a list, tagged with
/// that list's [fingerprint]; rebuilt when the fingerprint changes.
class ClientTokenIndex {
  ClientTokenIndex._(this.fingerprintValue, this.clients, this._byToken,
      this._addressCount);

  /// [fingerprint] of the list this index was built from.
  final int fingerprintValue;

  final List<IndexedClient> clients;
  final Map<String, List<int>> _byToken;

  /// How many clients' addresses hold each address word.
  final Map<String, int> _addressCount;

  /// How much a name word says about which client it is: high when few
  /// clients have it (`GALINATO`), low when many do (`HOSPITAL`). A word no
  /// client has counts as rare. Inverse document frequency,
  /// `ln((N + 1) / (n + 1)) + 1`, so a word every client has still counts 1.
  double nameWeight(String token) =>
      _rarity(_byToken[token]?.length ?? 0);

  /// [nameWeight] for address words (`MANDALUYONG` over `CITY`).
  double addressWeight(String token) => _rarity(_addressCount[token] ?? 0);

  double _rarity(int clientsWithIt) =>
      math.log((clients.length + 1) / (clientsWithIt + 1)) + 1;

  /// Cheap identity of a client list's content: length plus every
  /// `id|name|address`. Catches a sync, a hard reset or an edit that keeps
  /// the row count, and works when the list object itself is reused
  /// (`RxList.assignAll`).
  static int fingerprint(List<ClientModel> list) => Object.hash(
        list.length,
        Object.hashAll(list.map((c) => '${c.id}|${c.name}|${c.address}')),
      );

  static ClientTokenIndex build(List<ClientModel> list) {
    final clients = <IndexedClient>[];
    final byToken = <String, List<int>>{};
    final addressCount = <String, int>{};
    for (final c in list) {
      final tokens = BNameNormalizer.scoringTokens(c.name);
      final addressTokens = BClientAddress.isMissing(c.address)
          ? const <String>[]
          : BNameNormalizer.scoringTokens(c.address);
      final index = clients.length;
      clients.add(IndexedClient(
        id: c.id,
        normalized: BNameNormalizer.normalize(c.name),
        tokens: tokens,
        key: tokens.join(' '),
        addressTokens: addressTokens,
      ));
      for (final t in {...tokens, ...tokens.map(_prefixKey)}) {
        byToken.putIfAbsent(t, () => []).add(index);
      }
      for (final t in addressTokens.toSet()) {
        addressCount[t] = (addressCount[t] ?? 0) + 1;
      }
    }
    return ClientTokenIndex._(
        fingerprint(list), clients, byToken, addressCount);
  }

  /// Clients sharing at least one significant token, or the first three
  /// letters of one, with [tokens]. Only these are scored.
  Iterable<IndexedClient> candidatesFor(List<String> tokens) {
    final hits = <int>{};
    for (final t in {...tokens, ...tokens.map(_prefixKey)}) {
      hits.addAll(_byToken[t] ?? const []);
    }
    return hits.map((i) => clients[i]);
  }

  IndexedClient? byId(String id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  static String _prefixKey(String token) =>
      token.length > 3 ? '#${token.substring(0, 3)}' : '#$token';
}
