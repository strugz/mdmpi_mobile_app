import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/base/utils/b_string_similarity.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_rows.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';

/// Reads the item table of a scanned delivery document from the phone's own
/// text recognition, line by line with positions (Standard Delivery
/// one-scan, plan §4.5). No Gemini, no network.
///
/// Finds the row of column titles, takes the columns from where those titles
/// sit, and turns each row below into an [InventoryItemModel]. Pure, so it is
/// tested with hand-made lines.
class ItemTableParser {
  ItemTableParser._();

  /// Column titles seen on the samples (plan §1), longest first so
  /// `Unit Price` is never read as `Unit` and `Serial / Part No.` never as
  /// `Part No.`.
  static final List<(_Col, RegExp)> _titles = [
    for (final (col, pattern) in [
      (_Col.ignored, r'unit\s*price'),
      (_Col.ignored, r'price'),
      (_Col.ignored, r'from\s*warehouse'),
      (_Col.ignored, r'expiry\s*date'),
      (_Col.ignored, r'taken\s*from'),
      (_Col.ignored, r'gl\s*account'),
      (_Col.ignored, r'account\s*name'),
      (_Col.partNo, r'serial\s*/\s*part\s*no\.?'),
      (_Col.partNo, r'tag\s*/\s*part\s*no\.?'),
      (_Col.serialNo, r'lot\s*/\s*serial\s*no\.?'),
      (_Col.serialNo, r'serial\s*/\s*lot\s*no\.?'),
      // Reagents Issue Slip: the row number column, kept out of Part No.
      (_Col.ignored, r'[il1]tem\s*no\.?'),
      (_Col.ignored, r'expiry'),
      (_Col.description, r'[il1]tem\s*description'),
      (_Col.itemCode, r'[il1]tem\s*code'),
      (_Col.ptn, r'property\s*tag'),
      (_Col.partNo, r'part\s*no\.?'),
      (_Col.serialNo, r'serial\s*no\.?'),
      (_Col.description, r'description'),
      (_Col.ignored, r'warehouse'),
      (_Col.ignored, r'total'),
      (_Col.ignored, r'amoun\w*'),
      (_Col.ignored, r'remarks?'),
      (_Col.qty, r'quantity'),
      (_Col.qty, r'[qo0c]ty'),
      (_Col.ptn, r'ptn'),
      (_Col.unit, r'uom'),
      (_Col.unit, r'um'),
      (_Col.unit, r'un[il1]t'),
    ])
      (col, RegExp('(?<![A-Za-z])$pattern(?![A-Za-z])', caseSensitive: false)),
  ];

  /// Lines that end the table body. Matched as prefixes: a signature across
  /// "Comments:" is read as "Commenta:" (IT sample, device run 2026-10-15),
  /// and the grey bar printed before "Comments:" on the ITR is read as "|".
  static final RegExp _bodyEnd = RegExp(
    r'^\s*[|!\[\]]?\s*(comment|remark|total\b|prepared|received|released|approved|'
    r'requested\s*by|taken\s*by|signature|distribution|note\b)',
    caseSensitive: false,
  );

  /// The sub-header under an item on a Sales Invoice:
  /// "Batch/Serial #   Quantity   Expiry Date". OCR misspells "Serial"
  /// (`Seral`, `Serlal`: capture of 2026-10-21).
  static final RegExp _batchHeader =
      RegExp(r'batch\s*/?\s*s[ea]?r[a-z1|]*\s*#?', caseSensitive: false);

  /// A date, allowing the OCR slips seen on captures (`D8/06/2027`).
  static final RegExp _date = RegExp(
      r'(?<![A-Za-z0-9])[0-9ODQIl]{1,2}/[0-9ODQIl]{1,2}/[0-9ODQIl]{2,4}(?![A-Za-z0-9])');

  static String _fixDate(String raw) => raw
      .replaceAll(RegExp(r'[ODQ]'), '0')
      .replaceAll(RegExp(r'[Il]'), '1');
  static final RegExp _number = RegExp(r'^\d{1,6}(?:[.,]\d{1,3})?$');

