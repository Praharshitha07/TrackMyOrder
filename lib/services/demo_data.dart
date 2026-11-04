import '../models/order_model.dart';
import '../models/tracking_event_model.dart';

/// Generates clearly-labelled demo orders for first-run demonstration.
/// These are never mixed silently with user-created orders —
/// [isDemo] is always true and each sample is written to the signed-in user.
class DemoData {
  DemoData._();

  static List<OrderModel> generateDemoOrders(String userId) {
    final now = DateTime(2026, 11, 4, 12);

    return [
      _makeOrder(
        userId: userId,
        id: 'demo-$userId-amazon',
        platform: 'Amazon',
        platformOrderId: 'AMZ-406-8823401-1234567',
        productName: 'boAt Airdopes 141 TWS Earbuds',
        price: 1299.00,
        status: 'out_for_delivery',
        orderedDaysAgo: 5,
        expectedInDays: 0,
        courierName: 'Amazon Logistics',
        trackingNumber: 'AMZL999888777',
        events: [
          _event('ordered', 'Order placed successfully', 'Online', -5, now),
          _event(
            'confirmed',
            'Payment confirmed',
            'Amazon Fulfillment Centre, Mumbai',
            -5,
            now,
          ),
          _event(
            'packed',
            'Item packed and ready for dispatch',
            'Amazon FC, Mumbai',
            -3,
            now,
          ),
          _event(
            'shipped',
            'Shipment dispatched from fulfilment centre',
            'Mumbai Hub',
            -2,
            now,
          ),
          _event(
            'in_transit',
            'In transit to your city',
            'Pune Sorting Facility',
            -1,
            now,
          ),
          _event(
            'out_for_delivery',
            'Out for delivery — expected today',
            'Local Delivery Hub',
            0,
            now,
          ),
        ],
        isDemo: true,
        now: now,
      ),
      _makeOrder(
        userId: userId,
        id: 'demo-$userId-flipkart',
        platform: 'Flipkart',
        platformOrderId: 'OD427846701938290000',
        productName: 'Puma Men\'s Sports Shoes — Size 9',
        price: 3499.00,
        status: 'in_transit',
        orderedDaysAgo: 4,
        expectedInDays: 2,
        courierName: 'Ekart Logistics',
        trackingNumber: 'FMPP0072891234',
        events: [
          _event('ordered', 'Order placed', 'Online', -4, now),
          _event(
            'confirmed',
            'Seller confirmed the order',
            'Flipkart Smart Fulfilment, Bengaluru',
            -4,
            now,
          ),
          _event('packed', 'Ready to ship', 'Bengaluru Warehouse', -3, now),
          _event('shipped', 'Shipped via Ekart', 'Bengaluru', -2, now),
          _event('in_transit', 'Package in transit', 'Hyderabad Hub', -1, now),
        ],
        isDemo: true,
        now: now,
      ),
      _makeOrder(
        userId: userId,
        id: 'demo-$userId-myntra',
        platform: 'Myntra',
        platformOrderId: 'MYN-89234098-IN',
        productName: 'Levi\'s 511 Slim-Fit Jeans — Dark Blue',
        price: 2299.00,
        status: 'delivered',
        orderedDaysAgo: 12,
        expectedInDays: -5,
        courierName: 'Delhivery',
        trackingNumber: 'DEL4892736412',
        deliveredDaysAgo: 5,
        events: [
          _event('ordered', 'Order placed', 'Online', -12, now),
          _event(
            'confirmed',
            'Order confirmed by Myntra',
            'Myntra Warehouse, Bengaluru',
            -12,
            now,
          ),
          _event(
            'packed',
            'Packed and ready',
            'Myntra FC, Bengaluru',
            -10,
            now,
          ),
          _event('shipped', 'Handed over to Delhivery', 'Bengaluru', -9, now),
          _event('in_transit', 'In transit', 'Chennai Hub', -8, now),
          _event(
            'out_for_delivery',
            'Out for delivery',
            'Local Facility',
            -5,
            now,
          ),
          _event(
            'delivered',
            'Delivered successfully',
            'Your address',
            -5,
            now,
          ),
        ],
        isDemo: true,
        now: now,
      ),
      _makeOrder(
        userId: userId,
        id: 'demo-$userId-nykaa',
        platform: 'Nykaa',
        platformOrderId: 'NYK-20261020-83921',
        productName: 'Lakme Absolute Skin Natural Mousse Foundation',
        price: 699.00,
        status: 'shipped',
        orderedDaysAgo: 3,
        expectedInDays: 3,
        courierName: 'Blue Dart',
        trackingNumber: 'BD3920847162',
        events: [
          _event('ordered', 'Order placed on Nykaa', 'Online', -3, now),
          _event(
            'confirmed',
            'Order confirmed',
            'Nykaa Warehouse, Mumbai',
            -3,
            now,
          ),
          _event('packed', 'Packed', 'Mumbai Warehouse', -2, now),
          _event('shipped', 'Shipped via Blue Dart', 'Mumbai', -1, now),
        ],
        isDemo: true,
        now: now,
      ),
      _makeOrder(
        userId: userId,
        id: 'demo-$userId-meesho',
        platform: 'Meesho',
        platformOrderId: 'MSHO-TR-298761234',
        productName: 'Cotton Printed Kurti — Pack of 3',
        price: 899.00,
        status: 'delayed',
        orderedDaysAgo: 8,
        expectedInDays: -2,
        courierName: 'Shadowfax',
        trackingNumber: 'SFX9981234567',
        events: [
          _event('ordered', 'Order placed', 'Online', -8, now),
          _event('confirmed', 'Seller confirmed', 'Supplier, Surat', -8, now),
          _event('packed', 'Packed by seller', 'Surat', -6, now),
          _event('shipped', 'Picked up by Shadowfax', 'Surat', -5, now),
          _event(
            'delayed',
            'Delayed due to high volume at sorting centre',
            'Ahmedabad Hub',
            -3,
            now,
          ),
        ],
        isDemo: true,
        now: now,
      ),
    ];
  }

