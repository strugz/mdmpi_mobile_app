import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Light/Dark switch in the Home header's upper right.
///
/// Shows what a tap turns on: the moon while the screens are light, the sun
/// while they are dark. The choice is kept on the phone; until the collector
/// first taps it, Collection follows the phone's own setting.
class CollectionThemeModeToggle extends StatelessWidget {
  const CollectionThemeModeToggle({super.key, this.onChanged});

  /// Tests watch the choice here; the app saves and applies it.
  final void Function(ThemeMode mode)? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = BCollectionColors.isDark;
    final next = dark ? ThemeMode.light : ThemeMode.dark;
    return IconButton(
      key: const ValueKey('collection-theme-toggle'),
      tooltip: dark ? 'Light mode' : 'Dark mode',
      onPressed: () => (onChanged ?? BCollectionTheme.setMode)(next),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          dark ? Iconsax.sun_1 : Iconsax.moon,
          key: ValueKey(dark),
          color: BCollectionColors.onHeader,
        ),
      ),
    );
  }
}
