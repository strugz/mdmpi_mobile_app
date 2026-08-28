import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';

import '../../models/mobile_model.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class MobileRepository {
  static MobileRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<Mobile>> getAllMobile() async {
    // Return List<Mobile>
    try {
      final response = await http.get(
        BApiEnvironment.api4Uri('/api4/request/mobile'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Map to List<Mobile>
        return jsonData.map((item) => Mobile.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load mobiles. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      logDebug('Error in getAllMobile: $e');
      return [];
    }
  }
}
