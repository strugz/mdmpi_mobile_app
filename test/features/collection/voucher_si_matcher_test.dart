import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';

/// Reading a client's voucher: which of the account's SIs it lists.

void main() {
  const known = ['700013390', '700013391', '97339', 'AP-1790234393266'];

  VoucherMatchResult m(String text,
          {List<String> ignore = const [],
          List<String> elsewhere = const []}) =>
      VoucherSiMatcher.match(
          ocrText: text,
          knownIds: known,
          ignore: ignore,
          elsewhereIds: elsewhere);

  test('exact ids, first seen first, each once', () {
    final r = m('Payment for 97339 and 700013390\n700013390 again');
    expect(r.matchedIds, ['97339', '700013390']);
    expect(r.unmatched, isEmpty);
  });

  test('prefixes, separators and leading zeros', () {
    expect(m('SI-700013390').matchedIds, ['700013390']);
    expect(m('SI#700013391').matchedIds, ['700013391']);
    expect(m('INV700013390').matchedIds, ['700013390']);
    expect(m('0097339').matchedIds, ['97339']);
    expect(m('ap-1790234393266').matchedIds, ['AP-1790234393266']);
    expect(m('SI 700013390, 700013391.').matchedIds,
        ['700013390', '700013391']);
  });

  test('a number split by a space is joined only into a known id', () {
    expect(m('7000 13390').matchedIds, ['700013390']);
    expect(m('12 34').unmatched, isEmpty, reason: 'too short to report');
  });

  test('OCR letter-for-digit slips', () {
    expect(m('7OOO1339O').matchedIds, ['700013390']);
    expect(m('70001339l').matchedIds, ['700013391']);
  });

  test('read but not found: number-like, not money, dates or the P.O.', () {
    final r = m(
        'SI 700099999 Total 21,048.87 Date 09/15/2026 2026-09-15 '
        'PO 4500012345 qty 12 page 3',
        ignore: ['4500012345']);
    expect(r.matchedIds, isEmpty);
    expect(r.unmatched, ['700099999']);
  });

  test('an invoice of this client not open in the engagement', () {
    final r = m('700013390 700055555', elsewhere: ['700055555']);
    expect(r.matchedIds, ['700013390']);
    expect(r.elsewhere, ['700055555']);
    expect(r.unmatched, isEmpty);
  });

  test('two ids that read the same are not guessed between', () {
    final r = VoucherSiMatcher.match(
        ocrText: '0123', knownIds: const ['123', '0123']);
    expect(r.matchedIds, isEmpty);
    expect(r.ambiguous, ['0123']);
  });

  test('empty or garbage text', () {
    expect(m('').isEmpty, isTrue);
    expect(m('~~ ### !!').unmatched, isEmpty);
  });

  test('canonical form', () {
    expect(VoucherSiMatcher.canonical(' si-00123 '), 'SI00123');
    expect(VoucherSiMatcher.canonical('000'), '0');
    expect(VoucherSiMatcher.canonical('00123'), '123');
  });
}
