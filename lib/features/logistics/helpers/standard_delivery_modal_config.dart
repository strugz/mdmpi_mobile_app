import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/request_transport.dart';

/// Configuration resolved from (role, status) that drives the Standard Delivery modal.
///
/// Replaces the handler classes with a single data object.
/// Carries everything the modal needs: role context, action visibility,
/// button label, next status, an optional validator, and an optional
/// custom navigation callback for the Courier transport screen.
///
/// Mirrors [PullOutModalConfig] for consistency across modules.
class StandardDeliveryModalConfig {
  /// The resolved user role driving this modal instance.
  final String role;

  /// The status the request will transition to when the action button is pressed.
  /// Null when the modal is view-only.
  final String? nextStatus;

  /// Whether the action button is visible.
  final bool isActionVisible;

  /// Label shown on the action button (e.g., "Prepare Item").
  final String buttonLabel;

  /// Optional async validator called *before* the status transition.
  /// Returns `true` if validation passes; `false` to abort.
  final Future<bool> Function()? validate;

  /// Optional custom navigation callback instead of showing the modal.
  /// When non-null, the tap handler should invoke this instead of showing
  /// the standard modal dialog. Used for Courier → RequestTransport screen.
  final void Function(BuildContext context)? navigateTo;

  /// Optional legacy action callback. When provided, overrides the default
  /// nextStatus-based action in BModal. Used for backward compatibility
  /// with hotline direct role handlers.
  final VoidCallback? onAction;

  const StandardDeliveryModalConfig({
    required this.role,
    this.nextStatus,
    this.isActionVisible = false,
    this.buttonLabel = '',
    this.validate,
    this.navigateTo,
    this.onAction,
  });

  /// View-only config for any role.
  const StandardDeliveryModalConfig.viewOnly({required this.role})
      : nextStatus = null,
        isActionVisible = false,
        buttonLabel = '',
        validate = null,
        navigateTo = null,
        onAction = null;

  // ========================================================================
  // FACTORY — single source of truth for (role, status) → config
  // ========================================================================

  /// Resolves the correct modal configuration given a [request] and [role].
  ///
  /// This replaces `RequestRoleHandler`, `ReleaseRoleHandler`,
  /// `CourierRoleHandler`, `ViewerRoleHandler`, and `DefaultRequestHandler`.
  factory StandardDeliveryModalConfig.resolve({
    required StandardDeliveryModel request,
    required String role,
    required StandardDeliveryController controller,
  }) {
    final status = request.status;
    final userInitial = controller.userController.user.value.initial;

    // Terminal / view-only statuses — any role
    if (status == BTexts.statusDoneDelivery ||
        status == BTexts.statusCancelled) {
      return StandardDeliveryModalConfig.viewOnly(role: role);
    }

    switch (role) {
      // ── Request role ──────────────────────────────────────────────────
      // Request role is view-only for Standard Delivery.
      case BTexts.roleRequest:
        return StandardDeliveryModalConfig.viewOnly(role: role);

      // ── Release role ──────────────────────────────────────────────────
      case BTexts.roleRelease:
        if (status == BTexts.statusNewRequest) {
          return StandardDeliveryModalConfig(
            role: role,
            nextStatus: BTexts.statusGettingSuppliesReady,
            isActionVisible: true,
            buttonLabel: BTexts.requestModalPrepareItemButtonText,
          );
        }
        if (status == BTexts.statusGettingSuppliesReady &&
            request.itemPreparedBy == userInitial) {
          return StandardDeliveryModalConfig(
            role: role,
            nextStatus: BTexts.statusItemPrepared,
            isActionVisible: true,
            buttonLabel: BTexts.requestModalPackedAndReadyButtonText,
            validate: () async =>
                _validateDeliveryInfo(controller.formState),
          );
        }
        // Getting supplies ready but different preparer — view only
        return StandardDeliveryModalConfig.viewOnly(role: role);

      // ── Courier role ──────────────────────────────────────────────────
      case BTexts.roleCourier:
        if (status == BTexts.statusItemPrepared) {
          return StandardDeliveryModalConfig(
            role: role,
            isActionVisible: false,
            navigateTo: (context) => Get.to(
              () => RequestTransport(
                request: request,
                requestController: controller,
              ),
            ),
          );
        }
        if (status == BTexts.statusForDelivery &&
            (request.deliveredBy == userInitial ||
                request.helper == userInitial)) {
          return StandardDeliveryModalConfig(
            role: role,
            isActionVisible: false,
            navigateTo: (context) => Get.to(
              () => RequestTransport(
                request: request,
                requestController: controller,
              ),
            ),
          );
        }
        // For Delivery but not assigned driver/helper — view only
        return StandardDeliveryModalConfig.viewOnly(role: role);

      // ── Viewer / Admin / default ──────────────────────────────────────
      default:
        return StandardDeliveryModalConfig.viewOnly(role: role);
    }
  }

  // ========================================================================
  // VALIDATION HELPERS (private, co-located with config)
  // ========================================================================

  /// Validates trip ticket, driver, and vehicle fields
  /// before transitioning to Item Prepared.
  static bool _validateDeliveryInfo(StandardDeliveryFormState formState) {
    if (formState.tripTicketNumber.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Trip Ticket Number',
      );
      return false;
    }
    if (formState.selectedDriver.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Driver',
      );
      return false;
    }
    if (formState.mobile.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Vehicle',
      );
      return false;
    }
    return true;
  }
}


