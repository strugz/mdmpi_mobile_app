/// Model for storing alternative delivery locations (tapped coordinates/addresses)
/// when the initial address is determined to be wrong.
class LocationAlternativeModel {
  final int requestId; // stored as int in DB, but may come from String
  final double latitude;
  final double longitude;
  final String address;
  final String createdAt;
  final String? notes;

  LocationAlternativeModel({
    required int requestId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    this.notes,
  }) : requestId = requestId;

  /// Create from a String requestId (common in API responses)
  LocationAlternativeModel.fromStringId({
    required String stringRequestId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    this.notes,
  }) : requestId = int.tryParse(stringRequestId) ?? 0;

  /// Convert model to JSON for database storage
  Map<String, dynamic> toJson() => {
    'RequestID': requestId,
    'Latitude': latitude,
    'Longitude': longitude,
    'Address': address,
    'CreatedAt': createdAt,
    'Notes': notes,
  };

  /// Create model from database JSON
  factory LocationAlternativeModel.fromJson(Map<String, dynamic> json) =>
      LocationAlternativeModel(
        requestId: json['RequestID'] as int,
        latitude: json['Latitude'] as double,
        longitude: json['Longitude'] as double,
        address: json['Address'] as String,
        createdAt: json['CreatedAt'] as String,
        notes: json['Notes'] as String?,
      );

  @override
  String toString() =>
      'LocationAlternativeModel(requestId: $requestId, lat: $latitude, lng: $longitude, address: $address, createdAt: $createdAt)';
}
