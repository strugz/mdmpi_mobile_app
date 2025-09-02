import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../data/repositories/request/request_repository.dart';
import '../features/logistics/controllers/request_controller.dart';
import '../features/logistics/controllers/web_socket_notification_controller.dart';

class RequestBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RequestController());
    Get.lazyPut(() => RequestRepository());
    Get.lazyPut(() => WebSocketNotificationController());
    Get.lazyPut(() => UserController());
  }
}
