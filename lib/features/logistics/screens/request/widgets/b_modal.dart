import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/b_document_reference_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal_widgets/request_modal_header.dart';

import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart'; // Adjust path if necessary

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../models/request_model.dart';

class BModal extends StatelessWidget {
  final RequestModel requestModel;
  final VoidCallback onPressed;
  final bool status;

  const BModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.status = true,
  });

  /// Show an image dialog with the captured signature.
  Future<void> _showImageDialog(BuildContext context) async {
    final String imageRequestUrl =
        '${dotenv.env['API_URL']!}/api4/request/images/${requestModel.requestID}';
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(BTexts.requestModalDeliveryShotTitle),
          content: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageRequestUrl,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Error loading image'),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(BTexts.requestModalCloseButtonText),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;
    final bool isDoneDelivery = requestModel.status == BTexts.statusDoneDelivery;
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
                  CapturedSignatureImage(requestId: requestModel.requestID),
                const SizedBox(height: BSizes.xs),
                if (isDoneDelivery)
                  ViewDeliveredItemButton(
                    textColor: textColor,
                    onPressed: () => _showImageDialog(context),
                  ),
                if (isCancelled)
                  BCancelRemarks(remarks: requestModel.cancelRemarks.remarks, date: requestModel.cancelRemarks.date),
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
