import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';

import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

/// Module type enum for determining which API endpoint to use
enum RequestModule {
  standardDelivery,
  pullOut,
  pickUp,
  airSea,
}

class CancelRemarksRepository {
  static CancelRemarksRepository get instance => Get.find();

  /// Get the appropriate API endpoint based on module type
  String _getCancelEndpoint(String requestId, RequestModule module) {
    switch (module) {
      case RequestModule.standardDelivery:
        return BApiEnvironment.api4Uri('/api4/request/cancel/$requestId')
            .toString();
      case RequestModule.pullOut:
        return BApiEnvironment.api4Uri(
                '/api4/RequestPullOutReturnPickUp/cancel/$requestId')
            .toString();
      case RequestModule.pickUp:
        return BApiEnvironment.api4Uri('/api4/RequestPickUp/cancel/$requestId')
            .toString();
      case RequestModule.airSea:
        return BApiEnvironment.api4Uri('/api4/RequestAirSea/cancel/$requestId')
            .toString();
    }
  }

  /// Add cancel remarks for a request
  /// [module] defaults to standardDelivery for backward compatibility
  Future<void> addCancelRemarks(CancelRemarksModel m,
      {RequestModule module = RequestModule.standardDelivery}) async {
    try {
      final url = _getCancelEndpoint(m.requestId, module);
      // Server expects a JSON body with remarks, date, and userUpdated.
      final payload = jsonEncode({
        'remarks': m.remarks,
        'date': m.date,
        'userUpdated': m.userUpdated,
      });
      final response = await http
          .patch(
            Uri.parse(url),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8'
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // success - keep behavior simple (no snackbars here, repository should not show UI)
        return;
      } else {
        throw Exception(
            'Failed to save cancel remarks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Something went wrong while saving cancel remarks: $e');
    }
  }

  /// Fetch cancel remarks by request ID
  /// [module] defaults to standardDelivery for backward compatibility
  Future<CancelRemarksModel> getCancelRemarksByRequestId(
    String requestId, {
    RequestModule module = RequestModule.standardDelivery,
  }) async {
    try {
      final url = _getCancelEndpoint(requestId, module);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);

        // Handle single object response: {"RequestID":"...","Remarks":"...","Date":"..."}
        if (jsonResponse is Map<String, dynamic>) {
          return CancelRemarksModel.fromJson(jsonResponse);
        }

        // Handle array response: [{"RequestID":"...","Remarks":"...","Date":"..."}]
        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          return CancelRemarksModel.fromJson(
              jsonResponse[0] as Map<String, dynamic>);
        }

        // Empty response
        return CancelRemarksModel.empty;
      } else {
        throw Exception(
            'Failed to load cancel remarks. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching cancel remarks: $e');
    }
  }
}
