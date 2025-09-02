import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class ITextRecognitionService {
  Future<String> processImage(InputImage image);
  void close(); // For releasing resources
}