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
      type: json['Type'] ?? '',
      requestId: json['RequestID'] ?? '',
      riderId: json['RiderId'] ?? '',
      latitude: double.parse(json['Latitude'].toString()) ?? 0.0,
      longitude: double.parse(json['Longitude'].toString()) ?? 0.0,
      timestamp: DateTime.parse(json['Timestamp']) ?? DateTime.now(),
      status: json['Status'] ?? '',
      riderInitial: json['RiderInitial'] ?? '',
      eta: json['ETA'] ?? '',
      distance: json['Distance'] ?? '',
      client: json['Client'] ?? '',
    );
  }
}
