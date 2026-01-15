import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/status_color_mapper.dart';

/// Generic status chip with central color & label mapping.
class StatusChip extends StatelessWidget {
  const StatusChip(
      {super.key,
      required this.status,
      this.padding,
      this.minWidth,
      this.compact = false});

  final String status;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = LogisticsStatusColors.colorsForAuto(context, status);
    final label = LogisticsStatusColors.display(status);
    return BRoundedContainer(
      radius: 100,
      width: minWidth, // if provided, force width; else intrinsic via Row
      backgroundColor: bg,
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
                horizontal: compact ? BSizes.sm : BSizes.md,
                vertical: compact ? BSizes.xxs : BSizes.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BProductTitleText(
              title: label,
              maxLines: 1,
              smallSize: true,
              fontColor: fg,
            ),
          ],
        ),
      ),
    );
  }
}
