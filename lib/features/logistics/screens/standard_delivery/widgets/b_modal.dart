import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/b_section_title.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_backload_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_actions_row.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/backload_items_section.dart';
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

  /// Controller owning the form state this modal reads/writes. Defaults to
  /// [StandardDeliveryController]; Hotline Direct passes its own controller
  /// so validation reads the same form state the fields wrote to.
  final IDeliveryRequestController? requestController;

  const BModal({
    super.key,
    required this.requestModel,
    required this.config,
    this.requestController,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final bool isBackLoad = requestModel.status == BTexts.statusBackLoad;
    final controller =
        requestController ?? Get.find<StandardDeliveryController>();

    // Compute requestId once for reuse in children widgets
    final requestId =
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;

    // Preload cancel remarks for cancelled requests
    if (isCancelled) {
      controller.loadCancelRemarks(requestId);
    }

    // Preload BackLoad remarks for back-loaded requests
    if (isBackLoad) {
      Get.find<BackLoadController>().loadBackLoadRemarks(requestId);
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
        // Inventory items: show a compact 'View Items' button that opens
        // the full items page. Place this immediately after Document References
        // so it is always shown under that section.
        RequestActionsRow(requestModel: requestModel),
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
                const BSectionTitle('Cancel remarks'),
                BCancelRemarks(
                  remarks: remarks.remarks,
                  date: remarks.date,
                  user: remarks.userUpdated,
                ),
              ],
            );
          }),
        // Back Load Remarks Section
        if (isBackLoad)
          Obx(() {
            final blController = Get.find<BackLoadController>();
            final entries = blController.backLoadEntries;
            if (entries.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BSectionTitle('Back load remarks'),
                ...entries.map((entry) => BBackLoadRemarks(
                      remarks: entry.remarks,
                      dateReported: entry.dateReported,
                    )),
              ],
            );
          }),
        // Items backloaded at drop off (item-level, request completed
        // normally) — hides itself when none were recorded.
        if (requestModel.status == BTexts.statusDoneDelivery)
          BackloadItemsSection.readOnly(requestModel: requestModel),
        // Body with all sections (Request Info, Preparation Info, Delivery Info)
        RequestModalBody(
          requestModel: requestModel,
          requestController: controller,
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
