import 'tracking_result.dart';

/// Integration interface for Delhivery tracking.
/// Official Delhivery B2B/Client tracking requires a client API token and account ID.
/// When credentials are not supplied, returns an honest not-configured response.
class DelhiveryTrackingService implements CourierTrackingService {
  final String? apiToken;

  DelhiveryTrackingService({this.apiToken});

  @override
  String get courierName => 'Delhivery';

  @override
  bool get isConfigured => apiToken != null && apiToken!.isNotEmpty;

  @override
  Future<TrackingResult> fetchTrackingDetails({
    required String trackingNumber,
    required String currentStatus,
    required String orderId,
  }) async {
    if (!isConfigured) {
      return TrackingResult.notConfigured(
        courierName: courierName,
        trackingNumber: trackingNumber,
        currentStatus: currentStatus,
        message:
            'Delhivery API token is not configured. Authorized carrier tracking requires commercial Delhivery developer credentials.',
      );
    }

    // When configured with server-side gateway:
    // GET https://track.delhivery.com/api/v1/packages/json/?waybill={trackingNumber}&token={apiToken}
    return TrackingResult.notConfigured(
      courierName: courierName,
      trackingNumber: trackingNumber,
      currentStatus: currentStatus,
    );
  }
}

/// Integration interface for Blue Dart tracking.
/// Official Blue Dart API requires enterprise customer license key and login ID.
class BlueDartTrackingService implements CourierTrackingService {
  final String? licenseKey;

  BlueDartTrackingService({this.licenseKey});

  @override
  String get courierName => 'Blue Dart';

  @override
  bool get isConfigured => licenseKey != null && licenseKey!.isNotEmpty;

  @override
  Future<TrackingResult> fetchTrackingDetails({
    required String trackingNumber,
    required String currentStatus,
    required String orderId,
  }) async {
    if (!isConfigured) {
      return TrackingResult.notConfigured(
        courierName: courierName,
        trackingNumber: trackingNumber,
        currentStatus: currentStatus,
        message:
            'Blue Dart Tracking API requires enterprise license credentials and customer authorization.',
      );
    }

    return TrackingResult.notConfigured(
      courierName: courierName,
      trackingNumber: trackingNumber,
      currentStatus: currentStatus,
    );
  }
}

/// Integration interface for Ekart Logistics tracking.
/// Ekart tracking is restricted to Flipkart sellers and logistics partners.
class EkartTrackingService implements CourierTrackingService {
  final String? partnerToken;

  EkartTrackingService({this.partnerToken});

  @override
  String get courierName => 'Ekart';

  @override
  bool get isConfigured => partnerToken != null && partnerToken!.isNotEmpty;

  @override
  Future<TrackingResult> fetchTrackingDetails({
    required String trackingNumber,
    required String currentStatus,
    required String orderId,
  }) async {
    if (!isConfigured) {
      return TrackingResult.notConfigured(
        courierName: courierName,
        trackingNumber: trackingNumber,
        currentStatus: currentStatus,
        message:
            'Ekart Logistics API requires Flipkart partner authorization.',
      );
    }

    return TrackingResult.notConfigured(
      courierName: courierName,
      trackingNumber: trackingNumber,
      currentStatus: currentStatus,
    );
  }
}
