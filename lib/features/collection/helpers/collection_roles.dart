import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/utils/role_resolver.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Who gets the Head's tabs (Collection TODO item 21).
///
/// The Head of Collection is a role on the Firestore user, in the same
/// comma-separated `Role` field the admin web reads (`CollectionPoster` gates
/// posting there). The Head also collects, so the role adds a tab; it takes
/// none away.
class BCollectionRoles {
  BCollectionRoles._();

  static bool isCollectionDepartment(String department) =>
      department.trim().toLowerCase() == 'collection';

  /// Case-insensitive, so "collectionhead" typed on the web still counts.
  static bool hasRole(String roleField, String role) =>
      RoleResolver.parseRoles(roleField)
          .any((r) => r.trim().toLowerCase() == role.toLowerCase());

  static bool isHead(UserModel user) =>
      isCollectionDepartment(user.department) &&
      hasRole(user.role, BTexts.roleCollectionHead);
}
