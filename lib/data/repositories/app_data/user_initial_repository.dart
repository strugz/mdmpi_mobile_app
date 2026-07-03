import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';

import '../../models/user_initial_model.dart';

class UserInitialRepository {
  static UserInitialRepository get instance => Get.find();

  /// --  WEB API HTTPS
  Future<List<UserInitialModel>> getAllUserInitial() async {
    try {
      final response = await http.get(
        // The local MDMPI.App source does not currently expose CNTMST.
        BApiEnvironment.liveUri('/api4/CNTMST/initial'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => UserInitialModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load User Initial');
      }
    } catch (e) {
      throw Exception('Something went wrong. Please try again!');
    }
  }
}
