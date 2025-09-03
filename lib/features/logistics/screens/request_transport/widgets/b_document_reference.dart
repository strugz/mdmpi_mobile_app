import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/request_model.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key, required this.request});

  final RequestModel request;

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
        return BProductTitleText(
          title: reference,
          maxLines: 1,
          smallSize: true,
          fontColor: textColor,
        );
      },
    );
  }
}
