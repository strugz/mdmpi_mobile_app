import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_layout_reader.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';

/// What a scanned voucher said, against one account's invoices.
class VoucherMatchResult {
  const VoucherMatchResult({
    this.matchedIds = const [],
    this.unmatched = const [],
    this.ambiguous = const [],
    this.elsewhere = const [],
  });

  /// Invoice ids found on the voucher, first seen first, each once.
  final List<String> matchedIds;

  /// Number-like text read that is no invoice of this account (or a misread),
  /// for the collector to check against the paper.
  final List<String> unmatched;

  /// Read text that fits more than one invoice; nothing was added for it.
  final List<String> ambiguous;

  /// Invoices of this client the voucher names that are not open in this
  /// engagement (settled, or still in the bucket).
  final List<String> elsewhere;

  bool get isEmpty => matchedIds.isEmpty;
}

/// Finds an account's SI numbers in the text read off a client's voucher
/// (meeting of 2026-10-07, item 2).
///
/// Conservative, because adding the wrong invoice to a collection is worse
/// than missing one the collector can tick by hand: a token is matched only
/// when it equals a known id after [canonical] (no fuzzy matching, which
/// would catch amounts and dates). A few common OCR slips are retried
/// (a space inside a number, O for 0, I or l for 1, S for 5, B for 8).
class VoucherSiMatcher {
  VoucherSiMatcher._();