  /// A gap this many line heights below the last item ends the table:
  /// whatever follows (comments, footers) is not an item, labelled or not.
  static const double _tableEndGap = 4;

  /// "… 1.00 PIECE" at the end of a description that ran into the quantity
  /// and unit columns because their titles were not read.
  static final RegExp _trailingQtyUnit = RegExp(
    r'^(.*\S)\s+(\d+(?:[.,]\d+)?)\s+(PIECES?|PCS?|UNITS?|SETS?|BOX(?:ES)?|EA|LOTS?|'
    r'KITS?|BOTTLES?|BTLS?|VIALS?|PACKS?|ROLLS?|PAIRS?)$',
    caseSensitive: false,
  );

  static ItemTableReading parse(List<OcrLine> lines) {
    final sorted = BOcrOrientation.deskew(lines).where((l) => l.text.trim().isNotEmpty).toList()
      ..sort((a, b) => a.box.top.compareTo(b.box.top));
    if (sorted.isEmpty) return ItemTableReading.none;

    final rows = OcrRows.group(sorted);

    // The header: the row with the most titles, at least two, one of them
    // a description column.
    List<_Title>? header;
    var headerRow = -1;
    for (var i = 0; i < rows.length; i++) {
      final titles = [for (final l in rows[i]) ..._titlesIn(l)];
      if (titles.length < 2) continue;
      if (!titles.any((t) => t.col == _Col.description)) continue;
      if (header == null || titles.length > header.length) {
        header = titles;
        headerRow = i;
      }
    }
    if (header == null) return ItemTableReading.none;

    header.sort((a, b) => a.left.compareTo(b.left));
    final columns = _columns(header);
    // Every item on a table with an Item Code column has a code, so a line
    // without one continues the item above, whatever else lands in its row,
    // and across a wider gap (ITR device runs 2026-10-15: a wrapped line OCR
    // missed, and the item row's prices read on the tilted wrap line).
    final byCode = header.any((t) => t.col == _Col.itemCode);
    final wrapReach = byCode ? 3.0 : 1.0;
    final headerBottom = rows[headerRow].map((l) => l.box.bottom).reduce(math.max);

    final items = <InventoryItemModel>[];
    final unsure = <int>{};
    final tableTexts = <String>[];
    final dropped = <String>[];
    final collected = <_Row>[];
    _Row? last;
    double? lastBottom;

    // Batch sub-rows (Sales Invoice): the same rules as Add Item. They belong
    // to the item above, "Quantity" is the batch quantity, the expiry stays as
    // printed, and a batch serial never becomes the item's Serial No.
    //
    // Handled line by line, not row by row: on a hand-held photo the batch
    // header or a batch line often lands in the same row as an item, and
    // taking the whole row as a batch lost that item (device run 2026-10-15).
    final batchArea = _batchArea(sorted.where((l) => l.box.top >= headerBottom));
    // A batch row right under its titles may have no expiry date (capture of
    // 2026-10-21: "2617  2,00"), so the row after the titles is a batch even
    // without one.
    var batchTitled = false;

    for (final fullRow in rows.skip(headerRow + 1)) {
      if (fullRow.first.box.top < headerBottom) continue;
      if (_bodyEnd.hasMatch(fullRow.first.text)) break;

      var row = fullRow;
      if (batchArea != null) {
        final headerParts =
            row.where((l) => _isBatchHeaderPart(l, batchArea)).toList();
        // Values read on the same line as the titles.
        for (final l in headerParts) {
          final batch = _batchAfterTitles(l.text);
          if (last == null || batch == null) continue;
          last.batches.add(batch.$1);
          if (!batch.$2) last.unsure = true;
        }
        if (headerParts.isNotEmpty) batchTitled = true;
        var batchParts = <OcrLine>[];
        final dated =
            row.any((l) => batchArea.contains(l) && _date.hasMatch(l.text));
        if (last != null && (dated || batchTitled)) {
          batchParts = row
              .where((l) =>
                  !headerParts.contains(l) &&
                  batchArea.contains(l) &&
                  _isBatchToken(l.text) &&
                  // An item code is never part of a batch.
                  _columnFor(l.box.center.dx, columns) != _Col.itemCode)
              .toList()
            ..sort((a, b) => a.box.left.compareTo(b.box.left));
          final batch = _batch(batchParts.map((l) => l.text.trim()).join(' '),
              dateRequired: !batchTitled);
          if (batch == null) {
            batchParts = [];
          } else {
            last.batches.add(batch.$1);
            if (!batch.$2) last.unsure = true;
            batchTitled = false;
          }
        }
        if (headerParts.isNotEmpty || batchParts.isNotEmpty) {
          for (final l in [...headerParts, ...batchParts]) {
            tableTexts.add(l.text);
          }
          lastBottom = math.max(lastBottom ?? 0,
              [...headerParts, ...batchParts].map((l) => l.box.bottom).reduce(math.max));
          row = [
            for (final l in row)
              if (!headerParts.contains(l) && !batchParts.contains(l)) l,
          ];
          if (row.isEmpty) continue;
        }
      }

      final cells = <_Col, List<String>>{};
      var straddled = false;
      for (final line in row) {
        tableTexts.add(line.text);
        final hit = columns.where((c) => _contains(line.box, c.center)).toList();
        if (hit.length > 1) {
          straddled = true;
          for (final (col, word) in _splitByColumns(line, columns)) {
            cells.putIfAbsent(col, () => []).add(word);
          }
        } else {
          final col = _columnFor(line.box.center.dx, columns);
          cells.putIfAbsent(col, () => []).add(line.text.trim());
        }
      }

      String cell(_Col c) => (cells[c] ?? const []).join(' ').trim();
      final description = cell(_Col.description);
      final rowTop = row.map((l) => l.box.top).reduce(math.min);
      final rowBottom = row.map((l) => l.box.bottom).reduce(math.max);
      final height = row.map((l) => l.box.height).reduce(math.max);
      final others = [
        _Col.qty,
        _Col.unit,
        _Col.itemCode,
        _Col.partNo,
        _Col.serialNo,
        _Col.ptn,
      ].where((c) => cell(c).isNotEmpty);

      if (lastBottom != null && rowTop - lastBottom > _tableEndGap * height) {
        // Far below the last item: the table has ended.
        if (description.isNotEmpty) dropped.add(description);
        break;
      }

      if (description.isEmpty) continue; // sub-header, empty ruled row, notes

      // A number in another column (GL account, amount, warehouse code) starts
      // a new row even when the table has no quantity or code column (the
      // Delivery Receipt). Wrapped text there ("VATable") has no digit.
      final newRowSignal = RegExp(r'\d').hasMatch(cell(_Col.ignored));
      final continues = byCode
          ? cell(_Col.itemCode).isEmpty
          : others.isEmpty && !newRowSignal;
      if (continues &&
          last != null &&
          rowTop - lastBottom! <= wrapReach * height) {
        // The item above wraps onto this line.
        last.description = '${last.description} $description';
        lastBottom = rowBottom;
        continue;
      }

      var desc = description;
      var qtyText = cell(_Col.qty);
      var unit = cell(_Col.unit);
      var ranOn = false;
      if (qtyText.isEmpty && unit.isEmpty) {
        final m = _trailingQtyUnit.firstMatch(desc);
        if (m != null) {
          desc = m.group(1)!;
          qtyText = m.group(2)!;
          unit = m.group(3)!;
          ranOn = true;
        }
      }

      final (qty, qtyRead) = _quantity(qtyText);
      last = _Row(
        description: desc,
        qty: qty,
        unit: unit,
        itemCode: cell(_Col.itemCode),
        partNo: cell(_Col.partNo),
        serialNo: cell(_Col.serialNo),
        ptn: cell(_Col.ptn),
        unsure: !qtyRead || straddled || ranOn || _maybeLostDecimal(qtyText),
      );
      collected.add(last);
      lastBottom = rowBottom;
    }

    final codes = [for (final r in collected) _cleanCode(r.itemCode)];
    for (final (i, r) in collected.indexed) {
      _cutBatchTail(r);
      if (r.unsure ||
          r.description.length < 3 ||
          _codeLooksMisread(codes[i], codes)) {
        unsure.add(items.length);
      }
      // A single batch whose quantity was not read holds the whole item
      // quantity. The item stays flagged for the user to check.
      final batches = r.batches.length == 1 && r.batches.single.batchQuantity == 0
          ? [
              InventoryBatchModel(
                batchSerial: r.batches.single.batchSerial,
                batchQuantity: r.qty,
                expiryDate: r.batches.single.expiryDate,
              ),
            ]
          : r.batches;
      items.add(InventoryItemModel(
        itemCode: codes[i],
        description: r.description,
        qty: r.qty,
        unit: _cleanUnit(r.unit),
        partNo: r.partNo,
        serialNo: r.serialNo,
        ptn: r.ptn,
        batches: List.unmodifiable(batches),
      ));
    }

    return ItemTableReading(
      headerFound: true,
      items: items,
      unsure: unsure,
      tableTexts: tableTexts,
      dropped: dropped,
    );
  }

