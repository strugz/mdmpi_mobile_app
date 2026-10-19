import 'dart:ui' show Offset, Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class ITextRecognitionService {
  Future<String> processImage(InputImage image);

  /// The text line by line, each with where it sits on the image, so a
  /// caller can read a page's layout (a label and the number beside it, a
  /// column under a header) instead of one run of text.
  Future<List<OcrLine>> processImageLines(InputImage image);

  void close(); // For releasing resources
}

/// One line of recognised text and its box on the image (pixels).
class OcrLine {
  const OcrLine(this.text, this.box, {this.angle, this.cornerPoints});

  final String text;
  final Rect box;

  /// The line's rotation in degrees as the recognizer reports it, or null.
  /// About ±90 means the page was photographed sideways.
  final double? angle;

  /// The line's corners, clockwise from its top-left, or null. Gives the
  /// reading direction when [angle] is missing.
  final List<Offset>? cornerPoints;

  @override
  String toString() => 'OcrLine($text @ $box)';
}