  /// The comparable form of an id or a token: upper-case, letters and digits
  /// only, and an all-digit value without leading zeros.
  static String canonical(String raw) {
    final s = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s)) {
      final stripped = s.replaceFirst(RegExp(r'^0+'), '');
      return stripped.isEmpty ? '0' : stripped;
    }
    return s;
  }

  static VoucherMatchResult match({
    required String ocrText,
    required Iterable<String> knownIds,
    Iterable<String> ignore = const [],
    Iterable<String> elsewhereIds = const [],
  }) {
    final index = <String, List<String>>{};
    for (final id in knownIds) {
      final key = canonical(id);
      if (key.isEmpty) continue;
      final ids = index.putIfAbsent(key, () => []);
      if (!ids.contains(id)) ids.add(id);
    }
    final elsewhereIndex = <String, String>{
      for (final id in elsewhereIds)
        if (canonical(id) case final key when key.isNotEmpty) key: id,
    };
    final ignored = {for (final i in ignore) canonical(i)}..remove('');

    final matched = <String>[];
    final unmatched = <String>[];
    final ambiguous = <String>[];
    final elsewhere = <String>[];
    final seenUnmatched = <String>{};

    /// The id(s) [token] names, trying its parts, a dropped prefix, then the
    /// OCR slips undone.
    List<String>? lookUp(String token) {
      final fixed = _confusablesFixed(token);
      for (final read in [token, if (fixed != null) fixed]) {
        for (final candidate in _candidates(read)) {
          final hit = index[canonical(candidate)];
          if (hit != null) return hit;
        }
      }
      return null;
    }

    void take(List<String> ids, String token) {
      if (ids.length > 1) {
        if (!ambiguous.contains(token)) ambiguous.add(token);
        return;
      }
      if (!matched.contains(ids.single)) matched.add(ids.single);
    }

    final tokens = _tokens(ocrText);
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final hit = lookUp(token);
      if (hit != null) {
        take(hit, token);
        continue;
      }
      // "7000 13390": a number split by a space, joined only when the join
      // is a known id.
      if (i + 1 < tokens.length &&
          _digitsOnly.hasMatch(token) &&
          _digitsOnly.hasMatch(tokens[i + 1])) {
        final joined = index[canonical(token + tokens[i + 1])];
        if (joined != null) {
          take(joined, '$token ${tokens[i + 1]}');
          i++;
          continue;
        }
      }
      final key = canonical(token);
      final other = elsewhereIndex[key];
      if (other != null) {
        if (!elsewhere.contains(other)) elsewhere.add(other);
        continue;
      }
      if (_reportable(token, key, ignored) && seenUnmatched.add(key)) {
        unmatched.add(token);
      }
    }
    return VoucherMatchResult(
      matchedIds: matched,
      unmatched: unmatched,
      ambiguous: ambiguous,
      elsewhere: elsewhere,
    );
  }

  static final _digitsOnly = RegExp(r'^\d+$');
  static final _money =
      RegExp(r'^[-(]?[₱P]?\d{1,3}(,\d{3})*(\.\d+)?\)?$|^\d+\.\d+$');
  static final _date =
      RegExp(r'^\d{1,4}[/.-]\d{1,2}[/.-]\d{1,4}$|^\d{4}-\d{2}-\d{2}T');

  /// Words of the text, split on spaces and on anything an id never holds,
  /// with stray punctuation trimmed off the ends.
  static List<String> _tokens(String text) => text
      .split(RegExp(r'[^A-Za-z0-9\-#/.,()₱]+'))
      .map((t) => t.replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), ''))
      .where((t) => t.isNotEmpty)
      .toList();

  /// The token, its parts split on - / #, and the token without a leading
  /// alphabetic prefix ("SI-700013390", "INV700013390", "SI#…").
  static Iterable<String> _candidates(String token) sync* {
    yield token;
    final parts = token.split(RegExp(r'[-/#]')).where((p) => p.isNotEmpty);
    if (parts.length > 1) yield* parts;
    final unprefixed = token.replaceFirst(RegExp(r'^[A-Za-z]{1,4}[-#.]?'), '');
    if (unprefixed != token && unprefixed.isNotEmpty) yield unprefixed;
  }

  /// [token] with OCR's letter-for-digit slips undone, when it is mostly a
  /// number already (half its characters or more are digits); null when it
  /// is not, or nothing changed.
  static String? _confusablesFixed(String token) {
    if (token.length < 5) return null;
    final digits = token.split('').where((c) => _digitsOnly.hasMatch(c)).length;
    if (digits / token.length < 0.5) return null;
    final fixed = token
        .replaceAll(RegExp('[Oo]'), '0')
        .replaceAll(RegExp('[Il]'), '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8');
    return fixed == token ? null : fixed;
  }

  /// Whether [token] could be an invoice number at all: at least five
  /// digits, and not an amount or a date.
  static bool isIdLike(String token) =>
      _reportable(token, canonical(token), const {});

  /// The ids in [knownIds] that [token] misses by exactly one character, at
  /// the same length (OCR substitutes far more often than it drops), after
  /// undoing letter-for-digit slips. Five characters at least, so short
  /// numbers never match by accident.
  static List<String> nearIds(String token, Iterable<String> knownIds) {
    final read = canonical(_confusablesFixed(token) ?? token);
    if (read.length < 5) return const [];
    return [
      for (final id in knownIds)
        if (canonical(id) case final k
            when k.length == read.length && _oneApart(k, read))
          id,
    ];
  }

  static bool _oneApart(String a, String b) {
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i] && ++diff > 1) return false;
    }
    return diff == 1;
  }

  /// Worth showing as "read but not found": at least five digits, and not an
  /// amount, a date, or the account's own P.O. / reference.
  static bool _reportable(String token, String key, Set<String> ignored) {
    if (key.replaceAll(RegExp(r'\D'), '').length < 5) return false;
    if (_money.hasMatch(token) && token.contains(RegExp(r'[.,]'))) return false;
    if (_date.hasMatch(token)) return false;
    return !ignored.contains(key);
  }
}

/// Turns what a voucher gave into Scanned Invoices tiles, against one
/// account: its open invoices ([knownIds]), the client's other invoices
/// ([elsewhereIds]) and its P.O.s and references ([ignore]).
class ScannedInvoiceClassifier {
  const ScannedInvoiceClassifier({
    required this.knownIds,
    this.elsewhereIds = const [],
    this.ignore = const [],
  });

  final Iterable<String> knownIds;
  final Iterable<String> elsewhereIds;
  final Iterable<String> ignore;