  /// The titles a header line holds, each with its estimated horizontal
  /// span. A line counts only when it is nothing but titles (fewer than
  /// three other letters), so a body row holding the word "Unit" is not
  /// mistaken for a header.
  static List<_Title> _titlesIn(OcrLine line) {
    final text = line.text;
    // A whole line close to one title ("Unit Prise") is that title, before
    // a short exact title inside it ("Unit") takes part of it.
    final whole = _closestTitle(_plainTitle(text));
    if (whole != null) {
      return [_Title(whole, line.box.left, line.box.right)];
    }
    final found = <_Title>[];
    final taken = List<bool>.filled(text.length, false);
    for (final (col, re) in _titles) {
      for (final m in re.allMatches(text)) {
        if (taken.sublist(m.start, m.end).any((t) => t)) continue;
        for (var i = m.start; i < m.end; i++) {
          taken[i] = true;
        }
        found.add(_Title(col, _xAt(line, m.start), _xAt(line, m.end)));
      }
    }
    _closeTitlesIn(line, taken, found);
    var leftover = 0;
    var letters = 0;
    for (var i = 0; i < text.length; i++) {
      if (!RegExp(r'[A-Za-z]').hasMatch(text[i])) continue;
      letters++;
      if (!taken[i]) leftover++;
    }
    return leftover < math.max(3, 0.3 * letters) ? found : const [];
  }

