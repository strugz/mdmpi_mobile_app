
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
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
/// Allows full status progression: New Request → Getting Supplies Ready → Item Packed → Endorsed to Guard / Received / For Dispatch.
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

        // Validate that a status is selected
        if (selectedStatus.isEmpty) {
          BLoaders.errorSnackBar(
            title: 'Validation Error',
            message: 'Please select a status',
          );
          return;
        }

        if (selectedStatus == 'Endorsed to Guard') {
          // Validate Guard Name
          if (controller.formState.receivedByController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please enter Guard Name',
            );
            return;
          }

          // Validate Guard Signature
          if (controller.formState.receiverSignatureBytes.value == null ||
              controller.formState.receiverSignatureBytes.value!.isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please capture Guard Signature',
            );
            return;
          }

          await controller.updateStatusWithInputs(
              request, BTexts.statusEndorsedToGuard);
        } else if (selectedStatus == 'Received') {
          // Validate Receiver Name
          if (controller.formState.receivedByController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please enter Receiver Name',
            );
            return;
          }

          // Validate Waybill Number
          if (controller.formState.waybillNumberController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please enter Waybill Number',
            );
            return;
          }

          // Validate Receiver Signature
          if (controller.formState.receiverSignatureBytes.value == null ||
              controller.formState.receiverSignatureBytes.value!.isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please capture Receiver Signature',
            );
            return;
          }

          await controller.updateStatusWithInputs(
              request, BTexts.statusReceived);
        } else if (selectedStatus == BTexts.statusForDispatch) {
          // Validate Trip Ticket Number
          if (controller.formState.tripTicketController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please enter Trip Ticket Number',
            );
            return;
          }

          // Validate Driver
          if (controller.formState.driverController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please select Driver',
            );
            return;
          }

          // Validate Helper
          if (controller.formState.helperController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please select Helper',
            );
            return;
          }

          // Validate Vehicle
          if (controller.formState.vehicleController.text.trim().isEmpty) {
            BLoaders.errorSnackBar(
              title: 'Validation Error',
              message: 'Please select Vehicle',
            );
            return;
          }

          await controller.updateStatusWithInputs(
              request, BTexts.statusForDispatch);
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
/// Handles For Dispatch → Dispatch (accept) and Dispatch → Drop Off (deliver).
class AirSeaCourierRoleHandler extends AirSeaActionHandler {
  @override
  void handleAction(
      BuildContext context,
      AirSeaModel request,
      AirSeaController controller,
      UserController userController,
      String userInitial) {
    if (request.status == BTexts.statusForDispatch) {
      BFullScreenLoader.showAirSeaDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusDispatch);
      }, true);
    } else if (request.status == BTexts.statusDispatch) {
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
