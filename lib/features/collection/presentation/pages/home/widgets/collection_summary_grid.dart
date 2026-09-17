import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';

/// One figure on the dashboard scoreboard. [value] is read on every build, so
/// a reactive wrapper (Obx) around the grid keeps the number live.
class CollectionSummaryStat {
  const CollectionSummaryStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

/// The dashboard's four counts, two by two.
///
/// These were pages of a carousel, one at a time: 118pt of screen — a 104pt
/// card plus its dots — to show a single integer, with the other three behind
/// swipes. A carousel is for items you take in one at a time; four counts are
/// a scoreboard, and a scoreboard is read at a glance. Two by two shows all
/// four for about the height one page used to take.
///
/// The mirror carousel it replaced still runs the Engagement History below,
/// where the cards are rich enough that paging is the right way through them.
class CollectionSummaryGrid extends StatelessWidget {
  const CollectionSummaryGrid({super.key, required this.stats});

  final List<CollectionSummaryStat> stats;

  /// Gap between cells, the same on both axes so the block reads as a grid
  /// rather than as two rows that happen to sit near each other.
  static const double _gap = BSizes.sm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < stats.length; row += 2) ...[
          if (row > 0) const SizedBox(height: _gap),
          // IntrinsicHeight so the pair matches heights when one label wraps
          // and the other does not; stretch alone is unbounded in the
          // dashboard's scroll view and fails layout there.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: row + col < stats.length
                        ? _cell(stats[row + col])
                        // An odd count leaves a hole rather than a stretched
                        // last cell, so the columns stay aligned.
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(CollectionSummaryStat stat) => CollectionSummaryCard(
        title: stat.title,
        value: stat.value,
        icon: stat.icon,
        color: stat.color,
        onTap: stat.onTap,
      );
}
