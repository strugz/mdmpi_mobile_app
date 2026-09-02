import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Configuration resolved from (role, status) that drives the Stock Receive modal.
///
/// Mirrors [PullOutModalConfig], minus the "For Pull Out" step: Stock Receive
/// is for receiving items, so Release dispatches straight to In Transit and
/// Courier completes with Taken Out.
class StockReceiveModalConfig {
  /// The resolved user role driving this modal instance.
  final String role;

  /// The status the request will transition to when the action button is pressed.
  /// Null when the modal is view-only.
  final String? nextStatus;

  /// Whether the action button is visible.
  final bool isActionVisible;

  /// Label shown on the action button (e.g., "Set In Transit").
  /// Empty string hides the button.
  final String buttonLabel;

  /// Optional async validator called *before* the status transition.
  /// Returns `true` if validation passes; `false` to abort.
  final Future<bool> Function()? validate;

  const StockReceiveModalConfig({
    required this.role,
    this.nextStatus,
    this.isActionVisible = false,
    this.buttonLabel = '',
    this.validate,
  });

  /// View-only config for any role.
  const StockReceiveModalConfig.viewOnly({required this.role})
      : nextStatus = null,
        isActionVisible = false,
        buttonLabel = '',
        validate = null;

  // ========================================================================
  // FACTORY — single source of truth for (role, status) → config
  // ========================================================================

  /// Resolves the correct modal configuration given a [request] and [role].
  ///
  /// Status-Role Capability Matrix:
  /// | Status      | Request | Release        | Courier         |
  /// |-------------|---------|----------------|-----------------|
  /// | New Request | View    | Set In Transit | View            |
  /// | In Transit  | View    | View           | Mark Taken Out  |
  /// | Taken Out / Cancelled / Picked-up: all roles view-only.
  factory StockReceiveModalConfig.resolve({
    required PullOutModel request,
    required String role,
    required StockReceiveController controller,
  }) {
    final status = request.requestStatus;

    // Terminal / view-only statuses — any role
    if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'picked-up') {
      return StockReceiveModalConfig.viewOnly(role: role);
    }

    switch (role) {
      // ── Request role ──────────────────────────────────────────────────
      // Request role can only view, no actions allowed.
      case BTexts.roleRequest:
        return StockReceiveModalConfig.viewOnly(role: role);

      // ── Release role ──────────────────────────────────────────────────
      // Release handles dispatch prep: New Request → In Transit, entering
      // the trip ticket, driver, helper, and vehicle (with validation).
      case BTexts.roleRelease:
        if (status == BTexts.statusNewRequest) {
          return StockReceiveModalConfig(
            role: role,
            nextStatus: BTexts.statusInTransit,
            isActionVisible: true,
            buttonLabel: 'Set In Transit',
            validate: () async => _validateDeliveryInfo(controller.formState),
          );
        }
        return StockReceiveModalConfig.viewOnly(role: role);

      // ── Courier role ──────────────────────────────────────────────────
      // Courier confirms completion (In Transit → Taken Out); the data
      // manager validates released by, signature, and proof image.
      case BTexts.roleCourier:
        if (status == BTexts.statusInTransit) {
          return StockReceiveModalConfig(
            role: role,
            nextStatus: BTexts.statusTakenOut,
            isActionVisible: true,
            buttonLabel: 'Mark Taken Out',
          );
        }
        return StockReceiveModalConfig.viewOnly(role: role);

      // ── Viewer / default ──────────────────────────────────────────────
      default:
        return StockReceiveModalConfig.viewOnly(role: role);
    }
  }

  // ========================================================================
  // VALIDATION HELPERS (private, co-located with config)
  // ========================================================================

  /// Validates trip ticket, driver, and vehicle fields before dispatch.
  static bool _validateDeliveryInfo(PullOutFormState formState) {
    if (formState.tripTicketController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Trip Ticket Number',
      );
      return false;
    }
    if (formState.driverController.text.trim().isEmpty) {
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
