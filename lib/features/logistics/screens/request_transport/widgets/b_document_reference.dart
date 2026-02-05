import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key, required this.request});

  final StandardDeliveryModel request;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;
    return ListView.separated(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // If inside another scrollable
      separatorBuilder: (_, __) => const SizedBox(height: BSizes.xs),
      itemCount: request.documentReference.length,
      itemBuilder: (_, index) {
        String reference = request.documentReference[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BTextDivider(text: 'Document Reference/s'),
            BLabelValueText(
              label: reference,
              value: reference,
              copyable: true,
              showLabel: false,
              textColor: textColor,
            )
          ],
        );
      },
    );
  }
}
