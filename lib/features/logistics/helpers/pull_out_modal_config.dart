import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Configuration resolved from (role, status) that drives the Pull Out modal.
///
/// Replaces the handler classes with a single data object.
/// Carries everything the modal needs: role context, action visibility,
/// button label, next status, and an optional validator.
class PullOutModalConfig {
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

  const PullOutModalConfig({
    required this.role,
    this.nextStatus,
    this.isActionVisible = false,
    this.buttonLabel = '',
    this.validate,
  });

  /// View-only config for any role.
  const PullOutModalConfig.viewOnly({required this.role})
      : nextStatus = null,
        isActionVisible = false,
        buttonLabel = '',
        validate = null;

  // ========================================================================
  // FACTORY — single source of truth for (role, status) → config
  // ========================================================================

  /// Resolves the correct modal configuration given a [request] and [role].
  ///
  /// This replaces `PullOutRequestRoleHandler`, `PullOutReleaseRoleHandler`,
  /// `PullOutCourierRoleHandler`, `PullOutViewerRoleHandler`, and
  /// `PullOutDefaultHandler` with a single lookup.
  factory PullOutModalConfig.resolve({
    required PullOutModel request,
    required String role,
    required PullOutController controller,
  }) {
    final status = request.requestStatus;

    // Terminal / view-only statuses — any role
    if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'picked-up') {
      return PullOutModalConfig.viewOnly(role: role);
    }

    switch (role) {
      // ── Request role ──────────────────────────────────────────────────
      // Request role can only view, no actions allowed.
      case BTexts.roleRequest:
        return PullOutModalConfig.viewOnly(role: role);

      // ── Release role ──────────────────────────────────────────────────
      // Release role is view-only for Pull Out module.
      case BTexts.roleRelease:
        return PullOutModalConfig.viewOnly(role: role);

      // ── Courier role ──────────────────────────────────────────────────
      // Courier handles New Request → In Transit (with validation)
      // and In Transit → Taken Out
      case BTexts.roleCourier:
        if (status == BTexts.statusNewRequest) {
          return PullOutModalConfig(
            role: role,
            nextStatus: BTexts.statusInTransit,
            isActionVisible: true,
            buttonLabel: 'Set In Transit',
            validate: () => _validateInTransitTransition(controller),
          );
        }
        if (status == BTexts.statusInTransit) {
          return PullOutModalConfig(
            role: role,
            nextStatus: BTexts.statusTakenOut,
            isActionVisible: true,
            buttonLabel: 'Mark Taken Out',
          );
        }
        return PullOutModalConfig.viewOnly(role: role);

      // ── Viewer / default ──────────────────────────────────────────────
      default:
        return PullOutModalConfig.viewOnly(role: role);
    }
  }

  // ========================================================================
  // VALIDATION HELPERS (private, co-located with config)
  // ========================================================================

  /// Validates fields required before transitioning to In Transit.
  /// Returns `true` if validation passes; `false` to abort.
  static Future<bool> _validateInTransitTransition(
      PullOutController controller) async {
    final formState = controller.formState;
    return _validateDeliveryInfo(formState);
  }

  /// Validates trip ticket, driver, helper, and vehicle fields.
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

