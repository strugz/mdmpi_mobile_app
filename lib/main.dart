import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/data/controllers/navigation_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'data/local/database_helper.dart';
import 'firebase_options.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> requestBatteryOptimizationPermission() async {
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

/// --  Entry point of Flutter App
Future<void> main() async {
  ///  Widgets binding
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  ///  Load .env file
  await dotenv.load(fileName: ".env");
  await GetStorage.init();

  /// Get an instance of your DatabaseHelper
  final dHelper = DatabaseHelper.instance;

  try {
    /// Initialize the database
    await dHelper.database;
  } catch (e) {
    logDebug('Error initializing database: $e');
  }

  /// Request multiple permissions
  Map<Permission, PermissionStatus> statuses = await [
    Permission.manageExternalStorage,
    Permission.location,
    Permission.camera,
    Permission.sms
  ].request();

  await requestBatteryOptimizationPermission();

  /// Check if all required permissions are granted
  if (statuses[Permission.manageExternalStorage]?.isGranted == true &&
      statuses[Permission.location]?.isGranted == true &&
      statuses[Permission.camera]?.isGranted == true &&
      statuses[Permission.sms]?.isGranted == true) {
    /// -- Create storage folder
    final mdmpiAppDir = Directory('/storage/emulated/0/MDMPIAPP');

    if (!mdmpiAppDir.existsSync()) {
      mdmpiAppDir.createSync(recursive: true);
    }
  } else {
    if (statuses[Permission.sms]?.isDenied == true ||
        statuses[Permission.sms]?.isPermanentlyDenied == true) {
      logDebug('SMS permission was denied.');
    }
  }

  //  Todo: Init Payment Methods
  /// --  Await Splash until other items Load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// --  Initialize Firebase & Authentication Repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((FirebaseApp value) => Get.put(AuthenticationRepository()));

  HttpOverrides.global = MyHttpOverrides();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    final selectedPayload = Get.put(NavigationController());
    selectedPayload.selectedIndex.value = 1;
  });

  //  Load all the Material Design / Themes / Localizations / Bindings
  runApp(const App());
}
