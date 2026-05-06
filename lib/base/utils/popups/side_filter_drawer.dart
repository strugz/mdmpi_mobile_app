import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// Small helper to show a slide-in side panel from the right for filter UIs.
/// Usage: showSideFilter(const BucketFilterModal());
void showSideFilter(Widget child) {
  final ctx = Get.context;
  if (ctx == null) return;

  showGeneralDialog(
    context: ctx,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      final width = MediaQuery.of(context).size.width;
      final widthFactor = width > 900 ? 0.45 : 0.9;

      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          heightFactor: 1.0,
          child: Material(
            color: BColors.white,
            elevation: 8,
            child: SafeArea(child: child),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, widget) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation);
      return SlideTransition(position: offset, child: widget);
    },
  );
}


