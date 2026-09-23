import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_copy_icon_button.dart';

void main() {
  testWidgets('copies the value, confirms in place, and names what was copied',
      (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: BCopyIconButton(value: '23-122', label: 'P.O.')),
      ),
    ));

    expect(find.byIcon(Iconsax.copy), findsOneWidget);
    await tester.tap(find.byType(BCopyIconButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(clipboard, '23-122');
    expect(find.byIcon(Iconsax.tick_circle5), findsOneWidget);
    expect(find.text('P.O. 23-122 copied'), findsOneWidget);

    // The tick reverts on its own.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byIcon(Iconsax.copy), findsOneWidget);
  });
}
