import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  String id;
  String role;
  bool status;

  RoleModel({required this.id, required this.role, required this.status});

  static RoleModel empty() => RoleModel(id: '', role: '', status: false);

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Role': role,
    };
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(id: json['ID'], role: json['Role'], status: false);
  }

  factory RoleModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return RoleModel(id: document.id, role: data['Role'] ?? '', status: false);
    } else {
      return RoleModel.empty();
    }
  }
}
