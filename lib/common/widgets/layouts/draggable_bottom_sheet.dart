import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A reusable draggable bottom sheet with a drag handle, scrollable body,
/// an optional fixed info strip, and an optional fixed action widget at the bottom.
///
/// All content (body, bottomInfo, bottomAction) is placed inside the
/// scrollable area so the sheet can collapse cleanly to just the drag handle.
///
/// Layout (top → bottom):
/// ```
/// ┌──────────────────────┐
/// │     drag handle      │  ← always visible (GestureDetector for drag)
/// │ ──────────────────── │
/// │  scrollable [body]   │  ← scrolls with content
/// │   [bottomInfo]       │  ← scrolls with content
/// │   [bottomAction]     │  ← scrolls with content
/// └──────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// BDraggableBottomSheet(
///   body: MyDetailsWidget(),
///   bottomInfo: MyInfoStrip(),
///   bottomAction: MyActionButton(),
/// )
/// ```
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

  /// Optional action widget rendered at the bottom inside the scroll area.
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
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Drag handle — always at top
              SliverToBoxAdapter(child: _buildDragHandle(dark)),
              // Body content
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverToBoxAdapter(child: body),
              ),
              // Bottom info
              if (bottomInfo != null)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverToBoxAdapter(child: bottomInfo!),
                ),
              // Bottom action
              if (bottomAction != null)
                SliverPadding(
                  padding: const EdgeInsets.all(BSizes.sm),
                  sliver: SliverToBoxAdapter(child: bottomAction!),
                ),
            ],
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

