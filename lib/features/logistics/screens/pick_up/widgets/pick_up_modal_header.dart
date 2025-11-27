import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';

class PickUpRequestModalHeader extends StatelessWidget {
  const PickUpRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PickUpModel requestModel;

  String _formatDate(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasDatePickUp = requestModel.datePickUp.isNotEmpty;
    final hasReleasedBy = requestModel.releasedBy.isNotEmpty;
    final hasPreparedBy = requestModel.preparedBy.isNotEmpty;
    final hasCreatedBy = requestModel.createdBy.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BProductTitleText(
            title: requestModel.client.name,
            maxLines: 2,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black,
          ),
          if (hasAddress) ...[
            const SizedBox(height: BSizes.xxs),
            BProductTitleText(
              title: requestModel.client.address,
              maxLines: 2,
              smallSize: true,
              fontColor: dark ? BColors.light : BColors.black,
            ),
          ],
          if (hasDatePickUp || hasReleasedBy) ...[
            const SizedBox(height: BSizes.sm),
            const BTextDivider(text: 'Pick-Up Info'),
            Row(
              children: [
                if (hasReleasedBy)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Released By',
                      value: requestModel.releasedBy,
                      showLabel: false,
                      icon: Iconsax.user,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasDatePickUp)
                  Expanded(
                    child: BLabelValueText(
                      label: 'Pick-Up Date',
                      value: _formatDate(requestModel.datePickUp),
                      showLabel: false,
                      icon: Iconsax.calendar,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
          if (hasPreparedBy) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Prepared By',
              value: requestModel.preparedBy,
              icon: Iconsax.user,
              padding: EdgeInsets.zero,
            ),
          ],
          if (hasCreatedBy) ...[
            const SizedBox(height: BSizes.sm),
            BLabelValueText(
              label: 'Created By',
              value: requestModel.createdBy,
              icon: Iconsax.user,
              padding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: BSizes.sm),
        ],
      ),
    );
  }
}

