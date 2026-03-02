import 'package:camera/camera.dart';
import 'package:rxdart/rxdart.dart';

import '../abstracts/i_camera_service.dart';

class FlutterCameraService implements ICameraService {
  CameraController? _cameraController;
  final _isProcessing = BehaviorSubject<bool>.seeded(false);

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController =
          CameraController(cameras.first, ResolutionPreset.high);
      await _cameraController!.initialize();
    } else {
      // Handle no cameras
    }
  }

  @override
  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    _isProcessing.add(true);
    final image = await _cameraController!.takePicture();
    _isProcessing.add(false);
    return image;
  }

  @override
  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  @override
  Stream<bool> get isProcessingStream => _isProcessing.stream;

  @override
  dynamic getNativeCameraControllerInstance() {
    return _cameraController;
  }

  @override
  Future<void> pausePreview() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.pausePreview();
    }
  }

  @override
  Future<void> resumePreview() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Only resume if the preview is actually paused
      if (_cameraController!.value.isPreviewPaused) {
        await _cameraController!.resumePreview();
        // Small delay to ensure the camera feed is refreshed
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _isProcessing.close();
  }
}
