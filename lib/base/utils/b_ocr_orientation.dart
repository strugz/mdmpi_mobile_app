import 'dart:math' as math;

import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// Works out how far a photographed page is turned, from the lines the
/// phone's text recognition already returned (Standard Delivery one-scan,
/// plan §4.1). Lets the scan retry once at the right angle instead of trying
/// every side.
class BOcrOrientation {
  BOcrOrientation._();

  /// Fewer lines than this cannot tell a turned page from noise.
  static const int minLines = 3;

  /// Returns the clockwise rotation (90, 180 or 270) to apply to the image
  /// before a retry, or null when the page reads upright or there is too
  /// little to tell. Each line's angle comes from [OcrLine.angle], or from
  /// its top edge ([OcrLine.cornerPoints]) when the angle is missing; the
  /// median of those decides.
  static int? estimateRetryRotation(List<OcrLine> lines) {
    final angles = <double>[
      for (final line in lines)
        if (_angleOf(line) case final a?) _normalize(a),
    ];
    if (angles.length < minLines) return null;

    angles.sort();
    final median = angles[angles.length ~/ 2];

    // Text read at about +90° is turned clockwise: turn it back by 270.
    if (median >= 45 && median < 135) return 270;
    if (median <= -45 && median > -135) return 90;
    if (median >= 135 || median <= -135) return 180;
    return null;
  }

  /// The lines with a slight tilt taken out, so a row printed straight but
  /// photographed a few degrees off still reads as one row.
  ///
  /// A hand-held photo is rarely tilted evenly: in the in-app capture of
  /// 2026-10-15 the left of the page was nearly level and the right rose
  /// about 2.5 degrees. So the tilt is fitted as growing across the page
  /// (slope = a + b·x, weighted least squares over the lines' top edges from
  /// [OcrLine.cornerPoints], each weighted by its length, since a long line
  /// measures the tilt far better than a short date), and each line moves by
  /// the height that tilt adds up to at its position.
  ///
  /// A curved page (a sheet that bows, IT photo of 2026-10-15) tilts one way
  /// at the top and the other way at the bottom, so the tilt also changes
  /// down the page: slope = a + b·x + c·y. With too few usable lines or too
  /// little spread across or down the page, that term is left out, and with
  /// neither spread one weighted-median slope is used. Lines without
  /// corners, fewer than [minLines] usable lines, or a tilt under 0.3
  /// degrees everywhere leave the input as is.
  static List<OcrLine> deskew(List<OcrLine> lines) {
    final samples = <_TiltSample>[];
    for (final line in lines) {
      final c = line.cornerPoints;
      if (c == null || c.length < 2) continue;
      final dx = c[1].dx - c[0].dx;
      if (dx < 2 * line.box.height || dx <= 0) continue; // too short to tell
      final slope = (c[1].dy - c[0].dy) / dx;
      // ML Kit gives many short lines perfectly flat corners (angle 0) even
      // on a tilted page: they say nothing about the tilt.
      if (slope == 0 || slope.abs() >= 0.35) continue;
      samples.add(_TiltSample((c[0].dx + c[1].dx) / 2,
          (c[0].dy + c[1].dy) / 2, slope, dx));
    }
    if (samples.length < minLines) return lines;

    final fit = _fitTilt(samples);
    double slopeAt(double x, double y) => fit.a + fit.b * x + fit.c * y;
    final boxes = lines.map((l) => l.box);
    final left = boxes.map((b) => b.center.dx).reduce(math.min);
    final right = boxes.map((b) => b.center.dx).reduce(math.max);
    final top = boxes.map((b) => b.center.dy).reduce(math.min);
    final bottom = boxes.map((b) => b.center.dy).reduce(math.max);
    final steepest = [
      for (final x in [left, right])
        for (final y in [top, bottom]) slopeAt(x, y).abs(),
    ].reduce(math.max);
    if (steepest < 0.005) return lines;

    // Height the tilt adds up to between the left edge (x = 0) and x, on
    // the line at height y.
    double shift(double x, double y) =>
        -(fit.a * x + fit.b * x * x / 2 + fit.c * y * x);
    return [
      for (final l in lines)
        OcrLine(
          l.text,
          l.box.translate(0, shift(l.box.center.dx, l.box.center.dy)),
          angle: l.angle,
          cornerPoints: l.cornerPoints
              ?.map((p) => p.translate(0, shift(p.dx, l.box.center.dy)))
              .toList(),
        ),
    ];
  }

