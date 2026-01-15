import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

/// Reusable cancel reason dialog.
///
/// Usage:
/// await CancelReasonDialog.show(context, (reason) async { /* call controller */ });
class CancelReasonDialog {
  static const List<String> _defaultReasons = [
    "Customer unavailable",
    "Customer refused delivery",
    "Not Accepted expiry",
    "Backload due to constraint",
    "Reroute",
    "Other (specify)",
  ];

  /// Shows the dialog and calls [onSubmit] with the selected reason when user submits.
  /// [onSubmit] may be sync or async; the dialog will await the returned future.
  static Future<void> show(BuildContext context, Future<void> Function(String reason) onSubmit,
      {List<String>? reasons}) async {
    final items = reasons ?? _defaultReasons;

    String? selectedTerm;
    final TextEditingController otherReasonController = TextEditingController();
    bool showOtherTextField = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
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
                      if (!showOtherTextField) otherReasonController.clear();
                    });
                  },
                  items: items.map<DropdownMenuItem<String>>((String value) {
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
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                onPressed: isSubmitEnabled
                    ? () async {
                        String finalReason;
                        if (selectedTerm == "Other (specify)") {
                          finalReason = otherReasonController.text.trim();
                          if (finalReason.isEmpty) {
                            BLoaders.warningSnackBar(title: 'Please enter a reason', message: 'Reason is required');
                            return;
                          }
                        } else if (selectedTerm != null) {
                          finalReason = selectedTerm!;
                        } else {
                          BLoaders.warningSnackBar(title: 'Please enter a reason', message: 'Reason is required');
                          return;
                        }

                        try {
                          await onSubmit(finalReason);
                        } catch (e) {
                          // onSubmit can show its own snackbars; swallow unexpected errors
                          BLoaders.errorSnackBar(title: 'Error', message: e.toString());
                        } finally {
                          Navigator.of(dialogContext).pop();
                        }
                      }
                    : null,
                child: const Text('Submit'),
              ),
            ],
          );
        });
      },
    );

    otherReasonController.dispose();
  }
}

