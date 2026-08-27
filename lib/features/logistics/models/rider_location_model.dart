class RiderLocationModel {
  final String type;
  final String requestId;
  final String riderId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status;
  final String riderInitial;
  final String eta;
  final String distance;
  final String client;

  RiderLocationModel(
      {required this.type,
      required this.requestId,
      this.riderId = '',
      required this.latitude,
      required this.longitude,
      required this.timestamp,
      required this.status,
      required this.riderInitial,
      required this.eta,
      required this.distance,
      required this.client});

  static RiderLocationModel empty() => RiderLocationModel(
      type: '',
      requestId: '',
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      status: '',
      riderInitial: '',
      eta: '',
      distance: '',
      client: '');

  Map<String, dynamic> toJson() {
    return {
      'Type': type,
      'RequestID': requestId,
      'RiderId': riderId,
      'Latitude': latitude,
      'Longitude': longitude,
      'Timestamp': timestamp.toIso8601String(),
      'Status': status,
      'RiderInitial': riderInitial,
      'ETA': eta,
      'Distance': distance,
      'Client': client
    };
  }

  factory RiderLocationModel.fromJson(Map<String, dynamic> json) {
    return RiderLocationModel(
      type: json['Type']?.toString() ?? '',
      requestId: json['RequestID']?.toString() ?? '',
      riderId: json['RiderId']?.toString() ?? '',
      latitude: _parseDouble(json['Latitude']),
      longitude: _parseDouble(json['Longitude']),
      timestamp: _parseTimestamp(json['Timestamp']),
      status: json['Status']?.toString() ?? '',
      riderInitial: json['RiderInitial']?.toString() ?? '',
      eta: json['ETA']?.toString() ?? '',
      distance: json['Distance']?.toString() ?? '',
      client: json['Client']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime _parseTimestamp(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
