import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import '../../services/abstracts/i_notification_service.dart';

/// Notification service backed by flutter_local_notifications.
class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init(
      {void Function(String? payload)? onSelectNotification}) async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

    // Provide platform-specific initialization for desktop (Windows) to avoid
    // runtime errors when targeting Windows platform where Windows settings
    // are required by the plugin.
    InitializationSettings initSettings;
    if (!kIsWeb && Platform.isWindows) {
      // WindowsInitializationSettings requires several named parameters.
      final windowsInit = WindowsInitializationSettings(
        appName: 'MDMPI',
        appUserModelId: 'com.mdmpi.app',
        // GUID must be a valid GUID string. Using a constant developer GUID
        // is acceptable for local/dev/testing. Replace with your app's GUID
        // for production if required by your installer/shortcut.
        guid: '11111111-1111-1111-1111-111111111111',
      );
      initSettings = InitializationSettings(windows: windowsInit);
    } else {
      initSettings = InitializationSettings(android: androidInit);
    }

    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      onSelectNotification?.call(response.payload);
    });

    _initialized = true;
  }

  @override
  Future<void> showSimple({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (Get.isRegistered<IPermissionService>()) {
      final permission = await Get.find<IPermissionService>().requireForFeature(
        PermissionType.notifications,
        featureName: 'Notifications',
      );
      if (!permission.granted) return;
    }

    if (!_initialized) {
      await init();
    }
    NotificationDetails details;
    if (!kIsWeb && Platform.isWindows) {
      final windowsDetails = WindowsNotificationDetails();
      details = NotificationDetails(windows: windowsDetails);
    } else {
      const android = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      details = const NotificationDetails(android: android);
    }

    await _plugin.show(id, title, body, details, payload: payload);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
