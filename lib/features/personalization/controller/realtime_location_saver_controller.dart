import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_location_tracking_service.dart';

class RealtimeLocationSaverController extends GetxController {
  static const String _enabledKey = 'realtime_location_saver_enabled';
  static const String _latestLocationKey = 'realtime_location_saver_latest';
  static const String _historyKey = 'realtime_location_saver_history';
  static const int _maxHistoryItems = 500;

  final GetStorage _storage = GetStorage();
  late final ILocationTrackingService _locationTrackingService;

  final RxBool isEnabled = false.obs;
  final RxMap<String, dynamic> latestLocation = <String, dynamic>{}.obs;

  StreamSubscription<Position>? _positionSubscription;

  @override
  void onInit() {
    super.onInit();
    _locationTrackingService = Get.find<ILocationTrackingService>();

    isEnabled.value = _storage.read(_enabledKey) ?? false;

    final storedLatest = _storage.read(_latestLocationKey);
    if (storedLatest is Map) {
      latestLocation.value = Map<String, dynamic>.from(storedLatest);
    }

    if (isEnabled.value) {
      _startTracking();
    }
  }

  Future<void> toggle(bool enable) async {
    if (enable) {
      await _startTracking();
      return;
    }

    await _stopTracking();
  }

  Future<void> _startTracking() async {
    try {
      final serviceEnabled =
          await _locationTrackingService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        BLoaders.warningSnackBar(
          title: 'Location',
          message: 'Location services are disabled.',
        );
        isEnabled.value = false;
        _storage.write(_enabledKey, false);
        return;
      }

      var permission = await _locationTrackingService.checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationTrackingService.requestLocationPermission();
        if (permission == LocationPermission.denied) {
          BLoaders.warningSnackBar(
            title: 'Location',
            message: 'Location permission is required for realtime saver.',
          );
          isEnabled.value = false;
          _storage.write(_enabledKey, false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        BLoaders.warningSnackBar(
          title: 'Location',
          message:
              'Location permission is permanently denied. Enable it in Settings.',
        );
        isEnabled.value = false;
        _storage.write(_enabledKey, false);
        return;
      }

      await _positionSubscription?.cancel();
      _positionSubscription = _locationTrackingService
          .startTracking(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          )
          .listen(_persistLocationUpdate);

      isEnabled.value = true;
      _storage.write(_enabledKey, true);
    } catch (e) {
      isEnabled.value = false;
      _storage.write(_enabledKey, false);
      logDebug('Failed to start realtime location saver: $e');
      BLoaders.errorSnackBar(
        title: 'Realtime Saver',
        message: 'Failed to enable realtime location saver.',
      );
    }
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _locationTrackingService.stopTracking();

    isEnabled.value = false;
    _storage.write(_enabledKey, false);

    BLoaders.successSnackBar(
      title: 'Realtime Saver',
      message: 'Realtime location saver is disabled.',
    );
  }

  void _persistLocationUpdate(Position position) {
    final payload = <String, dynamic>{
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'altitude': position.altitude,
      'timestamp':
          (position.timestamp ?? DateTime.now()).toIso8601String(),
    };

    latestLocation.value = payload;
    _storage.write(_latestLocationKey, payload);

    final List<dynamic> existing = _storage.read(_historyKey) ?? <dynamic>[];
    final history = List<Map<String, dynamic>>.from(
      existing.map((entry) => Map<String, dynamic>.from(entry as Map)),
    );

    history.add(payload);
    if (history.length > _maxHistoryItems) {
      history.removeRange(0, history.length - _maxHistoryItems);
    }

    _storage.write(_historyKey, history);

    logDebug(
      'Realtime location saved: ${position.latitude}, ${position.longitude}',
    );
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _locationTrackingService.stopTracking();
    super.onClose();
  }
}
