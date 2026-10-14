import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/data/repositories/collection/team_activity_repository.dart';

/// `GET /api4/Collection/team/summary?month=`: the query, the answer, a
/// server without the endpoint (no summary: the reports fall back to the team
/// feed), and real failures, which must not look like that.
void main() {
  test('asks for the month and reads the rows', () async {
    Uri? asked;
    final repo = TeamActivityRepository(fetch: (url) async {
      asked = url;
      return http.Response(
          '{"Month":"2026-09","Collectors":[{"Code":"MAR","Name":"Mar",'
          '"Collected":300,"SettledInvoices":2}]}',
          200);
    });
    final result = await repo.loadSummary('2026-09');
    expect(asked!.path, endsWith('/api4/Collection/team/summary'));
    expect(asked!.queryParameters, {'month': '2026-09'});
    expect(result.isSuccess, isTrue);
    expect(result.value!.collectors.single.settledInvoices, 2);
  });

  test('a server without the summary (404) is no summary, not an error',
      () async {
    final repo = TeamActivityRepository(
        fetch: (_) async => http.Response('Not Found', 404));
    final result = await repo.loadSummary('2026-09');
    expect(result.isSuccess, isTrue,
        reason: 'the reports fall back to the team feed');
    expect(result.value, isNull);
  });

  test('a server error fails, so it is not taken for an older server',
      () async {
    for (final code in [500, 502, 401, 403]) {
      final repo = TeamActivityRepository(
          fetch: (_) async => http.Response('boom', code));
      final result = await repo.loadSummary('2026-09');
      expect(result.isFailure, isTrue, reason: '$code');
      expect(result.error, contains('$code'));
    }
  });

  test('an answer it cannot read fails', () async {
    for (final body in ['[]', '"text"', 'not json', '']) {
      final repo =
          TeamActivityRepository(fetch: (_) async => http.Response(body, 200));
      expect((await repo.loadSummary('2026-09')).isFailure, isTrue,
          reason: body);
    }
  });

  test('a summary for another month is refused, not shown as this one',
      () async {
    final repo = TeamActivityRepository(
        fetch: (_) async => http.Response(
            '{"Month":"2026-08","Collectors":[{"Code":"MAR"}]}', 200));
    final result = await repo.loadSummary('2026-09');
    expect(result.isFailure, isTrue);
    expect(
        result.error, 'The server sent the summary for 2026-08, not 2026-09.');
  });

  test('a summary without a Month is taken as the month asked for', () async {
    final repo = TeamActivityRepository(
        fetch: (_) async =>
            http.Response('{"Collectors":[{"Code":"MAR"}]}', 200));
    final result = await repo.loadSummary('2026-09');
    expect(result.value!.collectors.single.code, 'MAR');
  });

  test('missing keys read as zero, not a crash', () async {
    final repo = TeamActivityRepository(
        fetch: (_) async => http.Response(
            '{"Month":"2026-09","Collectors":[{"Code":"MAR"}]}', 200));
    final mar = (await repo.loadSummary('2026-09')).value!.collectors.single;
    expect(mar.code, 'MAR');
    expect(mar.collected, 0);
    expect(mar.settledInvoices, 0);
  });

  test('no connection fails with a message', () async {
    final repo =
        TeamActivityRepository(fetch: (_) async => throw Exception('offline'));
    final result = await repo.loadSummary('2026-09');
    expect(result.isFailure, isTrue);
    expect(result.error, contains('connection'));
  });
}
