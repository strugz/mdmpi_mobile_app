/// Supported app permission types.
enum PermissionType { notifications, camera, storage, location, sms }

/// Contract for requesting and checking app permissions.
abstract class IPermissionService {
  /// Ensures a single permission is granted. Returns `true` if granted.
  Future<bool> ensure(PermissionType type);

  /// Ensures all provided permissions are granted. Returns a per-permission result.
  Future<Map<PermissionType, bool>> ensureAll(List<PermissionType> types);
}

