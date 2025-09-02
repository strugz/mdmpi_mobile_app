import 'package:camera/camera.dart';

abstract class ICameraService {
  Future<void> initialize();
  Future<XFile?> takePicture();
  bool get isInitialized;
  Stream<bool> get isProcessingStream;
  dynamic getNativeCameraControllerInstance();
  void dispose();
}
