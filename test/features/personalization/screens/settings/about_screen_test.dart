import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/about_screen.dart';

/// Settings → About (Collection TODO item 15).
void main() {
  tearDown(Get.reset);

  test('the newest group stands in for a version with no notes yet', () {
    final newest = BWhatsNew.groups.first;
    expect(BWhatsNew.forVersion(newest.version), newest);
    expect(BWhatsNew.forVersion('9.9.9'), newest);
    expect(BWhatsNew.forVersion(''), newest);
    expect(newest.items, isNotEmpty);
  });

  test('the version label hides a build number that repeats the version', () {
    expect(
        const AppBuildInfo(appName: 'a', version: '1.1.110', build: '110').label,
        '1.1.110 (110)');
    expect(
        const AppBuildInfo(appName: 'a', version: '1.1.110', build: '1.1.110')
            .label,
        '1.1.110');
    expect(const AppBuildInfo(appName: 'a', version: '1.1.110', build: '').label,
        '1.1.110');
  });

  Future<void> pump(WidgetTester tester, AppBuildInfo info) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    Get.put(AboutController(load: () async => info));
    await tester.pumpWidget(const GetMaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version and what is new in it', (tester) async {
    final newest = BWhatsNew.groups.first;
    await pump(tester,
        AppBuildInfo(appName: 'MDMPI App', version: newest.version, build: '7'));

    expect(find.text('Version ${newest.version} (7)'), findsOneWidget);
    expect(find.text("What's new in ${newest.version}"), findsOneWidget);
    expect(find.byKey(const ValueKey('about-newer-note')), findsNothing);
    expect(find.textContaining(newest.items.first.title), findsOneWidget);
    expect(find.byKey(const ValueKey('about-copy')), findsOneWidget);
  });

  testWidgets('a build with no notes shows the newest list and says so',
      (tester) async {
    await pump(tester,
        const AppBuildInfo(appName: 'MDMPI App', version: '9.9.9', build: ''));
    expect(find.text('Version 9.9.9'), findsOneWidget);
    expect(find.byKey(const ValueKey('about-newer-note')), findsOneWidget);
    expect(find.textContaining('You are on 9.9.9'), findsOneWidget);
  });

  testWidgets('an unreadable version does not break the page', (tester) async {
    Get.put(AboutController(load: () async => throw Exception('no platform')));
    await tester.pumpWidget(const GetMaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Version unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('about-copy')), findsNothing);
  });
}
