import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A reusable draggable bottom sheet with a drag handle, scrollable body,
/// an optional fixed info strip, and an optional fixed action widget at the bottom.
///
/// The [body] and [bottomInfo] scroll with the content.
/// The [bottomAction] stays pinned at the bottom of the sheet.
class BDraggableBottomSheet extends StatelessWidget {
  const BDraggableBottomSheet({
    super.key,
    required this.body,
    this.bottomInfo,
    this.bottomAction,
    this.initialChildSize = 0.45,
    this.minChildSize = 0.06,
    this.maxChildSize = 0.85,
    this.horizontalPadding = BSizes.sm,
  });

  /// The scrollable content area.
  final Widget body;

  /// Optional info widget rendered below the body inside the scroll area.
  final Widget? bottomInfo;

  /// Optional action widget pinned at the bottom of the sheet (does not scroll).
  final Widget? bottomAction;

  /// Initial height fraction of the screen.
  final double initialChildSize;

  /// Minimum height fraction of the screen (drag handle only ≈ 0.06).
  final double minChildSize;

  /// Maximum height fraction of the screen.
  final double maxChildSize;

  /// Horizontal padding applied to body content.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: minChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? BColors.black : BColors.light,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Hide bottomAction when the sheet is too collapsed
              // (drag handle = 30px, need at least ~90px for handle + button)
              final showAction =
                  bottomAction != null && constraints.maxHeight > 100;

              return Column(
                children: [
                  // Drag handle — always visible, drives sheet dragging
                  _buildDragHandle(dark),
                  // Scrollable content area
                  Expanded(
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        // Body content
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          sliver: SliverToBoxAdapter(child: body),
                        ),
                        // Bottom info (scrolls with content)
                        if (bottomInfo != null)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            sliver: SliverToBoxAdapter(child: bottomInfo!),
                          ),
                      ],
                    ),
                  ),
                  // Action button — pinned at the bottom, hidden when collapsed
                  if (showAction)
                    Padding(
                      padding: const EdgeInsets.all(BSizes.sm),
                      child: bottomAction!,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(bool dark) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: dark ? BColors.light : BColors.black,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