  /// slope ≈ a + b·x + c·y, weighted least squares. A term is fitted only
  /// when the samples spread at least [_minSpread] pixels that way; with
  /// neither, b = c = 0 and a is the weighted median slope.
  static ({double a, double b, double c}) _fitTilt(List<_TiltSample> samples) {
    final total = samples.fold<double>(0, (s, p) => s + p.weight);
    double mean(double Function(_TiltSample) f) =>
        samples.fold<double>(0, (s, p) => s + p.weight * f(p)) / total;
    final mx = mean((p) => p.x);
    final my = mean((p) => p.y);
    final ms = mean((p) => p.slope);
    double cov(double Function(_TiltSample) f, double mf,
            double Function(_TiltSample) g, double mg) =>
        samples.fold<double>(
            0, (s, p) => s + p.weight * (f(p) - mf) * (g(p) - mg)) /
        total;
    final sxx = cov((p) => p.x, mx, (p) => p.x, mx);
    final syy = cov((p) => p.y, my, (p) => p.y, my);
    final sxy = cov((p) => p.x, mx, (p) => p.y, my);
    final sxs = cov((p) => p.x, mx, (p) => p.slope, ms);
    final sys = cov((p) => p.y, my, (p) => p.slope, ms);

    final enough = samples.length >= 2 * minLines;
    final useX = enough && math.sqrt(sxx) >= _minSpread;
    final useY = enough && math.sqrt(syy) >= _minSpread;
    var b = 0.0;
    var c = 0.0;
    if (useX && useY) {
      final det = sxx * syy - sxy * sxy;
      if (det > 1e-6 * sxx * syy) {
        b = (sxs * syy - sys * sxy) / det;
        c = (sys * sxx - sxs * sxy) / det;
      } else {
        b = sxs / sxx;
      }
    } else if (useX) {
      b = sxs / sxx;
    } else if (useY) {
      c = sys / syy;
    }
    if (useX || useY) return (a: ms - b * mx - c * my, b: b, c: c);

    final sorted = [...samples]..sort((p, q) => p.slope.compareTo(q.slope));
    var acc = 0.0;
    for (final p in sorted) {
      acc += p.weight;
      if (acc >= total / 2) return (a: p.slope, b: 0.0, c: 0.0);
    }
    return (a: sorted.last.slope, b: 0.0, c: 0.0);
  }

  /// Spread, in pixels, the samples need across (or down) the page before
  /// the tilt is fitted as changing that way.
  static const double _minSpread = 150;

  /// Degrees, or null when the line carries neither an angle nor corners.
  static double? _angleOf(OcrLine line) {
    if (line.angle != null) return line.angle;
    final corners = line.cornerPoints;
    if (corners == null || corners.length < 2) return null;
    final topLeft = corners[0];
    final topRight = corners[1];
    final dx = topRight.dx - topLeft.dx;
    final dy = topRight.dy - topLeft.dy;
    if (dx == 0 && dy == 0) return null;
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Into (-180, 180].
  static double _normalize(double degrees) {
    var d = degrees % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }
}

/// One line's top-edge slope at its middle, weighted by its length.
class _TiltSample {
  const _TiltSample(this.x, this.y, this.slope, this.weight);

  final double x;
  final double y;
  final double slope;
  final double weight;
}
