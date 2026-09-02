import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Abstract interface for controllers whose requests use the Pull Out modal
/// widgets (PullOutModalBody / PullOutRequestModalFooter).
///
/// Both PullOutController and StockReceiveController implement this interface
/// so the shared modal widgets bind their inputs (trip ticket, driver, vehicle,
/// released by, signature) to the same form state that the module's own
/// validator and update payload read. Mirrors [IDeliveryRequestController],
/// which serves the same purpose for the Standard Delivery / Hotline Direct
/// modal.
abstract class IPullOutRequestController {
  /// Encapsulates all form-related state (text controllers, signature bytes).
  PullOutFormState get formState;

  /// Cancellation remarks for the currently viewed request.
  Rx<CancelRemarksModel?> get cancelRemarks;

  /// Updates the request status, merging UI inputs from [formState].
  Future<void> updateStatusWithInputs(PullOutModel request, String newStatus);

  /// Sets the receiver's signature captured in the modal.
  void setSignature(Uint8List? signature);

  /// Fetches cancellation remarks for a specific request.
  Future<void> loadCancelRemarks(String requestId);
}