  /// Titles the patterns above miss because OCR misspelled or split them
  /// (`Descriptian`, `Descripti on`, `Quantlty`), on every form: a word, or
  /// two words read together, within one edit of a known title (two for
  /// titles of eight letters or more). Short titles (`Qty`, `Unit`, `UOM`)
  /// stay exact: one edit there matches almost anything.
  static final List<(_Col, String)> _closeTitles = [
    (_Col.description, 'description'),
    (_Col.description, 'itemdescription'),
    (_Col.itemCode, 'itemcode'),
    (_Col.qty, 'quantity'),
    (_Col.partNo, 'partno'),
    (_Col.serialNo, 'serialno'),
    (_Col.ptn, 'propertytag'),
    (_Col.ignored, 'unitprice'),
    (_Col.ignored, 'warehouse'),
    (_Col.ignored, 'fromwarehouse'),
    (_Col.ignored, 'expirydate'),
    (_Col.ignored, 'amount'),
    (_Col.ignored, 'remarks'),
    (_Col.ignored, 'glaccount'),
    (_Col.ignored, 'accountname'),
  ];

  static void _closeTitlesIn(OcrLine line, List<bool> taken, List<_Title> found) {
    final text = line.text;
    final words = [
      for (final m in RegExp(r'\S+').allMatches(text))
        if (!taken.sublist(m.start, m.end).any((t) => t)) m,
    ];
    void take(int start, int end, _Col col) {
      for (var i = start; i < end; i++) {
        taken[i] = true;
      }
      found.add(_Title(col, _xAt(line, start), _xAt(line, end)));
    }

    var i = 0;
    while (i < words.length) {
      final w = words[i];
      // Two words first: "Descripti on" is one title split by OCR.
      if (i + 1 < words.length && words[i + 1].start == w.end + 1) {
        final next = words[i + 1];
        final col = _closestTitle(_plainTitle('${w.group(0)}${next.group(0)}'));
        if (col != null) {
          take(w.start, next.end, col);
          i += 2;
          continue;
        }
      }
      final col = _closestTitle(_plainTitle(w.group(0)!));
      if (col != null) take(w.start, w.end, col);
      i++;
    }
  }

