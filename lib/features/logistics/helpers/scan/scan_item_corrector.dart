import 'dart:math' as math;

import 'package:mdmpi_mobile_app/base/utils/b_string_similarity.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scan_vocab_entry.dart';

/// The words, units and item codes of the known items, ready for lookups.
class ScanVocabulary {
  ScanVocabulary(Iterable<ScanVocabEntry> entries) {
    final displayUses = <String, int>{};
    for (final e in entries) {
      final code = e.itemCode.trim().toUpperCase();
      if (code.isNotEmpty &&
          (byCode[code] == null || byCode[code]!.uses < e.uses)) {
        byCode[code] = e;
      }
      for (final m in _token.allMatches(e.description)) {
        final word = m.group(0)!;
        if (word.length < 2 || !_letter.hasMatch(word)) continue;
        final lower = word.toLowerCase();
        words[lower] = (words[lower] ?? 0) + e.uses;
        final key = '$lower|$word';
        displayUses[key] = (displayUses[key] ?? 0) + e.uses;
        if ((displayUses['$lower|${display[lower]}'] ?? 0) < displayUses[key]!) {
          display[lower] = word;
        }
      }
      final unit = e.unit.trim();
      if (unit.isNotEmpty) {
        units[unit.toLowerCase()] = (units[unit.toLowerCase()] ?? 0) + e.uses;
        unitDisplay.putIfAbsent(unit.toLowerCase(), () => unit);
      }
    }
  }

  static final RegExp _token = RegExp(r'[A-Za-z0-9]+');
  static final RegExp _letter = RegExp('[A-Za-z]');

  /// Lower-case word → how many item uses it appears in.
  final Map<String, int> words = {};

  /// Lower-case word → its most used spelling (`dxh` → `DxH`).
  final Map<String, String> display = {};

  final Map<String, int> units = {};
  final Map<String, String> unitDisplay = {};

  /// Upper-case item code → its most used item.
  final Map<String, ScanVocabEntry> byCode = {};

  bool get isEmpty => words.isEmpty && byCode.isEmpty;
}

/// The result of one correction pass.
class ScanItemCorrection {
  const ScanItemCorrection({
    required this.reading,
    required this.changed,
    required this.unknownCodes,
    required this.unknownWords,
  });

  final ItemTableReading reading;

  /// How many items had their description or unit changed.
  final int changed;

  /// Item codes the vocabulary does not know, upper case.
  final Set<String> unknownCodes;

  /// Spellings worth asking the server for: unknown words and their
  /// look-alike variants, lower case.
  final Set<String> unknownWords;

  bool get hasUnknowns => unknownCodes.isNotEmpty || unknownWords.isNotEmpty;
}

/// Corrects scanned item descriptions and units against known items
/// ([ScanVocabulary]): the description saved before for the same item code,
/// else word by word, a word OCR could have misread (`B0ttle`, `Clcaner`)
/// replaced by the known word it is closest to. Codes and quantities are
/// never changed. Pure, so it is tested with hand-made vocabularies.
class ScanItemCorrector {
  ScanItemCorrector._();

  /// Characters OCR mixes up, both ways.
  static const Map<String, List<String>> lookAlikes = {
    '0': ['o'], 'o': ['0'],
    '1': ['l', 'i'], 'l': ['1', 'i'], 'i': ['l', '1'],
    '5': ['s'], 's': ['5'],
    '8': ['b'], 'b': ['8'],
    '6': ['g'], 'g': ['6'],
    '2': ['z'], 'z': ['2'],
    'e': ['c'], 'c': ['e'],
  };

  /// Letter groups OCR merges or splits.
  static const List<(String, String)> lookAlikeGroups = [
    ('rn', 'm'), ('m', 'rn'), ('cl', 'd'), ('d', 'cl'), ('vv', 'w'), ('w', 'vv'),
  ];

  /// How close a read description must be to the one saved for its item code
  /// to take that one (1 − edit distance / longer length).
  static const double sameItemSimilarity = 0.75;

  static const int maxVariants = 256;
  static final RegExp _token = RegExp(r'[A-Za-z0-9]+');
  static final RegExp _letter = RegExp('[A-Za-z]');
  static final RegExp _code = RegExp(r'^[A-Z0-9-]{2,40}$');

  static ScanItemCorrection correct(
      ItemTableReading reading, ScanVocabulary vocab) {
    final unknownCodes = <String>{};
    final unknownWords = <String>{};
    var changed = 0;
    final items = <InventoryItemModel>[];
    for (final item in reading.items) {
      final fixed = _correctItem(item, vocab, unknownCodes, unknownWords);
      if (fixed.description != item.description || fixed.unit != item.unit) {
        changed++;
      }
      items.add(fixed);
    }
    return ScanItemCorrection(
      reading: changed == 0 ? reading : reading.withItems(items),
      changed: changed,
      unknownCodes: unknownCodes,
      unknownWords: unknownWords,
    );
  }

