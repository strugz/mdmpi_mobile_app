import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Search field plus a filter toggle.
///
/// Owns its [TextEditingController] so the visible text stays in sync when the
/// query is cleared externally (e.g. "Clear all filters"), and shows a clear
/// button that fades in only while there is something to clear.
class CollectionSearchFilterBar extends StatefulWidget {
  const CollectionSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilter,
    this.searchHint = 'Search…',
    this.initialValue = '',
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;
  final String searchHint;

  /// Current query from the owner. When this changes to something other than
  /// what the field shows (an external reset), the field is updated to match.
  final String initialValue;

  @override
  State<CollectionSearchFilterBar> createState() =>
      _CollectionSearchFilterBarState();
}

class _CollectionSearchFilterBarState extends State<CollectionSearchFilterBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  static const Duration _stateDuration = Duration(milliseconds: 160);
  static const double _fieldHeight = 48;

  @override
  void didUpdateWidget(covariant CollectionSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.defaultSpace,
        vertical: BSizes.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _fieldHeight,
              child: TextField(
                controller: _controller,
                onChanged: widget.onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  // Clear affordance: only rendered while there is text, and
                  // faded rather than popped so the field doesn't jitter.
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final hasText = value.text.isNotEmpty;
                      return AnimatedOpacity(
                        key: const ValueKey('search-clear'),
                        opacity: hasText ? 1 : 0,
                        duration: _stateDuration,
                        curve: Curves.easeOut,
                        child: IgnorePointer(
                          ignoring: !hasText,
                          child: IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clear,
                            icon: const Icon(Iconsax.close_circle5, size: 18),
                            color: BCollectionColors.inkMuted,
                          ),
                        ),
                      );
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: BSizes.sm),

          // Filter toggle: tint/border animate between idle and active so a
          // filter applied from the side sheet is confirmed on return.
          Semantics(
            button: true,
            toggled: widget.hasActiveFilter,
            label: widget.hasActiveFilter ? 'Filters active' : 'Filters',
            child: AnimatedContainer(
              duration: _stateDuration,
              curve: Curves.easeOut,
              width: _fieldHeight,
              height: _fieldHeight,
              decoration: BoxDecoration(
                color: widget.hasActiveFilter
                    ? BCollectionColors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                border: Border.all(
                  color: widget.hasActiveFilter
                      ? BCollectionColors.primary
                      : BCollectionColors.outline,
                  width: widget.hasActiveFilter ? 1.5 : 1,
                ),
              ),
              child: IconButton(
                tooltip: 'Filters',
                onPressed: widget.onFilterTap,
                icon: Icon(
                  Iconsax.filter_edit,
                  size: 20,
                  color: widget.hasActiveFilter
                      ? BCollectionColors.primary
                      : BCollectionColors.inkSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
