class UserInitialModel {
  String initial;
  String fullName;
  bool status;
  String department;

  UserInitialModel(
      {required this.initial,
      required this.fullName,
      required this.status,
      required this.department});

  static UserInitialModel empty() => UserInitialModel(
      initial: '', fullName: '', status: false, department: '');

  Map<String, dynamic> toJson() {
    return {
      'Initial': initial,
      'FullName': fullName,
      'Status': status,
      'Department': department
    };
  }

  factory UserInitialModel.fromJson(Map<String, dynamic> json) {
    return UserInitialModel(
      initial: json['Initial'],
      fullName: json['FullName'],
      status: json['Status'],
      department: json['Department'],
    );
  }
}