  /// Lower case letters only, OCR digits read as the letters they replace
  /// (`Descr1ption`).
  static String _plainTitle(String s) => s
      .toLowerCase()
      .replaceAll('0', 'o')
      .replaceAll('1', 'i')
      .replaceAll(RegExp('[^a-z]'), '');

  /// The column of the title [word] is close to, or null.
  static _Col? _closestTitle(String word) {
    if (word.length < 5) return null;
    for (final (col, title) in _closeTitles) {
      final allowed = title.length >= 8 ? 2 : 1;
      if ((word.length - title.length).abs() > allowed) continue;
      if (BStringSimilarity.levenshtein(word, title) <= allowed) return col;
    }
    return null;
  }

  /// Horizontal position of character [index] in [line], assuming evenly
  /// spaced characters.
  static double _xAt(OcrLine line, int index) {
    final n = line.text.length;
    if (n == 0) return line.box.left;
    return line.box.left + line.box.width * index / n;
  }

  /// Each title owns the span up to the boundary with its neighbour: halfway
  /// between two titles, except left of the description column, whose text
  /// starts well before its centred title. There the boundary sits a fifth
  /// of the gap from the code column's title (IT sample: "RBC Counting
  /// Chamber" starts far left of "Description").
  static List<_Column> _columns(List<_Title> header) {
    double boundary(_Title a, _Title b) {
      final gap = b.left - a.right;
      if (b.col == _Col.description) return a.right + 0.2 * gap;
      return (a.right + b.left) / 2;
    }

    final out = <_Column>[];
    for (var i = 0; i < header.length; i++) {
      final t = header[i];
      final left =
          i == 0 ? double.negativeInfinity : boundary(header[i - 1], t);
      final right = i == header.length - 1
          ? double.infinity
          : boundary(t, header[i + 1]);
      out.add(_Column(t.col, left, right, (t.left + t.right) / 2));
    }
    return out;
  }

  static bool _contains(Rect box, double x) => x >= box.left && x <= box.right;

  static _Col _columnFor(double x, List<_Column> columns) => columns
      .firstWhere((c) => x >= c.left && x < c.right, orElse: () => columns.last)
      .col;

  /// Splits a line that runs across several columns into words, each placed
  /// by its estimated position.
  static List<(_Col, String)> _splitByColumns(
      OcrLine line, List<_Column> columns) {
    final out = <(_Col, String)>[];
    for (final m in RegExp(r'\S+').allMatches(line.text)) {
      final x = (_xAt(line, m.start) + _xAt(line, m.end)) / 2;
      out.add((_columnFor(x, columns), m.group(0)!));
    }
    return out;
  }

  /// Where batch sub-rows sit across the page, from the "Batch/Serial #"
  /// titles: from a little left of them (the serials start left of their
  /// centred title) to just past "Expiry Date". Null when the document has no
  /// batch sub-rows, so dates elsewhere are never read as batches.
  static _BatchArea? _batchArea(Iterable<OcrLine> body) {
    final titles = body
        .where((l) => _batchHeader.matchAsPrefix(l.text.trim()) != null)
        .toList();
    if (titles.isEmpty) return null;
    final h = titles.map((l) => l.box.height).reduce(math.max);
    final left = titles.map((l) => l.box.left).reduce(math.min) - 6 * h;
    var right = titles.map((l) => l.box.right).reduce(math.max);
    for (final l in body) {
      final text = l.text.trim();
      // "Quantity" only beside a batch title: elsewhere it may be any column.
      final besideTitle = _quantityTitle.hasMatch(text) &&
          titles.any((t) => (t.box.center.dy - l.box.center.dy).abs() < h);
      if (_expiryTitle.hasMatch(text) || besideTitle) {
        right = math.max(right, l.box.right);
      }
    }
    return _BatchArea(left, right + 2 * h);
  }

