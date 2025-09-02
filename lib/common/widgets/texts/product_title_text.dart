import 'package:flutter/material.dart';

class BProductTitleText extends StatelessWidget {
  const BProductTitleText(
      {super.key,
      required this.title,
      this.smallSize = false,
      this.maxLines = 2,
      this.textAlign = TextAlign.left,
      this.bold = false,
      this.fontColor = Colors.black});

  final String title;
  final bool smallSize;
  final int maxLines;
  final TextAlign? textAlign;
  final bool bold;
  final Color fontColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: smallSize
          ? Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: fontColor)
          : Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: fontColor),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
