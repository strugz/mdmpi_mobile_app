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

  /// Optional secondary transition (e.g. Pause while the primary action is
  /// Mark Taken Out). Rendered as an outlined button above the primary one.
  final String? secondaryNextStatus;

  /// Label for the secondary action button. Empty hides it.
  final String secondaryButtonLabel;

  const PullOutModalConfig({
    required this.role,
    this.nextStatus,
    this.isActionVisible = false,
    this.buttonLabel = '',
    this.validate,
    this.secondaryNextStatus,
    this.secondaryButtonLabel = '',
  });

  /// View-only config for any role.
  const PullOutModalConfig.viewOnly({required this.role})
      : nextStatus = null,
        isActionVisible = false,
        buttonLabel = '',
        validate = null,
        secondaryNextStatus = null,
        secondaryButtonLabel = '';

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
      // Release handles dispatch prep: New Request → For Pull Out, entering
      // the trip ticket, driver, helper, and vehicle (with validation).
      case BTexts.roleRelease:
        if (status == BTexts.statusNewRequest) {
          return PullOutModalConfig(
            role: role,
            nextStatus: BTexts.statusForPullOut,
            isActionVisible: true,
            buttonLabel: 'Set For Pull Out',
            validate: () => _validateForPullOutTransition(controller),
          );
        }
        return PullOutModalConfig.viewOnly(role: role);

      // ── Courier role ──────────────────────────────────────────────────
      // Courier confirms departure (For Pull Out → In Transit) and
      // completion (In Transit → Taken Out).
      case BTexts.roleCourier:
        if (status == BTexts.statusForPullOut) {
          return PullOutModalConfig(
            role: role,
            nextStatus: BTexts.statusInTransit,
            isActionVisible: true,
            buttonLabel: 'Set In Transit',
          );
        }
        if (status == BTexts.statusInTransit) {
          // Courier can pause an in-progress pull out to service a more
          // urgent one: the request returns to For Pull Out with its start
          // time cleared, and departing again ("Set In Transit") resumes it
          // with a fresh start time.
          return PullOutModalConfig(
            role: role,
            nextStatus: BTexts.statusTakenOut,
            isActionVisible: true,
            buttonLabel: 'Mark Taken Out',
            secondaryNextStatus: BTexts.statusForPullOut,
            secondaryButtonLabel: 'Pause (Back to For Pull Out)',
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

  /// Validates fields required before transitioning to For Pull Out.
  /// Returns `true` if validation passes; `false` to abort.
  static Future<bool> _validateForPullOutTransition(
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

