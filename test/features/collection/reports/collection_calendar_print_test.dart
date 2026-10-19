import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_calendar_print_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_calendar_print_controller.dart';

/// Calendar → Print: `GET /api4/Collection/reports/calendar` and the
/// controller that shares the PDF it returns.
void main() {
  setUp(() => Get.testMode = true);

  final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7 sample'));

  group('CollectionCalendarPrintRepository', () {
    test('asks /api4 for the collector, month and Head', () async {
      Uri? asked;
      final repo = CollectionCalendarPrintRepository(fetch: (url) async {
        asked = url;
        return http.Response.bytes(pdfBytes, 200);
      });

      final result = await repo.load(
          collector: ' C001 ',
          month: DateTime(2026, 3, 17),
          notedBy: 'Ma. Head');

      expect(asked!.path, endsWith('/api4/Collection/reports/calendar'));
      expect(asked!.queryParameters,
          {'collector': 'C001', 'month': '2026-03', 'notedBy': 'Ma. Head'});
      expect(result.isSuccess, isTrue);
      expect(result.value, pdfBytes);
    });

    test('leaves out a blank Head', () async {
      Uri? asked;
      final repo = CollectionCalendarPrintRepository(fetch: (url) async {
        asked = url;
        return http.Response.bytes(pdfBytes, 200);
      });
      await repo.load(
          collector: 'C001', month: DateTime(2026, 10), notedBy: ' ');
      expect(asked!.queryParameters.containsKey('notedBy'), isFalse);
    });

    test('no collector fails without calling the server', () async {
      var called = false;
      final repo = CollectionCalendarPrintRepository(fetch: (_) async {
        called = true;
        return http.Response.bytes(pdfBytes, 200);
      });
      final result =
          await repo.load(collector: '  ', month: DateTime(2026, 10));
      expect(result.isFailure, isTrue);
      expect(called, isFalse);
    });

    test('an older server (404), an error, junk or no connection fail',
        () async {
      final cases = <String, CalendarPdfFetcher>{
        'update': (_) async => http.Response('Not Found', 404),
        '500': (_) async => http.Response('boom', 500),
        'unexpected': (_) async => http.Response('{"oops":1}', 200),
        'connection': (_) async => throw TimeoutException('slow'),
      };
      for (final entry in cases.entries) {
        final result =
            await CollectionCalendarPrintRepository(fetch: entry.value)
                .load(collector: 'C001', month: DateTime(2026, 10));
        expect(result.isFailure, isTrue, reason: entry.key);
        expect(result.error, contains(entry.key), reason: entry.key);
      }
    });
  });

  group('CollectionCalendarPrintController', () {
    test('shares the month under its file name with the Head as Noted by',
        () async {
      String? sharedName;
      String? askedCollector;
      String? askedHead;
      DateTime? askedMonth;
      final controller = CollectionCalendarPrintController(
        collectorCode: () => 'C001',
        headName: () => ' Ma. Head ',
        load: ({required collector, required month, notedBy}) async {
          askedCollector = collector;
          askedMonth = month;
          askedHead = notedBy;
          return Result.success(pdfBytes);
        },
        share: (bytes, {required fileName}) async {
          sharedName = fileName;
          return Result.success(true);
        },
      );

      final error = await controller.printMonth(DateTime(2026, 10, 19));

      expect(error, isNull);
      expect(askedCollector, 'C001');
      expect(askedMonth, DateTime(2026, 10, 19));
      expect(askedHead, 'Ma. Head');
      expect(sharedName, 'Collection-Calendar-C001-2026-10.pdf');
      expect(controller.isBusy.value, isFalse);
    });

    test('no Head chosen prints a blank Noted by line', () async {
      String? askedHead = 'unset';
      final controller = CollectionCalendarPrintController(
        collectorCode: () => 'C001',
        headName: () => '',
        load: ({required collector, required month, notedBy}) async {
          askedHead = notedBy;
          return Result.success(pdfBytes);
        },
        share: (bytes, {required fileName}) async => Result.success(true),
      );
      await controller.printMonth(DateTime(2026, 10));
      expect(askedHead, isNull);
    });

    test('a load failure is returned and nothing is shared', () async {
      var shared = false;
      final controller = CollectionCalendarPrintController(
        collectorCode: () => 'C001',
        headName: () => '',
        load: ({required collector, required month, notedBy}) async =>
            Result.failure('Could not reach the server.'),
        share: (bytes, {required fileName}) async {
          shared = true;
          return Result.success(true);
        },
      );
      expect(await controller.printMonth(DateTime(2026, 10)),
          'Could not reach the server.');
      expect(shared, isFalse);
      expect(controller.isBusy.value, isFalse);
    });

    test('a second tap while loading is ignored', () async {
      var loads = 0;
      final gate = Completer<Result<Uint8List>>();
      final controller = CollectionCalendarPrintController(
        collectorCode: () => 'C001',
        headName: () => '',
        load: ({required collector, required month, notedBy}) {
          loads++;
          return gate.future;
        },
        share: (bytes, {required fileName}) async => Result.success(true),
      );
      final first = controller.printMonth(DateTime(2026, 10));
      expect(controller.isBusy.value, isTrue);
      await controller.printMonth(DateTime(2026, 10));
      gate.complete(Result.success(pdfBytes));
      await first;
      expect(loads, 1);
    });
  });
}
