import '../../models/tracking_event_model.dart';

/// Normalized result returned by courier tracking services
class TrackingResult {
  final String courierName;
  final String trackingNumber;
  final String normalizedStatus;
  final String? originalStatusDescription;
  final DateTime? estimatedDeliveryAt;
  final List<TrackingEvent> events;
  final DateTime lastCheckedAt;
  final bool isLive;
  final String? errorMessage;
  final bool isConfigured;

  const TrackingResult({
    required this.courierName,
    required this.trackingNumber,
    required this.normalizedStatus,
    this.originalStatusDescription,
    this.estimatedDeliveryAt,
    this.events = const [],
    required this.lastCheckedAt,
    this.isLive = false,
    this.errorMessage,
    this.isConfigured = false,
  });

  bool get hasEvents => events.isNotEmpty;
  bool get hasError => errorMessage != null;

  factory TrackingResult.notConfigured({
    required String courierName,
    required String trackingNumber,
    required String currentStatus,
    String? message,
  }) {
    return TrackingResult(
      courierName: courierName,
      trackingNumber: trackingNumber,
      normalizedStatus: currentStatus,
      lastCheckedAt: DateTime.now(),
      isLive: false,
      isConfigured: false,
      errorMessage: message ??
          'Live tracking for $courierName requires authorized carrier API credentials. The current status is preserved as manually recorded.',
    );
  }

  factory TrackingResult.unsupportedCarrier({
    required String courierName,
    required String trackingNumber,
    required String currentStatus,
  }) {
    return TrackingResult(
      courierName: courierName,
      trackingNumber: trackingNumber,
      normalizedStatus: currentStatus,
      lastCheckedAt: DateTime.now(),
      isLive: false,
      isConfigured: false,
      errorMessage:
          'Direct carrier API integration is not available for "$courierName". You can track directly on the courier website using the tracking link.',
    );
  }

  factory TrackingResult.success({
    required String courierName,
    required String trackingNumber,
    required String normalizedStatus,
    String? originalStatusDescription,
    DateTime? estimatedDeliveryAt,
    required List<TrackingEvent> events,
  }) {
    return TrackingResult(
      courierName: courierName,
      trackingNumber: trackingNumber,
      normalizedStatus: normalizedStatus,
      originalStatusDescription: originalStatusDescription,
      estimatedDeliveryAt: estimatedDeliveryAt,
      events: events,
      lastCheckedAt: DateTime.now(),
      isLive: true,
      isConfigured: true,
    );
  }
}

/// Abstract contract for courier tracking integrations.
abstract class CourierTrackingService {
  /// Name of the courier handled by this service (e.g. 'Delhivery', 'Blue Dart')
  String get courierName;

  /// Whether genuine API credentials or backend endpoints are configured
  bool get isConfigured;

  /// Fetch tracking details from the carrier
  Future<TrackingResult> fetchTrackingDetails({
    required String trackingNumber,
    required String currentStatus,
    required String orderId,
  });
}
