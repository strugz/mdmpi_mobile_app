import 'dart:ui' show Rect;

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
  const OcrLine(this.text, this.box);

  final String text;
  final Rect box;

  @override
  String toString() => 'OcrLine($text @ $box)';
}