  VoucherMatchResult _match(String text) => VoucherSiMatcher.match(
      ocrText: text,
      knownIds: knownIds,
      elsewhereIds: elsewhereIds,
      ignore: ignore);

  /// One number labelled as an invoice (by the AI, the page layout, or the
  /// collector typing it): every one becomes a tile. Exact first; failing
  /// that, one digit off a single open invoice is a likely misread.
  ScannedInvoice line(VoucherInvoiceLine line) {
    final r = _match(line.invoiceNo);
    final near =
        r.matchedIds.isEmpty && r.elsewhere.isEmpty && r.ambiguous.isEmpty
            ? VoucherSiMatcher.nearIds(line.invoiceNo, knownIds)
            : const <String>[];
    final (status, id) = r.matchedIds.isNotEmpty
        ? (ScannedInvoiceStatus.matched, r.matchedIds.first)
        : r.elsewhere.isNotEmpty
            ? (ScannedInvoiceStatus.elsewhere, r.elsewhere.first)
            : r.ambiguous.isNotEmpty || near.length > 1
                ? (ScannedInvoiceStatus.ambiguous, null)
                : near.length == 1
                    ? (ScannedInvoiceStatus.likely, near.single)
                    : (ScannedInvoiceStatus.notFound, null);
    return ScannedInvoice(
      read: line.invoiceNo,
      label: line.label,
      amount: line.amount,
      status: status,
      invoiceId: id,
    );
  }

  /// A page read by the phone without the AI, line by line with positions
  /// ([VoucherLayoutReader]): numbers the layout labels as invoices are
  /// matched like the AI's (near misses included); unlabelled ones only
  /// exactly; ones labelled as P.O., check, CV and the like never.
  List<ScannedInvoice> offlineLines(List<OcrLine> lines) {
    final reading = VoucherLayoutReader.read(lines);
    final tiles = <ScannedInvoice>[];
    final seen = <String>{};
    void add(ScannedInvoice t) {
      if (seen.add(t.key)) tiles.add(t.asOffline());
    }

    for (final number in reading.labelled) {
      final tile = line(VoucherInvoiceLine(invoiceNo: number));
      // A date or an amount beside the label is not a missing invoice.
      if (tile.status == ScannedInvoiceStatus.notFound &&
          !VoucherSiMatcher.isIdLike(number)) {
        continue;
      }
      add(tile);
    }
    final rest = ScannedInvoiceClassifier(
      knownIds: knownIds,
      elsewhereIds: elsewhereIds,
      ignore: [...ignore, ...reading.excluded, ...reading.labelled],
    ).offlineText(reading.unlabelled.join('\n'));
    rest.forEach(add);
    return tiles;
  }

  /// Everything the phone read off a page without the AI: only what looks
  /// like one of this client's invoices becomes a tile. With no labels to go
  /// by, a "not found" is shown only for a plain number as long as the
  /// account's invoice numbers (not a voucher no. like 2026-0098, a phone or
  /// an amount).
  List<ScannedInvoice> offlineText(String text) {
    final r = _match(text);
    final lengths = {
      for (final id in knownIds)
        if (RegExp(r'^\d+$').hasMatch(id.trim())) id.trim().length,
    };
    bool invoiceLike(String t) =>
        RegExp(r'^\d+$').hasMatch(t) && lengths.contains(t.length);
    return [
      for (final id in r.matchedIds)
        ScannedInvoice(
            read: id,
            status: ScannedInvoiceStatus.matched,
            invoiceId: id,
            offline: true),
      for (final id in r.elsewhere)
        ScannedInvoice(
            read: id,
            status: ScannedInvoiceStatus.elsewhere,
            invoiceId: id,
            offline: true),
      for (final t in r.ambiguous)
        ScannedInvoice(
            read: t, status: ScannedInvoiceStatus.ambiguous, offline: true),
      for (final t in r.unmatched.where(invoiceLike))
        ScannedInvoice(
            read: t, status: ScannedInvoiceStatus.notFound, offline: true),
    ];
  }
}
