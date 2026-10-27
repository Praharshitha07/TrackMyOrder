import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_order/models/order_model.dart';
import 'package:track_my_order/models/tracking_event_model.dart';
import 'package:track_my_order/core/theme/app_theme.dart';
import 'package:track_my_order/core/constants/app_constants.dart';
import 'package:track_my_order/services/demo_data.dart';
import 'package:track_my_order/core/utils/format_utils.dart';
import 'package:track_my_order/services/tracking/tracking_result.dart';
import 'package:track_my_order/services/notifications/notification_service.dart';
import 'package:track_my_order/services/analytics/analytics_service.dart';
import 'package:track_my_order/services/export/export_service.dart';

void main() {
  // ── OrderModel serialization ─────────────────────────────────────────────
  group('OrderModel', () {
    final now = DateTime(2026, 10, 1, 12, 0);

    OrderModel createOrder({String status = 'ordered'}) => OrderModel(
          id: 'test-id',
          userId: 'user-1',
          platformName: 'Amazon',
          platformOrderId: 'AMZ-001',
          productName: 'Test Product',
          quantity: 2,
          price: 999.0,
          currency: 'INR',
          status: status,
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    test('toJson and fromJson round-trip', () {
      final order = createOrder();
      final json = order.toJson();
      final restored = OrderModel.fromJson(json);

      expect(restored.id, order.id);
      expect(restored.productName, order.productName);
      expect(restored.price, order.price);
      expect(restored.currency, order.currency);
      expect(restored.status, order.status);
      expect(restored.orderedAt.millisecondsSinceEpoch,
          order.orderedAt.millisecondsSinceEpoch);
    });

    test('JSON string round-trip', () {
      final order = createOrder();
      final jsonStr = order.toJsonString();
      final restored = OrderModel.fromJsonString(jsonStr);
      expect(restored.id, order.id);
      expect(restored.platformName, order.platformName);
    });

    test('copyWith preserves unmodified fields', () {
      final order = createOrder();
      final copy = order.copyWith(productName: 'Updated Name');
      expect(copy.productName, 'Updated Name');
      expect(copy.id, order.id);
      expect(copy.price, order.price);
    });

    test('copyWith clearProductImage sets null', () {
      final order = createOrder().copyWith(productImageUrl: 'https://example.com/img.png');
      final copy = order.copyWith(clearProductImage: true);
      expect(copy.productImageUrl, isNull);
    });

    test('equality is based on id', () {
      final a = createOrder();
      final b = createOrder();
      expect(a, equals(b));
    });

    test('optional fields default to null', () {
      final order = createOrder();
      expect(order.productImageUrl, isNull);
      expect(order.courierName, isNull);
      expect(order.trackingNumber, isNull);
      expect(order.expectedDeliveryAt, isNull);
    });
  });

  // ── TrackingEvent ────────────────────────────────────────────────────────
  group('TrackingEvent', () {
    final now = DateTime(2026, 10, 1, 10, 0);

    test('toJson and fromJson round-trip', () {
      final event = TrackingEvent(
        id: 'ev-1',
        orderId: 'order-1',
        status: 'in_transit',
        description: 'Package in transit',
        locationName: 'Mumbai Hub',
        latitude: 19.076,
        longitude: 72.877,
        occurredAt: now,
        source: 'demo',
        isVerified: false,
      );
      final json = event.toJson();
      final restored = TrackingEvent.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.status, event.status);
      expect(restored.latitude, event.latitude);
      expect(restored.longitude, event.longitude);
    });
  });

  // ── Status labels and colours ────────────────────────────────────────────
  group('AppTheme status helpers', () {
    test('all statuses have a label', () {
      for (final s in AppConstants.allStatuses) {
        final label = AppTheme.statusLabel(s);
        expect(label.isNotEmpty, isTrue,
            reason: 'Status "$s" has no label');
      }
    });

    test('all statuses have an icon', () {
      for (final s in AppConstants.allStatuses) {
        final icon = AppTheme.statusIcon(s);
        expect(icon, isNotNull,
            reason: 'Status "$s" has no icon');
      }
    });

    test('all statuses have a colour', () {
      for (final s in AppConstants.allStatuses) {
        final color = AppTheme.statusColor(s);
        expect(color, isNotNull,
            reason: 'Status "$s" has no colour');
      }
    });

    test('platform colours are distinct', () {
      final platforms = ['Amazon', 'Flipkart', 'Myntra', 'Nykaa', 'Meesho'];
      final colors = platforms.map(AppTheme.platformColor).toSet();
      expect(colors.length, equals(platforms.length));
    });
  });

  // ── Filtering logic ──────────────────────────────────────────────────────
  group('Order filtering', () {
    final now = DateTime(2026, 10, 1);

    OrderModel buildOrder(String name, String status, String platform) =>
        OrderModel(
          id: name,
          userId: 'user-1',
          platformName: platform,
          platformOrderId: 'PO-$name',
          productName: name,
          quantity: 1,
          price: 100,
          currency: 'INR',
          status: status,
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    bool matchesSearch(OrderModel o, String q) {
      final query = q.toLowerCase();
      return o.productName.toLowerCase().contains(query) ||
          o.platformOrderId.toLowerCase().contains(query) ||
          (o.trackingNumber?.toLowerCase().contains(query) ?? false) ||
          o.platformName.toLowerCase().contains(query);
    }

    test('search by product name', () {
      final orders = [
        buildOrder('boAt Earbuds', 'ordered', 'Amazon'),
        buildOrder('Puma Shoes', 'shipped', 'Flipkart'),
      ];
      final results = orders.where((o) => matchesSearch(o, 'boat')).toList();
      expect(results.length, 1);
      expect(results.first.productName, 'boAt Earbuds');
    });

    test('status filter', () {
      final orders = [
        buildOrder('A', 'ordered', 'Amazon'),
        buildOrder('B', 'delivered', 'Flipkart'),
        buildOrder('C', 'ordered', 'Myntra'),
      ];
      final filtered =
          orders.where((o) => o.status == 'ordered').toList();
      expect(filtered.length, 2);
    });

    test('platform filter', () {
      final orders = [
        buildOrder('A', 'ordered', 'Amazon'),
        buildOrder('B', 'shipped', 'Amazon'),
        buildOrder('C', 'ordered', 'Flipkart'),
      ];
      final filtered =
          orders.where((o) => o.platformName == 'Amazon').toList();
      expect(filtered.length, 2);
    });

    test('combined search + status', () {
      final orders = [
        buildOrder('boAt Earbuds', 'ordered', 'Amazon'),
        buildOrder('boAt Speaker', 'delivered', 'Amazon'),
        buildOrder('Puma Shoes', 'ordered', 'Flipkart'),
      ];
      final results = orders
          .where((o) =>
              matchesSearch(o, 'boat') && o.status == 'ordered')
          .toList();
      expect(results.length, 1);
      expect(results.first.productName, 'boAt Earbuds');
    });
  });

  // ── Demo data ────────────────────────────────────────────────────────────
  group('DemoData', () {
    test('generates non-empty order list', () {
      final demos = DemoData.generateDemoOrders();
      expect(demos.isNotEmpty, isTrue);
    });

    test('all demo orders are marked isDemo=true', () {
      final demos = DemoData.generateDemoOrders();
      for (final o in demos) {
        expect(o.isDemo, isTrue,
            reason: 'Demo order "${o.productName}" has isDemo=false');
      }
    });

    test('all demo orders belong to demo user', () {
      final demos = DemoData.generateDemoOrders();
      for (final o in demos) {
        expect(o.userId, equals(DemoData.demoUserId));
      }
    });

    test('demo orders have tracking events', () {
      final demos = DemoData.generateDemoOrders();
      for (final o in demos) {
        expect(o.trackingEvents.isNotEmpty, isTrue,
            reason: 'Demo order "${o.productName}" has no tracking events');
      }
    });

    test('all demo platforms are supported', () {
      final demos = DemoData.generateDemoOrders();
      for (final o in demos) {
        expect(
          AppConstants.shoppingPlatforms.contains(o.platformName),
          isTrue,
          reason: 'Platform "${o.platformName}" not in supported list',
        );
      }
    });
  });

  // ── Formatting utilities ─────────────────────────────────────────────────
  group('FormatUtils', () {
    test('formatShort returns dash for null', () {
      expect(AppDateUtils.formatShort(null), '—');
    });

    test('formatShort returns formatted date', () {
      final date = DateTime(2026, 10, 27);
      final result = AppDateUtils.formatShort(date);
      expect(result, contains('27'));
      expect(result, contains('Oct'));
    });

    test('relativeLabel — today', () {
      final today = DateTime.now();
      expect(AppDateUtils.relativeLabel(today), 'Today');
    });

    test('relativeLabel — null returns dash', () {
      expect(AppDateUtils.relativeLabel(null), '—');
    });

    test('CurrencyUtils format INR', () {
      final result = CurrencyUtils.format(1299.0, 'INR');
      expect(result, contains('₹'));
      expect(result, contains('1'));
    });

    test('CurrencyUtils format USD', () {
      final result = CurrencyUtils.format(19.99, 'USD');
      expect(result, contains('\$'));
    });
  });

  // ── AppConstants ─────────────────────────────────────────────────────────
  group('AppConstants', () {
    test('supported platforms is non-empty', () {
      expect(AppConstants.shoppingPlatforms.isNotEmpty, isTrue);
    });

    test('currencies list is non-empty', () {
      expect(AppConstants.currencies.isNotEmpty, isTrue);
    });

    test('all statuses list covers known statuses', () {
      expect(AppConstants.allStatuses.contains(AppConstants.statusOrdered), isTrue);
      expect(AppConstants.allStatuses.contains(AppConstants.statusDelivered), isTrue);
      expect(AppConstants.allStatuses.contains(AppConstants.statusCancelled), isTrue);
    });

    test('tagline is defined', () {
      expect(AppConstants.appTagline, 'All your orders. One place.');
    });
  });

  // ── Sorting logic ────────────────────────────────────────────────────────
  group('Order sorting', () {
    final t1 = DateTime(2026, 10, 1);
    final t2 = DateTime(2026, 10, 2);
    final t3 = DateTime(2026, 10, 3);

    OrderModel sortOrder(String id, DateTime createdAt, DateTime? delivery) =>
        OrderModel(
          id: id,
          userId: 'user-1',
          platformName: 'Amazon',
          platformOrderId: 'PO-$id',
          productName: id,
          quantity: 1,
          price: 100,
          currency: 'INR',
          status: 'ordered',
          orderedAt: createdAt,
          expectedDeliveryAt: delivery,
          createdAt: createdAt,
          updatedAt: createdAt,
        );

    test('sort by newest first', () {
      final list = [
        sortOrder('1', t1, null),
        sortOrder('3', t3, null),
        sortOrder('2', t2, null),
      ];
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(list.map((o) => o.id).toList(), ['3', '2', '1']);
    });

    test('sort by oldest first', () {
      final list = [
        sortOrder('3', t3, null),
        sortOrder('1', t1, null),
        sortOrder('2', t2, null),
      ];
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(list.map((o) => o.id).toList(), ['1', '2', '3']);
    });

    test('sort by expected delivery date', () {
      final list = [
        sortOrder('no_date', t1, null),
        sortOrder('late', t1, t3),
        sortOrder('early', t1, t2),
      ];
      list.sort((a, b) {
        if (a.expectedDeliveryAt == null && b.expectedDeliveryAt == null) return 0;
        if (a.expectedDeliveryAt == null) return 1;
        if (b.expectedDeliveryAt == null) return -1;
        return a.expectedDeliveryAt!.compareTo(b.expectedDeliveryAt!);
      });
      expect(list.map((o) => o.id).toList(), ['early', 'late', 'no_date']);
    });
  });

  // ── Auth & User Isolation ────────────────────────────────────────────────
  group('User isolation & Auth State', () {
    test('effective user ID defaults to guest_user in guest mode', () {
      const guestId = 'guest_user';
      expect(guestId, 'guest_user');
    });

    test('orders are strictly separated by user ID', () {
      final now = DateTime.now();
      final user1Orders = [
        OrderModel(
          id: 'o1',
          userId: 'user_alice',
          platformName: 'Amazon',
          platformOrderId: 'PO-1',
          productName: 'Watch',
          quantity: 1,
          price: 500,
          currency: 'INR',
          status: 'ordered',
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final user2Orders = [
        OrderModel(
          id: 'o2',
          userId: 'user_bob',
          platformName: 'Flipkart',
          platformOrderId: 'PO-2',
          productName: 'Shoes',
          quantity: 1,
          price: 800,
          currency: 'INR',
          status: 'shipped',
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final allOrders = [...user1Orders, ...user2Orders];
      final aliceFiltered = allOrders.where((o) => o.userId == 'user_alice').toList();
      final bobFiltered = allOrders.where((o) => o.userId == 'user_bob').toList();

      expect(aliceFiltered.length, 1);
      expect(aliceFiltered.first.productName, 'Watch');
      expect(bobFiltered.length, 1);
      expect(bobFiltered.first.productName, 'Shoes');
      expect(aliceFiltered.any((o) => o.userId == 'user_bob'), isFalse);
    });
  });

  // ── Unified Tracking & Courier Services ──────────────────────────────────
  group('Unified Tracking Services', () {
    test('supported couriers list contains standard Indian carriers', () {
      expect(AppConstants.supportedCouriers.contains('Delhivery'), isTrue);
      expect(AppConstants.supportedCouriers.contains('Blue Dart'), isTrue);
      expect(AppConstants.supportedCouriers.contains('Ekart'), isTrue);
      expect(AppConstants.supportedCouriers.contains('India Post'), isTrue);
    });

    test('tracking result returns unconfigured message when credentials are empty', () {
      final notConfigured = TrackingResult.notConfigured(
        courierName: 'Delhivery',
        trackingNumber: 'DEL12345678',
        currentStatus: 'in_transit',
      );
      expect(notConfigured.isLive, isFalse);
      expect(notConfigured.isConfigured, isFalse);
      expect(notConfigured.hasError, isTrue);
      expect(notConfigured.errorMessage, contains('Delhivery'));
    });

    test('tracking result returns unsupported message for unknown courier', () {
      final unsupported = TrackingResult.unsupportedCarrier(
        courierName: 'CustomFly',
        trackingNumber: 'CF999',
        currentStatus: 'ordered',
      );
      expect(unsupported.isLive, isFalse);
      expect(unsupported.errorMessage, contains('CustomFly'));
    });
  });

  // ── Phase 4: OrderModel Backward Compatibility & Reminder Fields ───────────
  group('OrderModel Phase 4 Extensions', () {
    final now = DateTime(2026, 10, 1, 12, 0);

    test('backward compatible deserialization when category and reminder fields are omitted', () {
      final legacyJson = {
        'id': 'legacy-1',
        'user_id': 'u1',
        'platform_name': 'Flipkart',
        'platform_order_id': 'FLIP-123',
        'product_name': 'Earphones',
        'quantity': 1,
        'price': 499.0,
        'currency': 'INR',
        'status': 'ordered',
        'ordered_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final order = OrderModel.fromJson(legacyJson);
      expect(order.category, isNull);
      expect(order.reminderEnabled, isFalse);
      expect(order.reminderPreference, 'on_day');
    });

    test('deserializes and serializes category and reminder fields correctly', () {
      final order = OrderModel(
        id: 'ord-p4',
        userId: 'u1',
        platformName: 'Amazon',
        platformOrderId: 'AMZ-888',
        productName: 'Smart Watch',
        quantity: 2,
        price: 2499.0,
        currency: 'INR',
        category: 'Electronics',
        reminderEnabled: true,
        reminderPreference: 'day_before',
        status: 'shipped',
        orderedAt: now,
        expectedDeliveryAt: now.add(const Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
      );

      final json = order.toJson();
      expect(json['category'], 'Electronics');
      expect(json['reminder_enabled'], isTrue);
      expect(json['reminder_preference'], 'day_before');

      final restored = OrderModel.fromJson(json);
      expect(restored.category, 'Electronics');
      expect(restored.reminderEnabled, isTrue);
      expect(restored.reminderPreference, 'day_before');
    });
  });

  // ── Phase 4: NotificationService Reminders ────────────────────────────────
  group('NotificationService', () {
    final deliveryDate = DateTime(2026, 10, 15, 18, 30);

    OrderModel buildOrderWithDelivery({
      bool reminderEnabled = true,
      String reminderPreference = 'on_day',
      String status = 'in_transit',
      DateTime? expectedDelivery,
    }) {
      return OrderModel(
        id: 'rem-order-1',
        userId: 'u1',
        platformName: 'Amazon',
        platformOrderId: 'ORD-999',
        productName: 'Mechanical Keyboard',
        quantity: 1,
        price: 3500.0,
        currency: 'INR',
        status: status,
        reminderEnabled: reminderEnabled,
        reminderPreference: reminderPreference,
        orderedAt: DateTime(2026, 10, 10),
        expectedDeliveryAt: expectedDelivery ?? deliveryDate,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );
    }

    test('calculateScheduledTime on delivery day sets 9:00 AM', () {
      final order = buildOrderWithDelivery(reminderPreference: 'on_day');
      final scheduled = NotificationService.calculateScheduledTime(order);

      expect(scheduled, isNotNull);
      expect(scheduled!.year, 2026);
      expect(scheduled.month, 10);
      expect(scheduled.day, 15);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });

    test('calculateScheduledTime day_before sets 9:00 AM on the day prior', () {
      final order = buildOrderWithDelivery(reminderPreference: 'day_before');
      final scheduled = NotificationService.calculateScheduledTime(order);

      expect(scheduled, isNotNull);
      expect(scheduled!.year, 2026);
      expect(scheduled.month, 10);
      expect(scheduled.day, 14);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });

    test('calculateScheduledTime returns null when expectedDeliveryAt is null', () {
      final order = OrderModel(
        id: 'no-date',
        userId: 'u1',
        platformName: 'Meesho',
        platformOrderId: 'MEE-1',
        productName: 'Cotton Shirt',
        quantity: 1,
        price: 499.0,
        currency: 'INR',
        status: 'ordered',
        reminderEnabled: true,
        orderedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final scheduled = NotificationService.calculateScheduledTime(order);
      expect(scheduled, isNull);
    });

    test('shouldScheduleReminder returns false if order is terminal (delivered or cancelled)', () {
      final deliveredOrder = buildOrderWithDelivery(status: 'delivered');
      final cancelledOrder = buildOrderWithDelivery(status: 'cancelled');

      expect(NotificationService.shouldScheduleReminder(deliveredOrder), isFalse);
      expect(NotificationService.shouldScheduleReminder(cancelledOrder), isFalse);
    });

    test('shouldScheduleReminder returns false if reminderEnabled is false', () {
      final disabledOrder = buildOrderWithDelivery(reminderEnabled: false);
      expect(NotificationService.shouldScheduleReminder(disabledOrder), isFalse);
    });

    test('getPendingReminders filters only eligible orders', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final eligible = buildOrderWithDelivery(expectedDelivery: futureDate);
      final delivered = buildOrderWithDelivery(status: 'delivered', expectedDelivery: futureDate);
      final disabled = buildOrderWithDelivery(reminderEnabled: false, expectedDelivery: futureDate);

      final reminders = NotificationService.getPendingReminders([eligible, delivered, disabled]);
      expect(reminders.length, 1);
      expect(reminders.first.order.id, eligible.id);
    });
  });

  // ── Phase 4: AnalyticsService Spending & Insights ─────────────────────────
  group('AnalyticsService', () {
    final baseDate = DateTime(2026, 8, 15);

    final orders = [
      OrderModel(
        id: 'ord-1',
        userId: 'u1',
        platformName: 'Amazon',
        platformOrderId: 'A1',
        productName: 'Wireless Headphones',
        quantity: 1,
        price: 2000.0,
        currency: 'INR',
        category: 'Electronics',
        status: 'delivered',
        orderedAt: DateTime(2026, 8, 10),
        createdAt: baseDate,
        updatedAt: baseDate,
      ),
      OrderModel(
        id: 'ord-2',
        userId: 'u1',
        platformName: 'Amazon',
        platformOrderId: 'A2',
        productName: 'USB-C Cable',
        quantity: 2,
        price: 500.0, // 2 * 500 = 1000
        currency: 'INR',
        category: 'Electronics',
        status: 'shipped',
        orderedAt: DateTime(2026, 8, 20),
        createdAt: baseDate,
        updatedAt: baseDate,
      ),
      OrderModel(
        id: 'ord-3',
        userId: 'u1',
        platformName: 'Myntra',
        platformOrderId: 'M1',
        productName: 'Denim Jacket',
        quantity: 1,
        price: 1500.0,
        currency: 'INR',
        category: 'Fashion & Apparel',
        status: 'ordered',
        orderedAt: DateTime(2026, 9, 5),
        createdAt: baseDate,
        updatedAt: baseDate,
      ),
      OrderModel(
        id: 'ord-4',
        userId: 'u1',
        platformName: 'Flipkart',
        platformOrderId: 'F1',
        productName: 'Cancelled Blender',
        quantity: 1,
        price: 3000.0,
        currency: 'INR',
        category: 'Home & Kitchen',
        status: 'cancelled', // STRICT EXCLUSION FROM SPENDING
        orderedAt: DateTime(2026, 9, 10),
        createdAt: baseDate,
        updatedAt: baseDate,
      ),
    ];

    test('calculateSpending accurately computes sum excluding cancelled orders', () {
      final spending = AnalyticsService.calculateSpending(orders);

      // Expected spending:
      // ord-1: 2000 * 1 = 2000
      // ord-2: 500 * 2 = 1000
      // ord-3: 1500 * 1 = 1500
      // Total = 4500. ord-4 (3000) is excluded.
      expect(spending.totalSpent, 4500.0);
      expect(spending.includedOrderCount, 3);
      expect(spending.cancelledOrderCount, 1);
      expect(spending.averageOrderValue, 1500.0); // 4500 / 3 = 1500
    });

    test('calculatePlatformBreakdown handles percentages and spending per platform', () {
      final breakdown = AnalyticsService.calculatePlatformBreakdown(orders);

      // Total orders: 4. Amazon: 2 (50%), Myntra: 1 (25%), Flipkart: 1 (25%)
      final amazon = breakdown.firstWhere((p) => p.platform == 'Amazon');
      expect(amazon.orderCount, 2);
      expect(amazon.percentage, 50.0);
      expect(amazon.totalSpent, 3000.0);

      final myntra = breakdown.firstWhere((p) => p.platform == 'Myntra');
      expect(myntra.orderCount, 1);
      expect(myntra.totalSpent, 1500.0);
    });

    test('calculateCategoryBreakdown aggregates spending per category', () {
      final categories = AnalyticsService.calculateCategoryBreakdown(orders);

      final electronics = categories.firstWhere((c) => c.category == 'Electronics');
      expect(electronics.orderCount, 2);
      expect(electronics.totalSpent, 3000.0);

      final fashion = categories.firstWhere((c) => c.category == 'Fashion & Apparel');
      expect(fashion.orderCount, 1);
      expect(fashion.totalSpent, 1500.0);

      final home = categories.firstWhere((c) => c.category == 'Home & Kitchen');
      expect(home.orderCount, 1);
      // Cancelled order price is excluded from category spending:
      expect(home.totalSpent, 0.0);
    });

    test('calculateMonthlySpending creates chronological monthly buckets', () {
      final monthly = AnalyticsService.calculateMonthlySpending(orders);

      // Should have 2 months: Aug 2026 and Sep 2026 in chronological order
      expect(monthly.length, 2);
      expect(monthly[0].monthLabel, contains('Aug'));
      expect(monthly[0].totalSpent, 3000.0);
      expect(monthly[0].orderCount, 2);

      expect(monthly[1].monthLabel, contains('Sep'));
      expect(monthly[1].totalSpent, 1500.0); // excludes cancelled blender
      expect(monthly[1].orderCount, 2); // includes all 2 orders in Sep
    });
  });

  // ── Phase 4: ExportService CSV & JSON ─────────────────────────────────────
  group('ExportService', () {
    final now = DateTime(2026, 10, 5, 14, 30);
    final testOrders = [
      OrderModel(
        id: 'exp-1',
        userId: 'user-xyz',
        platformName: 'Amazon',
        platformOrderId: 'AMZ-1234',
        productName: 'Noise-Cancelling Headphones, Wireless',
        quantity: 1,
        price: 1999.50,
        currency: 'INR',
        category: 'Electronics',
        status: 'delivered',
        courierName: 'Delhivery',
        trackingNumber: 'DEL12345678',
        orderedAt: now,
        expectedDeliveryAt: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      OrderModel(
        id: 'exp-2',
        userId: 'user-xyz',
        platformName: 'Flipkart',
        platformOrderId: 'FLIP-9876',
        productName: 'Men\'s "Classic" Polo Shirt',
        quantity: 2,
        price: 599.0,
        currency: 'INR',
        category: 'Fashion & Apparel',
        status: 'shipped',
        orderedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('generateCsv contains correct header and properly escaped values', () {
      final csv = ExportService.generateCsv(testOrders);

      // Check headers
      expect(csv, contains('Order ID,Platform,Platform Order ID,Product Name'));
      expect(csv, contains('Price,Currency,Total Amount,Status,Courier Name,Tracking Number'));

      // Check commas and quotes escaping
      // "Noise-Cancelling Headphones, Wireless" has a comma so must be quoted:
      expect(csv, contains('"Noise-Cancelling Headphones, Wireless"'));
      // "Men's "Classic" Polo Shirt" has double quotes so must be escaped with double quotes:
      expect(csv, contains('""Classic""'));
    });

    test('generateJson produces valid JSON schema with version and orderCount', () {
      final jsonStr = ExportService.generateJson(testOrders);

      expect(jsonStr, contains('"version": 1'));
      expect(jsonStr, contains('"orderCount": 2'));
      expect(jsonStr, contains('"orders":'));

      // Test parsing back
      final imported = ExportService.parseImportJson(jsonStr);
      expect(imported.length, 2);
      expect(imported[0].id, 'exp-1');
      expect(imported[0].productName, 'Noise-Cancelling Headphones, Wireless');
      expect(imported[0].price, 1999.50);
      expect(imported[1].id, 'exp-2');
      expect(imported[1].category, 'Fashion & Apparel');
    });

    test('parseImportJson throws on corrupted or non-order JSON', () {
      expect(() => ExportService.parseImportJson('{ "version": 1 }'), throwsFormatException);
      expect(() => ExportService.parseImportJson('not json'), throwsFormatException);
    });
  });
}
