import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseApp;
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/notification_service.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../firebase_options.dart' as fb_options;

/// Ensures sqflite_common_ffi is initialized on desktop platforms before any
/// global `openDatabase` calls are made.
void ensureSqfliteFfiInitialized() {
  try {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      logDebug('sqflite_common_ffi initialized for desktop.');
    }
  } catch (e) {
    logDebug('Failed to initialize sqflite_common_ffi: $e');
  }
}

/// Initialize Firebase only when `DefaultFirebaseOptions.currentPlatform`
/// is supported and the platform is configured in the generated
/// `firebase_options.dart`. Returns the initialized [FirebaseApp] or null if
/// skipped.
Future<FirebaseApp?> initializeFirebaseIfConfigured() async {
  try {
    if (kIsWeb) {
      // Web may be configured in firebase_options.dart; attempt safe init.
      try {
        final app = await Firebase.initializeApp(options: fb_options.DefaultFirebaseOptions.currentPlatform);
        logDebug('Firebase initialized for web.');
        return app;
      } catch (e) {
        logDebug('Firebase for web not configured or failed: $e');
        return null;
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      final app = await Firebase.initializeApp(options: fb_options.DefaultFirebaseOptions.currentPlatform);
      logDebug('Firebase initialized for Android.');
      return app;
    }

    // Other desktop platforms should be explicitly configured with FlutterFire
    // if Firebase is required. Skip initialization here to avoid runtime
    // exceptions when DefaultFirebaseOptions.currentPlatform throws.
    logDebug('Skipping Firebase initialization on this platform.');
    return null;
  } catch (e, st) {
    logDebug('Firebase initialization skipped or failed: $e');
    logDebug(st.toString());
    return null;
  }
}

/// Initialize notification service and register it in GetX. If a
/// notification service is already registered, this will reuse it.
Future<void> initializeNotificationService({Function(String?)? onSelectNotification}) async {
  try {
    if (!Get.isRegistered<INotificationService>()) {
      Get.put<INotificationService>(NotificationService());
    }
    final service = Get.find<INotificationService>();
    await service.init(onSelectNotification: onSelectNotification);
    logDebug('Notification service initialized.');
  } catch (e) {
    logDebug('Failed to initialize notification service: $e');
  }
}

/// Convenience helper that does the common platform initialization sequence
/// used by the app entrypoints.
///
/// This will:
///  - initialize sqflite FFI on desktop
///  - initialize Firebase when configured (returns the FirebaseApp)
///  - register AuthenticationRepository after Firebase init if Firebase was initialized
///  - initialize the notification service
Future<FirebaseApp?> initPlatform({bool initFirebase = true, Function(String?)? onSelectNotification}) async {
  ensureSqfliteFfiInitialized();

  FirebaseApp? app;
  if (initFirebase) {
    app = await initializeFirebaseIfConfigured();
    if (app != null) {
      // Register authentication repository eagerly only when Firebase is available
      if (!Get.isRegistered<AuthenticationRepository>()) {
        Get.put(AuthenticationRepository());
      }
    }
  }

  await initializeNotificationService(onSelectNotification: onSelectNotification);

  return app;
}


