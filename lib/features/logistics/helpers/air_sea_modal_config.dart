import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

/// Configuration resolved from (role, status) that drives the Air/Sea modal.
///
/// Replaces the 5 `AirSeaActionHandler` subclasses with a single data object.
/// Carries everything the modal needs: role context, action visibility,
/// button label, next status, and an optional validator.
class AirSeaModalConfig {
  /// The resolved user role driving this modal instance.
  final String role;

  /// The status the request will transition to when the action button is pressed.
  /// Null when the modal is view-only.
  final String? nextStatus;

  /// Whether the action button is visible.
  final bool isActionVisible;

  /// Label shown on the action button (e.g., "Mark Preparing").
  /// Empty string hides the button.
  final String buttonLabel;

  /// Optional async validator called *before* the status transition.
  /// Returns `true` if validation passes; `false` to abort.
  final Future<bool> Function()? validate;

  const AirSeaModalConfig({
    required this.role,
    this.nextStatus,
    this.isActionVisible = false,
    this.buttonLabel = '',
    this.validate,
  });

  /// View-only config for any role.
  const AirSeaModalConfig.viewOnly({required this.role})
      : nextStatus = null,
        isActionVisible = false,
        buttonLabel = '',
        validate = null;

  // ========================================================================
  // FACTORY — single source of truth for (role, status) → config
  // ========================================================================

  /// Resolves the correct modal configuration given a [request] and [role].
  ///
  /// This replaces `AirSeaRequestRoleHandler`, `AirSeaReleaseRoleHandler`,
  /// `AirSeaCourierRoleHandler`, `AirSeaViewerRoleHandler`, and
  /// `AirSeaDefaultHandler` with a single lookup.
  factory AirSeaModalConfig.resolve({
    required AirSeaModel request,
    required String role,
    required AirSeaController controller,
  }) {
    final status = request.status;

    // Terminal / view-only statuses — any role
    if (status.toLowerCase() == 'cancelled' ||
        status == BTexts.statusProvincialDelivered) {
      return AirSeaModalConfig.viewOnly(role: role);
    }

    // Provincial statuses — only actionable by Provincial role
    if (status == BTexts.statusReceived ||
        status == BTexts.statusDropOff ||
        status == BTexts.statusProvincialPickUp ||
        status == BTexts.statusProvincialInTransit) {
      if (role == BTexts.roleProvincial) {
        return _resolveProvincial(status, role, controller);
      }
      return AirSeaModalConfig.viewOnly(role: role);
    }

    switch (role) {
      // ── Request role ──────────────────────────────────────────────────
      // Request role can only CREATE requests; viewing existing requests
      // is always read-only (no status transitions).
      case BTexts.roleRequest:
        return AirSeaModalConfig.viewOnly(role: role);

      // ── Release role ──────────────────────────────────────────────────
      case BTexts.roleRelease:
        if (status == BTexts.statusNewRequest) {
          return AirSeaModalConfig(
            role: role,
            nextStatus: BTexts.statusGettingSuppliesReady,
            isActionVisible: true,
            buttonLabel: 'Mark Preparing',
          );
        }
        if (status == BTexts.statusGettingSuppliesReady) {
          return AirSeaModalConfig(
            role: role,
            nextStatus: BTexts.statusItemPacked,
            isActionVisible: true,
            buttonLabel: 'Mark Item Packed',
          );
        }
        if (status == BTexts.statusItemPacked) {
          // Next status is determined by the dropdown selection inside
          // `AirSeaItemPackedSection`. Validation + status resolution
          // happen in the validate callback.
          return AirSeaModalConfig(
            role: role,
            nextStatus: null, // resolved dynamically
            isActionVisible: true,
            buttonLabel: 'Proceed',
            validate: () => _validateItemPackedTransition(controller),
          );
        }
        if (status == BTexts.statusEndorsedToGuard) {
          return AirSeaModalConfig(
            role: role,
            nextStatus: BTexts.statusReceived,
            isActionVisible: true,
            buttonLabel: 'Mark Received',
          );
        }
        return AirSeaModalConfig.viewOnly(role: role);

      // ── Courier role ──────────────────────────────────────────────────
      case BTexts.roleCourier:
        if (status == BTexts.statusForDispatch) {
          return AirSeaModalConfig(
            role: role,
            nextStatus: BTexts.statusDispatch,
            isActionVisible: true,
            buttonLabel: 'Dispatch',
          );
        }
        if (status == BTexts.statusDispatch) {
          return AirSeaModalConfig(
            role: role,
            nextStatus: BTexts.statusDropOff,
            isActionVisible: true,
            buttonLabel: 'Mark Drop Off',
          );
        }
        return AirSeaModalConfig.viewOnly(role: role);

      // ── Viewer / default ──────────────────────────────────────────────
      default:
        return AirSeaModalConfig.viewOnly(role: role);
    }
  }

