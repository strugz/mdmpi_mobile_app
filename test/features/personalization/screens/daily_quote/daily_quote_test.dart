import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/daily_quote_prompt_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/daily_quote.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/daily_quote/daily_quote_dialog.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/daily_quote/daily_quote_screen.dart';

class _FakeStorage implements GetStorage {
  final Map<String, dynamic> data = {};

  @override
  T? read<T>(String key) => data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Quote of the Day: the daily pick, the once-a-day popup, and the screen.
void main() {
  tearDown(Get.reset);

  group('the daily pick', () {
    test('has about 30 sayings and 18 verses, each verse with a reference', () {
      expect(BDailyQuotes.sayings.length, 30);
      expect(BDailyQuotes.verses.length, 18);
      expect(BDailyQuotes.sayings.every((q) => !q.isVerse), isTrue);
      expect(
          BDailyQuotes.verses.every((q) => q.reference!.isNotEmpty), isTrue);
      expect(BDailyQuotes.tips.length, 6);
    });

    test('every day has one saying and one verse', () {
      var day = DateTime(2026, 10, 28);
      for (var i = 0; i < 60; i++) {
        final today = BDailyQuotes.forDate(day);
        expect(today.saying.isVerse, isFalse, reason: '$day');
        expect(today.verse.isVerse, isTrue, reason: '$day');
        day = DateTime(day.year, day.month, day.day + 1);
      }
    });

    test('neither is the same two days in a row, for years either way', () {
      var day = DateTime(2025, 1, 1);
      var previous = BDailyQuotes.forDate(day);
      for (var i = 0; i < 365 * 4; i++) {
        day = DateTime(day.year, day.month, day.day + 1);
        final today = BDailyQuotes.forDate(day);
        expect(today.saying, isNot(same(previous.saying)), reason: '$day');
        expect(today.verse, isNot(same(previous.verse)), reason: '$day');
        previous = today;
      }
    });

    test('every quote comes up', () {
      final seen = <String>{};
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < 90; i++) {
        final today = BDailyQuotes.forDate(day);
        seen..add(today.saying.text)..add(today.verse.text);
        day = DateTime(day.year, day.month, day.day + 1);
      }
      expect(seen.length, 48);
    });

    test('same all day, changes at midnight', () {
      final morning = BDailyQuotes.forDate(DateTime(2026, 10, 28, 0, 0, 1));
      final night = BDailyQuotes.forDate(DateTime(2026, 10, 28, 23, 59, 59));
      final tomorrow = BDailyQuotes.forDate(DateTime(2026, 10, 29));
      expect(night.saying, same(morning.saying));
      expect(night.verse, same(morning.verse));
      expect(tomorrow.saying, isNot(same(morning.saying)));
      expect(tomorrow.verse, isNot(same(morning.verse)));
    });
  });

  group('the daily popup', () {
    test('is due once a day', () async {
      final storage = _FakeStorage();
      var now = DateTime(2026, 10, 28, 7);
      final c = DailyQuotePromptController(storage: storage, clock: () => now);

      expect(c.isDue, isTrue);
      await c.markSeen();
      expect(c.isDue, isFalse);
      now = DateTime(2026, 10, 28, 23, 59);
      expect(c.isDue, isFalse);
      now = DateTime(2026, 10, 29, 0, 1);
      expect(c.isDue, isTrue);
    });

    Future<List<bool?>> open(WidgetTester tester, DailyQuotePair today) async {
      final results = <bool?>[];
      await tester.pumpWidget(GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => results.add(await showDialog<bool>(
                    context: context,
                    builder: (_) => DailyQuoteDialog(today: today))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('Healthy tips pops true, Thanks pops false', (tester) async {
      final results = await open(
          tester,
          DailyQuotePair(
              saying: BDailyQuotes.sayings.first,
              verse: BDailyQuotes.verses.first));
      expect(find.text(BDailyQuotes.sayings.first.text), findsOneWidget);
      expect(find.text('— John 14:27'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily-quote-tips')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('daily-quote-thanks')));
      await tester.pumpAndSettle();
      expect(results, [true, false]);
    });
  });

  group('the screen', () {
    for (final size in const [Size(320, 568), Size(430, 932)]) {
      for (final brightness in Brightness.values) {
        testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} '
            '${brightness.name}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // The longest verse, at a large text size.
          final longest = DateTime(2026, 1, 8);
          final today = BDailyQuotes.forDate(longest);
          expect(today.verse.reference, 'Isaiah 41:10');
          await tester.pumpWidget(GetMaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: MediaQueryData(
                  size: size, textScaler: const TextScaler.linear(1.3)),
              child: DailyQuoteScreen(now: longest),
            ),
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Thursday, January 8, 2026'), findsOneWidget);
          expect(find.text(today.saying.text), findsOneWidget);
          expect(find.text('— Isaiah 41:10'), findsOneWidget);
          await tester.scrollUntilVisible(
              find.byKey(const ValueKey('daily-quote-disclaimer')), 200);
          expect(find.text('These are general tips, not medical advice.'),
              findsOneWidget);
          expect(find.text('Take care of your mind'), findsOneWidget);
        });
      }
    }
  });
}
