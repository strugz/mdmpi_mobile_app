import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../base/utils/constants/sizes.dart';
import '../../../features/logistics/models/client_model.dart';

/// A hidden FormField widget that validates client selection.
///
/// This widget displays validation errors when no client is selected
/// and can be placed after [BClientInformation] in forms.
///
/// Example usage:
/// ```dart
/// const BClientInformation(),
/// BClientValidationField(
///   clientInformation: controller.formState.clientInformation,
/// ),
/// ```
class BClientValidationField extends StatelessWidget {
  /// Creates a client validation field.
  ///
  /// [clientInformation] - The reactive client information to validate.
  /// [errorMessage] - Custom error message when no client is selected.
  /// Defaults to 'Please select a client'.
  const BClientValidationField({
    super.key,
    required this.clientInformation,
    this.errorMessage = 'Please select a client',
  });

  /// The reactive client information to validate.
  final Rx<ClientModel?> clientInformation;

  /// The error message displayed when validation fails.
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final ClientModel? client = clientInformation.value;
        if (client == null || client.id.isEmpty) {
          return errorMessage;
        }
        return null;
      },
      builder: (FormFieldState<String> formFieldState) {
        return formFieldState.hasError
            ? Padding(
                padding: const EdgeInsets.only(left: BSizes.sm, top: 4.0),
                child: Text(
                  formFieldState.errorText ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}


