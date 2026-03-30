import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/inventory_items_page.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_body.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';
// ...existing code...

/// Modal widget that displays detailed information about a standard delivery request.
///
/// Driven by [StandardDeliveryModalConfig] to determine visibility and action behavior.
/// Composed of three separate widgets following the Pull Out modal pattern:
/// - [RequestModalHeader]: Client, address, status/preference chips, item category,
///   shipping method, delivery terms, delivery date, requested by
/// - [RequestModalBody]: Preparation info + trip ticket input
/// - [RequestModalFooter]: Delivery info form (driver/helper/mobile),
///   proof capture + delivery details section
class BModal extends StatelessWidget {
  final StandardDeliveryModel requestModel;
  final StandardDeliveryModalConfig config;

  const BModal({
    super.key,
    required this.requestModel,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final controller = Get.find<StandardDeliveryController>();

    // Compute requestId once for reuse in children widgets
    final requestId = requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;

    // Preload cancel remarks for cancelled requests
    if (isCancelled) {
      controller.loadCancelRemarks(
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID,
      );
    }

    return RequestModalScaffold(
      header: RequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      // Status-specific action button driven by config
      bottomAction: StatusActionButton(
        status: requestModel.status,
        onPressed: () async {
          // Legacy onAction callback takes precedence
          if (config.onAction != null) {
            config.onAction!();
            return;
          }
          if (config.nextStatus != null) {
            // Run optional validator first
            if (config.validate != null) {
              final valid = await config.validate!();
              if (!valid) return;
            }
            final userInitial = controller.userController.user.value.initial;
            await controller.updateRequestStatus(
                requestModel, config.nextStatus!, userInitial);
          }
        },
        isVisible: config.isActionVisible,
        statusToTextMapper: (status) => config.buttonLabel,
      ),
      children: [
        // Cancel Remarks Section
        if (isCancelled)
          Obx(() {
            final remarks = controller.cancelRemarks.value;
            if (remarks == null || remarks.remarks.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BTextDivider(text: 'Cancel Remarks'),
                BCancelRemarks(
                  remarks: remarks.remarks,
                  date: remarks.date,
                  user: remarks.userUpdated,
                ),
              ],
            );
          }),
        // Body with all sections (Request Info, Preparation Info, Delivery Info)
        RequestModalBody(
          requestModel: requestModel,
          requestController: controller,
        ),
        // Inventory items: show a compact 'View Items' button that opens
        // the full items page. The actual items are loaded by the
        // InventoryItemsPage to keep the modal lightweight.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View Items'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Get.to(() => InventoryItemsPage(requestId: requestId));
              },
            ),
          ),
        ),
        // Footer with proof capture and delivery details
        RequestModalFooter(
          requestModel: requestModel,
          requestController: controller,
        ),
      ],
    );
  }
}
