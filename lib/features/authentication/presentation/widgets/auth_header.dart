import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Generic authentication header widget
///
/// Displays logo (optional) + title + subtitle for authentication screens.
/// Used across login, signup, forgot password, and other auth flows.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo)
          Image(
            height: 150,
            image: AssetImage(
                dark ? BImages.lightAppLogo : BImages.darkAppLogo),
          ),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
