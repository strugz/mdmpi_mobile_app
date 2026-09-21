import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
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

  // The dashboard measures its own intrinsic height (scroll view, min-height
  // box, IntrinsicHeight, Expanded tail), so the skeleton has to be able to
  // answer that question. A LayoutBuilder inside it could not, which failed
  // the whole page's layout and painted a blank screen on the device.
  testWidgets('lays out inside the dashboard fit recipe', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(children: const [
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
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(HomeSkeleton));
    expect(size.height, greaterThan(0));
    expect(size.width, greaterThan(0));
  });

  test('the bones are darker than the body they sit on', () {
    // Shimmer paints the bone in its base colour and sweeps the highlight
    // across it. The first attempt used a base a shade off the body, and the
    // skeleton was invisible on the device.
    expect(HomeSkeleton.boneBase, isNot(BCollectionColors.background));
    expect(HomeSkeleton.boneBase.computeLuminance(),
        lessThan(BCollectionColors.background.computeLuminance()));
  });
}
