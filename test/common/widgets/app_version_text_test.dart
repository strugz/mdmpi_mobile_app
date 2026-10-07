import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/app_version_text.dart';

/// The version line on the login screen, and the shared build read behind it.
void main() {
  tearDown(() => BAppBuildInfo.debugOverride(null));

  test('the build is read once and shared', () async {
    var reads = 0;
    BAppBuildInfo.debugOverride(() async {
      reads++;
      return const AppBuildInfo(appName: 'a', version: '1.1.112', build: '245');
    });
    final first = await BAppBuildInfo.current();
    final second = await BAppBuildInfo.current();
    expect(reads, 1);
    expect(identical(first, second), isTrue);
    expect(first.label, '1.1.112 (245)');
  });

  test('a failed read gives the unknown build instead of throwing', () async {
    BAppBuildInfo.debugOverride(() async => throw Exception('no platform'));
    final info = await BAppBuildInfo.current();
    expect(info.hasVersion, isFalse);
    expect(info.appName, 'MDMPI App');
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Center(child: BAppVersionText()))));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version once it is known', (tester) async {
    BAppBuildInfo.debugOverride(() async =>
        const AppBuildInfo(appName: 'a', version: '1.1.112', build: '245'));
    await pump(tester);
    expect(find.text('Version 1.1.112 (245)'), findsOneWidget);
  });

  testWidgets('a build read during the splash is there on the first frame',
      (tester) async {
    BAppBuildInfo.debugOverride(() async =>
        const AppBuildInfo(appName: 'a', version: '1.1.112', build: '245'));
    await BAppBuildInfo.current();
    expect(BAppBuildInfo.cached?.label, '1.1.112 (245)');

    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Center(child: BAppVersionText()))));
    // No settle: the very first frame already has it, fully opaque.
    expect(find.text('Version 1.1.112 (245)'), findsOneWidget);
    final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(fade.opacity, 1);
  });

  testWidgets('keeps its height but stays blank when the version cannot be read',
      (tester) async {
    BAppBuildInfo.debugOverride(() async => throw Exception('no platform'));
    await pump(tester);
    expect(find.byKey(const ValueKey('app-version-text')), findsNothing);
    expect(tester.getSize(find.byType(BAppVersionText)).height, greaterThan(0));
  });
}
