import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_document_reference_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';

import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart'; // Adjust path if necessary

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/request_image_dialog.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_cancel_remarks_loader.dart';

class BModal extends StatelessWidget {
  final StandardDeliveryModel requestModel;
  final VoidCallback onPressed;
  final bool status;

  const BModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.status = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;
    final bool isDoneDelivery =
        requestModel.status == BTexts.statusDoneDelivery;
    final bool isCancelled = requestModel.status == BTexts.statusCancelled;

    /// Request Details
    return BRoundedContainer(
      backgroundColor: dark ? BColors.black : BColors.light,
      radius: 0,
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RequestModalHeader(requestModel: requestModel),
                const SizedBox(height: BSizes.xs),
                const Divider(),
                const SizedBox(height: BSizes.xs),
                DocumentReferenceList(
                  documentReferences: requestModel.documentReference,
                  textColor: textColor,
                ),
                const Divider(),
                const SizedBox(height: BSizes.spaceBtwSections),
                if (isDoneDelivery)
                  Center(
                    child: BProductTitleText(
                        title: "Received By: ${requestModel.receiver}",
                        maxLines: 2,
                        smallSize: true,
                        fontColor: dark ? BColors.light : BColors.black),
                  ),
                if (isDoneDelivery)
                  CapturedSignatureImage(requestId: requestModel.id),
                const SizedBox(height: BSizes.xs),
                if (isDoneDelivery)
                  ViewDeliveredItemButton(
                    textColor: textColor,
                    onPressed: () {
                      final requestIdForDb = requestModel.id.isNotEmpty
                          ? requestModel.id
                          : requestModel.requestID;
                      showRequestImageDialog(
                        context,
                        requestId: requestIdForDb,
                        fetchIfMissing: true,
                        semanticsLabel:
                            'Delivered item image for request ${requestModel.id}',
                      );
                    },
                  ),
                if (isCancelled)
                  BCancelRemarksLoader(requestModel: requestModel),
                RequestModalFooter(requestModel: requestModel),
                BActionButton(
                  status: requestModel.status,
                  onPressed: onPressed,
                  isVisible: status,
                ),
                const SizedBox(height: BSizes.xs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
