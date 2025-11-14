// filepath: c:\Users\JayBryanCAbaoag\Documents\VuexJaysWayFile\VuexJaysWayFile\MDMPIMobileApp\mdmpi_mobile_app\lib\data\repositories\pull_out\pull_out_repository.dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/exceptions/format_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/exceptions/platform_exceptions.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

/// Repository for Pull-Out requests. Handles API communication for
/// - GetAll
/// - Insert
/// - Update
class PullOutRepository extends GetxController {
  static PullOutRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  // Endpoint base (adjust if backend uses a different route)
  static const String _resource = '/api4/pullout';

  /// Fetch all pull-out requests
  Future<List<PullOutModel>> getAll() async {
    try {
      final response = await http.get(_uri(_resource));
      if (response.statusCode == 200) {
        final body = response.body;
        final decoded = jsonDecode(body);
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            items = decoded['data'];
          } else if (decoded['items'] is List) {
            items = decoded['items'];
          } else {
            final List firstList = decoded.values
                .firstWhere((v) => v is List, orElse: () => const []) as List;
            items = List<dynamic>.from(firstList);
          }
        } else {
          throw Exception('Unexpected API response format');
        }

        return items
            .whereType<dynamic>()
            .map((e) => e is Map<String, dynamic>
                ? PullOutModel.fromJson(e)
                : PullOutModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw Exception('Failed to load pull-out requests (${response.statusCode})');
      }
    } catch (e, st) {
      // Keep debug prints minimal in production per project style; using snackbars for user feedback
      BLoaders.errorSnackBar(title: 'Error', message: 'Failed to fetch pull-out list');
      throw Exception('getAll pull-out error: $e\n$st');
    }
  }

  /// Insert a new pull-out request
  Future<void> insert(PullOutModel data) async {
    try {
      final payload = data.toJsonInsert();
      final response = await http.post(
        _uri(_resource),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        BLoaders.successSnackBar(title: 'Information', message: 'Success saving...');
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message: 'Failed to insert pull-out. Status code: ${response.statusCode}');
      }
    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
    }
  }

  /// Update an existing pull-out request
  Future<void> updatePullOut(PullOutModel data) async {
    try {
      final payload = _buildUpdatePayload(data);
      final response = await http.patch(
        _uri(_resource),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final raw = response.body;
        dynamic decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          decoded = raw;
        }
        String message;
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'].toString();
        } else if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'].toString();
        } else if (decoded is String) {
          message = decoded;
        } else {
          message = 'Update processed';
        }

        if (message.toLowerCase().contains('success')) {
          BLoaders.successSnackBar(title: 'Information', message: message);
        } else {
          BLoaders.warningSnackBar(title: 'Information', message: message);
        }
      } else {
        BLoaders.errorSnackBar(
            title: 'Error',
            message: 'Failed to update pull-out. Status code: ${response.statusCode}');
      }
    } on TFormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
    }
  }

  Map<String, dynamic> _buildUpdatePayload(PullOutModel m) {
    // Start with ID (required for update)
    final Map<String, dynamic> data = {};
    void put(String key, String value) {
      if (value.isNotEmpty) data[key] = value;
    }

    if (m.id.isNotEmpty) data['RequestID'] = m.id;
    put('ClientID', m.clientId);
    put('ClientContactPerson', m.clientContactPerson);
    put('FormCategoryID', m.formCategoryId);
    put('ItemCategoryID', m.itemCategoryId);
    put('SlipNo', m.slipNo);
    put('IRRFNumber', m.irrfNumber);
    put('IRRFDate', m.irrfDate);
    put('ReasonForReturn', m.reasonForReturn);
    put('ReleasedBy', m.releasedBy);
    put('PullOutDate', m.pullOutDate);
    put('PullOutDateStartAt', m.pullOutDateStartAt);
    put('PullOutDateEndAt', m.pullOutDateEndAt);
    put('RequestStatus', m.requestStatus);
    put('TripTicketNumber', m.tripTicketNumber);
    put('Driver', m.driver);
    put('Helper', m.helper);
    put('CreatedAt', m.createdAt);
    put('UpdatedAt', m.updatedAt);
    if (m.documentReference.isNotEmpty) {
      data['DocumentReference'] = m.documentReference;
    }
    if (m.client.id.isNotEmpty || m.client.name.isNotEmpty) {
      data['Client'] = m.client.toJson();
    }
    return data;
  }
}
