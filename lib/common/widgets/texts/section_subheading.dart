
import 'package:flutter/material.dart';

class BSectionSubHeading extends StatelessWidget {
  const BSectionSubHeading({
    super.key,
    this.textColor,
    this.buttonTitle = 'View all',
    this.showActionButton = true,
    this.onPressed,
    required this.title,
  });
  final Color? textColor;
  final String title, buttonTitle;
  final bool showActionButton;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall!.apply(color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if(showActionButton) TextButton(onPressed: onPressed, child: Text(buttonTitle))
      ],
    );
  }
}