import 'tracking_result.dart';
import 'carrier_services.dart';

/// Unified tracking manager that routes tracking requests to the appropriate
/// courier service or reports an honest unconfigured/unsupported status.
class UnifiedTrackingManager {
  final Map<String, CourierTrackingService> _carriers = {};

  UnifiedTrackingManager() {
    registerCarrier(DelhiveryTrackingService());
    registerCarrier(BlueDartTrackingService());
    registerCarrier(EkartTrackingService());
  }

  void registerCarrier(CourierTrackingService service) {
    _carriers[service.courierName.toLowerCase()] = service;
  }

  bool isCarrierSupported(String? courierName) {
    if (courierName == null || courierName.trim().isEmpty) return false;
    return _carriers.containsKey(courierName.trim().toLowerCase());
  }

  bool isCarrierConfigured(String? courierName) {
    if (courierName == null) return false;
    final service = _carriers[courierName.trim().toLowerCase()];
    return service?.isConfigured ?? false;
  }

  Future<TrackingResult> refreshTracking({
    required String? courierName,
    required String? trackingNumber,
    required String currentStatus,
    required String orderId,
  }) async {
    final cleanTracking = trackingNumber?.trim();
    final cleanCourier = courierName?.trim();

    if (cleanTracking == null || cleanTracking.isEmpty) {
      return TrackingResult(
        courierName: cleanCourier ?? 'Unknown',
        trackingNumber: '',
        normalizedStatus: currentStatus,
        lastCheckedAt: DateTime.now(),
        isLive: false,
        isConfigured: false,
        errorMessage: 'Please enter a tracking number to refresh shipment details.',
      );
    }

    if (cleanCourier == null || cleanCourier.isEmpty) {
      return TrackingResult(
        courierName: 'Unassigned',
        trackingNumber: cleanTracking,
        normalizedStatus: currentStatus,
        lastCheckedAt: DateTime.now(),
        isLive: false,
        isConfigured: false,
        errorMessage:
            'Courier name is not specified. Please select a courier in Edit Order to enable carrier tracking.',
      );
    }

    final service = _carriers[cleanCourier.toLowerCase()];
    if (service == null) {
      return TrackingResult.unsupportedCarrier(
        courierName: cleanCourier,
        trackingNumber: cleanTracking,
        currentStatus: currentStatus,
      );
    }

    return service.fetchTrackingDetails(
      trackingNumber: cleanTracking,
      currentStatus: currentStatus,
      orderId: orderId,
    );
  }
}
