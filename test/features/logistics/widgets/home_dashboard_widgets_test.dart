import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/dashboard_aggregator.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_hero_card.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_stat_grid.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_view.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/date_scope_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_quick_actions.dart';

/// The one-screen Home. What these protect: New request is the first content
/// and every shortcut opens its form; the page fits a phone without
/// scrolling, and scrolls rather than overflows when it cannot; a tile tap
/// drills into its module and the back chip returns; the scope pill names a
/// date a person reads; and the skeleton gives way to numbers once the cache
/// is read.

class _Dashboard extends DashboardController {
  @override
  void onInit() {}
}

const _labels = [
  'Standard Delivery',
  'Pull out',
  'Pick up',
  'Air / Sea / Land',
  'Hotline Direct',
  'Stock receive',
  'Air / Sea / Land HD',
];

/// A phone-sized test surface: the Home body on the user's device once the
/// status bar and tab bar are taken out.
const _phone = Size(393, 780);

/// A short phone, where the one-screen layout must fall back to scrolling.
const _shortPhone = Size(360, 480);

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget child) => MaterialApp(
      theme: BAppTheme.lightTheme,
      home: Scaffold(body: child),
    );

/// The Home body as HomeScreen lays it out, without the GetX-bound header.
Widget _oneScreen(Widget header, Widget body) => CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, Expanded(child: body)],
          ),
        ),
      ],
    );

