import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';

import '../../../../base/utils/popups/full_screen_loader.dart';
import '../../../personalization/controller/user_controller.dart';
import '../../controllers/request_controller.dart';
import '../../models/request_model.dart';

abstract class RequestActionHandler {
  void handleAction(
    BuildContext context,
    RequestModel request,
    RequestController requestController,
    UserController userController,
    String userInitial, // Pass userInitial directly
  );

  // Helper to show the dialog, can be part of the abstract class or a utility
  void showDialog(BuildContext context, RequestModel request,
      VoidCallback? onConfirm, bool canEdit) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, onConfirm ?? () {}, canEdit);
  }

  // Helper to navigate
  void navigateToRequestTransport(BuildContext context, RequestModel request,
      RequestController requestController) {
    Get.to(() => RequestTransport(
        request: request, requestController: requestController));
  }
}
