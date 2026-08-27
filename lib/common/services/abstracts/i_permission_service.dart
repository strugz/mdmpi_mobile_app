/// Supported app permission types.
enum PermissionType { notifications, camera, storage, location, sms }

/// Normalized permission state used by feature-level permission guards.
enum PermissionCheckStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Result returned by feature-level permission checks.
class PermissionCheckResult {
  const PermissionCheckResult({
    required this.type,
    required this.status,
  });

  final PermissionType type;
  final PermissionCheckStatus status;

  bool get granted => status == PermissionCheckStatus.granted;
  bool get denied => status == PermissionCheckStatus.denied;
  bool get permanentlyDenied =>
      status == PermissionCheckStatus.permanentlyDenied;
  bool get restricted => status == PermissionCheckStatus.restricted;
}

/// Contract for requesting and checking app permissions.
abstract class IPermissionService {
  /// Ensures a single permission is granted. Returns `true` if granted.
  Future<bool> ensure(PermissionType type);

  /// Ensures all provided permissions are granted. Returns a per-permission result.
  Future<Map<PermissionType, bool>> ensureAll(List<PermissionType> types);

  /// Ensures a permission before running a feature action.
  ///
  /// Shows validation feedback when the permission is denied and optionally
  /// opens app settings when the permission is permanently denied.
  Future<PermissionCheckResult> requireForFeature(
    PermissionType type, {
    required String featureName,
    String? rationale,
    bool openSettingsOnPermanentDenial = true,
  });
}
