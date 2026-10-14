import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// Why a saved engagement has (or has no) location. Sent as
/// `LocationStatus`, so a missing position is explained, never silent.
abstract final class BVisitLocationStatus {
  static const ok = 'OK';
  static const denied = 'DENIED';
  static const off = 'OFF';
  static const unavailable = 'UNAVAILABLE';
}

/// Whether positions are being recorded now (Settings → Visit location).
enum VisitLocationState {
  /// Recording: permission given and location turned on.
  on,

  /// Not asked yet, or refused once: a tap asks again.
  needsPermission,

  /// Refused for good: only the phone's settings can allow it.
  blocked,

  /// The phone's location is switched off.
  serviceOff,

  /// Not on this platform (Windows).
  unsupported,
}

/// One position, as it is sent with a queued change.
class VisitFix {
  const VisitFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.at,
  });

  final double latitude;
  final double longitude;

  /// Metres, as the phone reports it.
  final double accuracy;
  final DateTime at;
}

/// The phone's location, stamped once on every engagement the collector
/// saves (collections, visits, office activities, reconciliation steps) and
/// uploaded with it as `Latitude` / `Longitude` / `LocationAccuracy` /
/// `LocationAt` / `LocationStatus`. Collectors are told so in Settings.
///
/// It never blocks or fails a save: a fix younger than [maxAge] is reused (a
/// batch of fifty invoices asks once), a new one is given up after
/// [timeout], and no position is recorded as why ([BVisitLocationStatus]).
/// Permission is asked at most once per app session and never sends the
/// collector to Settings; the Settings tile is where they turn it on.
///
/// Android only (Windows is not a target for new features): elsewhere it
/// adds nothing.
class BVisitLocation {
  BVisitLocation({
    Future<bool> Function()? serviceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<VisitFix?> Function(Duration timeout)? currentFix,
    Future<VisitFix?> Function()? lastKnownFix,
    DateTime Function()? now,
    bool? supported,
    this.timeout = const Duration(seconds: 4),
    this.maxAge = const Duration(minutes: 2),
  })  : _serviceEnabled = serviceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _currentFix = currentFix ?? _geolocatorCurrent,
        _lastKnownFix = lastKnownFix ?? _geolocatorLastKnown,
        _now = now ?? DateTime.now,
        _supported = supported ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final Future<bool> Function() _serviceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<VisitFix?> Function(Duration timeout) _currentFix;
  final Future<VisitFix?> Function() _lastKnownFix;
  final DateTime Function() _now;
  final bool _supported;

  final Duration timeout;
  final Duration maxAge;

  VisitFix? _cached;
  bool _askedThisSession = false;

  /// Whether a save would record a position now.
  Future<VisitLocationState> state() async {
    if (!_supported) return VisitLocationState.unsupported;
    try {
      if (!await _serviceEnabled()) return VisitLocationState.serviceOff;
      return switch (await _checkPermission()) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          VisitLocationState.on,
        LocationPermission.deniedForever => VisitLocationState.blocked,
        _ => VisitLocationState.needsPermission,
      };
    } catch (_) {
      return VisitLocationState.needsPermission;
    }
  }

  /// The collector asked to turn it on (Settings): ask for permission, or
  /// open the phone's settings where only they can change it.
  Future<VisitLocationState> turnOn() async {
    switch (await state()) {
      case VisitLocationState.serviceOff:
        await Geolocator.openLocationSettings();
      case VisitLocationState.blocked:
        await Geolocator.openAppSettings();
      case VisitLocationState.needsPermission:
        await _requestPermission();
      case VisitLocationState.on || VisitLocationState.unsupported:
        break;
    }
    return state();
  }

  /// The fields to send with a queued change; empty where it does not apply.
  Future<Map<String, dynamic>> fields() async {
    if (!_supported) return const {};
    try {
      final cached = _cached;
      if (cached != null && _now().difference(cached.at) <= maxAge) {
        return _fixFields(cached);
      }
      if (!await _serviceEnabled()) {
        return {'LocationStatus': BVisitLocationStatus.off};
      }
      var permission = await _checkPermission();
      if (permission == LocationPermission.denied && !_askedThisSession) {
        _askedThisSession = true;
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return {'LocationStatus': BVisitLocationStatus.denied};
      }
      final fix = await _currentFix(timeout) ?? await _lastKnownFix();
      if (fix == null) {
        return {'LocationStatus': BVisitLocationStatus.unavailable};
      }
      _cached = fix;
      return _fixFields(fix);
    } catch (e) {
      logDebug('BVisitLocation: no position: $e');
      return {'LocationStatus': BVisitLocationStatus.unavailable};
    }
  }

  static Map<String, dynamic> _fixFields(VisitFix f) => {
        'Latitude': f.latitude,
        'Longitude': f.longitude,
        'LocationAccuracy': f.accuracy,
        'LocationAt': f.at.toUtc().toIso8601String(),
        'LocationStatus': BVisitLocationStatus.ok,
      };

  static VisitFix _fromPosition(Position p) => VisitFix(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      at: p.timestamp);

  static Future<VisitFix?> _geolocatorCurrent(Duration timeout) async {
    try {
      final p = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: timeout));
      return _fromPosition(p);
    } catch (e) {
      logDebug('BVisitLocation: no current fix: $e');
      return null;
    }
  }

  static Future<VisitFix?> _geolocatorLastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : _fromPosition(p);
    } catch (_) {
      return null;
    }
  }
}
