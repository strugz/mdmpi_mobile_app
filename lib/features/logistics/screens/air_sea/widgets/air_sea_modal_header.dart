import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
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

  /// Formats date string to readable format (MMM d, yyyy HH:mm)
  /// Handles various date formats and returns fallback if parsing fails
  String _formatDate(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy HH:mm').format(dt);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

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
              icon: Iconsax.location,
              showLabel: false,
              maxLines: 3,
              copyable: true,
            )
          ],
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
              value: _formatDate(
                BFormatter.formatDateTimeCustomizable(
                  requestModel.itemPreparedAt,
                  "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                  "yyyy-MM-dd HH:mm",
                ),
              ),
              showLabel: false,
              icon: Iconsax.calendar,
              padding: EdgeInsets.zero,
            ),
            if (hasItemPreparedEndAt)
              BLabelValueText(
                label: 'Item prepared end at',
                value: _formatDate(
                  BFormatter.formatDateTimeCustomizable(
                    requestModel.itemPreparedEndAt,
                    "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm",
                  ),
                ),
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
                value: _formatDate(
                  BFormatter.formatDateTimeCustomizable(
                    requestModel.updatedAt,
                    "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm",
                  ),
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

          // Receipt details section (only shown when status is 'Received')
          if (requestModel.status == BTexts.statusReceived) ...[
            const SizedBox(height: BSizes.xs),
            const BTextDivider(text: 'Receipt Details'),
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
              BLabelValueText(
                label: 'Received at',
                value: _formatDate(
                  BFormatter.formatDateTimeCustomizable(
                    requestModel.updatedAt,
                    "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm",
                  ),
                ),
                showLabel: false,
                icon: Iconsax.calendar_1,
                padding: EdgeInsets.zero,
                mainAlignment: MainAxisAlignment.center,
              ),
              const SizedBox(height: BSizes.sm),
              CapturedSignatureImage(requestId: requestModel.id),
              ViewDeliveredItemButton(
                textColor: textColor,
                labelTitle: BTexts.requestModalViewItemReceivedText,
                onPressed: () {
                  final requestIdForDb = requestModel.id;
                  showRequestImageDialog(context,
                      requestId: requestIdForDb,
                      fetchIfMissing: true,
                      semanticsLabel:
                          'Delivered item image for request ${requestModel.id}',
                      apiController: 'RequestAirSea',
                      title: 'Air/Sea Item');
                },
              )
            ],
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
                  value: _formatDate(
                    BFormatter.formatDateTimeCustomizable(
                      requestModel.dropOffAt,
                      "yyyy-MM-ddTHH:mm:ss.SSSSSS",
                      "yyyy-MM-dd HH:mm",
                    ),
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
