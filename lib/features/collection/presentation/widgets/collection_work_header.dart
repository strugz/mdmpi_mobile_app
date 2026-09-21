import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// The module header for a screen that is a list of work.
///
/// The dashboard header carries the screen name over the collector's own
/// name, which suits a screen you arrive at. On a queue it costs about 90pt —
/// a row and a half of accounts — to state the tab you just tapped and to
/// tell someone their own name on their own phone.
///
/// So this is the same purple, the same curve, one line. It keeps the module
/// looking like itself and gives the list back the height.
class CollectionWorkHeader extends StatelessWidget {
  const CollectionWorkHeader({super.key, required this.title, this.trailing});

  final String title;

  /// Optional action, aligned with the title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BPrimaryHeaderContainer(
      color: BCollectionColors.headerBackground,
      // The dashboard header gets its status bar inset from AppBar; without
      // one of those, the header has to ask for it itself.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BSizes.md,
            BSizes.sm,
            BSizes.md,
            // Enough to clear the 20pt the curve takes out of the bottom
            // corners, and no more.
            BSizes.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: BCollectionColors.surface,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
