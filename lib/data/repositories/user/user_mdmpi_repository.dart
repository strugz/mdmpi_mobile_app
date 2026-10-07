import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../base/utils/exceptions/api_exception.dart';
import '../../models/cntmst_model.dart';

class UserMDMPIRepository extends GetxController {
  static UserMDMPIRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<CNTMSTModel>> getAllClientAPI() async {
    try {
      // /api2 rather than /api3: both return the same 107 contacts from the
      // same live host, but /api3 omits CNTSTS and CNTEGP entirely. Without
      // CNTSTS every cached row had a null status, so the requester query's
      // "skip deactivated staff" filter silently matched everyone.
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']!}/api2/cntmst"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => CNTMSTModel.fromJson(data)).toList();
      }

      // Name the endpoint and the status code. A 502 here means nginx cannot
      // reach the upstream service, which is a server outage rather than
      // anything the user can retry their way out of -- the old message said
      // "Failed to load Client" from the requester endpoint and buried the
      // status, which sent at least one investigation down the wrong path.
      throw BApiException(
        'requester list',
        '/api2/cntmst',
        response.statusCode,
      );
    } on BApiException {
      rethrow;
    } catch (e) {
      throw Exception('Could not load the requester list: $e');
    }
  }
}
