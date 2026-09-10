
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/crew_assignment.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../base/utils/logger.dart';
import '../../../../../base/utils/local_storage/text_storage_service.dart';
import '../../../../../common/controllers/camera_controller.dart';
import '../../../controllers/request_transport_controller.dart';

class BActionButton extends StatelessWidget {
  const BActionButton({
    super.key,
    required this.requestController,
    required this.requestTransportController,
  });

  final IDeliveryRequestController requestController;
  final RequestTransportController requestTransportController;

  @override
  Widget build(BuildContext context) {
    logDebug('BActionButton build - requestController instance: ${requestController.hashCode}');

    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        bool isLoading = requestTransportController.isLoadingAction.value;
        // Watch currentSelectedRequest for reactive status updates
        final updatedRequest = requestController.currentSelectedRequest.value;

        logDebug('BActionButton rebuild - updatedRequest: ${updatedRequest?.status ?? "NULL"}');
        logDebug('BActionButton rebuild - controller instance: ${requestController.hashCode}');

        // If somehow null, use the static request as absolute fallback
        if (updatedRequest == null) {
          return const Text('Error: Request not found');
        }

        final String currentStatus = updatedRequest.status;
        logDebug('BActionButton currentStatus: $currentStatus');
        // Get the signature state
        final bool hasSignature =
            requestController.formState.receiverSignatureBytes.value != null;
        final bool hasReceiverName =
            requestController.formState.receiver.text.trim().isNotEmpty;

        // Use the actual stored picture path (TextStorageService or camera controller)
        final CameraHandlerController cameraController =
            Get.find<CameraHandlerController>();
        final textStorage = TextStorageService();

        final userController = Get.find<UserController>();

        // Dispatch / Drop Off belong to the assigned crew. Any other viewer
        // of this screen (e.g. a Release+Courier dispatcher who reached it
        // through another route) sees who is assigned instead of a button.
        if (!CrewAssignment.canOperate(updatedRequest,
            userInitial: userController.user.value.initial)) {
          final crew = CrewAssignment.describeCrew(updatedRequest);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              crew.isEmpty
                  ? 'No driver assigned yet. Only the assigned driver or helper can update this request.'
                  : 'Assigned to $crew. Only the assigned driver or helper can update this request.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  // VALIDATION START
                  if (currentStatus == BTexts.statusForDelivery) {
                    if (!hasReceiverName) {
                      BHelperFunctions.showSnackBar(
                          "Please enter the receiver's name.");
                      return;
                    }
                    // Validate signature
                    if (!hasSignature) {
                      BHelperFunctions.showSnackBar(
                          "Please capture the receiver's signature.");
                      return;
                    }

                    // Validate proof of delivery (min 1 photo). Check the
                    // multi-photo list first, then the legacy single path
                    // (camera or text storage).
                    final candidatePaths = <String>[
                      ...cameraController.imageProofPaths,
                      textStorage.getText('proofImagePath') ??
                          cameraController.imageProofPath.value,
                    ];

                    bool proofExists = false;
                    for (final path in candidatePaths) {
                      if (path.isEmpty) continue;
                      try {
                        if (await File(path).exists()) {
                          proofExists = true;
                          break;
                        }
                      } catch (_) {
                        // ignore unreadable path and keep checking
                      }
                    }

                    if (!proofExists) {
                      BHelperFunctions.showSnackBar(
                          "Please capture the delivery proof image.");
                      return;
                    }

                    // Every item marked for backload must carry a reason.
                    final missingBackloadRemarks = requestController
                        .formState.backloadItemRemarks.entries
                        .where((e) => e.value.trim().isEmpty)
                        .map((e) => e.key)
                        .toList();
                    if (missingBackloadRemarks.isNotEmpty) {
                      BHelperFunctions.showSnackBar(
                          "Please state a reason for each backloaded item: ${missingBackloadRemarks.join(', ')}.");
                      return;
                    }
                  }

                  await requestTransportController
                      .processRequestDispatchOrDropOff(
                    updatedRequest,
                    userController.user.value.initial,
                    requestController,
                  );

                  await requestController.loadRequests();
                },
          style: ElevatedButton.styleFrom(),
          child: isLoading
              ? const SizedBox(
                  height: 24.0,
                  width: 24.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  currentStatus == BTexts.statusItemPrepared
                      ? 'Dispatch'
                      : currentStatus == BTexts.statusForDelivery
                          ? 'Drop Off'
                          : 'Processing...',
                ),
        );
      }),
    );
  }
}
