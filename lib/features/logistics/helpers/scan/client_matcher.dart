import 'dart:async';

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:mdmpi_mobile_app/base/utils/b_name_normalizer.dart';
import 'package:mdmpi_mobile_app/base/utils/b_string_similarity.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_alias_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_token_index.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';

/// Ranks the local clients against a scanned customer name (plan §4.4):
/// a learned alias first, then a normalized exact name, then a fuzzy score.
/// It only ranks; the user always confirms.
///
/// The client list is passed in on every call (resolved fresh by the
/// caller), never stored. The normalized index is cached and checked against
/// the list's fingerprint each time.
class ClientMatcher {
  ClientMatcher({
    required ClientAliasRepository aliases,
    Future<ClientTokenIndex> Function(List<ClientModel>)? buildIndex,
  })  : _aliases = aliases,
        _buildIndex = buildIndex ?? _defaultBuild;

  final ClientAliasRepository _aliases;
  final Future<ClientTokenIndex> Function(List<ClientModel>) _buildIndex;

  /// Above this many clients the index is built off the UI thread.
  static const int isolateThreshold = 5000;

  ClientTokenIndex? _index;

  @visibleForTesting
  int buildCount = 0;

  @visibleForTesting
  bool get hasCache => _index != null;

  /// Frees the index (the Standard Delivery form was left).
  void clearCache() => _index = null;

  static Future<ClientTokenIndex> _defaultBuild(List<ClientModel> list) =>
      list.length > isolateThreshold
          ? compute(ClientTokenIndex.build, List<ClientModel>.of(list))
          : Future.value(ClientTokenIndex.build(list));

  Future<ClientTokenIndex> _indexFor(List<ClientModel> clients) async {
    final current = ClientTokenIndex.fingerprint(clients);
    final cached = _index;
    if (cached != null && cached.fingerprintValue == current) return cached;

    _index = null;
    buildCount++;
    var built = await _buildIndex(clients);
    // The list changed while the index was being built: never use a stale
    // index. Build again from what the list holds now.
    if (built.fingerprintValue != ClientTokenIndex.fingerprint(clients)) {
      logDebug('[OneScan] client list changed during index build; rebuilding');
      buildCount++;
      built = ClientTokenIndex.build(clients);
    }
    _index = built;
    return built;
  }

  Future<ClientMatchResult> match(
    ScannedClientHeader header,
    List<ClientModel> clients,
  ) async {
    final ocrName = header.name;
    if (ocrName == null || ocrName.trim().isEmpty || clients.isEmpty) {
      return ClientMatchResult(kind: ClientMatchKind.none, ocrName: ocrName);
    }

    final index = await _indexFor(clients);
    final byId = {for (final c in clients) c.id: c};
    final normalized = BNameNormalizer.normalize(ocrName);
    final tokens = BNameNormalizer.scoringTokens(ocrName);
    final key = tokens.join(' ');
    final scannedAddress = header.address == null
        ? const <String>[]
        : BNameNormalizer.scoringTokens(header.address!);

    final ranked = <ClientCandidate>[];
    final seen = <String>{};

    // 1. Learned alias.
    var kind = ClientMatchKind.fuzzy;
    final alias = await _aliases.clientFor(normalized);
    final aliasId = alias.isSuccess ? alias.value : null;
    if (aliasId != null) {
      final client = byId[aliasId];
      if (client == null) {
        // Its client is gone after a sync: skip it and clean up quietly.
        unawaited(_aliases.forget(normalized));
      } else {
        ranked.add(ClientCandidate(
            client: client, score: 1, kind: ClientMatchKind.alias));
        seen.add(aliasId);
        kind = ClientMatchKind.alias;
      }
    }

    // 2. Normalized exact name.
    for (final c in index.clients) {
      if (c.normalized != normalized || seen.contains(c.id)) continue;
      final client = byId[c.id];
      if (client == null) continue;
      ranked.add(ClientCandidate(
          client: client, score: 1, kind: ClientMatchKind.exact));
      seen.add(c.id);
      if (kind == ClientMatchKind.fuzzy) kind = ClientMatchKind.exact;
    }

    // 3. Fuzzy score over the clients sharing a token.
    final scored = <ClientCandidate>[];
    for (final c in index.candidatesFor(tokens)) {
      if (seen.contains(c.id)) continue;
      final client = byId[c.id];
      if (client == null) continue;
      scored.add(ClientCandidate(
        client: client,
        score: score(tokens, key, scannedAddress, c, index),
        kind: ClientMatchKind.fuzzy,
      ));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    ranked.addAll(scored);

    final top = ranked.take(ClientMatchResult.maxCandidates).toList();
    if (top.isNotEmpty && top.first.kind == ClientMatchKind.fuzzy) {
      final runnerUp = top.length > 1 ? top[1].score : 0.0;
      final best = top.first;
      top[0] = ClientCandidate(
        client: best.client,
        score: best.score,
        kind: best.kind,
        clearLead: best.score - runnerUp >= ClientMatchResult.strongLead,
      );
    }
    if (top.isEmpty) {
      logDebug('[OneScan] client: no candidate for "$ocrName"');
      return ClientMatchResult(kind: ClientMatchKind.none, ocrName: ocrName);
    }
    final second = top.length > 1 ? top[1].score.toStringAsFixed(2) : '-';
    logDebug('[OneScan] client matched via ${kind.name} '
        '${top.first.score.toStringAsFixed(2)} (2nd $second) '
        '→ ACCMID=${top.first.client.id}');
    return ClientMatchResult(kind: kind, ocrName: ocrName, candidates: top);
  }

  /// `0.60 · word overlap + 0.20 · Jaro-Winkler + 0.20 · address overlap`.
  /// When either side has no address, the name alone (`0.75 · word overlap
  /// + 0.25 · Jaro-Winkler`), so a missing address no longer caps the score.
  ///
  /// Both overlaps weigh each word by how rare it is among the clients
  /// ([ClientTokenIndex.nameWeight]). With every word counted once, and
  /// whole-name likeness at 0.35, "Hospital", "Medical" and "Center" (in
  /// hundreds of names) made wrong clients look close: device scans of
  /// 2026-10-21 topped out at 0.20–0.64 with the runner-up 0.02 behind.
  /// Word overlap already forgives one-letter OCR slips, so Jaro-Winkler
  /// weighs less than in plan §4.4 (0.45 / 0.35 / 0.20).
  @visibleForTesting
  static double score(
    List<String> tokens,
    String key,
    List<String> scannedAddress,
    IndexedClient client,
    ClientTokenIndex index,
  ) {
    final words = BStringSimilarity.weightedTokenSetRatio(
        tokens, client.tokens, index.nameWeight);
    final likeness = BStringSimilarity.jaroWinkler(key, client.key);
    if (scannedAddress.isEmpty || client.addressTokens.isEmpty) {
      return 0.75 * words + 0.25 * likeness;
    }
    final address = BStringSimilarity.weightedTokenSetRatio(
        scannedAddress, client.addressTokens, index.addressWeight);
    return 0.60 * words + 0.20 * likeness + 0.20 * address;
  }
}
