import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// Wraps a money field so its text reads "7,200,000.00" once the field is
/// left, the same as the Collection web. While typing, the field's
/// [ThousandsSeparatorInputFormatter] groups the digits; this adds the
/// centavos when focus moves on, so what was typed looks like what is saved.
///
/// A [Focus] that hears its descendants: no FocusNode to own or dispose, and
/// it never takes focus or a tab stop of its own.
class BAmountBlurPad extends StatelessWidget {
  const BAmountBlurPad({
    super.key,
    required this.controller,
    required this.child,
  });

  final TextEditingController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) return;
        final done = ThousandsSeparatorInputFormatter.finalize(controller.text);
        if (done == controller.text) return;
        controller.value = TextEditingValue(
          text: done,
          selection: TextSelection.collapsed(offset: done.length),
        );
      },
      child: child,
    );
  }
}
