import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/dividers/text_divider.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_document_reference_list.dart';

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

    // Same compact grouped-chip list as the request modals, so a delivery
    // with 15–20 references no longer fills the courier's sheet.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BTextDivider(text: 'Document Reference/s'),
        const SizedBox(height: BSizes.xs),
        DocumentReferenceList(
          documentReferences: request.documentReference,
          textColor: textColor,
        ),
      ],
    );
  }
}
