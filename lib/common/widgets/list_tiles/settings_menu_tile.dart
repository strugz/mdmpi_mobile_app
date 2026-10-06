import 'package:flutter/material.dart';

class BSettingsMenuTile extends StatelessWidget {
  const BSettingsMenuTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subTitle,
      this.onTap,
      this.trailing});

  final IconData icon;
  final String title, subTitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // The theme's accent, so the icons follow the department theme
      // Settings wears (Collection navy-blue, Logistics blue).
      leading:
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subTitle, style: Theme.of(context).textTheme.labelMedium),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
