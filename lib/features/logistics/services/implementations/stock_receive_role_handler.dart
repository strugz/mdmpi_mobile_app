import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Abstract base class for Stock Receive action handlers.
/// Defines the interface for handling user actions on Stock Receive requests.
abstract class StockReceiveActionHandler {
  /// Handle the action for a Stock Receive request based on user role and request status.
  ///
  /// Parameters:
  /// - [context] Build context for showing dialogs
  /// - [request] The Stock Receive request to handle
  /// - [controller] The StockReceiveController instance (dynamic to avoid type issues)
  /// - [userController] The UserController for user data access
  /// - [userInitial] The initial/abbreviation of the current user
  void handleAction(
    BuildContext context,
    PullOutModel request,
    dynamic controller,
    UserController userController,
    String userInitial,
  );
}

/// Handler for "Request" role actions on Stock Receive requests.
class StockReceiveRequestRoleHandler extends StockReceiveActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PullOutModel request,
      dynamic controller,
      UserController userController,
      String userInitial) {
    if (request.requestStatus == BTexts.statusNewRequest) {
      BFullScreenLoader.showStockReceiveDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusInTransit);
      }, true);
    } else {
      BFullScreenLoader.showStockReceiveDialog(context, request, () {}, false);
    }
  }
}

/// Handler for "Release" role actions on Stock Receive requests.
class StockReceiveReleaseRoleHandler extends StockReceiveActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PullOutModel request,
      dynamic controller,
      UserController userController,
      String userInitial) {
    if (request.requestStatus == BTexts.statusInTransit) {
      BFullScreenLoader.showStockReceiveDialog(context, request, () async {
        await controller.updateStatusWithInputs(request, BTexts.statusTakenOut);
      }, true);
    } else if (request.requestStatus == BTexts.statusNewRequest) {
      BFullScreenLoader.showStockReceiveDialog(context, request, () async {
        await controller.updateStatusWithInputs(
            request, BTexts.statusInTransit);
      }, true);
    } else {
      BFullScreenLoader.showStockReceiveDialog(context, request, () {}, false);
    }
  }
}

/// Handler for "Courier" role actions on Stock Receive requests.
class StockReceiveCourierRoleHandler extends StockReceiveActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PullOutModel request,
      dynamic controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showStockReceiveDialog(context, request, () {}, false);
  }
}

/// Handler for "Viewer" role actions on Stock Receive requests.
class StockReceiveViewerRoleHandler extends StockReceiveActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PullOutModel request,
      dynamic controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showStockReceiveDialog(context, request, () {}, false);
  }
}

/// Default handler for Stock Receive requests when no specific role handler applies.
class StockReceiveDefaultHandler extends StockReceiveActionHandler {
  @override
  void handleAction(
      BuildContext context,
      PullOutModel request,
      dynamic controller,
      UserController userController,
      String userInitial) {
    BFullScreenLoader.showStockReceiveDialog(context, request, () {}, false);
  }
}
