import 'dart:convert';

import 'tracking_event_model.dart';

/// Core order data model.
class OrderModel {
  final String id;
  final String userId;
  final String platformName;
  final String platformOrderId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double price;
  final String currency;
  final String? courierName;
  final String? trackingNumber;
  final String? courierContact;
  final String? pickupLocation;
  final String? deliveryLocation;
  final String? additionalNotes;
  final bool demoTrackingEnabled;
  final String status;
  final DateTime orderedAt;
  final DateTime? expectedDeliveryAt;
  final DateTime? deliveredAt;
  final String? trackingUrl;
  final String? orderUrl;
  final String? trackingSource;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDemo;
  final List<TrackingEvent> trackingEvents;
  final String? category;
  final bool reminderEnabled;
  final String reminderPreference; // 'on_day' | 'day_before'

  const OrderModel({
    required this.id,
    required this.userId,
    required this.platformName,
    required this.platformOrderId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.price,
    required this.currency,
    this.courierName,
    this.trackingNumber,
    this.courierContact,
    this.pickupLocation,
    this.deliveryLocation,
    this.additionalNotes,
    this.demoTrackingEnabled = true,
    required this.status,
    required this.orderedAt,
    this.expectedDeliveryAt,
    this.deliveredAt,
    this.trackingUrl,
    this.orderUrl,
    this.trackingSource,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isDemo = false,
    this.trackingEvents = const [],
    this.category,
    this.reminderEnabled = false,
    this.reminderPreference = 'on_day',
  });

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  OrderModel copyWith({
    String? id,
    String? userId,
    String? platformName,
    String? platformOrderId,
    String? productName,
    String? productImageUrl,
    bool clearProductImage = false,
    int? quantity,
    double? price,
    String? currency,
    String? courierName,
    bool clearCourierName = false,
    String? trackingNumber,
    bool clearTrackingNumber = false,
    String? courierContact,
    bool clearCourierContact = false,
    String? pickupLocation,
    bool clearPickupLocation = false,
    String? deliveryLocation,
    bool clearDeliveryLocation = false,
    String? additionalNotes,
    bool clearAdditionalNotes = false,
    bool? demoTrackingEnabled,
    String? status,
    DateTime? orderedAt,
    DateTime? expectedDeliveryAt,
    bool clearExpectedDelivery = false,
    DateTime? deliveredAt,
    bool clearDeliveredAt = false,
    String? trackingUrl,
    bool clearTrackingUrl = false,
    String? orderUrl,
    bool clearOrderUrl = false,
    String? trackingSource,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDemo,
    List<TrackingEvent>? trackingEvents,
    String? category,
    bool clearCategory = false,
    bool? reminderEnabled,
    String? reminderPreference,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platformName: platformName ?? this.platformName,
      platformOrderId: platformOrderId ?? this.platformOrderId,
      productName: productName ?? this.productName,
      productImageUrl: clearProductImage
          ? null
          : (productImageUrl ?? this.productImageUrl),
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      courierName: clearCourierName ? null : (courierName ?? this.courierName),
      trackingNumber: clearTrackingNumber
          ? null
          : (trackingNumber ?? this.trackingNumber),
      courierContact: clearCourierContact
          ? null
          : (courierContact ?? this.courierContact),
      pickupLocation: clearPickupLocation
          ? null
          : (pickupLocation ?? this.pickupLocation),
      deliveryLocation: clearDeliveryLocation
          ? null
          : (deliveryLocation ?? this.deliveryLocation),
      additionalNotes: clearAdditionalNotes
          ? null
          : (additionalNotes ?? this.additionalNotes),
      demoTrackingEnabled: demoTrackingEnabled ?? this.demoTrackingEnabled,
      status: status ?? this.status,
      orderedAt: orderedAt ?? this.orderedAt,
      expectedDeliveryAt: clearExpectedDelivery
          ? null
          : (expectedDeliveryAt ?? this.expectedDeliveryAt),
      deliveredAt: clearDeliveredAt ? null : (deliveredAt ?? this.deliveredAt),
      trackingUrl: clearTrackingUrl ? null : (trackingUrl ?? this.trackingUrl),
      orderUrl: clearOrderUrl ? null : (orderUrl ?? this.orderUrl),
      trackingSource: trackingSource ?? this.trackingSource,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo ?? this.isDemo,
      trackingEvents: trackingEvents ?? this.trackingEvents,
      category: clearCategory ? null : (category ?? this.category),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderPreference: reminderPreference ?? this.reminderPreference,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'platformName': platformName,
    'platformOrderId': platformOrderId,
    'productName': productName,
    'productImageUrl': productImageUrl,
    'quantity': quantity,
    'price': price,
    'currency': currency,
    'courierName': courierName,
    'trackingNumber': trackingNumber,
    'courierContact': courierContact,
    'pickupLocation': pickupLocation,
    'deliveryLocation': deliveryLocation,
    'additionalNotes': additionalNotes,
    'demoTrackingEnabled': demoTrackingEnabled,
    'status': status,
    'orderedAt': orderedAt.toIso8601String(),
    'expectedDeliveryAt': expectedDeliveryAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'trackingUrl': trackingUrl,
    'orderUrl': orderUrl,
    'trackingSource': trackingSource,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDemo': isDemo,
    'trackingEvents': trackingEvents.map((e) => e.toJson()).toList(),
    'category': category,
    'reminderEnabled': reminderEnabled,
    'reminderPreference': reminderPreference,
    // Snake_case aliases for legacy / export compatibility
    'user_id': userId,
    'platform_name': platformName,
    'platform_order_id': platformOrderId,
    'product_name': productName,
    'reminder_enabled': reminderEnabled,
    'reminder_preference': reminderPreference,
    'courier_name': courierName,
    'tracking_number': trackingNumber,
    'courier_contact': courierContact,
    'pickup_location': pickupLocation,
    'delivery_location': deliveryLocation,
    'additional_notes': additionalNotes,
    'demo_tracking_enabled': demoTrackingEnabled,
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: (json['id'] ?? json['order_id']) as String,
    userId: (json['userId'] ?? json['user_id']) as String? ?? 'local',
    platformName:
        (json['platformName'] ?? json['platform_name']) as String? ?? 'Other',
    platformOrderId:
        (json['platformOrderId'] ?? json['platform_order_id']) as String? ?? '',
    productName: (json['productName'] ?? json['product_name']) as String? ?? '',
    productImageUrl:
        (json['productImageUrl'] ?? json['product_image_url']) as String?,
    quantity: ((json['quantity']) as num?)?.toInt() ?? 1,
    price: ((json['price']) as num?)?.toDouble() ?? 0.0,
    currency: (json['currency']) as String? ?? 'INR',
    courierName: (json['courierName'] ?? json['courier_name']) as String?,
    trackingNumber:
        (json['trackingNumber'] ?? json['tracking_number']) as String?,
    courierContact:
        (json['courierContact'] ?? json['courier_contact']) as String?,
    pickupLocation:
        (json['pickupLocation'] ?? json['pickup_location']) as String?,
    deliveryLocation:
        (json['deliveryLocation'] ?? json['delivery_location']) as String?,
    additionalNotes:
        (json['additionalNotes'] ?? json['additional_notes']) as String?,
    demoTrackingEnabled:
        (json['demoTrackingEnabled'] ?? json['demo_tracking_enabled'])
            as bool? ??
        true,
    status: (json['status']) as String? ?? 'ordered',
    orderedAt: DateTime.parse(
      (json['orderedAt'] ?? json['ordered_at']) as String,
    ),
    expectedDeliveryAt:
        (json['expectedDeliveryAt'] ?? json['expected_delivery_at']) != null
        ? DateTime.parse(
            (json['expectedDeliveryAt'] ?? json['expected_delivery_at'])
                as String,
          )
        : null,
    deliveredAt: (json['deliveredAt'] ?? json['delivered_at']) != null
        ? DateTime.parse(
            (json['deliveredAt'] ?? json['delivered_at']) as String,
          )
        : null,
    trackingUrl: (json['trackingUrl'] ?? json['tracking_url']) as String?,
    orderUrl: (json['orderUrl'] ?? json['order_url']) as String?,
    trackingSource:
        (json['trackingSource'] ?? json['tracking_source']) as String?,
    lastSyncedAt: (json['lastSyncedAt'] ?? json['last_synced_at']) != null
        ? DateTime.parse(
            (json['lastSyncedAt'] ?? json['last_synced_at']) as String,
          )
        : null,
    createdAt: DateTime.parse(
      (json['createdAt'] ?? json['created_at']) as String,
    ),
    updatedAt: DateTime.parse(
      (json['updatedAt'] ?? json['updated_at']) as String,
    ),
    isDemo: (json['isDemo'] ?? json['is_demo']) as bool? ?? false,
    trackingEvents:
        ((json['trackingEvents'] ?? json['tracking_events']) as List<dynamic>?)
            ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    category: (json['category']) as String?,
    reminderEnabled:
        (json['reminderEnabled'] ?? json['reminder_enabled']) as bool? ?? false,
    reminderPreference:
        (json['reminderPreference'] ?? json['reminder_preference'])
            as String? ??
        'on_day',
  );

  String toJsonString() => jsonEncode(toJson());

  factory OrderModel.fromJsonString(String jsonStr) =>
      OrderModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OrderModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
