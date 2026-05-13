import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_backload_remarks.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/backload_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_view_items_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_body.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer_actions.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_modal_config.dart';

/// Full-screen Standard Delivery page.
class StandardDeliveryPage extends StatelessWidget {
  final StandardDeliveryModel requestModel;
  final StandardDeliveryModalConfig config;

  const StandardDeliveryPage({
    super.key,
    required this.requestModel,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;
    final bool isBackLoad = requestModel.status == BTexts.statusBackLoad;
    final controller = Get.find<StandardDeliveryController>();
    final requestId =
        requestModel.id.isNotEmpty ? requestModel.id : requestModel.requestID;

    if (isCancelled) {
      controller.loadCancelRemarks(requestId);
    }

    if (isBackLoad) {
      Get.find<BackLoadController>().loadBackLoadRemarks(requestId);
    }

    return Scaffold(
      backgroundColor: dark ? BColors.black : BColors.light,
      appBar: BAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Navigator.of(context).pop(),
        title: Text("Delivery Details",
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RequestModalScaffold(
              header: RequestModalHeader(requestModel: requestModel),
              documentReferences: requestModel.documentReference,
              children: [
                BViewItemsButton(requestId: requestId),
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
                if (isBackLoad)
                  Obx(() {
                    final blController = Get.find<BackLoadController>();
                    final entries = blController.backLoadEntries;
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BTextDivider(text: 'Back Load Remarks'),
                        ...entries.map((entry) => BBackLoadRemarks(
                              remarks: entry.remarks,
                              dateReported: entry.dateReported,
                            )),
                      ],
                    );
                  }),
                RequestModalBody(
                    requestModel: requestModel,
                    requestController: controller),
                RequestModalFooter(
                    requestModel: requestModel,
                    requestController: controller),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: RequestModalFooterActions(
        requestModel: requestModel,
        controller: controller,
        config: config,
      ),
    );
  }
}


