import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/widgets/dialogs/b_photo_viewer.dart';

// 1x1 transparent PNG.
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x00, 0x00, //
  0x02, 0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  late Directory dir;
  late List<String> paths;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_viewer_test');
    paths = List.generate(3, (i) {
      final f = File('${dir.path}/p$i.png')..writeAsBytesSync(_png);
      return f.path;
    });
  });

  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('shows title, counter and dots; swiping advances the counter',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BPhotoViewer(
          localPaths: paths, title: 'Delivery Shot', caption: 'Request 01002'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Delivery Shot'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Request 01002'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing); // single close control
    expect(find.text('Close'), findsNothing); // no redundant text button

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('rotate turns only the current photo, a quarter turn per tap',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BPhotoViewer(localPaths: paths, title: 'Delivery Shot'),
    ));
    await tester.pumpAndSettle();

    AnimatedRotation rotationOfPage(int i) => tester
        .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
        .elementAt(i);

    expect(rotationOfPage(0).turns, 0);

    await tester.tap(find.byKey(const Key('photo_viewer_rotate')));
    await tester.pumpAndSettle();
    expect(rotationOfPage(0).turns, 0.25);

    await tester.tap(find.byKey(const Key('photo_viewer_rotate')));
    await tester.pumpAndSettle();
    expect(rotationOfPage(0).turns, 0.5);

    // Four taps come back to upright.
    await tester.tap(find.byKey(const Key('photo_viewer_rotate')));
    await tester.tap(find.byKey(const Key('photo_viewer_rotate')));
    await tester.pumpAndSettle();
    expect(rotationOfPage(0).turns, 0);

    // Rotating page 1 leaves page 2 alone, and page 1 remembers its turn
    // when you swipe back (PageView only keeps the visible page built).
    await tester.tap(find.byKey(const Key('photo_viewer_rotate')));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(rotationOfPage(0).turns, 0);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(rotationOfPage(0).turns, 0.25);
  });

  testWidgets('single photo shows the caption instead of a counter',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BPhotoViewer(localPaths: [paths.first], caption: 'Request 7'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Request 7'), findsOneWidget);
    expect(find.textContaining(' of '), findsNothing);
  });

  testWidgets('tapping the photo hides the chrome, tapping again shows it',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BPhotoViewer(localPaths: paths, title: 'Delivery Shot'),
    ));
    await tester.pumpAndSettle();

    Widget chrome() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect((chrome() as AnimatedOpacity).opacity, 1);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect((chrome() as AnimatedOpacity).opacity, 0);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect((chrome() as AnimatedOpacity).opacity, 1);
  });
}
