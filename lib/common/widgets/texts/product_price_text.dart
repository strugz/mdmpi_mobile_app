import 'package:flutter/material.dart';

class BProductPriceText extends StatelessWidget {
  const BProductPriceText(
      {super.key,
      this.maxLines = 1,
      this.isLarge = false,
      this.lineThrough = false,
      required this.unit,
      required this.qty});

  final String unit, qty;
  final int maxLines;
  final bool isLarge;
  final bool lineThrough;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$qty$unit',
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: isLarge
          ? Theme.of(context).textTheme.headlineMedium!.apply(
              decoration: lineThrough ? TextDecoration.lineThrough : null)
          : Theme.of(context).textTheme.titleLarge!.apply(
              decoration: lineThrough ? TextDecoration.lineThrough : null),
    );
  }
}
