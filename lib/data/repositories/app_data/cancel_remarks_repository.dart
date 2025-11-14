import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

class CancelRemarksRepository {
  static CancelRemarksRepository get instance => Get.find();

  /// --  WEB API HTTPS
  Future<void> addCancelRemarks(CancelRemarksModel m) async {
    try {
      final url = "${dotenv.env['API_URL']!}/api4/request/cancel/${m.requestId}";
      // Server expects a JSON body with remarks (and optionally date).
      final payload = jsonEncode({'remarks': m.remarks, 'date': m.date});
      final response = await http.patch(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: payload,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // success - keep behavior simple (no snackbars here, repository should not show UI)
        return;
      } else {
        throw Exception('Failed to save cancel remarks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Something went wrong while saving cancel remarks: $e');
    }
  }

  /// Fetch cancel remarks by request ID (GET /api3/request/cancel/{id})
  Future<CancelRemarksModel> getCancelRemarksByRequestId(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']!}/api3/request/cancel/$requestId"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          return CancelRemarksModel.fromJson(jsonResponse[0] as Map<String, dynamic>);
        } else {
          return CancelRemarksModel.empty;
        }
      } else {
        throw Exception('Failed to load cancel remarks. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching cancel remarks: $e');
    }
  }
}
