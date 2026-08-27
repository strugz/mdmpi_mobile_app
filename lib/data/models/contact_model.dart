class ContactModel {
  final int? id;
  final String initial;
  final String department;
  final String contactNumber;
  final DateTime createdAt;

  const ContactModel({
    this.id,
    required this.initial,
    required this.department,
    required this.contactNumber,
    required this.createdAt,
  });

  ContactModel copyWith({
    int? id,
    String? initial,
    String? department,
    String? contactNumber,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      initial: initial ?? this.initial,
      department: department ?? this.department,
      contactNumber: contactNumber ?? this.contactNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'initial': initial,
      'department': department,
      'contact_number': contactNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int?,
      initial: (json['initial'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      contactNumber: (json['contact_number'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