  static final RegExp _expiryTitle =
      RegExp(r'^expiry\s*date$', caseSensitive: false);
  /// "Quantity", also as OCR misspells it (`Quantty`).
  static final RegExp _quantityTitle =
      RegExp(r'^qu?an?t[a-z1|]{0,4}$', caseSensitive: false);

  /// "Batch/Serial #", or the "Quantity" / "Expiry Date" beside it. A line
  /// that only ends in the titles is an item's description, cut later.
  static bool _isBatchHeaderPart(OcrLine line, _BatchArea area) {
    final text = line.text.trim();
    if (_batchHeader.matchAsPrefix(text) != null) return true;
    return area.contains(line) &&
        (_quantityTitle.hasMatch(text) || _expiryTitle.hasMatch(text));
  }

  /// A line that can be part of a batch: a date, or one serial / number
  /// token. A description ("DXH 500 Lyse, 500mL") has spaces and is not.
  static bool _isBatchToken(String text) {
    final t = text.trim();
    if (_date.hasMatch(t)) return true;
    // ".00" too: OCR drops a leading digit at times (capture of 2026-10-15).
    return RegExp(r'^[A-Za-z0-9.-]*\d[A-Za-z0-9./,-]*$').hasMatch(t);
  }

  /// One batch from a row such as "0179170   6.00   07/18/2027": the dated
  /// token is the expiry, the first other token with a digit the serial, and
  /// the next plain number the quantity. Null when the row has no date (not
  /// a batch row). The flag is false when the quantity was not read.
  ///
  /// With [dateRequired] false a row without a date is read too, the expiry
  /// left empty.
  static (InventoryBatchModel, bool)? _batch(String text,
      {bool dateRequired = true}) {
    final date = _date.firstMatch(text);
    if (date == null && dateRequired) return null;
    final rest = (date == null
            ? text
            : '${text.substring(0, date.start)} ${text.substring(date.end)}')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    String serial = '';
    double? quantity;
    for (final token in rest) {
      if (serial.isEmpty && RegExp(r'\d').hasMatch(token) && !_number.hasMatch(token)) {
        serial = token;
      } else if (serial.isEmpty &&
          _number.hasMatch(token) &&
          !RegExp('[.,]').hasMatch(token)) {
        // An all-digit serial such as 0179170 (no decimal point or comma:
        // `2,00` is a quantity).
        serial = token;
      } else if (quantity == null && _number.hasMatch(token)) {
        quantity = double.tryParse(token.replaceAll(',', '.'));
      }
    }
    if (serial.isEmpty && quantity == null) return null;
    return (
      InventoryBatchModel(
        batchSerial: serial,
        batchQuantity: quantity ?? 0,
        expiryDate: date == null ? '' : _fixDate(date.group(0)!),
      ),
      quantity != null,
    );
  }

  /// The batch read after the titles on one line ("Batch/Seral # Quantty
  /// 2617 2,00"), or null when only titles are there.
  static (InventoryBatchModel, bool)? _batchAfterTitles(String text) {
    final m = _batchHeader.firstMatch(text);
    if (m == null) return null;
    final values = text
        .substring(m.end)
        .split(RegExp(r'\s+'))
        .where((t) =>
            t.isNotEmpty &&
            t != '#' &&
            !_quantityTitle.hasMatch(t) &&
            !RegExp(r'^(expiry|date)$', caseSensitive: false).hasMatch(t))
        .toList();
    if (values.isEmpty || !values.every(_isBatchToken)) return null;
    return _batch(values.join(' '), dateRequired: false);
  }

