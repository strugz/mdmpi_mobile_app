import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Settings → Theme: light or dark (the same choice as the Home toggle) and a
/// colour theme for Collection, with a preview that changes as they are
/// picked.
///
/// The choices live in [BCollectionColors] and are applied by
/// [BCollectionTheme.setMode] / [BCollectionTheme.setAccent], which rebuild
/// the whole app, this page included; it only reads them.
class CollectionThemeScreen extends StatelessWidget {
  const CollectionThemeScreen({super.key, this.onMode, this.onAccent});

  /// Tests pass fakes; the app saves and applies the choice.
  final ValueChanged<ThemeMode>? onMode;
  final ValueChanged<BCollectionAccent>? onAccent;

  /// What Settings shows under "Theme": "Ocean · Follows the phone".
  static String summary() =>
      '${BCollectionColors.accent.label} · ${_modeLabel(BCollectionColors.themeMode)}';

  static String _modeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follows the phone',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness =
        BCollectionColors.isDark ? Brightness.dark : Brightness.light;
    final caption = theme.textTheme.bodySmall
        ?.copyWith(color: BCollectionColors.inkSecondary);

    return Scaffold(
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
          _Heading('Mode'),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('theme-mode'),
            showSelectedIcon: false,
            // The Collection scheme sets no secondary container, which the
            // selected segment would otherwise fall back to (a flat grey).
            style: SegmentedButton.styleFrom(
              backgroundColor: BCollectionColors.surface,
              foregroundColor: BCollectionColors.inkSecondary,
              selectedBackgroundColor: BCollectionColors.primarySoft,
              selectedForegroundColor: BCollectionColors.primary,
              side: BorderSide(color: BCollectionColors.outline),
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
            selected: {BCollectionColors.themeMode},
            onSelectionChanged: (s) =>
                (onMode ?? BCollectionTheme.setMode)(s.first),
          ),
          const SizedBox(height: BSizes.xs),
          Text('"Phone" follows your phone\'s light or dark setting.',
              style: caption),
          const SizedBox(height: BSizes.spaceBtwSections),
          _Heading('Colour'),
          LayoutBuilder(builder: (context, constraints) {
            const gap = BSizes.sm;
            final columns = constraints.maxWidth >= 520 ? 5 : 3;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final accent in BCollectionAccent.values)
                  SizedBox(
                    width: width,
                    child: _AccentChoice(
                      accent: accent,
                      palette: BCollectionTheme.paletteFor(brightness, accent),
                      selected: accent == BCollectionColors.accent,
                      onTap: () => (onAccent ?? BCollectionTheme.setAccent)(accent),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: BSizes.spaceBtwItems),
          Text(
              'Paid, due, overdue and reconciliation keep their colours in '
              'every theme, so a status always reads the same.',
              style: caption),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BSizes.sm),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

/// A small Home, in the colours in use: the header, a card with a soft tile
/// and a primary button. Its colours ease from one theme to the next instead
/// of snapping, so the change is seen where it happens.
class _Preview extends StatelessWidget {
  const _Preview();

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.ease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = BCollectionColors.current;
    return ClipRRect(
      key: const ValueKey('theme-preview'),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        decoration: BoxDecoration(
          color: c.background,
          border: Border.all(color: c.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: _duration,
              curve: _curve,
              color: c.headerBackground,
              padding: const EdgeInsets.fromLTRB(
                  BSizes.md, BSizes.md, BSizes.md, BSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Home',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: c.onHeaderMuted)),
                  Text('Good day',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: c.onHeader, fontWeight: FontWeight.w700)),
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
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.outline),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.bucket, size: 20, color: c.primary),
                    ),
                    const SizedBox(width: BSizes.md - 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Collection Bucket',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: c.ink, fontWeight: FontWeight.w700)),
                          Text('Items to collect',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: c.inkSecondary)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.md, vertical: BSizes.sm),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('Open',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: c.onPrimary, fontWeight: FontWeight.w600)),
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

/// One colour theme: a swatch of its header and accent, and its name. The
/// picked one has an accent ring and a tick. It gives a little under the
/// finger when pressed, so the tap is felt before the app recolours.
class _AccentChoice extends StatefulWidget {
  const _AccentChoice({
    required this.accent,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final BCollectionAccent accent;
  final BCollectionPalette palette;
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
    final p = widget.palette;
    final ringColor =
        widget.selected ? BCollectionColors.primary : BCollectionColors.outline;
    // Read once as "Rose colour theme, selected", not as the name twice.
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.accent.label} colour theme',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('theme-accent-${widget.accent.name}'),
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
              color: BCollectionColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: ringColor, width: widget.selected ? 2 : 1),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Header on the left half, accent on the right.
                      Positioned.fill(
                        child: ClipOval(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child:
                                      ColoredBox(color: p.headerBackground)),
                              Expanded(child: ColoredBox(color: p.primary)),
                            ],
                          ),
                        ),
                      ),
                      // A hairline ring, so a dark header half does not melt
                      // into a dark card.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: BCollectionColors.outline),
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
                                color: BCollectionColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: BCollectionColors.surface,
                                    width: 2),
                              ),
                              child: Icon(Icons.check,
                                  size: 12,
                                  color: BCollectionColors.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BSizes.sm),
                Text(widget.accent.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: BCollectionColors.ink,
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
