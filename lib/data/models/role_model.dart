import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  String id;
  String role;
  bool status;

  /// Departments this role is offered to on the sign-up form, from the
  /// optional `Departments` array on the `Roles` doc. Empty when the doc is
  /// untagged; see [appliesTo] for the default.
  List<String> departments;

  RoleModel(
      {required this.id,
      required this.role,
      required this.status,
      this.departments = const []});

  static RoleModel empty() => RoleModel(id: '', role: '', status: false);

  /// Whether sign-up offers this role to a user of [department].
  ///
  /// A tagged role follows its `Departments`. An untagged one keeps today's
  /// behaviour, except the Collection roles (`CollectionHead`,
  /// `CollectionPoster`, …) go to Collection only. Collection users still get
  /// the Logistics roles: they request deliveries too.
  bool appliesTo(String department) {
    final dept = department.trim().toLowerCase();
    if (dept.isEmpty) return false;
    if (departments.isNotEmpty) {
      return departments.any((d) => d.trim().toLowerCase() == dept);
    }
    if (role.trim().toLowerCase().startsWith('collection')) {
      return dept == 'collection';
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Role': role,
      if (departments.isNotEmpty) 'Departments': departments,
    };
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
        id: json['ID'],
        role: json['Role'],
        status: false,
        departments: parseDepartments(json['Departments']));
  }

  factory RoleModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return RoleModel(
          id: document.id,
          role: data['Role'] ?? '',
          status: false,
          departments: parseDepartments(data['Departments']));
    } else {
      return RoleModel.empty();
    }
  }

  /// An array, or a comma-separated string typed in the console; blanks dropped.
  static List<String> parseDepartments(dynamic value) {
    final Iterable<dynamic> raw = value is Iterable
        ? value
        : value is String
            ? value.split(',')
            : const [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
