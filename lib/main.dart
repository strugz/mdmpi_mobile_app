import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/notification_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/permission_service.dart';
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

  /// Request multiple permissions using service
  final permissionService = Get.put<IPermissionService>(PermissionService());
  final statuses = await permissionService.ensureAll([
    PermissionType.storage,
    PermissionType.location,
    PermissionType.camera,
    PermissionType.sms,
  ]);

  await requestBatteryOptimizationPermission();

  /// Check if all required permissions are granted
  if (statuses[PermissionType.storage] == true &&
      statuses[PermissionType.location] == true &&
      statuses[PermissionType.camera] == true &&
      statuses[PermissionType.sms] == true) {
    /// -- Create storage folder
    final mdmpiAppDir = Directory('/storage/emulated/0/MDMPIAPP');

    if (!mdmpiAppDir.existsSync()) {
      mdmpiAppDir.createSync(recursive: true);
    }
  } else {
    if (statuses[PermissionType.sms] == false) {
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

  // Initialize notifications via service and set tap handler
  final notificationService = Get.put<INotificationService>(NotificationService());
  await notificationService.init(onSelectNotification: (payload) {
    final selectedPayload = Get.put(NavigationController());
    selectedPayload.selectedIndex.value = 1;
  });

  //  Load all the Material Design / Themes / Localizations / Bindings
  runApp(const App());
}
