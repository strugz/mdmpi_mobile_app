import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key, required this.request});

  final StandardDeliveryModel request;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    if (request.documentReference.isEmpty) return const SizedBox.shrink();

    // Render a single section header and then compact rows for each document reference
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BTextDivider(text: 'Document Reference/s'),
        const SizedBox(height: BSizes.xs),
        ...request.documentReference.map((reference) {
          return Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: BLabelValueText(
              label: reference,
              value: reference,
              copyable: true,
              showLabel: false,
              textColor: textColor,
              smallSize: true,
            ),
          );
        }),
      ],
    );
  }
}
