import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/b_ocr_orientation.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

OcrLine _a(double? angle, {List<Offset>? corners}) => OcrLine(
    'x', const Rect.fromLTWH(0, 0, 10, 10),
    angle: angle, cornerPoints: corners);

void main() {
  test('upright text needs no retry', () {
    expect(BOcrOrientation.estimateRetryRotation([_a(0), _a(2), _a(-3)]), isNull);
  });

  test('about +90 retries at 270, about -90 at 90, about 180 at 180', () {
    expect(BOcrOrientation.estimateRetryRotation([_a(88), _a(91), _a(90)]), 270);
    expect(BOcrOrientation.estimateRetryRotation([_a(-89), _a(-92), _a(-90)]), 90);
    expect(BOcrOrientation.estimateRetryRotation([_a(179), _a(-178), _a(180)]), 180);
    expect(BOcrOrientation.estimateRetryRotation([_a(270), _a(268), _a(271)]), 90,
        reason: '270 is the same as -90');
  });

  test('the median ignores a few odd lines', () {
    expect(
      BOcrOrientation.estimateRetryRotation([_a(90), _a(89), _a(0), _a(91), _a(5)]),
      270,
    );
  });

  test('too few lines, or none with an angle, is no retry', () {
    expect(BOcrOrientation.estimateRetryRotation([_a(90), _a(90)]), isNull);
    expect(BOcrOrientation.estimateRetryRotation([_a(null), _a(null), _a(null)]),
        isNull);
    expect(BOcrOrientation.estimateRetryRotation([]), isNull);
  });

  group('deskew', () {
    OcrLine tilted(double left, double level, {double slope = -0.035}) {
      final top = level + slope * left;
      return OcrLine('word word word', Rect.fromLTWH(left, top, 120, 14),
          cornerPoints: [
            Offset(left, top),
            Offset(left + 120, top + slope * 120),
          ]);
    }

    test('a slightly tilted row comes out level', () {
      final row = [tilted(100, 400), tilted(500, 400), tilted(900, 400)];
      final out = BOcrOrientation.deskew(row);
      final centres = out.map((l) => l.box.center.dy).toList();
      expect(centres.reduce((a, b) => a > b ? a : b) -
          centres.reduce((a, b) => a < b ? a : b), lessThan(1));
    });

    test('a curved page: top and bottom tilt opposite ways, both come out level',
        () {
      // A bowed sheet (IT photo of 2026-10-15): the top rises to the right,
      // the bottom falls, the middle is flat.
      final rows = {
        300.0: -0.03,
        1100.0: 0.0,
        1900.0: 0.03,
      };
      final lines = [
        for (final MapEntry(key: level, value: slope) in rows.entries)
          for (final x in [100.0, 500.0, 900.0, 1300.0])
            tilted(x, level, slope: slope),
      ];
      final out = BOcrOrientation.deskew(lines);
      for (var r = 0; r < rows.length; r++) {
        final centres =
            out.skip(4 * r).take(4).map((l) => l.box.center.dy).toList();
        expect(
            centres.reduce((a, b) => a > b ? a : b) -
                centres.reduce((a, b) => a < b ? a : b),
            lessThan(2),
            reason: 'row at ${rows.keys.elementAt(r)}');
      }
    });

    test('running it twice changes nothing', () {
      final once = BOcrOrientation.deskew(
          [tilted(100, 400), tilted(500, 400), tilted(900, 400)]);
      final twice = BOcrOrientation.deskew(once);
      for (var i = 0; i < once.length; i++) {
        expect(twice[i].box.top, closeTo(once[i].box.top, 0.001));
      }
    });

    test('straight pages and lines without corners are left alone', () {
      final straight = [
        for (final x in [100.0, 500.0, 900.0]) tilted(x, 400, slope: 0)
      ];
      expect(identical(BOcrOrientation.deskew(straight), straight), isTrue);
      final bare = [_a(null), _a(null), _a(null)];
      expect(identical(BOcrOrientation.deskew(bare), bare), isTrue);
    });
  });

  test('corner points give the angle when it is missing', () {
    // Top edge running straight down the image: text turned +90.
    final down = [const Offset(100, 0), const Offset(100, 50)];
    expect(
      BOcrOrientation.estimateRetryRotation(
          [for (var i = 0; i < 3; i++) _a(null, corners: down)]),
      270,
    );
    final flat = [const Offset(0, 0), const Offset(50, 0)];
    expect(
      BOcrOrientation.estimateRetryRotation(
          [for (var i = 0; i < 3; i++) _a(null, corners: flat)]),
      isNull,
    );
  });
}
