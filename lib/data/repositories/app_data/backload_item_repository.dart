import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_item_model.dart';

/// Repository for backloaded items on Standard Delivery / Hotline Direct
/// requests (`/api4/BackloadItem/request/{requestId}`). The server validates
/// the request id against `a_tblRequestStandardDelivery` and answers 404
/// otherwise.
class BackloadItemRepository extends GetxController {
  static BackloadItemRepository get instance => Get.find();

  Uri _uri(String requestId) =>
      BApiEnvironment.api4Uri('/api4/BackloadItem/request/$requestId');

  /// Fetch the backloaded items recorded for a request. A 404 (not a
  /// delivery request, or unknown id) is returned as an empty list so
  /// callers can simply hide the section.
  Future<Result<List<BackloadItemModel>>> getByRequestId(
      String requestId) async {
    try {
      final response =
          await http.get(_uri(requestId)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return Result.success(const []);
      }
      if (response.statusCode != 200) {
        return Result.failure(
            'Failed to load backloaded items (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return Result.failure('Unexpected backloaded items response');
      }
      final items = decoded
          .whereType<dynamic>()
          .map((e) => e is Map<String, dynamic>
              ? BackloadItemModel.fromJson(e)
              : BackloadItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Result.success(items);
    } catch (e) {
      logDebug('BackloadItemRepository.getByRequestId error: $e');
      return Result.failure('Failed to load backloaded items: $e');
    }
  }

  /// Replace the backloaded-item set for a request (the server deletes
  /// existing rows and inserts this set; an empty list clears them).
  Future<Result<void>> replaceForRequest(
      String requestId, List<BackloadItemModel> items) async {
    try {
      final response = await http
          .post(_uri(requestId),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(items.map((e) => e.toInsertJson()).toList()))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return Result.success(null);
      }
      return Result.failure(
          'Failed to save backloaded items (${response.statusCode}): ${response.body}');
    } catch (e) {
      logDebug('BackloadItemRepository.replaceForRequest error: $e');
      return Result.failure('Failed to save backloaded items: $e');
    }
  }
}
