// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';

import '../../../../base/utils/constants/colors.dart';
import 'circular_container.dart';

class BPrimaryHeaderContainer extends StatelessWidget {
  const BPrimaryHeaderContainer({
    super.key,
    required this.child,
    this.color,
  });

  final Widget child;

  /// Fill colour. Left null, it follows the theme's app bar colour when a
  /// department theme gives the bar one (Collection's navy), so a header
  /// and the bar inside it are one surface; otherwise [BColors.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bar = Theme.of(context).appBarTheme.backgroundColor;
    final fill = color ??
        (bar == null || bar.a == 0 ? BColors.primary : bar);
    return BCurvedEdgeWidget(
      child: Container(
        color: fill,
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          child: Stack(
            children: [
              /// --  Background Custom Shapes
              Positioned(
                top: -150,
                right: -250,
                child: CircularContainer(
                  backgroundColor: BColors.textWhite.withOpacity(0.1),
                ),
              ),
              Positioned(
                  top: 100,
                  right: -300,
                  child: CircularContainer(
                      backgroundColor: BColors.textWhite.withOpacity(0.1))),
              child
            ],
          ),
        ),
      ),
    );
  }
}
