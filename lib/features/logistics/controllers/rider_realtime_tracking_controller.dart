import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_location_tracking_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_dispatcher_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Coordinates active rider tracking and delegates socket transport to
/// WebSocketDispatcherController.
class RiderRealtimeTrackingController extends GetxController {
  static const String _queueKey = 'rider_realtime_location_queue';
  static const int _maxQueuedUpdates = 200;

  final GetStorage _storage = GetStorage();
  late final ILocationTrackingService _locationTrackingService;
  IPermissionService get _permissionService => Get.find<IPermissionService>();

  final RxBool isTracking = false.obs;
  final RxString activeRequestId = ''.obs;

  StreamSubscription<Position>? _positionSubscription;
  StandardDeliveryModel? _activeRequest;
  bool _isStarting = false;
  String _eta = 'Calculating...';
  String _distance = 'Calculating...';

  WebSocketDispatcherController get _webSocketController =>
      Get.find<WebSocketDispatcherController>();

  @override
  void onInit() {
    super.onInit();
    _locationTrackingService = Get.find<ILocationTrackingService>();
  }

  Future<void> startTrackingForRequest(
    StandardDeliveryModel request, {
    String? eta,
    String? distance,
  }) async {
    updateRouteMeta(eta: eta, distance: distance);

    if ((isTracking.value || _isStarting) &&
        activeRequestId.value == request.id) {
      _activeRequest = request;
      _flushQueuedUpdates();
      return;
    }

    _isStarting = true;
    await stopTracking();

    _activeRequest = request;
    activeRequestId.value = request.id;

    try {
      final permission = await _permissionService.requireForFeature(
        PermissionType.location,
        featureName: 'Rider realtime tracking',
      );
      if (!permission.granted) {
        isTracking.value = false;
        activeRequestId.value = '';
        _activeRequest = null;
        return;
      }

      _positionSubscription = _locationTrackingService
          .startTracking(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        useForegroundService: true,
        notificationTitle: 'MDMPI delivery tracking active',
        notificationText: 'Sharing rider location for request ${request.id}.',
      )
          .listen(
        _sendPositionUpdate,
        onError: (error) {
          logDebug('Rider realtime tracking error: $error');
        },
      );

      isTracking.value = true;
      _flushQueuedUpdates();
    } catch (e) {
      isTracking.value = false;
      logDebug('Failed to start rider realtime tracking: $e');
    } finally {
      _isStarting = false;
    }
  }

  void updateRouteMeta({String? eta, String? distance}) {
    if (eta != null && eta.isNotEmpty) {
      _eta = eta;
    }

    if (distance != null && distance.isNotEmpty) {
      _distance = distance;
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _locationTrackingService.stopTracking();

    isTracking.value = false;
    activeRequestId.value = '';
    _activeRequest = null;
  }

  void _sendPositionUpdate(Position position) {
    final request = _activeRequest;
    if (request == null) return;

    final riderLocation = RiderLocationModel(
      type: 'location_update',
      requestId: request.id,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      status: 'en_route',
      riderInitial: request.deliveredBy,
      eta: _eta,
      distance: _distance,
      client: request.client.name,
    );

    final payload = jsonEncode(riderLocation.toJson());
    if (_webSocketController.isConnected.value) {
      _flushQueuedUpdates();
      _webSocketController.sendMessage(payload);
      return;
    }

    _queueUpdate(payload);
    _webSocketController.reconnectWebSocket();
  }

  void _queueUpdate(String payload) {
    final queue = _readQueue();
    queue.add(payload);

    if (queue.length > _maxQueuedUpdates) {
      queue.removeRange(0, queue.length - _maxQueuedUpdates);
    }

    _storage.write(_queueKey, queue);
  }

  void _flushQueuedUpdates() {
    if (!_webSocketController.isConnected.value) return;

    final queue = _readQueue();
    if (queue.isEmpty) return;

    for (final payload in queue) {
      _webSocketController.sendMessage(payload);
    }

    _storage.write(_queueKey, <String>[]);
  }

  List<String> _readQueue() {
    final stored = _storage.read(_queueKey);
    if (stored is! List) return <String>[];

    return stored.whereType<String>().toList();
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _locationTrackingService.stopTracking();
    super.onClose();
  }
}
