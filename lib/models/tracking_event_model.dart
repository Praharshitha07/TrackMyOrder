/// A single shipment event in the tracking timeline.
class TrackingEvent {
  final String id;
  final String orderId;
  final String status;
  final String description;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime occurredAt;
  final String source;
  final bool isVerified;

  const TrackingEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.description,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.occurredAt,
    this.source = 'manual',
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'status': status,
        'description': description,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'occurredAt': occurredAt.toIso8601String(),
        'source': source,
        'isVerified': isVerified,
      };

  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        status: json['status'] as String,
        description: json['description'] as String,
        locationName: json['locationName'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        source: json['source'] as String? ?? 'manual',
        isVerified: json['isVerified'] as bool? ?? false,
      );

  TrackingEvent copyWith({
    String? id,
    String? orderId,
    String? status,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? occurredAt,
    String? source,
    bool? isVerified,
  }) {
    return TrackingEvent(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      occurredAt: occurredAt ?? this.occurredAt,
      source: source ?? this.source,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
