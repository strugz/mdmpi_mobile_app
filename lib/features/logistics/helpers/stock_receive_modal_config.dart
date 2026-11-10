import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Configuration resolved from (role, status) that drives the Stock Receive modal.
///
/// Mirrors [PullOutModalConfig], minus the "For Pull Out" step and the
/// Release dispatch step: Stock Receive is dispatched on the create form, so
/// the assigned Courier sets In Transit and completes with Taken Out.
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
  /// Stock Receive is dispatched at creation (trip ticket, driver, helper and
  /// vehicle are entered on the create form), so the assigned driver runs
  /// the whole flow and Release has no step.
  ///
  /// Status-Role Capability Matrix:
  /// | Status      | Request | Release | Courier         |
  /// |-------------|---------|---------|-----------------|
  /// | New Request | View    | View    | Set In Transit  |
  /// | In Transit  | View    | View    | Mark Taken Out  |
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

    // Only the Courier acts. The data manager validates the dispatch info
    // (falling back to what was saved on the request) before In Transit, and
    // released by, signature and proof image before Taken Out.
    if (role == BTexts.roleCourier) {
      if (status == BTexts.statusNewRequest) {
        return StockReceiveModalConfig(
          role: role,
          nextStatus: BTexts.statusInTransit,
          isActionVisible: true,
          buttonLabel: 'Set In Transit',
        );
      }
      if (status == BTexts.statusInTransit) {
        return StockReceiveModalConfig(
          role: role,
          nextStatus: BTexts.statusTakenOut,
          isActionVisible: true,
          buttonLabel: 'Mark Taken Out',
        );
      }
    }

    // Request, Release, Viewer and anything else: view only.
    return StockReceiveModalConfig.viewOnly(role: role);
  }
}
