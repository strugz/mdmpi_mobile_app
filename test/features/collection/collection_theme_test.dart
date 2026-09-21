import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Calls the theme switch from inside a build, the way AppRouter does.
class _CallsDuringBuild extends StatelessWidget {
  const _CallsDuringBuild(this.department);
  final String department;

  @override
  Widget build(BuildContext context) {
    BCollectionTheme.applyFor(department);
    return const Scaffold(body: SizedBox());
  }
}

void main() {
  tearDown(Get.reset);

  // Changing the theme marks GetMaterialApp dirty; doing that while it is
  // building throws "setState() or markNeedsBuild() called during build"
  // and painted the login a red screen. The switch has to wait a frame.
  testWidgets('switching from inside a build does not throw', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: BAppTheme.lightTheme,
      home: const _CallsDuringBuild('Collection'),
    ));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(Get.theme.scaffoldBackgroundColor, BCollectionColors.background);
  });

  testWidgets('another department keeps the base theme', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: BAppTheme.lightTheme,
      home: const _CallsDuringBuild('Logistics'),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(Get.theme.scaffoldBackgroundColor,
        BAppTheme.lightTheme.scaffoldBackgroundColor);
  });
}
