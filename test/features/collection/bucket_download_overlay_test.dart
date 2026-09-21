import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/bucket_download_overlay.dart';

Widget _host(BucketDownloadPhase phase, {int itemCount = 0}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          const Center(child: Text('behind')),
          BucketDownloadOverlay(phase: phase, itemCount: itemCount),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('idle renders nothing over the screen', (tester) async {
    await tester.pumpWidget(_host(BucketDownloadPhase.idle));
    await tester.pumpAndSettle();

    expect(find.text('Downloading bucket'), findsNothing);
    expect(find.text('behind'), findsOneWidget);
  });

  testWidgets('downloading shows the transfer card and cycles status text',
      (tester) async {
    await tester.pumpWidget(_host(BucketDownloadPhase.downloading));
    await tester.pump(BucketDownloadOverlay.fadeDuration);

    expect(find.text('Downloading bucket'), findsOneWidget);
    expect(find.text('Downloading bucket'), findsOneWidget);
    expect(find.text('Connecting to server…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Status line rotates after its interval (animation keeps running, so
    // pump a fixed duration instead of settling).
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Fetching collection items…'), findsOneWidget);
  });

  testWidgets('success shows the item count', (tester) async {
    await tester.pumpWidget(_host(BucketDownloadPhase.success, itemCount: 12));
    await tester.pumpAndSettle();

    expect(find.text('Bucket updated'), findsOneWidget);
    expect(find.text('12 items to collect'), findsOneWidget);
  });

  testWidgets('error shows the retry hint', (tester) async {
    await tester.pumpWidget(_host(BucketDownloadPhase.error));
    await tester.pumpAndSettle();

    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
  });

  testWidgets('overlay fades out when phase returns to idle', (tester) async {
    await tester.pumpWidget(_host(BucketDownloadPhase.success, itemCount: 1));
    await tester.pumpAndSettle();
    expect(find.text('Bucket updated'), findsOneWidget);

    await tester.pumpWidget(_host(BucketDownloadPhase.idle));
    await tester.pumpAndSettle();
    expect(find.text('Bucket updated'), findsNothing);
  });
}
