import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/mirror_carousel.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/collection_bucket_button.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_subheading.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_bucket_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/recent_activities_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/bucket_download_overlay.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_summary_grid.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_sync_bar.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_totals_card.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/home_skeleton.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/total_collected_month/monthly_summary_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

class CollectionHomeScreen extends StatelessWidget {
  const CollectionHomeScreen({super.key});

  /// Phone-sized rhythm for the dashboard. The shared defaults (24px margins,
  /// 32px sections) are desktop-sized and pushed Engagement History below
  /// the fold on a real device.
  static const double _margin = BSizes.md; // 16
  static const double _gap = BSizes.spaceBtwItemsLight; // 12
  static const double _sectionGap = 20;

  /// Respect the system text size, but stop a large setting from wrapping
  /// buttons and truncating tile labels in this fixed dashboard layout.
  static const double _maxTextScale = 1.15;

  /// Placeholder height for the history carousel's loading skeleton only.
  /// The carousel itself sizes to its tallest card: a fixed 172 here once
  /// clipped a card's footer by 2px when its labels grew a point.
  static const double _historyCardHeight = 172;

  static const _pageTransition = Transition.cupertino;
  static const _pageDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Scaffold(
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxTextScale,
        child: Stack(
          children: [
            // The dashboard is a fixed set of blocks, nothing incremental,
            // so it is laid out to fit the viewport: the history panel takes
            // whatever height is left. Scrolling stays only as a fallback
            // for a screen shorter than the content (small phone, large
            // text), where a clipped layout would be worse than a scroll.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header
                        const BPrimaryHeaderContainer(
                          color: BCollectionColors.headerBackground,
                          child: Column(
                            children: [
                              BHomeAppBar(),
                              SizedBox(height: BSizes.spaceBtwSections),
                            ],
                          ),
                        ),

                        // Everything under the header. While the first load
                        // is still running the same blocks are drawn as grey
                        // bones; the real content crossfades in when the data
                        // lands. Only the first load: a later refresh keeps
                        // the figures on screen and updates them in place.
                        Expanded(
                          child: Obx(() => AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeOutCubic,
                                child: controller.isFirstLoad
                                    ? const HomeSkeleton(
                                        key: ValueKey('skeleton'),
                                        margin: _margin,
                                        gap: _gap,
                                        sectionGap: _sectionGap,
                                        historyCardHeight: _historyCardHeight,
                                      )
                                    : Column(
                                        key: const ValueKey('content'),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: _margin),
                                            child: Column(
                                              children: [
                                                // Money at a glance: one card, two figures.
                                                CollectionTotalsCard(
                                                  onActualTap: () => Get.to(
                                                    () =>
                                                        const MonthlySummaryScreen(
                                                            type: 'Actual'),
                                                    transition: _pageTransition,
                                                    duration: _pageDuration,
                                                  ),
                                                  onCollectedTap: () => Get.to(
                                                    () =>
                                                        const MonthlySummaryScreen(
                                                            type: 'Collection'),
                                                    transition: _pageTransition,
                                                    duration: _pageDuration,
                                                  ),
                                                ),
                                                const SizedBox(height: _gap),

                                                // Collection bucket
                                                Obx(() =>
                                                    CollectionBucketButton(
                                                      itemCount: controller
                                                          .bucketItems.length,
                                                      onTap: () => Get.to(
                                                        () =>
                                                            const CollectionBucketScreen(),
                                                        transition:
                                                            _pageTransition,
                                                        duration: _pageDuration,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    )),
                                                const SizedBox(height: _gap),

                                                // Download bucket / Upload (offline sync controls)
                                                const CollectionSyncBar(),
                                                const SizedBox(
                                                    height: _sectionGap),

                                                // The scoreboard: four counts,
                                                // two by two, all visible at
                                                // once. Obx wraps the whole
                                                // grid so every figure stays
                                                // live.
                                                Obx(() => CollectionSummaryGrid(
                                                      stats: [
                                                        CollectionSummaryStat(
                                                          title: 'Settled',
                                                          value: controller
                                                              .completedItems
                                                              .length
                                                              .toString(),
                                                          icon: Iconsax
                                                              .tick_circle,
                                                          color:
                                                              BCollectionColors
                                                                  .success,
                                                          onTap: () =>
                                                              _openCategory(
                                                                  'Settled',
                                                                  BCollectionColors
                                                                      .success),
                                                        ),
                                                        CollectionSummaryStat(
                                                          title: 'Past Due',
                                                          value: controller
                                                              .overdueItems
                                                              .length
                                                              .toString(),
                                                          icon: Iconsax.timer,
                                                          color:
                                                              BCollectionColors
                                                                  .danger,
                                                          onTap: () =>
                                                              _openCategory(
                                                                  'Past Due',
                                                                  BCollectionColors
                                                                      .danger),
                                                        ),
                                                        CollectionSummaryStat(
                                                          title:
                                                              'Reconciliation',
                                                          value: controller
                                                              .reconciliationItems
                                                              .length
                                                              .toString(),
                                                          icon:
                                                              Iconsax.status_up,
                                                          color:
                                                              BCollectionColors
                                                                  .reconcile,
                                                          onTap: () => _openCategory(
                                                              'Reconciliation',
                                                              BCollectionColors
                                                                  .reconcile),
                                                        ),
                                                        CollectionSummaryStat(
                                                          title:
                                                              'Advanced Payment',
                                                          value: controller
                                                              .advancedPaymentsCount
                                                              .toString(),
                                                          icon:
                                                              Iconsax.card_send,
                                                          color:
                                                              BCollectionColors
                                                                  .warning,
                                                          onTap: () => _openCategory(
                                                              'Advanced Payment',
                                                              BCollectionColors
                                                                  .warning),
                                                        ),
                                                      ],
                                                    )),
                                                const SizedBox(
                                                    height: _sectionGap),
                                              ],
                                            ),
                                          ),

                                          // Bottom: Recent Activities. Fills the rest of the screen.
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    BCollectionColors.surface,
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(
                                                        BSizes.borderRadiusLg)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: BCollectionColors.ink
                                                        .withValues(
                                                            alpha: 0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, -5),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: _margin),
                                                child: Column(
                                                  children: [
                                                    // Recent Activities Header with Show All button
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        // Expanded bounds the heading's width inside this Row
                                                        // (its internal Row uses Expanded for ellipsizing).
                                                        const Expanded(
                                                          child:
                                                              BSectionSubHeading(
                                                            title: BTexts
                                                                .collectionHomeSubTitle1,
                                                            showActionButton:
                                                                false,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Get.to(
                                                            () =>
                                                                const RecentActivitiesScreen(),
                                                            transition:
                                                                _pageTransition,
                                                            duration:
                                                                _pageDuration,
                                                          ),
                                                          child: const Text(
                                                              'Show All'),
                                                        ),
                                                      ],
                                                    ),

                                                    Obx(() {
                                                      // Today only, like Show All;
                                                      // earlier days are on the calendar.
                                                      final recentItems =
                                                          controller
                                                              .todayEngagements;

                                                      if (recentItems.isEmpty) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      BSizes
                                                                          .lg),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Icon(
                                                                  Iconsax.clock,
                                                                  size: 48,
                                                                  color: BCollectionColors
                                                                      .inkMuted),
                                                              const SizedBox(
                                                                  height: BSizes
                                                                      .sm),
                                                              Text(
                                                                'No engagements yet today',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                        color: BCollectionColors
                                                                            .inkMuted),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }

                                                      // The seven most recent entries, one per page;
                                                      // Show All has the rest. Cards are keyed by entry
                                                      // so a refresh does not rebuild every page.
                                                      final recent = recentItems
                                                          .take(7)
                                                          .toList();
                                                      final cards = [
                                                        for (final e in recent)
                                                          ActivityHistoryCard(
                                                            key: ValueKey(
                                                                e['history']),
                                                            history: e[
                                                                    'history']
                                                                as CollectionHistoryModel,
                                                            accountName:
                                                                e['accountName']
                                                                    .toString(),
                                                            invoiceId: e[
                                                                    'invoiceId']
                                                                ?.toString(),
                                                            item: e['item']
                                                                as CollectionItemModel?,
                                                            reconciledOn:
                                                                e['reconciledOn']
                                                                    as String?,
                                                            invoiceCount:
                                                                e['invoiceCount']
                                                                    as int?,
                                                            timeOnly: true,
                                                            margin:
                                                                EdgeInsets.zero,
                                                          ),
                                                      ];

                                                      return BMirrorCarousel(
                                                        itemCount: cards.length,
                                                        // No height: the carousel
                                                        // takes its tallest card's,
                                                        // at whatever font size.
                                                        onSettleTap: (i) =>
                                                            cards[i].showDetail(
                                                                context),
                                                        itemBuilder:
                                                            (context, i) =>
                                                                Align(
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: cards[i],
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // "Download Bucket" transition: server → bucket data-transfer
            // animation over a blurred scrim, resolving to a check / error.
            Obx(() => BucketDownloadOverlay(
                  phase: controller.bucketDownloadPhase.value,
                  itemCount: controller.lastDownloadedCount.value,
                )),
          ],
        ),
      ),
    );
  }

  static void _openCategory(String title, Color color) {
    Get.to(
      () => CategoryDetailScreen(title: title, color: color),
      transition: _pageTransition,
      duration: _pageDuration,
    );
  }
}
