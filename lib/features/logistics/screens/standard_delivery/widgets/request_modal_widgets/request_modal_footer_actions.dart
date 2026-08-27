import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_modal_config.dart';

/// Sticky actions shown at the bottom of the modal. Extracted so action
/// buttons can be pinned while the rest of the footer remains scrollable.
class RequestModalFooterActions extends StatelessWidget {
  const RequestModalFooterActions({
    super.key,
    required this.requestModel,
    required this.controller,
    required this.config,
  });

  final StandardDeliveryModel requestModel;
  final StandardDeliveryController controller;
  final StandardDeliveryModalConfig config;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        child: StatusActionButton(
          status: requestModel.status,
          onPressed: () async {
            if (config.onAction != null) {
              config.onAction!();
              return;
            }
            if (config.nextStatus != null) {
              if (config.validate != null) {
                final valid = await config.validate!();
                if (!valid) return;
              }
              final userInitial = controller.userController.user.value.initial;
              await controller.updateRequestStatus(requestModel, config.nextStatus!, userInitial);
            }
          },
          isVisible: config.isActionVisible,
          statusToTextMapper: (status) => config.buttonLabel,
        ),
      ),
    );
  }
}

