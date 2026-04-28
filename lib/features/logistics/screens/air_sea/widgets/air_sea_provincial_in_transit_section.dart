import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_map_location_link.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';

/// Displays the Provincial In Transit stage for Air/Sea requests.
///
/// The stage is readonly once transit has started. While active, the modal/page
/// action button handles the actual status transition and timestamp capture.
class AirSeaProvincialInTransitSection extends StatelessWidget {
  const AirSeaProvincialInTransitSection({
    super.key,
    required this.requestModel,
    required this.isActive,
  });

  final AirSeaModel requestModel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isActive) ...[
          const SizedBox(height: BSizes.spaceBtwItems),
          const BTextDivider(text: 'Provincial In Transit'),
          const SizedBox(height: BSizes.sm),
          if (requestModel.provincialInTransitAt.isNotEmpty)
            BLabelValueText(
              label: 'Transit Started At',
              value: BFormatter.formatDateWithAmPm(
                requestModel.provincialInTransitAt,
              ),
              showLabel: true,
              icon: Iconsax.calendar_1,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
            ),
          if (requestModel.provincialInTransitLocation.isNotEmpty)
            BMapLocationLink(
              label: 'Transit Location',
              location: requestModel.provincialInTransitLocation,
              showLabel: true,
              icon: Iconsax.location,
              padding: EdgeInsets.zero,
              mainAlignment: MainAxisAlignment.start,
              iconOnly: true,
            ),
          if (requestModel.provincialInTransitAt.isEmpty &&
              requestModel.provincialInTransitLocation.isEmpty)
            Text(
              'Transit has been recorded for this request.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ],
    );
  }
}
