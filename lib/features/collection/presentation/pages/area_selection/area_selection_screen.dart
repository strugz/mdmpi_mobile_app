import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// One tile on the area picker. [codes] is what the tile represents: a single
/// territory code, several (a parent like Luzon), or empty for "All areas".
class _AreaOption {
  const _AreaOption({
    required this.name,
    required this.icon,
    this.code,
    this.children = const [],
  });

  final String name;
  final IconData icon;

  /// Selectable code. Null for a parent that drills down.
  final String? code;
  final List<_AreaOption> children;

  bool get hasChildren => children.isNotEmpty;

  /// Codes to count accounts for.
  List<String> get codes =>
      hasChildren ? children.map((c) => c.code!).toList() : [code ?? ''];
}

const List<_AreaOption> _luzonRegions = [
  _AreaOption(name: 'North Luzon', icon: Iconsax.arrow_up_1, code: 'NLN'),
  _AreaOption(name: 'Central Luzon', icon: Iconsax.record_circle, code: 'CLN'),
  _AreaOption(name: 'South Luzon', icon: Iconsax.arrow_down, code: 'SLN'),
  _AreaOption(name: 'NCR', icon: Iconsax.buildings_2, code: 'NCR'),
];

const List<_AreaOption> _mainAreas = [
  _AreaOption(name: 'Luzon', icon: Iconsax.map, children: _luzonRegions),
  _AreaOption(name: 'Visayas', icon: Iconsax.global, code: 'VIS'),
  _AreaOption(name: 'Mindanao', icon: Iconsax.routing_2, code: 'MIN'),
  _AreaOption(name: 'Medical Imaging', icon: Iconsax.scan, code: 'RAD'),
  // Every code whose prefix is not one of the named territories (VET, CSAT, …).
  _AreaOption(
      name: 'Others', icon: Iconsax.category, code: BCollectionArea.others),
];

class AreaSelectionScreen extends StatefulWidget {
  final Widget Function()? targetScreenBuilder;
  final String title;
  final bool isFilterMode;

  const AreaSelectionScreen({
    super.key,
    this.targetScreenBuilder,
    required this.title,
    this.isFilterMode = false,
  });

  @override
  State<AreaSelectionScreen> createState() => _AreaSelectionScreenState();
}

class _AreaSelectionScreenState extends State<AreaSelectionScreen> {
  /// Parent currently drilled into (Luzon), or null for the top level.
  _AreaOption? _parent;

  static const Duration _stateDuration = Duration(milliseconds: 220);

  CollectionActivityController get _controller =>
      CollectionActivityController.instance;

  void _select(String code) {
    _controller.selectedArea.value = code;
    if (widget.isFilterMode) {
      Get.back();
    } else if (widget.targetScreenBuilder != null) {
      Get.off(() => widget.targetScreenBuilder!());
    }
  }

  void _drillInto(_AreaOption parent) => setState(() => _parent = parent);
  void _drillOut() => setState(() => _parent = null);

  int _countFor(_AreaOption option) => option.codes
      .fold(0, (sum, code) => sum + _controller.accountCountForArea(code));

