import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/mobile_controller.dart';
import 'package:mdmpi_mobile_app/data/controllers/app_data/user_initial_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_mdmpi_repository.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/loading_screen/loading_screen_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/login/login_controller.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/signup/signup_controller.dart';

import '../base/utils/helpers/network_manager.dart';
import '../common/services/abstracts/i_camera_service.dart';
import '../common/services/abstracts/i_text_extractor.dart';
import '../common/services/abstracts/i_text_recognition_service.dart';
import '../common/services/abstracts/i_notification_service.dart';
import '../common/services/abstracts/i_permission_service.dart';
import '../common/services/implementations/flutter_camera_service.dart';
import '../common/services/implementations/google_ml_kit_text_recognizer.dart';
import '../common/services/implementations/notification_service.dart';
import '../common/services/implementations/permission_service.dart';
import '../data/controllers/app_data/user_mdmpi_controller.dart';
import '../data/controllers/client_controller.dart';
import '../data/repositories/app_data/department_repository.dart';
import '../data/repositories/app_data/mobile_repository.dart';
import '../data/repositories/app_data/role_repository.dart';
import '../data/repositories/app_data/user_initial_repository.dart';
import '../data/repositories/app_data/cancel_remarks_repository.dart';
import '../data/repositories/client/client_repository.dart';
import '../data/repositories/delivery_vehicle/delivery_vehicle_repository.dart';
import '../data/repositories/standard_delivery/standard_delivery_repository.dart';
import '../data/repositories/image/image_repository.dart';
import '../data/repositories/user/user_repository.dart';
import '../data/services/messaging_controller.dart';
import '../features/authentication/controllers/forget_password/forget_password_controller.dart';
import '../features/authentication/controllers/onboarding/onboarding_controller.dart';
import '../features/authentication/controllers/signup/verify_email_controller.dart';
import '../common/controllers/camera_controller.dart';
import '../features/logistics/controllers/chart_controller.dart';
import '../features/logistics/controllers/delivery_location_controller.dart';
import '../features/logistics/controllers/delivery_vehicle_controller.dart';
import '../features/logistics/controllers/standard_delivery_controller.dart';
import '../features/logistics/controllers/request_transport_controller.dart';
import '../features/logistics/controllers/web_socket_delivery_controller.dart';
import '../features/logistics/controllers/web_socket_dispatcher_controller.dart';
import '../features/logistics/controllers/web_socket_notification_controller.dart';
import '../features/personalization/controller/update_name_controller.dart';
import '../features/personalization/controller/user_controller.dart';
import '../data/repositories/pull_out/pull_out_repository.dart';
import '../features/logistics/controllers/pull_out_controller.dart';
import '../data/repositories/pick_up/pick_up_repository.dart';
import '../features/logistics/controllers/pick_up_controller.dart';
import '../data/repositories/air_sea/air_sea_repository.dart';
import '../features/logistics/controllers/air_sea_controller.dart';
import '../features/logistics/controllers/hotline_direct_controller.dart';
import '../features/logistics/controllers/stock_receive_controller.dart';
import '../data/repositories/common/item_category_repository.dart';
import '../data/repositories/common/form_category_repository.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(WebSocketNotificationController());
    Get.put(MessagingController());
    Get.put(UserController(), permanent: true);
    Get.lazyPut(() => UserInitialController(), fenix: true);
    Get.lazyPut(() => StandardDeliveryController(), fenix: true);

    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => LoadingScreenController(), fenix: true);
    Get.lazyPut(() => WebSocketDispatcherController(), fenix: true);
    Get.lazyPut(() => RequestTransportController(), fenix: true);
    Get.lazyPut(() => DeliveryVehicleController(), fenix: true);
    Get.lazyPut(() => ClientController(), fenix: true);
    Get.lazyPut(() => UserMdmpiController(), fenix: true);
    Get.lazyPut(() => WebSocketDeliveryController(), fenix: true);
    Get.lazyPut(() => DeliveryLocationController(), fenix: true);
    Get.lazyPut(() => SignupController(), fenix: true);
    Get.lazyPut(() => VerifyEmailController(), fenix: true);
    Get.lazyPut(() => OnBoardingController(), fenix: true);
    Get.lazyPut(() => ForgetPasswordController(), fenix: true);
    Get.lazyPut(() => UpdateNameController(), fenix: true);
    Get.lazyPut(() => ChartController(), fenix: true);
    Get.lazyPut(() => MobileController(), fenix: true);
    Get.lazyPut(() => PullOutController(), fenix: true);
    Get.lazyPut(() => PickUpController(), fenix: true);
    Get.lazyPut(() => AirSeaController(), fenix: true);
    Get.lazyPut(() => HotlineDirectController(), fenix: true);
    Get.lazyPut(() => StockReceiveController(), fenix: true);
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
    Get.lazyPut(() => StandardDeliveryRepository(), fenix: true);
    Get.lazyPut(() => ImageRepository(), fenix: true);
    Get.lazyPut(() => DeliveryVehicleRepository(), fenix: true);
    Get.lazyPut(() => UserRepository());
    Get.lazyPut(() => UserInitialRepository(), fenix: true);
    Get.lazyPut(() => ClientRepository(), fenix: true);
    Get.lazyPut(() => MobileRepository(), fenix: true);
    Get.lazyPut(() => RoleRepository(), fenix: true);
    Get.lazyPut(() => DepartmentRepository(), fenix: true);
    Get.lazyPut(() => CancelRemarksRepository(), fenix: true);
    Get.lazyPut(() => UserMDMPIRepository(), fenix: true);
    Get.lazyPut<IPermissionService>(() => PermissionService(), fenix: true);
    Get.lazyPut<INotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut(() => PullOutRepository(), fenix: true);
    Get.lazyPut(() => PickUpRepository(), fenix: true);
    Get.lazyPut(() => AirSeaRepository(), fenix: true);
    Get.lazyPut(() => ItemCategoryRepository(), fenix: true);
    Get.lazyPut(() => FormCategoryRepository(), fenix: true);
  }
}