  static InventoryItemModel _correctItem(
    InventoryItemModel item,
    ScanVocabulary vocab,
    Set<String> unknownCodes,
    Set<String> unknownWords,
  ) {
    final code = item.itemCode.trim().toUpperCase();
    final known = code.isEmpty ? null : vocab.byCode[code];
    if (code.isNotEmpty && known == null && _code.hasMatch(code)) {
      unknownCodes.add(code);
    }
    if (known != null &&
        (item.description.trim().isEmpty ||
            similarity(item.description, known.description) >=
                sameItemSimilarity)) {
      return item.copyWith(
        description: known.description,
        unit: item.unit.trim().isEmpty ? known.unit : _correctUnit(item.unit, vocab),
      );
    }

    final description = item.description.replaceAllMapped(_token, (m) {
      final word = m.group(0)!;
      final fixed = correctWord(word, vocab);
      if (fixed == null) unknownWords.addAll(queryTerms(word));
      return fixed ?? word;
    });
    return item.copyWith(
      description: description,
      unit: _correctUnit(item.unit, vocab),
    );
  }

  /// [word] as a known word, or null when it is not known and nothing known
  /// is close enough. Numbers and short tokens come back as they are.
  static String? correctWord(String word, ScanVocabulary vocab) {
    if (!_letter.hasMatch(word) || word.length < 3) return word;
    final lower = word.toLowerCase();
    if (vocab.words.containsKey(lower)) return word;

    String? best;
    for (final v in variants(lower)) {
      if ((vocab.words[v] ?? 0) > (vocab.words[best] ?? 0)) best = v;
    }
    best ??= _oneEditAway(lower, vocab);
    if (best == null) return null;
    return _inCaseOf(word, best, vocab.display[best] ?? best);
  }

  /// The single known word one edit from [lower], for words of six letters
  /// or more, or a clear favourite (three times the uses of the next).
  static String? _oneEditAway(String lower, ScanVocabulary vocab) {
    if (lower.length < 6) return null;
    final close = [
      for (final w in vocab.words.keys)
        if ((w.length - lower.length).abs() <= 1 &&
            BStringSimilarity.levenshtein(w, lower) == 1)
          w,
    ]..sort((a, b) => vocab.words[b]!.compareTo(vocab.words[a]!));
    if (close.isEmpty) return null;
    if (close.length == 1 ||
        vocab.words[close[0]]! >= 3 * vocab.words[close[1]]!) {
      return close.first;
    }
    return null;
  }

  /// A unit is a word from the known units: one inside the cell is taken
  /// alone (`1.00 BOX` → `BOX`), else a look-alike of one (`8OX` → `BOX`).
  static String _correctUnit(String unit, ScanVocabulary vocab) {
    final lower = unit.trim().toLowerCase();
    if (lower.isEmpty || vocab.units.containsKey(lower)) return unit;
    for (final word in lower.split(RegExp('[^a-z]+'))) {
      if (vocab.units.containsKey(word)) return vocab.unitDisplay[word]!;
    }
    String? best;
    for (final v in variants(lower)) {
      if ((vocab.units[v] ?? 0) > (vocab.units[best] ?? 0)) best = v;
    }
    return best == null ? unit : vocab.unitDisplay[best]!;
  }

  /// The spellings [lower] could be with one or two OCR look-alikes undone
  /// (one group swap such as `rn` → `m`), [lower] itself excluded, at most
  /// [maxVariants].
  static Set<String> variants(String lower) {
    final singles = <String>{};
    for (var i = 0; i < lower.length; i++) {
      for (final o in lookAlikes[lower[i]] ?? const <String>[]) {
        singles.add(lower.replaceRange(i, i + 1, o));
      }
    }
    for (final (from, to) in lookAlikeGroups) {
      for (var at = lower.indexOf(from); at >= 0; at = lower.indexOf(from, at + 1)) {
        singles.add(lower.replaceRange(at, at + from.length, to));
      }
    }
    final out = <String>{...singles};
    // Two swaps: each single again, character swaps only.
    for (final s in singles) {
      if (s.length != lower.length) continue;
      for (var i = 0; i < s.length && out.length < maxVariants; i++) {
        if (s[i] != lower[i]) continue;
        for (final o in lookAlikes[s[i]] ?? const <String>[]) {
          out.add(s.replaceRange(i, i + 1, o));
        }
      }
    }
    return out..remove(lower);
  }

  /// What to ask the server for an unknown [word]: the word and its
  /// letters-only variants (digits there are misread letters), lower case.
  static List<String> queryTerms(String word) {
    if (!_letter.hasMatch(word) || word.length < 3) return const [];
    final lower = word.toLowerCase();
    final lettersOnly = variants(lower)
        .where((v) => !RegExp(r'\d').hasMatch(v))
        .take(3);
    return [lower, ...lettersOnly];
  }

  /// 1 − edit distance / longer length, on upper case with spaces collapsed.
  static double similarity(String a, String b) {
    String norm(String s) =>
        s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    final x = norm(a);
    final y = norm(b);
    final longer = math.max(x.length, y.length);
    if (longer == 0) return 1;
    return 1 - BStringSimilarity.levenshtein(x, y) / longer;
  }

  /// [lower] written the way [read] was: all capitals, capitalised, or as
  /// the vocabulary usually spells it ([display]).
  static String _inCaseOf(String read, String lower, String display) {
    final letters = read.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters.isNotEmpty && letters == letters.toUpperCase() && letters.length > 1) {
      return lower.toUpperCase();
    }
    if (letters.isNotEmpty && letters == letters.toLowerCase()) {
      return display == display.toLowerCase() ? lower : display;
    }
    final rest = letters.substring(1);
    if (letters[0] == letters[0].toUpperCase() && rest == rest.toLowerCase()) {
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
    return display;
  }
}
