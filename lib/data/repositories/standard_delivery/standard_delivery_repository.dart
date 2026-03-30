import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'dart:convert';

import '../../../base/utils/exceptions/platform_exceptions.dart';
import '../../../features/logistics/models/cancel_remarks_model.dart';

class StandardDeliveryRepository extends GetxController {
  static StandardDeliveryRepository get instance => Get.find();

  Future<void> insertDelivery(StandardDeliveryModel requestData,
      [List<InventoryItemModel>? items]) async {
    try {
      // Map request + scanned items into DTO
      // Prefer explicitly provided items parameter; otherwise, try to read
      // `items` from the requestData (some callers may attach items there).
      final dto = StandardDeliveryMapper.toInsertDto(requestData, items);
      final payload = dto.toJson();

      logDebug('⚠️ Could not refresh Hotline Direct list: ${jsonEncode(payload)}');


      final response = await http.post(
        Uri.parse("${dotenv.env['API_URL']!}/api4/request"),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        BLoaders.successSnackBar(
            title: 'Information', message: 'Success saving...');
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message:
            'Failed to insert request. Status code: ${response.statusCode}');
      }      print(jsonEncode(payload));

    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred1: $e');
    }
  }

  Future<void> updateDelivery(StandardDeliveryModel requestData) async {
    try {
      final updateDto = StandardDeliveryMapper.toUpdateDto(requestData);
      final payload = updateDto.toJson();

      final url = "${dotenv.env['API_URL']!}/api4/request";

      final response = await http
          .patch(Uri.parse(url),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final rawBody = response.body;
        dynamic decodedBody;
        try {
          decodedBody = jsonDecode(rawBody);
        } catch (_) {
          decodedBody = rawBody;
        }

        String message;
        if (decodedBody is Map && decodedBody.containsKey('error')) {
          message = decodedBody['error'].toString();
        } else if (decodedBody is String) {
          message = decodedBody;
        } else {
          message = rawBody.toString();
        }

        if (message == 'Request updated successfully.' ||
            message.contains('updated successfully')) {
          BLoaders.successSnackBar(title: 'Information', message: message);
          return;
        } else {
          BLoaders.warningSnackBar(title: 'Information', message: message);
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

  Future<void> cancelDelivery(
      String requestID, String remarks, String user) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                "${dotenv.env['API_URL']!}/api4/request/cancel/$requestID/$user"),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(remarks),
          )
          .timeout(const Duration(seconds: 60));
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

  Future<CancelRemarksModel> getCancelRemarks(String requestID) async {
    try {
      final response = await http.get(Uri.parse(
          "${dotenv.env['API_URL']!}/api3/request/cancel/$requestID"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          return CancelRemarksModel.fromJson(
              jsonResponse[0] as Map<String, dynamic>);
        } else {
          throw Exception('No cancel remarks found for request ID: $requestID');
        }
      } else {
        throw Exception(
            'Failed to load cancel remarks. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching cancel remarks: $e');
    }
  }

  Future<List<StandardDeliveryModel>> getAllPending() async {
    try {
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']}/api4/request"));
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> jsonResponse;
        if (decoded is List) {
          jsonResponse = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonResponse = decoded['data'];
          } else if (decoded.containsKey('items') && decoded['items'] is List) {
            jsonResponse = decoded['items'];
          } else {
            final List<dynamic>? found =
                decoded.values.firstWhere((v) => v is List, orElse: () => null)
                    as List<dynamic>?;
            if (found != null) {
              jsonResponse = found;
            } else {
              throw Exception(
                  'Unexpected API response format: ${response.body}');
            }
          }
        } else {
          throw Exception('Unexpected API response format: ${response.body}');
        }

        final List<StandardDeliveryModel> parsed = [];
        for (var item in jsonResponse) {
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(StandardDeliveryModel.fromJson(map));
          } catch (e) {
            print('Failed to parse request item: $e');
            try {
              print('Item data: ${json.encode(item)}');
            } catch (_) {
              print('Item data: $item');
            }
          }
        }

        return parsed;
      } else {
        throw Exception('Failed to load pending request');
      }
    } catch (e, st) {
      throw Exception('Something went wrong. Please try again: $e\n$st');
    }
  }
}