  static OrderModel _makeOrder({
    required String userId,
    required String id,
    required String platform,
    required String platformOrderId,
    required String productName,
    required double price,
    required String status,
    required int orderedDaysAgo,
    required int expectedInDays,
    String? courierName,
    String? trackingNumber,
    int? deliveredDaysAgo,
    required bool isDemo,
    required DateTime now,
    required List<TrackingEvent> events,
  }) {
    final orderedAt = now.subtract(Duration(days: orderedDaysAgo));
    final expectedDelivery = now.add(Duration(days: expectedInDays));
    final deliveredAt = deliveredDaysAgo != null
        ? now.subtract(Duration(days: deliveredDaysAgo))
        : null;

    return OrderModel(
      id: id,
      userId: userId,
      platformName: platform,
      platformOrderId: platformOrderId,
      productName: productName,
      quantity: 1,
      price: price,
      currency: 'INR',
      courierName: courierName,
      trackingNumber: trackingNumber,
      status: status,
      orderedAt: orderedAt,
      expectedDeliveryAt: expectedDelivery,
      deliveredAt: deliveredAt,
      createdAt: orderedAt,
      updatedAt: now,
      isDemo: isDemo,
      trackingSource: 'demo',
      trackingEvents: events
          .map(
            (event) => event.copyWith(
              id: '$id-${event.status}-${event.occurredAt.millisecondsSinceEpoch}',
              orderId: id,
            ),
          )
          .toList(),
    );
  }

  static TrackingEvent _event(
    String status,
    String description,
    String location,
    int daysFromNow,
    DateTime now,
  ) {
    return TrackingEvent(
      id: status,
      orderId: '',
      status: status,
      description: description,
      locationName: location,
      occurredAt: now.add(Duration(days: daysFromNow)),
      source: 'demo',
      isVerified: false,
    );
  }
}
