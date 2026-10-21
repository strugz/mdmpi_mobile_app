import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/b_name_normalizer.dart';
import 'package:mdmpi_mobile_app/base/utils/b_string_similarity.dart';

void main() {
  group('normalize', () {
    test('dotted acronym, abbreviation and case', () {
      expect(
        BNameNormalizer.normalize('U.S. Dept. of Veterans Affairs'),
        'US DEPARTMENT OF VETERANS AFFAIRS',
      );
      expect(
        BNameNormalizer.normalize('U.S. Dept. of Veterans Affairs'),
        BNameNormalizer.normalize('US DEPARTMENT OF VETERANS AFFAIRS'),
      );
    });

    test("apostrophes vanish, other punctuation splits words", () {
      expect(
        BNameNormalizer.normalize("St. Luke's Med. Ctr."),
        'ST LUKES MEDICAL CENTER',
      );
      expect(BNameNormalizer.normalize('ST.LUKES'), 'ST LUKES');
      expect(
        BNameNormalizer.normalize('CHONG HUA HOSPITAL- MANDAUE'),
        'CHONG HUA HOSPITAL MANDAUE',
      );
    });

    test('& and AND are the same', () {
      expect(
        BNameNormalizer.normalize('Galinato Clinic & Hospital'),
        BNameNormalizer.normalize('GALINATO CLINIC AND HOSPITAL'),
      );
    });

    test('OCR digit slips are fixed inside words only', () {
      expect(
        BNameNormalizer.normalize('QUEZ0N C1TY GENERAL H0SPITAL'),
        'QUEZON CITY GENERAL HOSPITAL',
      );
      expect(BNameNormalizer.normalize('ST LUKE5'), 'ST LUKES');
      expect(
        BNameNormalizer.normalize('Seminary Road, Project 8'),
        'SEMINARY ROAD PROJECT 8',
      );
    });

    test('a prefix code is not treated specially (the extractor strips it)',
        () {
      expect(
        BNameNormalizer.normalize('DLR-190 Galinato Clinic and Hospital'),
        'DLR 190 GALINATO CLINIC AND HOSPITAL',
      );
    });

    test('keeps stop words, collapses spaces, handles empty input', () {
      expect(
        BNameNormalizer.normalize('  The   Medical City,  Inc. '),
        'THE MEDICAL CITY INC',
      );
      expect(BNameNormalizer.normalize(''), '');
      expect(BNameNormalizer.normalize(' .,- '), '');
    });

    test('a single initial is not merged into the next word', () {
      expect(
        BNameNormalizer.normalize('Mr. Tito V. Reyes'),
        'MR TITO V REYES',
      );
    });
  });

  group('scoringTokens', () {
    test('drops stop words so legal suffixes do not matter', () {
      expect(
        BNameNormalizer.scoringTokens("St. Luke's Med. Ctr."),
        BNameNormalizer.scoringTokens('ST LUKES MEDICAL CENTER INC'),
      );
      expect(
        BNameNormalizer.scoringTokens('Marsman Corp. Phils.'),
        ['MARSMAN'],
      );
      expect(
        BNameNormalizer.scoringTokens('U.S. Dept. of Veterans Affairs'),
        ['US', 'DEPARTMENT', 'VETERANS', 'AFFAIRS'],
      );
    });

    test('keeps the words when the name is only stop words', () {
      expect(
        BNameNormalizer.scoringTokens('The Company Inc'),
        ['THE', 'COMPANY', 'INC'],
      );
    });

    test('scoringKey joins the tokens', () {
      expect(
        BNameNormalizer.scoringKey('Galinato Clinic & Hospital, Inc.'),
        'GALINATO CLINIC HOSPITAL',
      );
    });
  });

  group('with BStringSimilarity', () {
    test('differently written names of one client score as a match', () {
      final score = BStringSimilarity.tokenSetRatio(
        BNameNormalizer.scoringTokens('U.S. Dept. of Veterans Affalrs'),
        BNameNormalizer.scoringTokens('US DEPARTMENT OF VETERANS AFFAIRS'),
      );
      expect(score, 1.0);
    });

    test('different clients sharing a generic word stay apart', () {
      final score = BStringSimilarity.tokenSetRatio(
        BNameNormalizer.scoringTokens('Quezon City General Hospital'),
        BNameNormalizer.scoringTokens('Chong Hua Hospital - Mandaue'),
      );
      expect(score, lessThan(0.3));
    });
  });
}
