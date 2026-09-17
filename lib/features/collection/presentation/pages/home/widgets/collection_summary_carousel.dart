import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/mirror_carousel.dart';
import 'package:mdmpi_mobile_app/common/widgets/cards/collection_summary_card.dart';

/// One summary tile of the carousel. [value] is read on every build so a
/// reactive wrapper (Obx) around the carousel keeps the figure live.
class CollectionSummaryPage {
  const CollectionSummaryPage({
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

/// The home dashboard's summary tiles in a [BMirrorCarousel]: one card at a
/// time, looping, with the active dot in the card's colour.
class CollectionSummaryCarousel extends StatelessWidget {
  const CollectionSummaryCarousel({
    super.key,
    required this.pages,
    this.height = 104,
    this.initialPage = 0,
  });

  final List<CollectionSummaryPage> pages;
  final double height;
  final int initialPage;

  @override
  Widget build(BuildContext context) {
    return BMirrorCarousel(
      itemCount: pages.length,
      height: height,
      initialPage: initialPage,
      dotColor: (i) => pages[i].color,
      onSettleTap: (i) => pages[i].onTap?.call(),
      itemBuilder: (context, i) {
        final page = pages[i];
        return CollectionSummaryCard(
          title: page.title,
          value: page.value,
          icon: page.icon,
          color: page.color,
          onTap: page.onTap,
        );
      },
    );
  }
}
