import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/b_string_similarity.dart';

void main() {
  group('levenshtein', () {
    test('known distances', () {
      expect(BStringSimilarity.levenshtein('KITTEN', 'SITTING'), 3);
      expect(BStringSimilarity.levenshtein('FLAW', 'LAWN'), 2);
      expect(BStringSimilarity.levenshtein('VETERANS', 'VETERAMS'), 1);
    });

    test('identical and empty strings', () {
      expect(BStringSimilarity.levenshtein('CLINIC', 'CLINIC'), 0);
      expect(BStringSimilarity.levenshtein('', ''), 0);
      expect(BStringSimilarity.levenshtein('', 'ABC'), 3);
      expect(BStringSimilarity.levenshtein('ABC', ''), 3);
    });

    test('is symmetric', () {
      expect(
        BStringSimilarity.levenshtein('GALINATO', 'GALINCATO'),
        BStringSimilarity.levenshtein('GALINCATO', 'GALINATO'),
      );
    });
  });

  group('jaro / jaroWinkler', () {
    test('known values', () {
      expect(BStringSimilarity.jaro('MARTHA', 'MARHTA'), closeTo(0.9444, 1e-4));
      expect(
        BStringSimilarity.jaroWinkler('MARTHA', 'MARHTA'),
        closeTo(0.9611, 1e-4),
      );
      expect(BStringSimilarity.jaro('DWAYNE', 'DUANE'), closeTo(0.8222, 1e-4));
      expect(
        BStringSimilarity.jaroWinkler('DWAYNE', 'DUANE'),
        closeTo(0.84, 1e-4),
      );
      expect(
        BStringSimilarity.jaroWinkler('DIXON', 'DICKSONX'),
        closeTo(0.8133, 1e-4),
      );
    });

    test('identical, empty and disjoint strings', () {
      expect(BStringSimilarity.jaroWinkler('CLINICA MANILA', 'CLINICA MANILA'),
          1.0);
      expect(BStringSimilarity.jaroWinkler('', ''), 1.0);
      expect(BStringSimilarity.jaroWinkler('', 'ABC'), 0.0);
      expect(BStringSimilarity.jaroWinkler('ABC', 'XYZ'), 0.0);
    });

    test('a typo late in a name costs less than an early one', () {
      final late = BStringSimilarity.jaroWinkler(
          'QUEZON CITY GENERAL HOSPITAL', 'QUEZON CITY GENERAL H0SPITAL');
      final early = BStringSimilarity.jaroWinkler(
          'QUEZON CITY GENERAL HOSPITAL', 'Q0EZON CITY GENERAL HOSPITAL');
      expect(late, greaterThan(early));
      expect(early, greaterThan(0.9));
    });
  });

  group('tokensMatch', () {
    test('one edit is tolerated for tokens of five or more characters', () {
      expect(BStringSimilarity.tokensMatch('VETERANS', 'VETERAMS'), isTrue);
      expect(BStringSimilarity.tokensMatch('CLINIC', 'CLINC'), isTrue);
      expect(BStringSimilarity.tokensMatch('GALINATO', 'GALINCATO'), isTrue);
    });

    test('short tokens must be equal', () {
      expect(BStringSimilarity.tokensMatch('CTR', 'CTR'), isTrue);
      expect(BStringSimilarity.tokensMatch('CITY', 'CITX'), isFalse);
      expect(BStringSimilarity.tokensMatch('LUKE', 'LUKES'), isFalse);
    });

    test('two edits never match', () {
      expect(BStringSimilarity.tokensMatch('MANILA', 'MANDAUE'), isFalse);
      expect(BStringSimilarity.tokensMatch('HOSPITAL', 'HOSPITALS2'), isFalse);
    });
  });

  group('tokenSetRatio', () {
    test('is order-insensitive', () {
      expect(
        BStringSimilarity.tokenSetRatio(
          ['CHONG', 'HUA', 'HOSPITAL', 'MANDAUE'],
          ['MANDAUE', 'CHONG', 'HUA', 'HOSPITAL'],
        ),
        1.0,
      );
    });

    test('a missing word lowers the score but stays high', () {
      final score = BStringSimilarity.tokenSetRatio(
        ['US', 'DEPARTMENT', 'VETERANS', 'AFFAIRS'],
        ['DEPARTMENT', 'VETERANS', 'AFFAIRS'],
      );
      expect(score, closeTo((1 + 6 / 7) / 2, 1e-9));
      expect(score, lessThan(1.0));
    });

    test('tolerates an OCR typo inside a long token', () {
      expect(
        BStringSimilarity.tokenSetRatio(
          ['DEPARTMENT', 'VETERAMS', 'AFFAIRS'],
          ['DEPARTMENT', 'VETERANS', 'AFFAIRS'],
        ),
        1.0,
      );
    });

    test('pairs each token once', () {
      // Both VETERAMS and VETERANZ are one edit from VETERANS; only one may
      // claim it.
      final score = BStringSimilarity.tokenSetRatio(
        ['VETERAMS', 'VETERANZ'],
        ['VETERANS', 'AFFAIRS'],
      );
      expect(score, closeTo(0.5, 1e-9));
    });

    test('one shared generic word scores well below a real match', () {
      final generic = BStringSimilarity.tokenSetRatio(
        ['HOSPITAL'],
        ['GALINATO', 'CLINIC', 'HOSPITAL'],
      );
      expect(generic, closeTo(0.75, 1e-9));
      expect(
        generic,
        lessThan(BStringSimilarity.tokenSetRatio(
          ['GALINATO', 'CLINIC', 'HOSPITAL'],
          ['GALINATO', 'CLINIC', 'HOSPITAL'],
        )),
      );
    });

    test('duplicates and empty tokens are ignored', () {
      expect(
        BStringSimilarity.tokenSetRatio(
          ['CLINICA', 'CLINICA', '', 'MANILA'],
          ['CLINICA', 'MANILA'],
        ),
        1.0,
      );
    });

    test('disjoint and empty lists', () {
      expect(BStringSimilarity.tokenSetRatio(['A'], ['B']), 0.0);
      expect(BStringSimilarity.tokenSetRatio([], []), 1.0);
      expect(BStringSimilarity.tokenSetRatio([], ['A']), 0.0);
    });
  });

  group('weightedTokenSetRatio', () {
    double rarity(String t) => t == 'HOSPITAL' ? 1 : 4;

    test('a shared rare word beats a shared common one', () {
      final rare = BStringSimilarity.weightedTokenSetRatio(
          ['GALINATO', 'HOSPITAL'], ['GALINATO', 'CLINIC'], rarity);
      final common = BStringSimilarity.weightedTokenSetRatio(
          ['GALINATO', 'HOSPITAL'], ['MANILA', 'HOSPITAL'], rarity);
      expect(rare, greaterThan(common));
      expect(
          BStringSimilarity.tokenSetRatio(
              ['GALINATO', 'HOSPITAL'], ['GALINATO', 'CLINIC']),
          BStringSimilarity.tokenSetRatio(
              ['GALINATO', 'HOSPITAL'], ['MANILA', 'HOSPITAL']),
          reason: 'unweighted, both look the same');
    });

    test('equal weights give tokenSetRatio', () {
      const a = ['ST', 'LUKES', 'MEDICAL'];
      const b = ['ST', 'LUKE', 'MEDICAL', 'CENTER'];
      expect(BStringSimilarity.weightedTokenSetRatio(a, b, (_) => 1),
          BStringSimilarity.tokenSetRatio(a, b));
    });

    test('a misread word counts with its partner weight', () {
      expect(
          BStringSimilarity.weightedTokenSetRatio(
              ['GALINAT0'], ['GALINATO'], (t) => t == 'GALINATO' ? 4 : 9),
          1.0);
    });
  });
}
