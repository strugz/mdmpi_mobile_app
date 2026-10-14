import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
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
  bool get canSchedule => !kIsWeb && Platform.isAndroid;

  static bool _zonesLoaded = false;

  @override
  Future<bool> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime wallClock,
    required String channelId,
    required String channelName,
    String timeZone = 'Asia/Manila',
    String? payload,
    bool daily = false,
  }) async {
    if (!canSchedule) return false;
    if (!_initialized) await init();
    if (!_zonesLoaded) {
      tz_data.initializeTimeZones();
      _zonesLoaded = true;
    }
    final location = tz.getLocation(timeZone);
    final at = tz.TZDateTime(location, wallClock.year, wallClock.month,
        wallClock.day, wallClock.hour, wallClock.minute);
    if (!at.isAfter(tz.TZDateTime.now(location))) return false;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // A morning reminder need not be to the minute; inexact needs no
      // SCHEDULE_EXACT_ALARM permission or Play declaration.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
    );
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    await _plugin.cancel(id);
  }

  @override
  Future<List<PendingNotification>> pending() async {
    if (!canSchedule) return const [];
    if (!_initialized) await init();
    return [
      for (final r in await _plugin.pendingNotificationRequests())
        (id: r.id, payload: r.payload),
    ];
  }

  @override
  Future<String?> launchPayload() async {
    if (!canSchedule) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
