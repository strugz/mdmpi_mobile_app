import 'package:permission_handler/permission_handler.dart';
import '../../services/abstracts/i_permission_service.dart';

class PermissionService implements IPermissionService {
  @override
  Future<bool> ensure(PermissionType type) async {
    final permission = _toPermission(type);
    final currentStatus = await permission.status;

    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    final status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  @override
  Future<Map<PermissionType, bool>> ensureAll(List<PermissionType> types) async {
    final result = <PermissionType, bool>{};
    for (final t in types) {
      result[t] = await ensure(t);
    }
    return result;
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

