import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';

/// Utility class for resolving user roles based on request status.
///
/// Provides status-driven role selection to ensure users with multiple roles
/// can perform all available actions at any status.
class RoleResolver {
  RoleResolver._();

  /// Default role priority for fallback when no preferred role exists.
  /// Lower number = Higher priority.
  static const Map<String, int> defaultRolePriority = {
    BTexts.roleRelease: 1,
    BTexts.roleCourier: 2,
    BTexts.roleRequest: 3,
    BTexts.roleViewer: 4,
  };

  /// Parses a comma-separated role string into a list of trimmed roles.
  ///
  /// Example: "Request, Release, Courier" → ["Request", "Release", "Courier"]
  static List<String> parseRoles(String roleString) {
    return roleString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Resolves the best role for a given status from the user's available roles.
  ///
  /// [status] - The current request status.
  /// [userRoles] - List of roles the user has.
  /// [statusToPreferredRole] - Map of status to preferred role with action capability.
  /// [rolePriority] - Optional custom role priority map. Uses [defaultRolePriority] if null.
  ///
  /// Strategy:
  /// 1. Check if there's a preferred role (with action capability) for this status
  /// 2. If user has that role, use it
  /// 3. Otherwise, fall back to highest-priority role for view-only access
  static String resolveRoleForStatus({
    required String status,
    required List<String> userRoles,
    required Map<String, String> statusToPreferredRole,
    Map<String, int>? rolePriority,
  }) {
    if (userRoles.isEmpty) return BTexts.roleViewer;

    final priority = rolePriority ?? defaultRolePriority;

    // 1. Check for status-specific preferred role
    final preferredRole = statusToPreferredRole[status];
    if (preferredRole != null && userRoles.contains(preferredRole)) {
      return preferredRole;
    }

    // 2. Fallback to highest-priority role (for view-only statuses)
    String selectedRole = BTexts.roleViewer;
    int highestPriority = 999;

    for (final role in userRoles) {
      final p = priority[role] ?? 999;
      if (p < highestPriority) {
        highestPriority = p;
        selectedRole = role;
      }
    }

    return selectedRole;
  }

  /// Checks if user has a specific role.
  static bool hasRole(List<String> userRoles, String role) {
    return userRoles.contains(role);
  }

  /// Gets the highest priority role from a list of user roles.
  static String getHighestPriorityRole(
    List<String> userRoles, [
    Map<String, int>? rolePriority,
  ]) {
    if (userRoles.isEmpty) return BTexts.roleViewer;

    final priority = rolePriority ?? defaultRolePriority;
    String selectedRole = BTexts.roleViewer;
    int highestPriority = 999;

    for (final role in userRoles) {
      final p = priority[role] ?? 999;
      if (p < highestPriority) {
        highestPriority = p;
        selectedRole = role;
      }
    }

    return selectedRole;
  }
}

