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
// Guard endorsement and drop-off UI elements were moved to the
// parent `AirSeaPage` to keep this header focused on client and
// preparation summary.

/// Header widget for Air/Sea request modal.
/// Displays client information, preparation details, and release details.
class AirSeaRequestModalHeader extends StatelessWidget {
  const AirSeaRequestModalHeader({
    super.key,
    required this.requestModel,
    required this.role,
  });

  final AirSeaModel requestModel;
  final String role;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasAddress = requestModel.client.address.isNotEmpty;

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
        ],
      ),
    );
  }
}
