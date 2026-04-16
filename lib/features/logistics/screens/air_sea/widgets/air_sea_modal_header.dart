import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';

import '../../../../../common/widgets/dialogs/request_image_dialog.dart';

/// Header widget for Air/Sea request modal.
/// Displays client information, preparation details, and release details.
class AirSeaRequestModalHeader extends StatelessWidget {
  const AirSeaRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;

    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasPreparedBy = requestModel.preparedBy.isNotEmpty;
    final hasReceivedBy = requestModel.receivedBy.isNotEmpty;
    final hasItemPreparedEndAt = requestModel.itemPreparedEndAt.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 2,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),

          if (hasAddress) ...[
            const SizedBox(height: BSizes.xxs),
            BLabelValueText(
              label: 'Address',
              value: requestModel.client.address,
              showLabel: false,
              maxLines: 3,
              copyable: true,
              smallSize: true,
            )
          ],

          const SizedBox(height: BSizes.xs),

          StatusChip(status: requestModel.status),

          // Preparation details section (who prepared and when)
          if (hasPreparedBy) ...[
            const SizedBox(height: BSizes.xs),
            BTextDivider(text: 'Preparation Details'),
            BLabelValueText(
              label: 'Prepared By',
              value: requestModel.preparedBy,
              showLabel: false,
              icon: Iconsax.user_edit,
              padding: EdgeInsets.zero,
            ),
            BLabelValueText(
              label: 'Item prepared at',
              // Use BFormatter's customizable formatter directly with the desired display format (12-hour with AM/PM)
              value: BFormatter.formatDateWithAmPm(requestModel.itemPreparedAt),
              showLabel: false,
              icon: Iconsax.calendar,
              padding: EdgeInsets.zero,
            ),
            if (hasItemPreparedEndAt)
              BLabelValueText(
                label: 'Item prepared end at',
                value: BFormatter.formatDateWithAmPm(
                    requestModel.itemPreparedEndAt),
                showLabel: false,
                icon: Iconsax.calendar_1,
                padding: EdgeInsets.zero,
              ),
          ],

          // Guard Endorsement section (only shown when status is 'Endorsed to Guard')
          if (requestModel.status == BTexts.statusEndorsedToGuard) ...[
            const SizedBox(height: BSizes.xs),
            const BTextDivider(text: 'Guard Endorsement'),
            if (hasReceivedBy) ...[
              const SizedBox(height: BSizes.sm),
              BLabelValueText(
                label: 'Endorsed To (Guard)',
                value: requestModel.receivedBy,
                showLabel: false,
                icon: Iconsax.user_octagon,
                padding: EdgeInsets.zero,
                mainAlignment: MainAxisAlignment.center,
              ),
              BLabelValueText(
                label: 'Endorsed at',
                value: BFormatter.formatDateTimeCustomizable(
                  requestModel.updatedAt,
                  "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                  "MMM d, yyyy hh:mm a",
                ),
                showLabel: false,
                icon: Iconsax.calendar_1,
                padding: EdgeInsets.zero,
                mainAlignment: MainAxisAlignment.center,
              ),
              const SizedBox(height: BSizes.sm),
            ],
          ],

          if (requestModel.status == BTexts.statusEndorsedToGuard) ...[
            // Display captured guard signature image
            CapturedSignatureImage(requestId: requestModel.id),
            // Button to view guard receipt proof image
            ViewDeliveredItemButton(
              textColor: textColor,
              labelTitle: 'View Guard Receipt Proof',
              onPressed: () {
                final requestIdForDb = requestModel.id;
                showRequestImageDialog(context,
                    requestId: requestIdForDb,
                    fetchIfMissing: true,
                    semanticsLabel:
                        'Guard receipt proof image for request ${requestModel.id}',
                    apiController: 'RequestAirSea',
                    title: 'Guard Receipt Proof');
              },
            )
          ],

          // Drop Off details section (only shown when status is 'Drop Off')
          if (requestModel.status == 'Drop Off') ...[
            const SizedBox(height: BSizes.xs),
            const BTextDivider(text: 'Drop Off Details'),
            if (hasReceivedBy) ...[
              const SizedBox(height: BSizes.sm),
              BLabelValueText(
                label: 'Received By',
                value: requestModel.receivedBy,
                showLabel: false,
                icon: Iconsax.user_octagon,
                padding: EdgeInsets.zero,
                mainAlignment: MainAxisAlignment.center,
              ),
              if (requestModel.dropOffAt.isNotEmpty)
                BLabelValueText(
                  label: 'Dropped Off at',
                  value: BFormatter.formatDateTimeCustomizable(
                    requestModel.dropOffAt,
                    "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                    "MMM d, yyyy hh:mm a",
                  ),
                  showLabel: false,
                  icon: Iconsax.calendar_1,
                  padding: EdgeInsets.zero,
                  mainAlignment: MainAxisAlignment.center,
                ),
              const SizedBox(height: BSizes.sm),
              // Display captured receiver signature image
              CapturedSignatureImage(requestId: requestModel.id),
              // Button to view drop off proof image
              ViewDeliveredItemButton(
                textColor: textColor,
                labelTitle: 'View Drop Off Proof',
                onPressed: () {
                  final requestIdForDb = requestModel.id;
                  showRequestImageDialog(context,
                      requestId: requestIdForDb,
                      fetchIfMissing: true,
                      semanticsLabel:
                          'Drop off proof image for request ${requestModel.id}',
                      apiController: 'RequestAirSea',
                      title: 'Drop Off Proof');
                },
              )
            ],
          ],
        ],
      ),
    );
  }
}
