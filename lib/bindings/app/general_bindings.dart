import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_mdmpi_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/loading_screen_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/login_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/repositories/i_authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_email_password_usecase.dart';
import 'package:mdmpi_mobile_app/features/authentication/domain/usecases/login_with_google_usecase.dart';
import 'package:mdmpi_mobile_app/data/repositories/authentication/authentication_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';

import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_camera_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_location_tracking_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_maps_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_notification_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_places_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/location_alternative_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/flutter_camera_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/google_ml_kit_text_recognizer.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/location_alternative_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/location_tracking_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/maps_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/notification_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/permission_service.dart';
import 'package:mdmpi_mobile_app/common/services/implementations/places_service.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_mdmpi_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/air_sea/air_sea_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/backload_item_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/backload_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/lose_item_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/cancel_remarks_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/department_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/mobile_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/role_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/user_initial_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/contact_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/form_category_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/inventory_item_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pick_up/pick_up_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/pull_out/pull_out_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/standard_delivery_repository.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_repository.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/forget_password_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/verify_email_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_onboarding_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/chart_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_location_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/inventory_item_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/logistics_onboarding_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_transport_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/rider_realtime_tracking_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_dispatcher_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_notification_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/contact_directory_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/realtime_location_saver_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/update_name_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../data/repositories/collection/collection_repository.dart';
import '../../features/collection/helpers/sync_manager.dart';
import '../../features/collection/presentation/controllers/collection_activity_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // ========================================================================
    // Core Services
    // ========================================================================
    Get.put(NetworkManager());
    Get.lazyPut(() => WebSocketNotificationController(), fenix: true);
    Get.put(MessagingController());
    // UserController must be registered after repositories are available.

    // ========================================================================
    // Authentication - Repository Interface & Use Cases (NEW - Phase 2)
    // ========================================================================
    // Register repository interface
    Get.lazyPut<IAuthenticationRepository>(
      () => AuthenticationRepository(),
      fenix: true,
    );

    // Register login use cases
    Get.lazyPut(
      () => LoginWithEmailPasswordUseCase(
        authRepository: Get.find<IAuthenticationRepository>(),
        networkManager: Get.find<NetworkManager>(),
        localStorage: GetStorage(),
      ),
      fenix: true,
    );

    Get.lazyPut(
      () => LoginWithGoogleUseCase(
        authRepository: Get.find<IAuthenticationRepository>(),
        userRepository: Get.find<UserRepository>(),
        networkManager: Get.find<NetworkManager>(),
      ),
      fenix: true,
    );

    // ========================================================================
    // Repositories (must be registered before controllers that depend on them)
    // ========================================================================
    // Only register Firestore-backed repositories when Firebase has been
    // initialized. On desktop (Windows/macOS/Linux) we intentionally skip
    // Firebase initialization unless configured via FlutterFire CLI — in
    // that case we should avoid creating Firestore instances here.
    if (Firebase.apps.isNotEmpty) {
      Get.lazyPut(() => RoleRepository(), fenix: true);
      Get.lazyPut(() => DepartmentRepository(), fenix: true);
      Get.lazyPut(() => UserRepository());
      Get.lazyPut(() => UserInitialRepository(), fenix: true);
      Get.lazyPut(() => ClientRepository(), fenix: true);
      Get.lazyPut(() => MobileRepository(), fenix: true);
      Get.lazyPut(() => CancelRemarksRepository(), fenix: true);
      Get.lazyPut(() => UserMDMPIRepository(), fenix: true);
      Get.lazyPut(() => StandardDeliveryRepository(), fenix: true);
      Get.lazyPut(() => ImageRepository(), fenix: true);
      Get.lazyPut(() => PullOutRepository(), fenix: true);
      Get.lazyPut(() => PickUpRepository(), fenix: true);
      Get.lazyPut(() => AirSeaRepository(), fenix: true);
      Get.lazyPut(() => ItemCategoryRepository(), fenix: true);
      Get.lazyPut(() => FormCategoryRepository(), fenix: true);
      Get.lazyPut(() => InventoryItemRepository(), fenix: true);

      // Register UserController after repositories are registered so it can
      // resolve UserRepository via Get.find() in its fields/constructor.
      Get.put(UserController(), permanent: true);
    } else {
      // Firebase not initialized — skip Firestore-backed repo registration
      // to avoid runtime errors on unsupported platforms (desktop without
      // FlutterFire configuration). Some controllers handle missing
      // repositories gracefully by checking Get.isRegistered before use.
      Get.put(UserController(), permanent: true);
      // Note: consider registering local-only repositories here if needed.
      // For now we prefer to skip Firestore dependencies on non-Firebase
      // platforms to keep the UI operational.
    }

    // BackLoad uses REST + local DB only, so register it outside the Firebase
    // guard to make the long-press flow available on all targets.
    Get.lazyPut(() => BackLoadRepository(), fenix: true);
    Get.lazyPut(() => ContactRepository(), fenix: true);
    // Lost items on Pull Out requests: REST only, no Firebase dependency.
    Get.lazyPut(() => LoseItemRepository(), fenix: true);
    // Backloaded items on delivery requests: REST only, no Firebase dependency.
    Get.lazyPut(() => BackloadItemRepository(), fenix: true);

    // ========================================================================
    // Controllers
    // ========================================================================
    Get.lazyPut(() => UserInitialController(), fenix: true);
    Get.lazyPut(() => StandardDeliveryController(), fenix: true);
    Get.lazyPut(() => DashboardController(), fenix: true);

    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => LoadingScreenController(), fenix: true);
    Get.lazyPut(() => WebSocketDispatcherController(), fenix: true);
    Get.lazyPut(() => RiderRealtimeTrackingController(), fenix: true);
    Get.lazyPut(() => RequestTransportController(), fenix: true);
    Get.lazyPut(() => ClientController(), fenix: true);
    Get.lazyPut(() => UserMdmpiController(), fenix: true);
    Get.lazyPut(() => WebSocketDeliveryController(), fenix: true);
    Get.lazyPut(() => DeliveryLocationController(), fenix: true);
    Get.lazyPut(() => BackLoadController(), fenix: true);
    // SignupController is kept as a lazily registered singleton so it is
    // instantiated only when the signup UI is requested. This prevents
    // creating Firebase-backed repositories during app startup on platforms
    // where Firebase is not initialized.
    // Dependencies: RoleRepository, DepartmentRepository (registered above)
    Get.lazyPut(() => SignupController(), fenix: true);
    Get.lazyPut(() => VerifyEmailController(), fenix: true);
    Get.lazyPut(() => LogisticsOnboardingController(), fenix: true);
    // Collection onboarding controller registration
    Get.lazyPut(() => CollectionOnboardingController(), fenix: true);
    Get.lazyPut(() => ForgetPasswordController(), fenix: true);
    Get.lazyPut(() => UpdateNameController(), fenix: true);
    Get.lazyPut(() => RealtimeLocationSaverController(), fenix: true);
    Get.lazyPut(() => ContactDirectoryController(), fenix: true);
    Get.lazyPut(() => ChartController(), fenix: true);
    Get.lazyPut(() => MobileController(), fenix: true);
    Get.lazyPut(() => PullOutController(), fenix: true);
    Get.lazyPut(() => PickUpController(), fenix: true);
    Get.lazyPut(() => AirSeaController(), fenix: true);
    Get.lazyPut(() => AirSeaHdController(), fenix: true);
    Get.lazyPut(() => HotlineDirectController(), fenix: true);
    Get.lazyPut(() => StockReceiveController(), fenix: true);
    Get.lazyPut(() => RequestController(), fenix: true);
    Get.lazyPut(() => InventoryItemController(), fenix: true);
    Get.lazyPut(
        () => CameraHandlerController(
              cameraService: Get.find<ICameraService>(),
              textRecognitionService: Get.find<ITextRecognitionService>(),
              textExtractor: Get.find<ITextExtractor>(),
            ),
        fenix: true);
    Get.lazyPut<ICameraService>(() => FlutterCameraService(), fenix: true);
    Get.lazyPut<ITextRecognitionService>(() => GoogleMlKitTextRecognizer(),
        fenix: true);
    Get.lazyPut<ITextExtractor>(() => DocumentReferenceExtractor(),
        fenix: true);

    // ========================================================================
    // Platform Services
    // ========================================================================
    Get.lazyPut<IPermissionService>(() => PermissionService(), fenix: true);
    Get.lazyPut<INotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<ILocationAlternativeService>(() => LocationAlternativeService(),
        fenix: true);
    Get.lazyPut<IMapsService>(() => MapsService(), fenix: true);
    Get.lazyPut<IPlacesService>(() => PlacesService(), fenix: true);
    Get.lazyPut<ILocationTrackingService>(() => LocationTrackingService(),
        fenix: true);

    /// Collection Activity Controller
    Get.lazyPut(() => CollectionActivityController(), fenix: true);
    Get.lazyPut(() => CollectionRepository(), fenix: true);
    Get.lazyPut(() => SyncManager(), fenix: true);
  }
}