  bool _isSelected(_AreaOption option, String selected) {
    if (option.hasChildren)
      return option.children.any((c) => c.code == selected);
    return (option.code ?? '') == selected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drilled = _parent != null;

    // System back returns to the top level first instead of leaving the screen.
    return PopScope(
      canPop: !drilled,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && drilled) _drillOut();
      },
      child: Scaffold(
        appBar: BAppBar(
          showBackArrow: !drilled,
          leadingIcon: drilled ? Iconsax.arrow_left : null,
          leadingOnPressed: _drillOut,
          title: Text(
            drilled
                ? _parent!.name
                : (widget.isFilterMode
                    ? 'Filter by Area'
                    : 'Select Area - ${widget.title}'),
          ),
        ),
        body: Obx(() {
          final selected = _controller.selectedArea.value;
          final options = drilled ? _parent!.children : _mainAreas;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BSizes.defaultSpace,
                  BSizes.sm,
                  BSizes.defaultSpace,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drilled ? 'Choose a region' : 'Choose an area',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: BSizes.xs),
                    Text(
                      drilled
                          ? 'Accounts in ${_parent!.name} are grouped by region code.'
                          : 'Counts show accounts currently in your bucket.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Expanded(
                // Slide between levels: forward into a parent, back out again.
                child: AnimatedSwitcher(
                  duration: _stateDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) {
                    final incomingIsSub = child.key == const ValueKey('sub');
                    final offset = Tween<Offset>(
                      begin: Offset(incomingIsSub ? 0.08 : -0.08, 0),
                      end: Offset.zero,
                    ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: _AreaGrid(
                    key: ValueKey(drilled ? 'sub' : 'main'),
                    options: options,
                    selected: selected,
                    showAllAreas: widget.isFilterMode && !drilled,
                    totalCount: _controller.accountCountForArea(''),
                    countFor: _countFor,
                    isSelected: (o) => _isSelected(o, selected),
                    onTap: (o) =>
                        o.hasChildren ? _drillInto(o) : _select(o.code ?? ''),
                    onTapAll: () => _select(''),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AreaGrid extends StatelessWidget {
  const _AreaGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.showAllAreas,
    required this.totalCount,
    required this.countFor,
    required this.isSelected,
    required this.onTap,
    required this.onTapAll,
  });

  final List<_AreaOption> options;
  final String selected;
  final bool showAllAreas;
  final int totalCount;
  final int Function(_AreaOption) countFor;
  final bool Function(_AreaOption) isSelected;
  final void Function(_AreaOption) onTap;
  final VoidCallback onTapAll;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (showAllAreas)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              0,
              BSizes.defaultSpace,
              BSizes.spaceBtwItems,
            ),
            sliver: SliverToBoxAdapter(
              child: _AllAreasTile(
                count: totalCount,
                selected: selected.isEmpty,
                onTap: onTapAll,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            0,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: BSizes.spaceBtwItemsLight,
              mainAxisSpacing: BSizes.spaceBtwItemsLight,
              childAspectRatio: 1.25,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final option = options[index];
                return _AreaTile(
                  option: option,
                  count: countFor(option),
                  selected: isSelected(option),
                  onTap: () => onTap(option),
                );
              },
              childCount: options.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared visual language for the tiles: flat surface, 1.5px border that turns
/// primary when selected, soft tint, and a check badge. Colours animate so a
/// selection reads as the same tile changing state.
BoxDecoration _tileDecoration(bool selected) => BoxDecoration(
      color: selected
          ? BCollectionColors.primary.withValues(alpha: 0.06)
          : BCollectionColors.surface,
      borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
      border: Border.all(
        color: selected ? BCollectionColors.primary : BCollectionColors.outline,
        width: 1.5,
      ),
    );

const Duration _tileDuration = Duration(milliseconds: 160);

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.option,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _AreaOption option;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = count == 0;

    return BPressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${option.name}, $count account${count == 1 ? '' : 's'}'
            '${option.hasChildren ? ', has regions' : ''}',
        child: AnimatedContainer(
          duration: _tileDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(BSizes.md),
          decoration: _tileDecoration(selected),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(
                      icon: option.icon, selected: selected, muted: empty),
                  const Spacer(),
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: empty ? BCollectionColors.inkMuted : BColors.dark,
                    ),
                  ),
                  const SizedBox(height: BSizes.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          empty
                              ? 'No accounts'
                              : '$count account${count == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                        ),
                      ),
                      if (option.hasChildren)
                        Text(
                          '${option.children.length} regions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: BCollectionColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Top-right affordance: check when selected, chevron for parents.
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: _tileDuration,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: selected
                      ? const Icon(
                          Iconsax.tick_circle5,
                          key: ValueKey('check'),
                          size: 22,
                          color: BCollectionColors.primary,
                        )
                      : option.hasChildren
                          ? const Icon(
                              Iconsax.arrow_right_3,
                              key: ValueKey('chevron'),
                              size: 18,
                              color: BCollectionColors.inkMuted,
                            )
                          : const SizedBox.shrink(key: ValueKey('none')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width "All areas" row shown at the top in filter mode; selected when
/// no area filter is set, so clearing the filter is a visible choice rather
/// than a separate action.
class _AllAreasTile extends StatelessWidget {
  const _AllAreasTile(
      {required this.count, required this.selected, required this.onTap});

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BPressableScale(
      onTap: onTap,
      pressedScale: 0.985,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'All areas, $count account${count == 1 ? '' : 's'}',
        child: AnimatedContainer(
          duration: _tileDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: BSizes.md, vertical: BSizes.md),
          decoration: _tileDecoration(selected),
          child: Row(
            children: [
              _IconBadge(
                  icon: Iconsax.global_search,
                  selected: selected,
                  muted: false,
                  size: 40),
              const SizedBox(width: BSizes.spaceBtwItemsLight),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All areas',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$count account${count == 1 ? '' : 's'} in your bucket',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: _tileDuration,
                opacity: selected ? 1 : 0,
                child: const Icon(Iconsax.tick_circle5,
                    size: 22, color: BCollectionColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.selected,
    required this.muted,
    this.size = 44,
  });

  final IconData icon;
  final bool selected;
  final bool muted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color =
        muted ? BCollectionColors.inkMuted : BCollectionColors.primary;

    return AnimatedContainer(
      duration: _tileDuration,
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? BCollectionColors.primary
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
      ),
      alignment: Alignment.center,
      child: Icon(icon,
          size: size * 0.5,
          color: selected ? BCollectionColors.surface : color),
    );
  }
}
