/// Model for storing client contact person names with usage frequency.
class ClientContactPersonModel {
  final int? id;
  final String name;
  final int usageCount;
  final DateTime lastUsedAt;

  ClientContactPersonModel({
    this.id,
    required this.name,
    this.usageCount = 1,
    DateTime? lastUsedAt,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  /// Convert model to database map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  /// Create model from database map
  factory ClientContactPersonModel.fromJson(Map<String, dynamic> json) {
    return ClientContactPersonModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      usageCount: json['usageCount'] as int? ?? 1,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  ClientContactPersonModel copyWith({
    int? id,
    String? name,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return ClientContactPersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  static ClientContactPersonModel empty() => ClientContactPersonModel(name: '');
}

