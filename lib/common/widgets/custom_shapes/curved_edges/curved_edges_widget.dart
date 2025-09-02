import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/curved_edges/curved_edges.dart';

class BCurvedEdgeWidget extends StatelessWidget {
  const BCurvedEdgeWidget({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BCustomCurvedEdges(),
      child: child,
    );
  }
}