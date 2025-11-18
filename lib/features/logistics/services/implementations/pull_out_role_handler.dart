import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

abstract class PullOutActionHandler {
  void handleAction(
    BuildContext context,
    PullOutModel request,
    PullOutController controller,
    UserController userController,
    String userInitial,
  );
}

class PullOutRequestRoleHandler extends PullOutActionHandler {
  @override
  void handleAction(BuildContext context, PullOutModel request, PullOutController controller,
      UserController userController, String userInitial) {
    if (request.requestStatus == 'New Request') {
      BFullScreenLoader.showPullOutDialog(context, request, () async {
        await controller.updatePullOut(request.copyWith(requestStatus: 'In Transit'));
      }, true);
    } else {
      BFullScreenLoader.showPullOutDialog(context, request, () {}, false);
    }
  }
}

class PullOutReleaseRoleHandler extends PullOutActionHandler {
  @override
  void handleAction(BuildContext context, PullOutModel request, PullOutController controller,
      UserController userController, String userInitial) {
    if (request.requestStatus == 'In Transit') {
      BFullScreenLoader.showPullOutDialog(context, request, () async {
        await controller.updatePullOut(request.copyWith(requestStatus: 'Taken Out'));
      }, true);
    } else if (request.requestStatus == 'New Request') {
      BFullScreenLoader.showPullOutDialog(context, request, () async {
        await controller.updatePullOut(request.copyWith(requestStatus: 'In Transit'));
      }, true);
    } else {
      BFullScreenLoader.showPullOutDialog(context, request, () {}, false);
    }
  }
}

class PullOutCourierRoleHandler extends PullOutActionHandler {
  @override
  void handleAction(BuildContext context, PullOutModel request, PullOutController controller,
      UserController userController, String userInitial) {
    BFullScreenLoader.showPullOutDialog(context, request, () {}, false);
  }
}

class PullOutViewerRoleHandler extends PullOutActionHandler {
  @override
  void handleAction(BuildContext context, PullOutModel request, PullOutController controller,
      UserController userController, String userInitial) {
    BFullScreenLoader.showPullOutDialog(context, request, () {}, false);
  }
}

class PullOutDefaultHandler extends PullOutActionHandler {
  @override
  void handleAction(BuildContext context, PullOutModel request, PullOutController controller,
      UserController userController, String userInitial) {
    BFullScreenLoader.showPullOutDialog(context, request, () {}, false);
  }
}
