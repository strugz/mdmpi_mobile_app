import 'package:flutter/material.dart';

import '../../../../../base/utils/constants/text_string.dart';

class BActionButton extends StatelessWidget {
  final String? status;
  final VoidCallback onPressed;
  final bool isVisible;

  const BActionButton({
    super.key,
    required this.status,
    required this.onPressed,
    required this.isVisible,
  });

  String _getButtonText() {
    switch (status) {
      case BTexts.statusNewRequest: // USE BTexts
        return BTexts.requestModalPrepareItemButtonText; // USE BTexts
      case BTexts.statusGettingSuppliesReady: // USE BTexts
        return BTexts.requestModalPackedAndReadyButtonText; // USE BTexts
      default:
        // Assuming 'For Delivery' or other statuses lead to 'Drop Off'
        // If you have a specific BTexts entry for "Drop Off", use that.
        // For example, if BTexts.requestModalDropOffButtonText exists:
        return BTexts.requestModalDropOffButtonText; // USE BTexts
      // Or keep the direct string if it's not in BTexts yet
      // return "Drop Off";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: _getButtonText() == BTexts.requestModalDropOffButtonText
          ? Container()
          : ElevatedButton(
              onPressed: onPressed,
              child: Text(_getButtonText()),
            ),
    );
  }
}