DashboardController _seeded(List<DashboardEntry> entries) {
  final controller = Get.put<DashboardController>(_Dashboard());
  controller.entries.assignAll(entries);
  controller.isLoading.value = false;
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  group('dateScopeLabel', () {
    test('reads as All Time, a year, or a month and year', () {
      expect(dateScopeLabel(null, null), 'All Time');
      expect(dateScopeLabel(2026, null), '2026');
      expect(dateScopeLabel(2026, 9), 'Sep 2026');
    });
  });

  group('HomeQuickActionGrid', () {
    test('four columns on a phone, one row of eight from 600px', () {
      expect(HomeQuickActionGrid.columnsFor(393), 4);
      expect(HomeQuickActionGrid.columnsFor(600), 8);
    });

    testWidgets('every shortcut is a tile, plus All forms, and a tap opens it',
        (tester) async {
      int? opened;
      var openedAll = false;
      await tester.pumpWidget(_app(SingleChildScrollView(
        child: HomeQuickActionGrid(
          labels: _labels,
          pages: const [],
          iconPaths: List.filled(_labels.length, 'assets/icons/request/delivery.png'),
          onOpen: (i) => opened = i,
          onOpenAll: () => openedAll = true,
        ),
      )));
      await tester.pump();

      expect(find.byType(QuickActionTile), findsNWidgets(_labels.length + 1));
      expect(find.text(HomeQuickActionGrid.allFormsLabel), findsOneWidget);

      await tester.tap(find.text('Hotline Direct'));
      expect(opened, 4);
      await tester.tap(find.text(HomeQuickActionGrid.allFormsLabel));
      expect(openedAll, isTrue);
    });
  });

  group('HomeQuickActionGrid label sizing', () {
    // The user's phone runs a 1.25 system font scale, which is what cut the
    // second line of "Standard Delivery" off the tile.
    const scaled = TextScaler.linear(1.25);
    final style = BAppTheme.lightTheme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      height: HomeQuickActionGrid.labelLineHeight,
    );
    final width = HomeQuickActionGrid.labelWidthFor(393, 4);
    final allLabels = [..._labels, HomeQuickActionGrid.allFormsLabel];

    QuickActionLabelLayout layoutAt(TextScaler scaler) =>
        HomeQuickActionGrid.resolveLabelLayout(
          labels: allLabels,
          maxWidth: width,
          style: style,
          textScaler: scaler,
        );

    test('label width follows the tile width the rows lay out', () {
      expect(
        width,
        closeTo((393 - 48 - 3 * 8) / 4 - 2 * QuickActionTile.horizontalPadding, 0.01),
      );
      expect(HomeQuickActionGrid.labelWidthFor(1280, 8), greaterThan(width));
    });

    test('the box holds two rendered lines of the longest label', () {
      final layout = layoutAt(scaled);

      for (final label in allLabels) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: layout.style),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: HomeQuickActionGrid.labelMaxLines,
          textScaler: scaled,
        )..layout(maxWidth: width);

        expect(layout.boxHeight, greaterThanOrEqualTo(painter.height),
            reason: '$label would clip');
        painter.dispose();
      }
    });

    test('type shrinks as the text scale grows, never past the floor', () {
      expect(layoutAt(const TextScaler.linear(2.0)).style.fontSize,
          lessThanOrEqualTo(layoutAt(TextScaler.noScaling).style.fontSize!));
      expect(layoutAt(const TextScaler.linear(4.0)).style.fontSize,
          greaterThanOrEqualTo(HomeQuickActionGrid.minLabelFontSize));
      expect(
        layoutAt(TextScaler.noScaling).style.fontSize,
        lessThanOrEqualTo(
            style.fontSize ?? HomeQuickActionGrid.defaultLabelFontSize),
      );
    });

    test('the resolved style always carries an explicit size', () {
      // The app's Poppins theme leaves labelSmall.fontSize null, so a tile
      // would otherwise inherit the ambient default size.
      expect(style.fontSize, isNull);
      expect(layoutAt(scaled).style.fontSize, isNotNull);
    });

    testWidgets('renders every label without clipping at a 1.25 font scale',
        (tester) async {
      _setScreen(tester, _phone);
      await tester.pumpWidget(MaterialApp(
        theme: BAppTheme.lightTheme,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: scaled),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: _TestQuickActions(),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      for (final label in allLabels) {
        final text = find.text(label);
        expect(text, findsOneWidget, reason: '$label should render');

        final rendered = tester.renderObject<RenderBox>(text);
        final box = tester.renderObject<RenderBox>(
          find.ancestor(of: text, matching: find.byKey(QuickActionTile.labelBoxKey)),
        );
        expect(rendered.size.height, lessThanOrEqualTo(box.size.height + 0.01),
            reason: '$label is taller than its box, so it clips');
        expect(rendered.size.width, lessThanOrEqualTo(box.size.width + 0.01),
            reason: '$label is wider than its box, so it clips');
      }
    });
  });

  group('LogisticsHomeHeader', () {
    test('greets by the hour', () {
      expect(LogisticsHomeHeader.greetingFor(DateTime(2026, 9, 18, 8)),
          'Good morning');
      expect(LogisticsHomeHeader.greetingFor(DateTime(2026, 9, 18, 13)),
          'Good afternoon');
      expect(LogisticsHomeHeader.greetingFor(DateTime(2026, 9, 18, 19)),
          'Good evening');
    });

    testWidgets('New request sits above the quick actions', (tester) async {
      await tester.pumpWidget(_app(SingleChildScrollView(
        child: LogisticsHomeHeader(
          now: DateTime(2026, 9, 18, 13),
          quickActions: const Text('ACTIONS'),
        ),
      )));
      await tester.pump();

      final title = tester.getTopLeft(find.text(LogisticsHomeHeader.newRequestTitle));
      final actions = tester.getTopLeft(find.text('ACTIONS'));
      expect(title.dy, lessThan(actions.dy));
      expect(find.textContaining('Good afternoon'), findsOneWidget);
    });
  });

  group('DashboardHeroCard', () {
    testWidgets('shows the total, the scope, and no legend', (tester) async {
      var scopeTapped = false;
      await tester.pumpWidget(_app(Align(
        alignment: Alignment.topCenter,
        child: DashboardHeroCard(
          title: 'All Requests',
          total: 12,
          scopeLabel: 'Sep 2026',
          onScopeTap: () => scopeTapped = true,
          segments: const [
            ShareSegment(label: 'Pick Up', count: 12, color: Colors.green),
            ShareSegment(label: 'Pull Out', count: 0, color: Colors.orange),
          ],
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('requests'), findsOneWidget);
      expect(find.textContaining('Pick Up'), findsNothing);
      expect(find.byType(DashboardShareBar), findsOneWidget);

      await tester.tap(find.text('Sep 2026'));
      expect(scopeTapped, isTrue);
    });

    testWidgets('a back chip appears only for a module', (tester) async {
      var back = false;
      await tester.pumpWidget(_app(Align(
        alignment: Alignment.topCenter,
        child: DashboardHeroCard(
          title: 'Pick Up',
          total: 2,
          scopeLabel: 'All Time',
          segments: const [],
          onBack: () => back = true,
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text(DashboardHeroCard.backLabel));
      expect(back, isTrue);
    });
  });

  group('DashboardStatGrid', () {
    test('three columns on a phone, four from 600px', () {
      expect(DashboardStatGrid.columnsFor(393), 3);
      expect(DashboardStatGrid.columnsFor(600), 4);
    });

    testWidgets('fills the height it is given and a tile tap drills in',
        (tester) async {
      _setScreen(tester, _phone);
      String? tapped;
      await tester.pumpWidget(_app(DashboardStatGrid(
        switchKey: 'all',
        stats: [
          for (var i = 0; i < 7; i++)
            DashboardStat(
              label: 'Module $i',
              count: i,
              icon: Icons.inbox,
              accent: Colors.green,
              onTap: () => tapped = 'Module $i',
            ),
        ],
      )));
      await tester.pumpAndSettle();

      // Three rows share the 780px body: each tile is far taller than its
      // ~72px minimum, and all rows are equal.
      final tiles = find.byType(DashboardStatCard);
      final first = tester.getSize(tiles.first);
      expect(first.height, closeTo((780 - 2 * DashboardStatGrid.gap) / 3, 0.5));
      expect(tester.getSize(tiles.last).height, first.height);

      await tester.tap(find.text('Module 6'));
      expect(tapped, 'Module 6');
    });
  });

  group('DashboardView on one screen', () {
    const entries = [
      DashboardEntry(module: FormCategoryType.pickUp, status: 'New Request'),
      DashboardEntry(module: FormCategoryType.pickUp, status: 'Delivered'),
      DashboardEntry(
          module: FormCategoryType.standardDelivery, status: 'New Request'),
    ];

    testWidgets('skeleton until the cache is read, then module tiles',
        (tester) async {
      _setScreen(tester, _phone);
      final controller = Get.put<DashboardController>(_Dashboard());
      await tester.pumpWidget(_app(const DashboardView()));

      expect(find.byType(DashboardSkeleton), findsOneWidget);

      controller.entries.assignAll(entries);
      controller.isLoading.value = false;
      await tester.pumpAndSettle();

      expect(find.byType(DashboardSkeleton), findsNothing);
      expect(find.byType(DashboardHeroCard), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(DashboardStatCard),
          findsNWidgets(FormCategoryType.values.length));
    });

    testWidgets('a module tile filters, and the back chip returns',
        (tester) async {
      _setScreen(tester, _phone);
      final controller = _seeded(entries);
      await tester.pumpWidget(_app(const DashboardView()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DashboardStatCard, 'Pick Up'));
      await tester.pumpAndSettle();
      expect(controller.selectedModule.value, FormCategoryType.pickUp);
      expect(find.byType(DashboardStatCard),
          findsNWidgets(controller.buckets.length));

      await tester.tap(find.text(DashboardHeroCard.backLabel));
      await tester.pumpAndSettle();
      expect(controller.selectedModule.value, isNull);
    });

    testWidgets('fits a phone without scrolling', (tester) async {
      _setScreen(tester, _phone);
      _seeded(entries);
      await tester.pumpWidget(_app(_oneScreen(
        LogisticsHomeHeader(
          now: DateTime(2026, 9, 18, 13),
          quickActions: HomeQuickActionGrid(
            labels: _labels,
            pages: const [],
            iconPaths: List.filled(_labels.length, 'assets/icons/request/delivery.png'),
            onOpen: (_) {},
            onOpenAll: () {},
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: DashboardView(),
        ),
      )));
      await tester.pumpAndSettle();

      final position =
          Scrollable.of(tester.element(find.byType(DashboardView))).position;
      expect(position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);

      // New request is above the fold and above the numbers.
      final title = tester.getTopLeft(find.text(LogisticsHomeHeader.newRequestTitle));
      final hero = tester.getTopLeft(find.byType(DashboardHeroCard));
      expect(title.dy, lessThan(hero.dy));
    });

    testWidgets('scrolls instead of overflowing on a short screen',
        (tester) async {
      _setScreen(tester, _shortPhone);
      _seeded(entries);
      await tester.pumpWidget(_app(
        _oneScreen(
          LogisticsHomeHeader(
            now: DateTime(2026, 9, 18, 13),
            quickActions: HomeQuickActionGrid(
              labels: _labels,
              pages: const [],
              iconPaths: List.filled(_labels.length, 'assets/icons/request/delivery.png'),
              onOpen: (_) {},
              onOpenAll: () {},
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: DashboardView(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final position =
          Scrollable.of(tester.element(find.byType(DashboardView))).position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}

/// The quick-action grid with test seams, const so the widget test can build
/// the surrounding MediaQuery subtree as a constant.
class _TestQuickActions extends StatelessWidget {
  const _TestQuickActions();

  @override
  Widget build(BuildContext context) {
    return HomeQuickActionGrid(
      labels: _labels,
      pages: const [],
      iconPaths:
          List.filled(_labels.length, 'assets/icons/request/delivery.png'),
      onOpen: (_) {},
      onOpenAll: () {},
    );
  }
}
