import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  String id;
  String department;
  bool status;

  DepartmentModel(
      {required this.id, required this.department, required this.status});

  static DepartmentModel empty() =>
      DepartmentModel(id: '', department: '', status: false);

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Department': department,
    };
  }

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
        id: json['ID'], department: json['Department'], status: false);
  }

  factory DepartmentModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return DepartmentModel(
          id: document.id, department: data['Department'] ?? '', status: false);
    } else {
      return DepartmentModel.empty();
    }
  }
}
