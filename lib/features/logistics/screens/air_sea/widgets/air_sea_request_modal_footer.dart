import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/b_delivery_details_section.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_drop_off_section.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_item_packed_section.dart';

/// Footer widget for Air/Sea request modal.
/// Uses [role] to gate editable sections so only the relevant role sees input forms.
class AirSeaRequestModalFooter extends StatelessWidget {
  const AirSeaRequestModalFooter({
    super.key,
    required this.requestModel,
    required this.role,
  });

  final AirSeaModel requestModel;
  final String role;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- Item Packed Status Transition (Release role only) --
        if (requestModel.status == BTexts.statusItemPacked &&
            role == BTexts.roleRelease) ...[
          AirSeaItemPackedSection(requestModel: requestModel),
        ],

        /// -- Drop Off Status Section (Courier role only) --
        if (requestModel.status == BTexts.statusDispatch &&
            role == BTexts.roleCourier) ...[
          AirSeaDropOffSection(requestModel: requestModel),
        ],

        /// -- Remarks --
        if (requestModel.remarks.isNotEmpty) ...[
          const SizedBox(height: BSizes.sm),
          const BTextDivider(text: 'Remarks'),
          BProductTitleText(
            title: requestModel.remarks,
            maxLines: 3,
            smallSize: true,
            fontColor: textColor,
          ),
        ],

        /// -- Receipt Details (use reusable delivery details section) --
        if (requestModel.status == BTexts.statusReceived ||
            requestModel.status == BTexts.statusProvincialPickUp ||
            requestModel.status == BTexts.statusProvincialInTransit ||
            requestModel.status == BTexts.statusProvincialDelivered) ...[
          BDeliveryDetailsSection(
            sectionTitle: 'Receipt Details',
            driver: requestModel.driver,
            helper: requestModel.helper,
            receivedBy: requestModel.receivedBy,
            receivedByLabel: 'Received By',
            departedAt: requestModel.dispatchedAt,
            completedAt: requestModel.updatedAt,
            completedAtLabel: 'Received At',
            requestId: requestModel.id,
            apiController: 'RequestAirSea',
            viewItemButtonLabel: BTexts.requestModalViewItemReceivedText,
            dialogTitle: 'Air/Sea Item',
            showViewItemButton: true,
            // Use AM/PM formatter
            completedAtFormatter: (s) => BFormatter.formatDateTimeCustomizable(
              s,
              "yyyy-MM-ddTHH:mm:ss.SSSSSS",
              "MMM d, yyyy hh:mm a",
            ),
            // Render the signature below the Received By value and allow larger size
            signatureBelowReceivedBy: true,
            signatureHeight: 50,
            // Place signature on the left column by default for Air/Sea
            signatureLeft: true,
          ),
        ],

        const SizedBox(height: BSizes.sm),
      ],
    );
  }
}
