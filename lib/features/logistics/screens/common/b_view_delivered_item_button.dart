import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../base/utils/constants/text_string.dart';

class ViewDeliveredItemButton extends StatelessWidget {
  final Color textColor;
  final VoidCallback onPressed;
  final String labelTitle;

  const ViewDeliveredItemButton({
    super.key,
    required this.textColor,
    required this.onPressed,
    this.labelTitle = BTexts.requestModalViewItemDeliveredText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        icon: Icon(
          Iconsax.image,
          color: textColor,
        ),
        label: Text(
          labelTitle, // USE BTexts
          style: TextStyle(color: textColor),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
