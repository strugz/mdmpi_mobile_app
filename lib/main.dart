import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:path_provider/path_provider.dart';

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
  // This permission is Android-only. Keep the implementation defensive so an
  // accidental call on other platforms won't crash the app.
  try {
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  } catch (e) {
    logDebug('Battery optimization permission check skipped: $e');
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

  /// Request multiple permissions using service. Build a platform-aware list
  /// because some permission types (e.g., SMS, ignoreBatteryOptimizations)
  /// are Android-only and will fail on desktop platforms.
  final permissionService = Get.put<IPermissionService>(PermissionService());
  final List<PermissionType> requiredPermissions = [];
  if (!kIsWeb && Platform.isAndroid) {
    requiredPermissions.addAll([
      PermissionType.storage,
      PermissionType.location,
      PermissionType.camera,
      PermissionType.sms,
    ]);
  } else {
    // On desktop/web, request a minimal set of permissions that are
    // commonly supported. Adjust per platform if more are available.
    requiredPermissions.addAll([
      PermissionType.location,
      PermissionType.camera,
    ]);
  }

  final statuses = await permissionService.ensureAll(requiredPermissions);

  // Request battery optimisation permission only on Android where API exists.
  if (!kIsWeb && Platform.isAndroid) {
    await requestBatteryOptimizationPermission();
  }

  /// Check if all required permissions are granted
  if ((statuses.containsKey(PermissionType.storage)
          ? statuses[PermissionType.storage] == true
          : true) &&
      (statuses.containsKey(PermissionType.location)
          ? statuses[PermissionType.location] == true
          : true) &&
      (statuses.containsKey(PermissionType.camera)
          ? statuses[PermissionType.camera] == true
          : true) &&
      (statuses.containsKey(PermissionType.sms)
          ? statuses[PermissionType.sms] == true
          : true)) {
    /// -- Create storage folder. Use Android external storage on Android;
    /// otherwise use application documents directory (Windows/macOS/Linux).
    Directory mdmpiAppDir;
    if (!kIsWeb && Platform.isAndroid) {
      mdmpiAppDir = Directory('/storage/emulated/0/MDMPIAPP');
    } else {
      final appDoc = await getApplicationDocumentsDirectory();
      mdmpiAppDir = Directory('${appDoc.path}${Platform.pathSeparator}MDMPIAPP');
    }

    if (!mdmpiAppDir.existsSync()) {
      await mdmpiAppDir.create(recursive: true);
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
