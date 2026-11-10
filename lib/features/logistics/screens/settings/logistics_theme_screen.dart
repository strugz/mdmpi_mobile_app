import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/logistics_theme.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';

/// Settings → Theme for Logistics: Phone, Light or Dark and one of five
/// colour themes, with a preview that changes as they are picked. The same
/// page as Collection's, in Logistics' colours.
///
/// The choices live in [BLogisticsColors] and are applied by
/// [BLogisticsTheme.setMode] / [BLogisticsTheme.setAccent], which rebuild
/// the whole app, this page included; it only reads them.
class LogisticsThemeScreen extends StatelessWidget {
  const LogisticsThemeScreen({super.key, this.onMode, this.onAccent});

  /// Tests pass fakes; the app saves and applies the choice.
  final ValueChanged<ThemeMode>? onMode;
  final ValueChanged<BLogisticsAccent>? onAccent;

  /// What Settings shows under "Theme": "Ocean · Follows the phone".
  static String summary() =>
      '${BLogisticsColors.accent.label} · ${_modeLabel(BLogisticsColors.themeMode)}';

  static String _modeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follows the phone',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = _Neutrals.current;
    final primary = BColors.primary;
    final caption = theme.textTheme.bodySmall?.copyWith(color: n.inkSecondary);

    return Scaffold(
      backgroundColor: n.background,
      appBar: const BAppBar(title: Text('Theme'), showBackArrow: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
        children: [
          const _Preview(),
          const SizedBox(height: BSizes.spaceBtwSections),
          _Heading('Mode', color: n.ink),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('theme-mode'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: n.surface,
              foregroundColor: n.inkSecondary,
              selectedBackgroundColor: _soft(n.dark),
              selectedForegroundColor: primary,
              side: BorderSide(color: n.outline),
            ),
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Iconsax.mobile, size: 18),
                  label: Text('Phone')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Iconsax.sun_1, size: 18),
                  label: Text('Light')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Iconsax.moon, size: 18),
                  label: Text('Dark')),
            ],
            selected: {BLogisticsColors.themeMode},
            onSelectionChanged: (s) =>
                (onMode ?? BLogisticsTheme.setMode)(s.first),
          ),
          const SizedBox(height: BSizes.xs),
          Text('"Phone" follows your phone\'s light or dark setting.',
              style: caption),
          const SizedBox(height: BSizes.spaceBtwSections),
          _Heading('Colour', color: n.ink),
          LayoutBuilder(builder: (context, constraints) {
            const gap = BSizes.sm;
            final columns = constraints.maxWidth >= 520 ? 5 : 3;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final accent in BLogisticsAccent.values)
                  SizedBox(
                    width: width,
                    child: _AccentChoice(
                      accent: accent,
                      selected: accent == BLogisticsColors.accent,
                      onTap: () =>
                          (onAccent ?? BLogisticsTheme.setAccent)(accent),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: BSizes.spaceBtwItems),
          Text(
              'Priorities and statuses (low, medium, high, rush; delivered, '
              'pending, cancelled) keep their colours in every theme, so a '
              'status always reads the same.',
              style: caption),
        ],
      ),
    );
  }
}

/// The picked theme's tint for tiles and the selected segment: its soft
/// shade on light, its colour at low opacity on dark (as the Home cards do).
Color _soft(bool dark) {
  final a = BLogisticsColors.accent;
  return dark ? a.primary.withValues(alpha: 0.22) : a.soft;
}

/// The greys this page and its preview sit on, for the mode in use. Logistics
/// has no neutral tokens of its own; these are the app theme's.
class _Neutrals {
  const _Neutrals({
    required this.dark,
    required this.background,
    required this.surface,
    required this.outline,
    required this.ink,
    required this.inkSecondary,
  });

  final bool dark;
  final Color background;
  final Color surface;
  final Color outline;
  final Color ink;
  final Color inkSecondary;

  static _Neutrals get current => BLogisticsColors.isDark
      ? const _Neutrals(
          dark: true,
          background: Color(0xFF000000),
          surface: Color(0xFF1E1E1E),
          outline: Color(0xFF333333),
          ink: Color(0xFFFFFFFF),
          inkSecondary: BColors.darkGrey,
        )
      : const _Neutrals(
          dark: false,
          background: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          outline: BColors.grey,
          ink: BColors.textPrimary,
          inkSecondary: BColors.textSecondary,
        );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BSizes.sm),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

/// A small Logistics Home, in the colours in use: the header, a card with a
/// soft tile and a primary button. Its colours ease from one theme to the
/// next instead of snapping, so the change is seen where it happens.
class _Preview extends StatelessWidget {
  const _Preview();

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.ease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = _Neutrals.current;
    final primary = BColors.primary;
    return ClipRRect(
      key: const ValueKey('theme-preview'),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        decoration: BoxDecoration(
          color: n.dark ? n.background : BColors.light,
          border: Border.all(color: n.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: _curve,
              color: primary,
              padding: const EdgeInsets.fromLTRB(
                  BSizes.md, BSizes.md, BSizes.md, BSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Home',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78))),
                  Text('Good day',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BSizes.md),
              child: AnimatedContainer(
                duration: _duration,
                curve: _curve,
                padding: const EdgeInsets.all(BSizes.md - 2),
                decoration: BoxDecoration(
                  color: n.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: n.outline),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _soft(n.dark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.truck_fast, size: 20, color: primary),
                    ),
                    const SizedBox(width: BSizes.md - 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deliveries',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: n.ink, fontWeight: FontWeight.w700)),
                          Text('Requests for today',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: n.inkSecondary)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.md, vertical: BSizes.sm),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('Open',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One colour theme: a swatch of its colour over its soft tint, and its
/// name. The picked one has a ring in the colour in use and a tick. It gives
/// a little under the finger when pressed, so the tap is felt before the app
/// recolours.
class _AccentChoice extends StatefulWidget {
  const _AccentChoice({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final BLogisticsAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AccentChoice> createState() => _AccentChoiceState();
}

class _AccentChoiceState extends State<_AccentChoice> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = _Neutrals.current;
    final a = widget.accent;
    final ringColor = widget.selected ? BColors.primary : n.outline;
    // Read once as "Rose colour theme, selected", not as the name twice.
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${a.label} colour theme',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('theme-accent-${a.name}'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.ease,
            padding: const EdgeInsets.symmetric(
                vertical: BSizes.md, horizontal: BSizes.sm),
            decoration: BoxDecoration(
              color: n.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: ringColor, width: widget.selected ? 2 : 1),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The colour on the left half, its soft tint on the right.
                      Positioned.fill(
                        child: ClipOval(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: ColoredBox(color: a.primary)),
                              Expanded(
                                  child: ColoredBox(
                                      color: n.dark
                                          ? a.primary.withValues(alpha: 0.45)
                                          : a.soft)),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: n.outline),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: AnimatedScale(
                          scale: widget.selected ? 1 : 0.6,
                          duration: const Duration(milliseconds: 180),
                          curve: const Cubic(0.23, 1, 0.32, 1),
                          child: AnimatedOpacity(
                            opacity: widget.selected ? 1 : 0,
                            duration: const Duration(milliseconds: 140),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: BColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: n.surface, width: 2),
                              ),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BSizes.sm),
                Text(a.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: n.ink,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
