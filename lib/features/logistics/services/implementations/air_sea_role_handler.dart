
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Abstract base class for Air/Sea action handlers.
/// Defines the contract for role-specific action handling.
abstract class AirSeaActionHandler {
  void handleAction(
    BuildContext context,
    AirSeaModel request,
    AirSeaController controller,
    UserController userController,
    String userInitial,
  );
}

/// Handler for users with Request role.
/// Allows marking items as preparing from New Request status.
class AirSeaRequestRoleHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusGettingSuppliesReady);
      }, true);
    } else {
      BFullScreenLoader.showAirSeaDialog(context, request, () {}, false);
    }
  }
}

/// Handler for users with Release role.
/// Allows full status progression: New Request → Getting Supplies Ready → Item Packed → Endorsed to Guard → Received.
class AirSeaReleaseRoleHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusGettingSuppliesReady);
      }, true);
    } else if (request.status == BTexts.statusGettingSuppliesReady) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusItemPacked);
      }, true);
    } else if (request.status == BTexts.statusItemPacked) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        final selectedStatus = controller.formState.endorsedToController.text;
        if (selectedStatus == 'Endorsed to Guard') {
          await controller.updateStatusWithInputs(
              request, BTexts.statusEndorsedToGuard);
        } else if (selectedStatus == 'Received') {
          await controller.updateStatusWithInputs(
              request, BTexts.statusReceived);
        } else if (selectedStatus == BTexts.statusDispatch) {
          await controller.updateStatusWithInputs(
              request, BTexts.statusDispatch);
        }
      }, true);
    } else if (request.status == BTexts.statusEndorsedToGuard) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(request, BTexts.statusReceived);
      }, true);
    } else {
      BFullScreenLoader.showAirSeaDialog(context, request, () {}, false);
    }
  }
}

/// Handler for users with Courier role.
/// View-only access to Air/Sea requests.
class AirSeaCourierRoleHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    if (request.status == BTexts.statusDispatch) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(request, BTexts.statusDropOff);
      }, true);
    } else {
      BFullScreenLoader.showAirSeaDialog(context, request, () {}, false);
    }
  }
}

/// Handler for users with Viewer role.
/// View-only access to Air/Sea requests.
class AirSeaViewerRoleHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showAirSeaDialog(context, request, () {}, false);
  }
}

/// Default handler for completed or cancelled requests.
/// Provides view-only access regardless of user role.
class AirSeaDefaultHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showAirSeaDialog(context, request, () {}, false);
  }
}
