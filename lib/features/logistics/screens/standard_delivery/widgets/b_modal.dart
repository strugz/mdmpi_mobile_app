import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_cancel_remarks.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_document_reference_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_footer.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/request_modal_header.dart';

import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart'; // Adjust path if necessary

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'package:mdmpi_mobile_app/data/repositories/image/image_repository.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';

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

  /// Show an image dialog with the captured signature.
  Future<void> _showImageDialog(BuildContext context) async {
    final base = dotenv.env['API_URL'];
    if (base == null || base.isEmpty) {
      BLoaders.errorSnackBar(
          title: 'Configuration', message: 'API_URL not configured.');
      return;
    }

    // Build the new API URL: /api4/Request/image?requestid=<id>&type=Proof
    final apiBase = Uri.parse(base);
    final imageUri = apiBase.replace(
      path: '/api4/Request/image',
      queryParameters: {
        'requestid': requestModel.id,
        'type': 'Proof',
      },
    );
    final imageUrl = imageUri.toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to allow switching to the fallback (bytes) view
        return StatefulBuilder(builder: (context, setState) {
          Uint8List? bytes;
          bool loadingBytes = false;
          String? bytesError;

          // Helper to load bytes via ImageRepository fallback
          Future<void> _loadBytesFallback() async {
            setState(() {
              loadingBytes = true;
              bytesError = null;
            });
            try {
              // Use the repository helper which accepts an endpoint + query params
              final data = await ImageRepository.instance.getFileFromApi(
                endpoint: '/api4/Request/image',
                queryParameters: {
                  'requestid': requestModel.id,
                  'type': 'Proof'
                },
              );
              setState(() {
                bytes = data;
                loadingBytes = false;
              });
            } catch (e) {
              setState(() {
                bytesError = e.toString();
                loadingBytes = false;
              });
            }
          }

          // Dialog content: either bytes (fallback) or CachedNetworkImage
          Widget contentChild;
          if (bytes != null) {
            contentChild = InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: Semantics(
                label: 'Delivered item image for request ${requestModel.id}',
                child: Image.memory(bytes!, fit: BoxFit.contain),
              ),
            );
          } else if (loadingBytes) {
            contentChild = const Center(child: CircularProgressIndicator());
          } else {
            // Primary load using CachedNetworkImage (better UX + caching)
            contentChild = InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Error loading image'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              // force reload by changing the URL slightly (append timestamp)
                              // workaround: rebuild CachedNetworkImage by triggering a rebuild
                              setState(() {});
                              // Note: CachedNetworkImage will try again automatically; user may also choose fallback
                            },
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () async {
                              await _loadBytesFallback();
                            },
                            child: const Text('Use fallback'),
                          ),
                        ],
                      ),
                      if (bytesError != null) ...[
                        const SizedBox(height: 8),
                        Text(bytesError!),
                      ]
                    ],
                  ),
                ),
              ),
            );
          }

          // Build a full-screen styled dialog for image viewing
          return Dialog(
            insetPadding: const EdgeInsets.all(12.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(BTexts.requestModalDeliveryShotTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          tooltip: BTexts.requestModalCloseButtonText,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: contentChild,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text(BTexts.requestModalCloseButtonText),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

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
                    onPressed: () => _showImageDialog(context),
                  ),
                if (isCancelled)
                  BCancelRemarks(
                      remarks: requestModel.cancelRemarks.remarks,
                      date: requestModel.cancelRemarks.date),
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
