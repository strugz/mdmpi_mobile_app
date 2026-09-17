import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/home_skeleton.dart';

/// On the first login the bucket is fetched from the server and the home
/// screen used to show zeros and "No items" while it waited. The skeleton
/// stands in for that stretch, and only that stretch.

CollectionActivityController _bare() {
  // onInit needs DI; nothing here touches the repository.
  final c = CollectionActivityController();
  c.startAggregateTracking();
  return c;
}

void main() {
  test('first load is only the stretch before anything has loaded', () {
    final c = _bare();
    expect(c.isFirstLoad, isFalse, reason: 'idle before any load starts');

    c.isLoading.value = true;
    expect(c.isFirstLoad, isTrue);

    c.isLoading.value = false;
    c.hasLoadedOnce.value = true;
    expect(c.isFirstLoad, isFalse);

    // A later refresh keeps the real figures on screen.
    c.isLoading.value = true;
    expect(c.isFirstLoad, isFalse);
  });

  testWidgets('skeleton fills a bounded height without overflow',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          SizedBox(height: 120),
          Expanded(
            child: HomeSkeleton(
              margin: 16,
              gap: 12,
              sectionGap: 20,
              historyCardHeight: 172,
            ),
          ),
        ]),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeSkeleton), findsOneWidget);
  });
}
