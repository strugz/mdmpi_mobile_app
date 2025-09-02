import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/request_model.dart';
import 'dart:convert';

import '../../../base/utils/exceptions/platform_exceptions.dart';

class RequestRepository extends GetxController {
  static RequestRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<void> insertRequest(RequestModel requestData) async {
    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['API_URL']!}/api3/request"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(requestData), // Encode the request data as JSON
      );
      if (response.statusCode == 200) {
        BLoaders.successSnackBar(
            title: 'Information', message: 'Success saving...');
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message:
                'Failed to insert request. Status code: ${response.statusCode}');
      }
    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred1: $e');
    }
  }

  /// -- WEB API HTTPS
  Future<void> updateRequest(RequestModel requestData) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                "${dotenv.env['API_URL']!}/api3/request/${requestData.requestID}"),
            headers: <String, String>{
              'Content-Type':
                  'application/json; charset=UTF-8', // Specify JSON content type
            },
            body: jsonEncode(requestData), // Encode the request data as JSON
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['error'] ==
            "Request updated successfully.") {
          BLoaders.successSnackBar(
              title: 'Information',
              message: jsonDecode(response.body)['error']);
          return;
        } else {
          BLoaders.warningSnackBar(
              title: 'Information',
              message: jsonDecode(response.body)['error']);
        }
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message:
                'Failed to update request. Status code: ${response.statusCode}');
      }
    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
    }
  }

  /// -- WEB API HTTPS
  Future<List<RequestModel>> getAllPendingRequestAPI() async {
    try {
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']}/api3/request"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => RequestModel.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load pending request');
      }
    } catch (e) {
      throw Exception('Something went wrong. Please try again: $e');
    }
  }
}
