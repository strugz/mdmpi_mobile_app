import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';

void main() {
  final extractor = DocumentReferenceExtractor();

  group('DocumentReferenceExtractor', () {
    test('extracts GI No. when value is on an indented next line', () {
      const ocr = 'GI No.:\n        760006528\nReference No.:\nIT750005359';
      expect(extractor.extractPatterns(ocr), contains('GINo.:760006528'));
    });

    test('handles real ML Kit output: dropped I, stray line, misspelling', () {
      const ocr = 'VAT Reg TIN 204-595-997-0\n'
          'Tel # (632) 7751-9999\n'
          'G No.:\n'
          'GO\n'
          '760006528\n'
          'Referance No.:\n'
          'IT750005359\n'
          'Warehou\n'
          'MIN143';
      // Only GI is wanted here; the "Reference No." line is ignored.
      expect(extractor.extractPatterns(ocr), ['GINo.:760006528']);
    });

    test('handles real ML Kit output: GOODS ISSUE header and 6 read as G', () {
      const ocr = 'Tel\n'
          'G No.:\n'
          'GOODS ISS\n'
          '76000G528\n'
          'Referenca No.:\n'
          'IT750005359\n'
          'Wanehouse\n'
          'MIN143\n'
          'ORIGINAL\n'
          'Posting Date\n'
          'O9/07/2026-\n'
          'MIN143';
      expect(extractor.extractPatterns(ocr), ['GINo.:760006528']);
    });

    test('never treats a word as a number when digits are missing', () {
      expect(extractor.extractPatterns('G No.:\nGOODS ISS\nORIGINAL'), isEmpty);
    });

    test('handles real ML Kit output: IT with dropped I and header noise', () {
      expect(
        extractor.extractPatterns(
            'Tel # (632) 7751-\nT No.:\nINVI\n750005359\nTransfer Reques'),
        ['ITNo.:750005359'],
      );
      expect(extractor.extractPatterns('T No.:\nIN\n750005359'),
          ['ITNo.:750005359']);
      expect(extractor.extractPatterns('TNo.:\n750005359\nTransfer Reque'),
          ['ITNo.:750005359']);
      expect(
        extractor.extractPatterns(
            'Tel # (632) 7751-9990\nT No.:\nINVEN\n750005359\nTransfer Request Ne'),
        ['ITNo.:750005359'],
      );
      expect(
        extractor.extractPatterns(
            'Tel # (632) 7751-9999\nT No.:\nINVENTORY TRANSFER\n750005359\nMAINSPA'),
        ['ITNo.:750005359'],
      );
    });

    test('tolerates OCR reading I as l or 1', () {
      expect(extractor.extractPatterns('Gl No.: 760006528'),
          contains('GINo.:760006528'));
      expect(extractor.extractPatterns('G1 No.:760006528'),
          contains('GINo.:760006528'));
      expect(extractor.extractPatterns('lT No.: 123'), contains('ITNo.:123'));
      expect(extractor.extractPatterns('Sl No.: 456'), contains('SINo.:456'));
    });

    test('tolerates "Na." and missing colon', () {
      expect(extractor.extractPatterns('DR Na.: 789'), contains('DRNo.:789'));
      expect(extractor.extractPatterns('DR No 789'), contains('DRNo.:789'));
    });

    test('keeps legacy same-line matches', () {
      expect(extractor.extractPatterns('SI No.: 111'), ['SINo.:111']);
      expect(extractor.extractPatterns('PO No.: PO-2024-01'),
          ['PONo.:PO-2024-01']);
      expect(extractor.extractPatterns('SIS#: 12345'), ['SIS#:12345']);
      expect(extractor.extractPatterns('AB12-34567'), ['AB12-34567']);
    });

    test('returns empty when nothing matches', () {
      expect(extractor.extractPatterns('Warehouse MIN143'), isEmpty);
    });
  });
}
