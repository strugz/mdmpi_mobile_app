/// Model representing a realtime location sample persisted in GetStorage or
/// exchanged over the network.
class RealtimeLocationModel {
  double latitude;
  double longitude;
  double accuracy;
  double heading;
  double speed;
  double speedAccuracy;
  double altitude;
  DateTime timestamp;

  RealtimeLocationModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
    required this.altitude,
    required this.timestamp,
  });

  /// Empty/default instance (useful for initialization)
  static RealtimeLocationModel empty() => RealtimeLocationModel(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitude: 0.0,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
      'altitude': altitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  factory RealtimeLocationModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime parseTimestamp(dynamic v) {
      if (v == null) return DateTime.now().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v).toUtc();
      if (v is String) return DateTime.parse(v).toUtc();
      return DateTime.now().toUtc();
    }

    return RealtimeLocationModel(
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      accuracy: parseDouble(json['accuracy']),
      heading: parseDouble(json['heading']),
      speed: parseDouble(json['speed']),
      speedAccuracy: parseDouble(json['speedAccuracy']),
      altitude: parseDouble(json['altitude']),
      timestamp: parseTimestamp(json['timestamp']),
    );
  }

  RealtimeLocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? heading,
    double? speed,
    double? speedAccuracy,
    double? altitude,
    DateTime? timestamp,
  }) {
    return RealtimeLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      speedAccuracy: speedAccuracy ?? this.speedAccuracy,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

