import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import '../../services/abstracts/i_permission_service.dart';

class PermissionService implements IPermissionService {
  PermissionService({
    Future<PermissionStatus> Function(PermissionType type)? statusResolver,
    Future<PermissionStatus> Function(PermissionType type)? requestResolver,
    Future<bool> Function()? openSettings,
  })  : _statusResolver = statusResolver,
        _requestResolver = requestResolver,
        _openSettings = openSettings ?? openAppSettings;

  final Future<PermissionStatus> Function(PermissionType type)? _statusResolver;
  final Future<PermissionStatus> Function(PermissionType type)?
      _requestResolver;
  final Future<bool> Function() _openSettings;

  @override
  Future<bool> ensure(PermissionType type) async {
    if (!_shouldRequestOnCurrentPlatform(type)) {
      return true;
    }

    final currentStatus = await _status(type);

    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    final status = await _request(type);
    return status.isGranted || status.isLimited;
  }

  @override
  Future<Map<PermissionType, bool>> ensureAll(
      List<PermissionType> types) async {
    final result = <PermissionType, bool>{};
    for (final t in types) {
      result[t] = await ensure(t);
    }
    return result;
  }

  @override
  Future<PermissionCheckResult> requireForFeature(
    PermissionType type, {
    required String featureName,
    String? rationale,
    bool openSettingsOnPermanentDenial = true,
  }) async {
    if (!_shouldRequestOnCurrentPlatform(type)) {
      return PermissionCheckResult(
        type: type,
        status: PermissionCheckStatus.granted,
      );
    }

    try {
      final currentStatus = await _status(type);
      if (_isGranted(currentStatus)) {
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.granted,
        );
      }

      if (currentStatus.isPermanentlyDenied) {
        await _handlePermissionBlocked(
          type,
          featureName: featureName,
          openSettingsOnPermanentDenial: openSettingsOnPermanentDenial,
        );
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.permanentlyDenied,
        );
      }

      if (currentStatus.isRestricted) {
        _showRestrictedMessage(type, featureName: featureName);
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.restricted,
        );
      }

      final requestedStatus = await _request(type);
      if (_isGranted(requestedStatus)) {
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.granted,
        );
      }

      if (requestedStatus.isPermanentlyDenied) {
        await _handlePermissionBlocked(
          type,
          featureName: featureName,
          openSettingsOnPermanentDenial: openSettingsOnPermanentDenial,
        );
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.permanentlyDenied,
        );
      }

      if (requestedStatus.isRestricted) {
        _showRestrictedMessage(type, featureName: featureName);
        return PermissionCheckResult(
          type: type,
          status: PermissionCheckStatus.restricted,
        );
      }

      _showDeniedMessage(
        type,
        featureName: featureName,
        rationale: rationale,
      );
      return PermissionCheckResult(
        type: type,
        status: PermissionCheckStatus.denied,
      );
    } catch (e, st) {
      logDebug('Permission check failed for $type: $e\n$st');
      _showDeniedMessage(
        type,
        featureName: featureName,
        rationale: rationale,
      );
      return PermissionCheckResult(
        type: type,
        status: PermissionCheckStatus.denied,
      );
    }
  }

  Future<PermissionStatus> _status(PermissionType type) async {
    if (_statusResolver != null) {
      return _statusResolver(type);
    }

    return _toPermission(type).status;
  }

  Future<PermissionStatus> _request(PermissionType type) async {
    if (_requestResolver != null) {
      return _requestResolver(type);
    }

    return _toPermission(type).request();
  }

  bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  bool _shouldRequestOnCurrentPlatform(PermissionType type) {
    if (kIsWeb) {
      return type == PermissionType.camera ||
          type == PermissionType.location ||
          type == PermissionType.notifications;
    }

    if (Platform.isAndroid) return true;

    return type == PermissionType.camera || type == PermissionType.location;
  }

  Future<void> _handlePermissionBlocked(
    PermissionType type, {
    required String featureName,
    required bool openSettingsOnPermanentDenial,
  }) async {
    BLoaders.errorSnackBar(
      title: 'Permission Required',
      message:
          '$featureName needs ${_permissionLabel(type)} permission. Enable it in App Settings to continue.',
      duration: 4,
    );

    if (!openSettingsOnPermanentDenial) return;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _openSettings();
    } catch (e) {
      logDebug('Failed to open app settings for $type: $e');
    }
  }

  void _showDeniedMessage(
    PermissionType type, {
    required String featureName,
    String? rationale,
  }) {
    BLoaders.warningSnackBar(
      title: 'Permission Required',
      message: rationale ??
          '$featureName needs ${_permissionLabel(type)} permission to continue. Please allow it and try again.',
      duration: 4,
    );
  }

  void _showRestrictedMessage(
    PermissionType type, {
    required String featureName,
  }) {
    BLoaders.errorSnackBar(
      title: 'Permission Restricted',
      message:
          '$featureName needs ${_permissionLabel(type)} permission, but it is restricted on this device.',
      duration: 4,
    );
  }

  String _permissionLabel(PermissionType type) {
    switch (type) {
      case PermissionType.notifications:
        return 'notification';
      case PermissionType.camera:
        return 'camera';
      case PermissionType.storage:
        return 'storage';
      case PermissionType.location:
        return 'location';
      case PermissionType.sms:
        return 'SMS';
    }
  }

  Permission _toPermission(PermissionType type) {
    switch (type) {
      case PermissionType.notifications:
        return Permission.notification;
      case PermissionType.camera:
        return Permission.camera;
      case PermissionType.storage:
        return Permission.manageExternalStorage;
      case PermissionType.location:
        return Permission.location;
      case PermissionType.sms:
        return Permission.sms;
    }
  }
}
