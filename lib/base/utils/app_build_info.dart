import 'package:flutter/foundation.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The running build: name, version, build number.
class AppBuildInfo {
  const AppBuildInfo(
      {required this.appName, required this.version, required this.build});

  /// What a build looks like when the platform cannot say.
  static const unknown =
      AppBuildInfo(appName: 'MDMPI App', version: '', build: '');

  final String appName;
  final String version;
  final String build;

  bool get hasVersion => version.isNotEmpty;

  /// "1.1.110 (110)", or just the version when the build number repeats it.
  String get label =>
      build.isEmpty || build == version ? version : '$version ($build)';
}

typedef BuildInfoLoader = Future<AppBuildInfo> Function();

/// Reads the build once per run and shares it: Settings, About and the
/// login screen all show the same version without asking the platform again.
class BAppBuildInfo {
  BAppBuildInfo._();

  static BuildInfoLoader _loader = fromPackageInfo;
  static Future<AppBuildInfo>? _current;
  static AppBuildInfo? _cached;

  /// The running build, or [AppBuildInfo.unknown] when it cannot be read.
  /// Never throws.
  static Future<AppBuildInfo> current() => _current ??= _read();

  /// The build if it has already been read, for a first frame that should
  /// show the version straight away rather than swap it in a frame later.
  static AppBuildInfo? get cached => _cached;

  /// Starts the read early (from `main`) so [cached] is filled before the
  /// first screen draws.
  static void warmUp() => current();

  static Future<AppBuildInfo> _read() async {
    try {
      return _cached = await _loader();
    } catch (e) {
      logDebug('BAppBuildInfo: package info unavailable: $e');
      return _cached = AppBuildInfo.unknown;
    }
  }

  static Future<AppBuildInfo> fromPackageInfo() async {
    final p = await PackageInfo.fromPlatform();
    return AppBuildInfo(
        appName: p.appName, version: p.version, build: p.buildNumber);
  }

  /// Swaps the platform read for [loader] and forgets the cached build.
  /// Pass null to go back to [fromPackageInfo].
  @visibleForTesting
  static void debugOverride(BuildInfoLoader? loader) {
    _loader = loader ?? fromPackageInfo;
    _current = null;
    _cached = null;
  }
}
