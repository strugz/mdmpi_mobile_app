import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';

/// Loads the printout; throws on failure (the repository catches).
typedef CalendarPdfFetcher = Future<http.Response> Function(Uri url);

/// The Collection Calendar printout for reimbursement: one collector's month
/// as a PDF, drawn on the server (QuestPDF) from
/// `GET /api4/Collection/reports/calendar?collector=&month=&notedBy=`.
///
/// Online only and uploaded work only, like the team feed: the server has
/// nothing still waiting in the outbox.
class CollectionCalendarPrintRepository extends GetxController {
  CollectionCalendarPrintRepository({CalendarPdfFetcher? fetch})
      : _fetch = fetch ?? _httpGet;

  static CollectionCalendarPrintRepository get instance => Get.find();

  static const String path = '/api4/Collection/reports/calendar';

  final CalendarPdfFetcher _fetch;

  static Future<http.Response> _httpGet(Uri url) =>
      http.get(url).timeout(const Duration(seconds: 60));

  /// `yyyy-MM` for the query string.
  static String monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  /// The PDF for [collector]'s [month]; [notedBy] is printed under "Noted by".
  Future<Result<Uint8List>> load({
    required String collector,
    required DateTime month,
    String? notedBy,
  }) async {
    final code = collector.trim();
    if (code.isEmpty) {
      return Result.failure('Sign in as a collector to print the calendar.');
    }
    final query = <String, String>{
      'collector': code,
      'month': monthKey(month),
      if (notedBy != null && notedBy.trim().isNotEmpty)
        'notedBy': notedBy.trim(),
    };
    try {
      final response = await _fetch(BApiEnvironment.api4Uri(path, query));
      if (response.statusCode == 404) {
        return Result.failure(
            'The server cannot print the calendar yet. Ask IT to update it.');
      }
      if (response.statusCode != 200) {
        logDebug('CollectionCalendarPrintRepository: ${response.statusCode}');
        return Result.failure(
            'The server could not make the printout (${response.statusCode}).');
      }
      final bytes = response.bodyBytes;
      if (bytes.length < 4 || String.fromCharCodes(bytes.take(4)) != '%PDF') {
        return Result.failure('The server sent an unexpected answer.');
      }
      return Result.success(bytes);
    } catch (e) {
      logDebug('CollectionCalendarPrintRepository.load error: $e');
      return Result.failure(
          'Could not reach the server. Check your connection and try again.');
    }
  }
}
