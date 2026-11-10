import 'dart:ui' show Offset, Rect;

import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// OCR lines to and from JSON, for the developer "Dump OCR lines" tool and
/// the one-scan fixture tests (plan §6). Fixtures hold customer data and stay
/// git-ignored under `test/fixtures/one_scan/`.
///
/// Shape:
/// ```json
/// { "source": "IMG_….jpg", "capturedAt": "…",
///   "expected": { "name": "…", "address": "…", "references": ["…"], "items": 1 },
///   "lines": [ { "text": "…", "left": 0, "top": 0, "width": 0, "height": 0,
///                "angle": 0.0, "corners": [[x, y], …] } ] }
/// ```
/// `expected` is written empty; fill it in by hand to make the fixture test
/// check the reading.
class OcrLineDump {
  OcrLineDump._();

  static Map<String, dynamic> toJson(
    List<OcrLine> lines, {
    required String source,
    DateTime? capturedAt,
  }) =>
      {
        'source': source,
        'capturedAt': (capturedAt ?? DateTime.now()).toIso8601String(),
        'expected': <String, dynamic>{},
        'lines': [
          for (final l in lines)
            {
              'text': l.text,
              'left': l.box.left,
              'top': l.box.top,
              'width': l.box.width,
              'height': l.box.height,
              if (l.angle != null) 'angle': l.angle,
              if (l.cornerPoints != null)
                'corners': [
                  for (final p in l.cornerPoints!) [p.dx, p.dy],
                ],
            },
        ],
      };

  static List<OcrLine> linesFromJson(Map<String, dynamic> json) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return [
      for (final raw in (json['lines'] as List? ?? const []))
        if (raw is Map)
          OcrLine(
            raw['text']?.toString() ?? '',
            Rect.fromLTWH(n(raw['left']), n(raw['top']), n(raw['width']),
                n(raw['height'])),
            angle: (raw['angle'] as num?)?.toDouble(),
            cornerPoints: raw['corners'] is List
                ? [
                    for (final p in raw['corners'] as List)
                      if (p is List && p.length == 2) Offset(n(p[0]), n(p[1])),
                  ]
                : null,
          ),
    ];
  }
}
