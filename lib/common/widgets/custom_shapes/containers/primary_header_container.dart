import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';

import '../../../../base/utils/constants/colors.dart';
import 'circular_container.dart';

class BPrimaryHeaderContainer extends StatelessWidget {
  const BPrimaryHeaderContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BCurvedEdgeWidget(
      child: Container(
        color: BColors.primary,
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
