import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';
import 'dart:convert';

import '../../../features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/b_in_flight_requests.dart';

class StandardDeliveryRepository extends GetxController {
  static StandardDeliveryRepository get instance => Get.find();

  /// Insert a new request, with its scanned [items]. Returns `true` only when
  /// the server accepted it (HTTP 201) — callers must gate follow-up side
  /// effects (SMS, WebSocket notifications) on that, so a failed POST never
  /// notifies the recipient about a request that was never created.
  ///
  /// Never throws: whatever goes wrong is shown to the user here and comes
  /// back as `false`.
  Future<bool> insertDelivery(
    StandardDeliveryModel requestData, [
    List<InventoryItemModel>? items,
    http.Client? client,
  ]) async {
    try {
      final payload =
          StandardDeliveryMapper.toInsertDto(requestData, items).toJson();

      final response = await (client ?? http.Client()).post(
        BApiEnvironment.api4Uri('/api4/request'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        BLoaders.successSnackBar(
            title: 'Information', message: 'Success saving...');
        return true;
      }

      BLoaders.errorSnackBar(
          title: 'Error',
          message:
              'Failed to insert request. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      logDebug('StandardDeliveryRepository.insertDelivery error: $e');
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
      return false;
    }
  }

  /// Update an existing request. Returns `true` only when the server
  /// confirmed the update — callers must gate follow-up side effects (SMS,
  /// WebSocket notifications, the local DB write) on that, so a rejected
  /// update never notifies the recipient about a status the server never
  /// recorded. A 200 carrying an error or unrecognised message counts as a
  /// failure: it is already surfaced as a warning, and an unconfirmed update
  /// is not something to text a client about.
  ///
  /// Never throws: whatever goes wrong is shown to the user here and comes
  /// back as `false`.
  Future<bool> updateDelivery(
    StandardDeliveryModel requestData,
    String actionBy, {
    bool showSuccessSnackBar = true,
    http.Client? client,
  }) async {
    try {
      final payload =
          StandardDeliveryMapper.toUpdateDto(requestData, actionBy).toJson();

      final response = await (client ?? http.Client())
          .patch(BApiEnvironment.api4Uri('/api4/request'),
              headers: const {
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final message = _messageFrom(response.body);

        if (message.contains('updated successfully')) {
          if (showSuccessSnackBar) {
            BLoaders.successSnackBar(title: 'Information', message: message);
          }
          return true;
        }

        BLoaders.warningSnackBar(title: 'Information', message: message);
        return false;
      }

      BLoaders.errorSnackBar(
          title: 'Error',
          message:
              'Failed to update request. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      logDebug('StandardDeliveryRepository.updateDelivery error: $e');
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
      return false;
    }
  }

  /// The human-readable message in an API response body, which may be a JSON
  /// object (`{"error": ...}` / `{"message": ...}`), a bare JSON string, or
  /// plain text.
  static String _messageFrom(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return body;
    }
    if (decoded is Map) {
      return (decoded['error'] ?? decoded['message'] ?? body).toString();
    }
    return decoded is String ? decoded : body;
  }

  /// Cancel a request. Returns `true` only when the server accepted the
  /// cancellation, so callers can withhold the cancellation SMS when it did
  /// not go through.
  ///
  /// Never throws: whatever goes wrong is shown to the user here and comes
  /// back as `false`.
  Future<bool> cancelDelivery(String requestID, String remarks, String user,
      {http.Client? client}) async {
    try {
      final response = await (client ?? http.Client())
          .patch(
            BApiEnvironment.api4Uri('/api4/request/cancel/$requestID/$user'),
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(remarks),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        BLoaders.successSnackBar(
            title: 'Information', message: 'Success saving...');
        return true;
      }

      BLoaders.errorSnackBar(
          title: 'Error',
          message:
              'Failed to cancel request. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      logDebug('StandardDeliveryRepository.cancelDelivery error: $e');
      BLoaders.errorSnackBar(title: 'Error', message: 'An error occurred: $e');
      return false;
    }
  }

  Future<CancelRemarksModel> getCancelRemarks(String requestID) async {
    try {
      // /api2, not /api4: the cancel route does not exist on the api4 host --
      // every casing 404s there, while /api4/Request/image answers, so it is
      // the route that is missing rather than the host. /api2 answers, and it
      // is where cntmst and accmst already read from.
      final response = await http.get(Uri.parse(
          "${dotenv.env['API_URL']!}/api2/request/cancel/$requestID"));

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

  /// Fetches requests from `/api4/request`.
  ///
  /// [scope] narrows the fetch server-side via `?dateFilter=`. The offline and
  /// error fallbacks deliberately return the *whole* local table regardless of
  /// scope; the caller's client-side filter narrows it.
  /// Collapses concurrent identical fetches (paired tabs share this repo).
  final BInFlightRequests _inFlight = BInFlightRequests();

  Future<List<StandardDeliveryModel>> getAllPending({
    bool allowLocalFallback = true,
    RequestDateScope scope = RequestDateScope.all,
  }) =>
      _inFlight.run(
        'getAllPending:${scope.wireValue}:$allowLocalFallback',
        () => _getAllPendingUncached(
            allowLocalFallback: allowLocalFallback, scope: scope),
      );

  Future<List<StandardDeliveryModel>> _getAllPendingUncached({
    required bool allowLocalFallback,
    required RequestDateScope scope,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        if (!allowLocalFallback) {
          throw Exception('No internet connection');
        }
        logDebug('StandardDeliveryRepository: Offline, returning local data');
        return await dbHelper.getRequests();
      }

      final response = await http
          .get(BApiEnvironment.api4Uri('/api4/request', scope.queryParameters));
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
            logDebug('Failed to parse request item: $e');
            try {
              logDebug('Item data: ${json.encode(item)}');
            } catch (_) {
              logDebug('Item data: $item');
            }
          }
        }

        return parsed;
      } else {
        throw Exception('Failed to load pending request');
      }
    } catch (e, st) {
      logDebug('StandardDeliveryRepository.getAllPending error: $e\n$st');
      if (!allowLocalFallback) {
        throw Exception('Something went wrong. Please try again: $e\n$st');
      }
      try {
        final localData = await DatabaseHelper.instance.getRequests();
        if (localData.isNotEmpty) {
          logDebug(
              'StandardDeliveryRepository: API failed, returning ${localData.length} local rows');
          return localData;
        }
      } catch (dbError) {
        logDebug('StandardDeliveryRepository: Local fallback failed: $dbError');
      }
      throw Exception('Something went wrong. Please try again: $e\n$st');
    }
  }
}
