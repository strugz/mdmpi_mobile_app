import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/user_initial_model.dart';

class UserInitialRepository {
  static UserInitialRepository get instance => Get.find();

  /// --  WEB API HTTPS
  Future<List<UserInitialModel>> getAllUserInitial() async {
    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']!}/api3/CNTMST/initial"),
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
