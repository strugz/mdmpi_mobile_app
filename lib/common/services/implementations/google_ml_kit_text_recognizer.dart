import 'dart:ui' show Offset;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../abstracts/i_text_recognition_service.dart';

class GoogleMlKitTextRecognizer implements ITextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  Future<String> processImage(InputImage image) async {
    final RecognizedText recognizedTextResult = await _textRecognizer.processImage(image);
    return recognizedTextResult.text;
  }

  @override
  Future<List<OcrLine>> processImageLines(InputImage image) async {
    final result = await _textRecognizer.processImage(image);
    return [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            line.boundingBox,
            angle: line.angle,
            cornerPoints: [
              for (final p in line.cornerPoints)
                Offset(p.x.toDouble(), p.y.toDouble()),
            ],
          ),
    ];
  }

  @override
  void close() {
    _textRecognizer.close();
  }
}
