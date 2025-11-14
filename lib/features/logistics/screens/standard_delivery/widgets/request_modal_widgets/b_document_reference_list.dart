import 'package:flutter/material.dart';

import '../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../common/widgets/texts/product_title_text.dart';

class DocumentReferenceList extends StatelessWidget {
  final List<String> documentReferences;
  final Color textColor;

  const DocumentReferenceList({
    super.key,
    required this.documentReferences,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: BSizes.xs),
      itemCount: documentReferences.length,
      itemBuilder: (_, index) {
        final String reference = documentReferences[index];
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
