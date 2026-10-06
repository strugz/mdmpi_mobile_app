import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/models/team_engagement.dart';

/// Loads one date window of the feed; throws on failure (the repository catches).
typedef TeamFeedFetcher = Future<http.Response> Function(Uri url);

/// The Head's team feed (Collection TODO items 21–22), read-only and online
/// only, from `GET /api4/Collection/team/engagements?from=&to=&collector=`.
///
/// Nothing is cached on the phone: the Head reads what collectors have
/// uploaded, so the answer is only right while it is fresh. The screen says
/// "as of" the time it loaded.
class TeamActivityRepository extends GetxController {
  TeamActivityRepository({TeamFeedFetcher? fetch}) : _fetch = fetch ?? _httpGet;

  static TeamActivityRepository get instance => Get.find();

  static const String path = '/api4/Collection/team/engagements';

  final TeamFeedFetcher _fetch;

  static Future<http.Response> _httpGet(Uri url) =>
      http.get(url).timeout(const Duration(seconds: 60));

  /// `yyyy-MM-dd` for the query string.
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// The team's activity from [from] to [to] inclusive; one collector's when
  /// [collector] is given. Fails with a message the screen can show.
  Future<Result<TeamActivityFeed>> load({
    required DateTime from,
    required DateTime to,
    String? collector,
  }) async {
    final query = <String, String>{
      'from': dayKey(from),
      'to': dayKey(to),
      if (collector != null && collector.trim().isNotEmpty)
        'collector': collector.trim(),
    };
    try {
      final response = await _fetch(BApiEnvironment.api4Uri(path, query));
      if (response.statusCode != 200) {
        logDebug('TeamActivityRepository: ${response.statusCode} '
            '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
        return Result.failure(response.statusCode == 400
            ? 'The server refused the date range.'
            : 'The server could not load the team activity '
                '(${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return Result.failure('The server sent an unexpected answer.');
      }
      return Result.success(TeamActivityFeed.fromJson(decoded));
    } catch (e) {
      logDebug('TeamActivityRepository.load error: $e');
      return Result.failure(
          'Could not reach the server. Check your connection and try again.');
    }
  }
}
