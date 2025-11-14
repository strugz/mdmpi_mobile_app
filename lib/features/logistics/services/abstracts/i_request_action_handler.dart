import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';

import '../../../../base/utils/popups/full_screen_loader.dart';
import '../../../personalization/controller/user_controller.dart';
import '../../controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

abstract class RequestActionHandler {
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial, // Pass userInitial directly
  );

  // Helper to show the dialog, can be part of the abstract class or a utility
  void showDialog(BuildContext context, StandardDeliveryModel request,
      VoidCallback? onConfirm, bool canEdit) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, onConfirm ?? () {}, canEdit);
  }

  // Helper to navigate
  void navigateToRequestTransport(BuildContext context, StandardDeliveryModel request,
      StandardDeliveryController requestController) {
    Get.to(() => RequestTransport(
        request: request, requestController: requestController));
  }
}