  // ========================================================================
  // VALIDATION HELPERS (private, co-located with config)
  // ========================================================================

  /// Validates the "Item Packed" → dynamic-next-status transition.
  /// The user picks Endorsed to Guard / Received / For Dispatch from a dropdown.
  /// Returns `true` and sets `nextStatus` on success; shows error + returns
  /// `false` on failure.
  static Future<bool> _validateItemPackedTransition(
      AirSeaController controller) async {
    final formState = controller.formState;
    final selectedStatus = formState.endorsedToController.text;

    if (selectedStatus.isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select a status',
      );
      return false;
    }

    if (selectedStatus == 'Endorsed to Guard') {
      return _validateEndorsedToGuard(formState);
    } else if (selectedStatus == 'Received') {
      return _validateReceived(formState);
    } else if (selectedStatus == BTexts.statusForDispatch) {
      return _validateForDispatch(formState);
    }

    return false;
  }

  static bool _validateEndorsedToGuard(AirSeaFormState formState) {
    if (formState.receivedByController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Guard Name',
      );
      return false;
    }
    if (formState.receiverSignatureBytes.value == null ||
        formState.receiverSignatureBytes.value!.isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture Guard Signature',
      );
      return false;
    }
    return true;
  }

  static bool _validateReceived(AirSeaFormState formState) {
    if (formState.receivedByController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Receiver Name',
      );
      return false;
    }
    if (formState.waybillNumberController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter Waybill Number',
      );
      return false;
    }
    if (formState.receiverSignatureBytes.value == null ||
        formState.receiverSignatureBytes.value!.isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture Receiver Signature',
      );
      return false;
    }
    return true;
  }

  static bool _validateForDispatch(AirSeaFormState formState) {
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
    if (formState.helperController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Helper',
      );
      return false;
    }
    if (formState.vehicleController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select Vehicle',
      );
      return false;
    }
    return true;
  }

  // ========================================================================
  // PROVINCIAL ROLE CONFIG
  // ========================================================================

  /// Resolves modal config for the Provincial role based on current status.
  static AirSeaModalConfig _resolveProvincial(
      String status, String role, AirSeaController controller) {
    if (status == BTexts.statusReceived || status == BTexts.statusDropOff) {
      return AirSeaModalConfig(
        role: role,
        nextStatus: BTexts.statusProvincialPickUp,
        isActionVisible: true,
        buttonLabel: 'Confirm Pick Up',
        validate: () => _validateProvincialPickUp(controller.formState),
      );
    }
    if (status == BTexts.statusProvincialPickUp) {
      return AirSeaModalConfig(
        role: role,
        nextStatus: BTexts.statusProvincialInTransit,
        isActionVisible: true,
        buttonLabel: 'Start Transit',
      );
    }
    if (status == BTexts.statusProvincialInTransit) {
      return AirSeaModalConfig(
        role: role,
        nextStatus: BTexts.statusProvincialDelivered,
        isActionVisible: true,
        buttonLabel: 'Confirm Delivery',
        validate: () => _validateProvincialDelivery(controller.formState),
      );
    }
    return AirSeaModalConfig.viewOnly(role: role);
  }

  /// Validates provincial pick-up confirmation: requires pick-up proof image.
  static Future<bool> _validateProvincialPickUp(
      AirSeaFormState formState) async {
    if (formState.cameraPickUpPicture.value.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture or attach pick-up proof image',
      );
      return false;
    }
    return true;
  }

  /// Validates start transit: requires pick-up proof image exists before starting transit.
  static Future<bool> _validateProvincialStartTransit(
      AirSeaFormState formState) async {
    if (formState.cameraPickUpPicture.value.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Cannot start transit without pick-up proof image',
      );
      return false;
    }
    return true;
  }

  /// Validates provincial delivery: delivered-to is required, signature and proof image required.
  static Future<bool> _validateProvincialDelivery(
      AirSeaFormState formState) async {
    if (formState.provincialDeliveredToController.text.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter the client contact person name',
      );
      return false;
    }
    if (formState.receiverSignatureBytes.value == null ||
        formState.receiverSignatureBytes.value!.isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture recipient signature',
      );
      return false;
    }
    if (formState.cameraDropOffPicture.value.trim().isEmpty) {
      BLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please capture proof image for delivery',
      );
      return false;
    }
    return true;
  }
}
