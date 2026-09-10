import 'dart:ui';

import 'package:flutter/cupertino.dart' show BuildContext;
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/crew_assignment.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';

import '../../../../base/utils/constants/text_strings.dart';
import '../../../../base/utils/popups/full_screen_loader.dart';
import '../../../personalization/controller/user_controller.dart';
import '../../models/standard_delivery_model.dart';

/// Abstract base class for Hotline Direct action handlers.
abstract class HotlineDirectActionHandler {
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
    UserController userController,
    String userInitial,
  );

  /// Helper to show the dialog
  void _showDialog(
      BuildContext context,
      StandardDeliveryModel request,
      VoidCallback? onConfirm,
      bool canEdit,
      IDeliveryRequestController requestController) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, onConfirm ?? () {}, canEdit, requestController);
  }
}

/// Handler for "Request" role actions on Hotline Direct requests.
class HotlineDirectRequestRoleHandler extends HotlineDirectActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
    UserController userController,
    String userInitial,
  ) {
    if (request.status == BTexts.statusNewRequest &&
        userController.user.value.role.contains('Request')) {
      _showDialog(context, request, null, false, requestController);
    } else if (request.status == BTexts.statusNewRequest &&
        !userController.user.value.role.contains('Release')) {
      _showDialog(context, request, null, false, requestController);
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        !userController.user.value.role.contains('Release')) {
      _showDialog(context, request, null, false, requestController);
    } else if (request.status == BTexts.statusItemPrepared &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (request.status == BTexts.statusForDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (request.status == BTexts.statusDoneDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    }
  }
}

/// Handler for "Release" role actions on Hotline Direct requests.
class HotlineDirectReleaseRoleHandler extends HotlineDirectActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
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
        requestController,
      );
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        request.itemPreparedBy == userInitial) {
      _showDialog(
        context,
        request,
        () => requestController.updateRequestStatus(
            request, BTexts.statusItemPrepared, userInitial),
        true,
        requestController,
      );
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        request.itemPreparedBy != userInitial) {
      _showDialog(context, request, null, false, requestController);
    } else if (request.status == BTexts.statusItemPrepared &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (request.status == BTexts.statusForDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (request.status == BTexts.statusDoneDelivery &&
        !userController.user.value.role.contains('Courier')) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    }
  }
}

/// Handler for "Courier" role actions on Hotline Direct requests.
class HotlineDirectCourierRoleHandler extends HotlineDirectActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
    UserController userController,
    String userInitial,
  ) {
    // Couriers may create Hotline Direct requests, and may also prepare the
    // requests they created themselves (mirrors the Release preparation
    // flow); other requests stay view-only during preparation.
    if (request.status == BTexts.statusNewRequest &&
        request.createdBy == userInitial) {
      _showDialog(
        context,
        request,
        () => requestController.updateRequestStatus(
            request, BTexts.statusGettingSuppliesReady, userInitial),
        true,
        requestController,
      );
    } else if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (request.status == BTexts.statusGettingSuppliesReady &&
        request.itemPreparedBy == userInitial) {
      _showDialog(
        context,
        request,
        () => requestController.updateRequestStatus(
            request, BTexts.statusItemPrepared, userInitial),
        true,
        requestController,
      );
    } else if (request.status == BTexts.statusGettingSuppliesReady) {
      BFullScreenLoader.showRequestForReleasingDialog(
          context, request, () {}, false, requestController);
    } else if (CrewAssignment.isCrewOnlyStatus(request.status)) {
      // Item Prepared / For Delivery: the courier screen is for the assigned
      // driver or helper; everyone else gets the read-only request dialog.
      final isCrew = CrewAssignment.isCrew(
        driver: request.deliveredBy,
        helper: request.helper,
        userInitial: userInitial,
      );
      if (isCrew) {
        Get.to(() => RequestTransport(
            request: request, requestController: requestController));
      } else {
        BFullScreenLoader.showRequestForReleasingDialog(
            context, request, () {}, false, requestController);
      }
    }
  }
}

/// Handler for "Viewer" role actions on Hotline Direct requests.
class HotlineDirectViewerRoleHandler extends HotlineDirectActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
    UserController userController,
    String userInitial,
  ) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, () {}, false, requestController);
  }
}

/// Default handler for Hotline Direct requests when no specific role handler applies.
class HotlineDirectDefaultHandler extends HotlineDirectActionHandler {
  @override
  void handleAction(
    BuildContext context,
    StandardDeliveryModel request,
    IDeliveryRequestController requestController,
    UserController userController,
    String userInitial,
  ) {
    BFullScreenLoader.showRequestForReleasingDialog(
        context, request, () {}, false, requestController);
  }
}
