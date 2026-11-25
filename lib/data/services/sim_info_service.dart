import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';

/// The SIM Android sends SMS from (the default SMS SIM), since the app never
/// picks a SIM itself.
class DefaultSmsSim {
  const DefaultSmsSim({
    required this.simCount,
    required this.hasDefault,
    this.slot,
    this.carrier,
    this.number,
  });

  final int simCount;

  /// False when the phone is set to "Ask every time" or has no SIM.
  final bool hasDefault;
  final int? slot;
  final String? carrier;

  /// Often empty: many prepaid SIMs do not store their own number.
  final String? number;

  /// One line for Settings, e.g. "SIM 2 · Globe · 09171234567".
  String get summary {
    if (simCount == 0) return 'No SIM found';
    if (!hasDefault) {
      return "No default SMS SIM · the phone asks every time; set one in "
          "the phone's SIM settings";
    }
    return [
      if (slot != null) 'SIM $slot',
      if (carrier != null) carrier!,
      number ?? 'number not stored on this SIM',
    ].join(' · ');
  }

  factory DefaultSmsSim.fromMap(Map<Object?, Object?> map) {
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return DefaultSmsSim(
      simCount: (map['simCount'] as int?) ?? 0,
      hasDefault: map['hasDefault'] == true,
      slot: map['slot'] as int?,
      carrier: text(map['carrier']),
      number: text(map['number']),
    );
  }
}

enum SimInfoAccess { granted, denied, blocked, unsupported }

class SimInfoService {
  static const _channel = MethodChannel('mdmpi/sim_info');

  Future<SimInfoAccess> access({bool request = false}) async {
    if (!GetPlatform.isAndroid) return SimInfoAccess.unsupported;
    var status = await Permission.phone.status;
    if (!status.isGranted && request) status = await Permission.phone.request();
    if (status.isGranted) return SimInfoAccess.granted;
    return status.isPermanentlyDenied
        ? SimInfoAccess.blocked
        : SimInfoAccess.denied;
  }

  Future<Result<DefaultSmsSim>> defaultSmsSim() async {
    try {
      final map =
          await _channel.invokeMethod<Map<Object?, Object?>>('getDefaultSmsSim');
      if (map == null) return Result.failure('No SIM information');
      return Result.success(DefaultSmsSim.fromMap(map));
    } on PlatformException catch (e) {
      logDebug('SimInfoService: ${e.code} ${e.message}');
      return Result.failure('Could not read the SIM');
    } on MissingPluginException {
      return Result.failure('Not available on this device');
    }
  }
}