  /// The batch titles and values glued onto the end of a description
  /// ("… 4x15mL Batch/Seral # Quantty 2617 2,00"; capture of 2026-10-21)
  /// are cut off; the values become the item's batch when it has none.
  static void _cutBatchTail(_Row r) {
    final m = _batchHeader.firstMatch(r.description);
    if (m == null || m.start == 0) return;
    final tail = r.description.substring(m.start);
    r.description = r.description.substring(0, m.start).trim();
    if (r.batches.isNotEmpty) return;
    final batch = _batchAfterTitles(tail);
    if (batch == null) return;
    r.batches.add(batch.$1);
    if (!batch.$2) r.unsure = true;
  }

  /// Codes are plain capitals and digits: an accented letter is the capital
  /// OCR misread (`öSRS116` is `OSRS116`), and a stray mark before the code
  /// is dropped.
  static String _cleanCode(String code) => _cleanUnit(code.replaceAllMapped(
          RegExp('[à-öø-ÿ]'), (m) => m.group(0)!.toUpperCase()))
      .replaceFirst(RegExp(r'^[^A-Za-z0-9]+(?=[A-Za-z0-9])'), '');

  /// Whether [code] looks like another code on the same document with a
  /// letter where that one has a digit, the rest digits: `OSRB116` next to
  /// `OSR6122` (the 6 read as B or S, capture of 2026-10-21). Which digit it
  /// was cannot be told, so the item is only flagged for the user to check.
  static bool _codeLooksMisread(String code, List<String> codes) {
    final m = RegExp(r'^([A-Za-z0-9]*?[A-Za-z])([A-Za-z])(\d+)$').firstMatch(code);
    if (m == null) return false;
    final prefix = m.group(1)!;
    return codes.any((other) =>
        other != code &&
        other.length > prefix.length &&
        other.startsWith(prefix) &&
        RegExp(r'\d').hasMatch(other[prefix.length]));
  }

  /// Accented letters OCR puts into plain capitals (`BÖTTLE`).
  static String _cleanUnit(String unit) => unit
      .replaceAll(RegExp('[ÖÓÒÔ]'), 'O')
      .replaceAll(RegExp('[ÜÚÙ]'), 'U')
      .replaceAll(RegExp('[ÉÈË]'), 'E')
      .replaceAll(RegExp('[İÍÌ]'), 'I');

  /// `100` where the paper likely says `1.00`: OCR often drops the point.
  static bool _maybeLostDecimal(String raw) =>
      RegExp(r'^\s*\d+00\s*$').hasMatch(raw);

  /// The quantity, and whether it was actually read. `1.00` → 1; the OCR
  /// slips `l`, `I`, `|` read as 1 and `O` as 0. Missing or unreadable → 1.
  static (double, bool) _quantity(String raw) {
    final fixed = raw
        .replaceAll(RegExp(r'[lI|]'), '1')
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(',', '');
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(fixed);
    final value = m == null ? null : double.tryParse(m.group(0)!);
    if (value == null || value <= 0) return (1, false);
    return (value, true);
  }
}

class _BatchArea {
  const _BatchArea(this.left, this.right);

  final double left;
  final double right;

  bool contains(OcrLine line) =>
      line.box.center.dx >= left && line.box.center.dx <= right;
}

enum _Col { description, qty, unit, itemCode, partNo, serialNo, ptn, ignored }

class _Title {
  const _Title(this.col, this.left, this.right);

  final _Col col;
  final double left;
  final double right;
}

class _Column {
  const _Column(this.col, this.left, this.right, this.center);

  final _Col col;
  final double left;
  final double right;
  final double center;
}

class _Row {
  _Row({
    required this.description,
    required this.qty,
    required this.unit,
    required this.itemCode,
    required this.partNo,
    required this.serialNo,
    required this.ptn,
    required this.unsure,
  });

  String description;
  final double qty;
  final String unit;
  final String itemCode;
  final String partNo;
  final String serialNo;
  final String ptn;
  bool unsure;

  /// Batch sub-rows (Sales Invoice), in print order.
  final List<InventoryBatchModel> batches = [];
}
