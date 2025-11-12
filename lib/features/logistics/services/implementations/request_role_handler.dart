import 'dart:ui';

import 'package:flutter/cupertino.dart' show BuildContext;
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';

import '../../../../base/utils/constants/text_string.dart';
import '../../../../base/utils/popups/full_screen_loader.dart';
import '../../../personalization/controller/user_controller.dart';
import '../../controllers/standard_delivery_controller.dart';
import '../../models/standard_delivery_model.dart';

abstract class RequestActionHandler {
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial, // Pass userInitial directly
  );

  // Helper to show the dialog, can be part of the abstract class or a utility
  void _showDialog(BuildContext context, StandardDeliveryModel request,
      VoidCallback? onConfirm, bool canEdit) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, onConfirm ?? () {}, canEdit);
  }
}

class RequestRoleHandler extends RequestActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial,
  ) {
    if (request.status == BTexts.statusNewRequest &&
        userController.user.value.role.contains('Request')) {
      _showDialog(context, request, null, false);
    } else if (request.status == BTexts.statusNewRequest &&
        !userController.user.value.role.contains('Release')) {
      _showDialog(context, request, null, false);
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        !userController.user.value.role.contains('Release')) {
      _showDialog(context, request, null, false);
    } else if (request.status == BTexts.statusItemPrepared &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusForDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusDoneDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    }
  }
}

class ReleaseRoleHandler extends RequestActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial,
  ) {
    if (request.status == BTexts.statusNewRequest) {
      _showDialog(
        context,
        request,
        () => requestController.updateRequestStatus(
            request, BTexts.statusGettingSuppliesReady, userInitial),
        true,
      );
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        request.itemPreparedBy == userInitial) {
      _showDialog(
        context,
        request,
        () => requestController.updateRequestStatus(
            request, BTexts.statusItemPrepared, userInitial),
        true,
      );
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        request.itemPreparedBy != userInitial) {
      _showDialog(context, request, null, false);
    } else if (request.status == BTexts.statusItemPrepared &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusForDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusDoneDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    }
  }
}

class CourierRoleHandler extends RequestActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial,
  ) {
    if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusGettingSuppliesReady) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusItemPrepared) {
      Get.to(() => RequestTransport(
          request: request, requestController: requestController));
    } else if (request.status == BTexts.statusForDelivery && request.deliveredBy != userInitial && request.helper != userInitial) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false);
    } else if (request.status == BTexts.statusForDelivery &&
        (request.deliveredBy == userInitial || request.helper == userInitial)) {
      Get.to(() => RequestTransport(
          request: request, requestController: requestController));
    }
  }
}

class ViewerRoleHandler extends RequestActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial,
  ) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, () {}, false);
  }
}

// A default handler if no specific role matches or for common cases
class DefaultRequestHandler extends RequestActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    StandardDeliveryController requestController,
    UserController userController,
    String userInitial,
  ) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, () {}, false);
  }
}
