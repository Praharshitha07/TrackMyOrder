import '../models/order_model.dart';
import '../models/tracking_event_model.dart';

class SimulatedTrackingData {
  SimulatedTrackingData._();

  static const _stages = [
    (
      status: 'ordered',
      description: 'The sample order was placed successfully.',
      location: null,
      offset: Duration.zero,
    ),
    (
      status: 'confirmed',
      description: 'The sample order was confirmed by the merchant.',
      location: null,
      offset: Duration(hours: 3),
    ),
    (
      status: 'packed',
      description: 'The parcel was packed and prepared for dispatch.',
      location: 'Mumbai Fulfillment Center',
      offset: Duration(days: 1),
    ),
    (
      status: 'shipped',
      description: 'The parcel left the sample fulfillment center.',
      location: 'Mumbai, Maharashtra',
      offset: Duration(days: 2),
    ),
    (
      status: 'in_transit',
      description: 'The parcel is moving along the sample delivery route.',
      location: 'Lonavala, Maharashtra',
      offset: Duration(days: 3),
    ),
    (
      status: 'out_for_delivery',
      description: 'The parcel is on the way to the sample destination.',
      location: 'Pune, Maharashtra',
      offset: Duration(days: 4),
    ),
    (
      status: 'delivered',
      description: 'Sample delivery completed for demonstration only.',
      location: 'Pune, Maharashtra',
      offset: Duration(days: 5),
    ),
  ];

  static List<TrackingEvent> eventsFor(OrderModel order) => [
    for (final stage in _stages)
      TrackingEvent(
        id: 'simulation-${order.id}-${stage.status}',
        orderId: order.id,
        status: stage.status,
        description: stage.description,
        locationName: stage.location,
        occurredAt: order.orderedAt.add(stage.offset),
        source: 'simulation',
      ),
  ];
}
