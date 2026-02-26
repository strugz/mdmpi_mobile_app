import 'package:flutter/material.dart';
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
/// Displays remarks section.
class AirSeaRequestModalFooter extends StatelessWidget {
  const AirSeaRequestModalFooter({super.key, required this.requestModel});

  final AirSeaModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- Item Packed Status Transition --
        if (requestModel.status == BTexts.statusItemPacked) ...[
          AirSeaItemPackedSection(requestModel: requestModel),
        ],

        /// -- Drop Off Status Section (shown when Courier is actively delivering) --
        if (requestModel.status == BTexts.statusDispatch) ...[
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
        const SizedBox(height: BSizes.sm),
      ],
    );
  }
}

