import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

import '../../../../controllers/standard_delivery_controller.dart';
import '../../../../models/standard_delivery_model.dart';

/// Small helper that shows dialogs used in the standard delivery flows.
class BDialog {
  /// Shows a dialog allowing the user to select a cancellation reason
  /// for [requestModel].
  ///
  /// The method resolves the controller via Get.find() (per DI conventions),
  /// keeps UI-local state in a StatefulBuilder, and disposes controllers
  /// after the dialog is dismissed.
  static Future<void> showRemarksDialog(
      BuildContext context, StandardDeliveryModel requestModel) async {
    const List<String> cancelledDeliveryTerms = [
      "Customer unavailable",
      "Customer refused delivery",
      "Not Accepted expiry",
      "Backload due to constraint",
      "Reroute",
      "Other (specify)",
    ];

    // Resolve controller outside the builder to follow DI rules.
    final requestController = Get.find<StandardDeliveryController>();

    String? selectedTerm;
    final TextEditingController otherReasonController = TextEditingController();
    bool showOtherTextField = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final bool isOther = selectedTerm == "Other (specify)";
            final bool isSubmitEnabled =
                selectedTerm != null && (!isOther || otherReasonController.text.trim().isNotEmpty);

            return AlertDialog(
              title: const Text('Select Reason'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Reason for cancellation",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedTerm,
                    hint: const Text("Select a reason"),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTerm = newValue;
                        showOtherTextField = newValue == "Other (specify)";
                        if (!showOtherTextField) {
                          otherReasonController.clear();
                        }
                      });
                    },
                    items: cancelledDeliveryTerms
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  if (showOtherTextField)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                        controller: otherReasonController,
                        decoration: const InputDecoration(
                          labelText: "Specify other reason",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  // Disable the button when input is invalid by setting onPressed to null.
                  onPressed: isSubmitEnabled
                      ? () {
                          String finalReason;
                          if (selectedTerm == "Other (specify)") {
                            finalReason = otherReasonController.text.trim();
                            if (finalReason.isEmpty) {
                              BLoaders.warningSnackBar(
                                  title: 'Please enter a reason',
                                  message: 'Reason is required');
                              return;
                            }
                            requestController.updateRequestForCancellation(
                                requestModel, finalReason);
                          } else if (selectedTerm != null) {
                            finalReason = selectedTerm!;
                            requestController.updateRequestForCancellation(
                                requestModel, finalReason);
                          } else {
                            BLoaders.warningSnackBar(
                                title: 'Please enter a reason',
                                message: 'Reason is required');
                            return;
                          }

                          Navigator.of(dialogContext).pop(); // Close the dialog
                        }
                      : null,
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dispose controller after dialog is dismissed to avoid leaks.
    otherReasonController.dispose();
  }
}
