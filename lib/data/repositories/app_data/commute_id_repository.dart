import 'dart:async';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/api_response_keys.dart';
import 'package:mdmpi_mobile_app/base/utils/http/http_client.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';

/// Issues Commute IDs, which stand in for the Trip Ticket Number when a driver
/// commutes. `/api4`: the daily sequence lives in MDMPI.App
/// (`a_tblcommutecounters`), so every phone draws from the same counter and
/// two drivers can never get the same number.
class CommuteIdRepository extends GetxController {
  static CommuteIdRepository get instance => Get.find();

  static const String _path = '/api4/CommuteId';

  /// The next Commute ID for today (e.g. `202610200001`), or a failure the
  /// caller can show when the server is unreachable.
  Future<Result<String>> issue() async {
    try {
      final decoded = await BHttpHelper.post(_path, const <String, dynamic>{})
          .timeout(const Duration(seconds: 15));
      final id = BApiResponse.commuteId(decoded);
      if (id == null) {
        logDebug('CommuteIdRepository.issue: no CommuteID in $decoded');
        return Result.failure('The server did not return a Commute ID.');
      }
      return Result.success(id);
    } on TimeoutException {
      return Result.failure('The server took too long to issue a Commute ID.');
    } catch (e) {
      logDebug('CommuteIdRepository.issue failed: $e');
      return Result.failure(
          'Could not get a Commute ID. Check your internet connection.');
    }
  }
}
