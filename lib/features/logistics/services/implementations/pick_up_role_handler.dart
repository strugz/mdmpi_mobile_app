import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

abstract class PickUpActionHandler {
  void handleAction(
    BuildContext context,
    PickUpModel request,
    PickUpController controller,
    UserController userController,
    String userInitial,
  );
}

class PickUpRequestRoleHandler extends PickUpActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PickUpModel request,
      PickUpController controller,
      UserController userController,
      String userInitial) {
    if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showPickUpDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusItemPrepared);
      }, true);
    } else {
      BFullScreenLoader.showPickUpDialog(context, request, () {}, false);
    }
  }
}

class PickUpReleaseRoleHandler extends PickUpActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PickUpModel request,
      PickUpController controller,
      UserController userController,
      String userInitial) {

    if (request.status == BTexts.statusItemPrepared) {
      BFullScreenLoader.showPickUpDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusItemPacked);
      }, true);
    } else if (request.status == BTexts.statusGettingSuppliesReady) {
      BFullScreenLoader.showPickUpDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusItemPrepared);
      }, true);
    } else if (request.status == BTexts.statusItemPacked) {
      BFullScreenLoader.showPickUpDialog(context, request, () async {
        await controller.updateStatusWithInputs(request, BTexts.statusReceived);
      }, true);
    } else if (request.status == BTexts.statusNewRequest) {
      BFullScreenLoader.showPickUpDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusItemPrepared);
      }, true);
    } else {
      BFullScreenLoader.showPickUpDialog(context, request, () {}, false);
    }
  }
}

class PickUpCourierRoleHandler extends PickUpActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PickUpModel request,
      PickUpController controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showPickUpDialog(context, request, () {}, false);
  }
}

class PickUpViewerRoleHandler extends PickUpActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PickUpModel request,
      PickUpController controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showPickUpDialog(context, request, () {}, false);
  }
}

class PickUpDefaultHandler extends PickUpActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PickUpModel request,
      PickUpController controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showPickUpDialog(context, request, () {}, false);
  }
}
