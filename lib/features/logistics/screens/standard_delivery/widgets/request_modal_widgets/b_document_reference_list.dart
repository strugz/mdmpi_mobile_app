import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';

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
    final uniqueReferences = LinkedHashSet<String>.from(
      documentReferences.map((reference) => reference.trim()).where((reference) => reference.isNotEmpty),
    ).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemCount: uniqueReferences.length,
      itemBuilder: (_, index) {
        final String reference = uniqueReferences[index];
        return BLabelValueText(
          label: 'Doc Ref',
          value: reference,
          showLabel: false,
          maxLines: 1,
          copyable: true,
          padding: EdgeInsets.zero,
        );
      },
    );
  }
}
