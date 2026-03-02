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
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_view_delivered_item_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_captured_signature_image.dart';

import '../../../../../common/widgets/dialogs/request_image_dialog.dart';

class PickUpRequestModalHeader extends StatelessWidget {
  const PickUpRequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final PickUpModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    final hasAddress = requestModel.client.address.isNotEmpty;
    final hasPreparedBy = requestModel.preparedBy.isNotEmpty;
    final hasCreatedBy = requestModel.createdBy.isNotEmpty;

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
          if (hasCreatedBy && hasPreparedBy) ...[
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
              value: BFormatter.formatDate2(
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
                value: BFormatter.formatDate2(
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
        ],
      ),
    );
  }
}
