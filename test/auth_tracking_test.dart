import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:track_my_order/core/theme/app_theme.dart';
import 'package:track_my_order/models/order_model.dart';
import 'package:track_my_order/models/tracking_event_model.dart';
import 'package:track_my_order/models/user_model.dart';
import 'package:track_my_order/providers/auth_provider.dart';
import 'package:track_my_order/providers/orders_provider.dart';
import 'package:track_my_order/repositories/auth_repository.dart';
import 'package:track_my_order/repositories/order_repository.dart';
import 'package:track_my_order/screens/add_order/add_order_screen.dart';
import 'package:track_my_order/screens/order_details/order_details_screen.dart';
import 'package:track_my_order/screens/order_details/widgets/tracking_timeline.dart';

void main() {
  test(
    'unauthenticated Firebase state cannot access protected app screens',
    () async {
      final auth = AuthProvider(_UnauthenticatedAuthRepository());
      await auth.initialize();

      expect(auth.state, AuthState.unauthenticated);
      expect(auth.canAccessApp, isFalse);

      auth.dispose();
    },
  );

  testWidgets('a normal order with no events shows no fabricated timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const TrackingTimeline(events: [], currentStatus: 'shipped'),
      ),
    );

    expect(
      find.text('Tracking updates are not available yet.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Current order status: Shipped. This status is not a courier scan.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'editing an order saves optional tracking details without a duplicate',
    (tester) async {
      final order = _order(id: 'real-order', userId: 'user-1').copyWith(
        expectedDeliveryAt: DateTime(2026, 11, 10),
        trackingEvents: [
          TrackingEvent(
            id: 'genuine-event',
            orderId: 'real-order',
            status: 'ordered',
            description: 'Genuine order placed',
            occurredAt: DateTime(2026, 11, 1),
          ),
        ],
      );
      final repository = _MemoryOrderRepository()..orders.add(order);
      final ordersProvider = OrdersProvider(repository);
      await ordersProvider.loadOrders('user-1');
      final authProvider = AuthProvider(_AuthenticatedAuthRepository());
      await authProvider.initialize();
      addTearDown(ordersProvider.dispose);
      addTearDown(authProvider.dispose);

      final router = GoRouter(
        initialLocation: '/details',
        routes: [
          GoRoute(
            path: '/details',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/edit'),
                  child: const Text('Open Edit'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) => AddOrderScreen(existingOrder: order),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: ordersProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      Future<void> fillField(String label, String value) async {
        final field = find.ancestor(
          of: find.text(label),
          matching: find.byType(TextFormField),
        );
        expect(field, findsOneWidget);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
      }

      await fillField('Courier Name', 'Shiprocket');
      await fillField('Courier Tracking Number', 'TRK-12345');
      await fillField(
        'Courier Tracking URL (optional)',
        'https://example.com/track',
      );
      await fillField('Courier Contact Number (optional)', '+91 9876543210');

      final expectedDeliveryField = find.ancestor(
        of: find.text('Expected Delivery'),
        matching: find.byType(GestureDetector),
      );
      await tester.ensureVisible(expectedDeliveryField);
      await tester.tap(expectedDeliveryField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.orders, hasLength(1));
      final saved = repository.orders.single;
      expect(saved.id, order.id);
      expect(saved.courierName, 'Shiprocket');
      expect(saved.trackingNumber, 'TRK-12345');
      expect(saved.trackingUrl, 'https://example.com/track');
      expect(saved.courierContact, '+91 9876543210');
      expect(saved.expectedDeliveryAt?.day, 15);
      expect(saved.status, order.status);
      expect(saved.demoTrackingEnabled, order.demoTrackingEnabled);
      expect(saved.trackingEvents.single.id, 'genuine-event');
    },
  );

  test(
    'demo orders are persisted for the account and removed separately',
    () async {
      final repository = _MemoryOrderRepository();
      final provider = OrdersProvider(repository);
      final genuineOrder = _order(id: 'real-order', userId: 'user-1');
      repository.orders.add(genuineOrder);

      await provider.loadOrders('user-1');
      await provider.addDemoOrders('user-1');

      expect(repository.orders, hasLength(6));
      expect(repository.orders.where((order) => order.isDemo), hasLength(5));
      expect(
        repository.orders
            .where((order) => order.isDemo)
            .every((order) => order.userId == 'user-1'),
        isTrue,
      );
      expect(provider.totalCount, 1);
      expect(provider.filteredOrders, hasLength(1));

      provider.toggleDemoOrders(true);
      expect(provider.filteredOrders, hasLength(6));
      await provider.deleteDemoOrders();

      expect(repository.orders, [genuineOrder]);
      expect(provider.allUserOrders, [genuineOrder]);
      expect(provider.hasDemoOrders, isFalse);

      provider.dispose();
    },
  );

  testWidgets('demo timeline labels sample events as simulated', (
    tester,
  ) async {
    final event = TrackingEvent(
      id: 'demo-event',
      orderId: 'demo-order',
      status: 'shipped',
      description: 'Sample parcel dispatched',
      occurredAt: DateTime(2026, 11, 2),
      source: 'demo',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: TrackingTimeline(events: [event], isDemo: true),
      ),
    );

    expect(find.text('Demo Event'), findsOneWidget);
    expect(find.text('Sample parcel dispatched'), findsOneWidget);
  });

  testWidgets(
    'demo tracking preference persists without changing order status',
    (tester) async {
      final order = _order(id: 'real-order', userId: 'user-1');
      final repository = _MemoryOrderRepository()..orders.add(order);
      final provider = OrdersProvider(repository);
      await provider.loadOrders('user-1');
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: OrderDetailsScreen(order: order),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('SIMULATED TRACKING — FOR DEMONSTRATION ONLY'),
        findsOneWidget,
      );
      expect(find.text('Delivered'), findsOneWidget);

      final demoTrackingSwitch = find.descendant(
        of: find.byType(SwitchListTile),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(demoTrackingSwitch);
      await tester.pumpAndSettle();
      await tester.tap(demoTrackingSwitch);
      await tester.pumpAndSettle();

      expect(repository.orders.single.demoTrackingEnabled, isFalse);
      expect(repository.orders.single.status, 'ordered');
      expect(
        find.text('SIMULATED TRACKING — FOR DEMONSTRATION ONLY'),
        findsNothing,
      );
      expect(
        find.text('Tracking updates are not available yet.'),
        findsOneWidget,
      );

      await tester.ensureVisible(demoTrackingSwitch);
      await tester.pumpAndSettle();
      await tester.tap(demoTrackingSwitch);
      await tester.pumpAndSettle();

      expect(repository.orders.single.demoTrackingEnabled, isTrue);
      expect(repository.orders.single.status, 'ordered');
      expect(
        find.text('SIMULATED TRACKING — FOR DEMONSTRATION ONLY'),
        findsOneWidget,
      );
    },
  );
}

OrderModel _order({required String id, required String userId}) {
  final date = DateTime(2026, 11, 1);
  return OrderModel(
    id: id,
    userId: userId,
    platformName: 'Amazon',
    platformOrderId: 'order-$id',
    productName: 'Genuine order',
    quantity: 1,
    price: 250,
    currency: 'INR',
    status: 'ordered',
    orderedAt: date,
    createdAt: date,
    updatedAt: date,
  );
}

class _MemoryOrderRepository implements OrderRepository {
  final List<OrderModel> orders = [];

  @override
  Future<List<OrderModel>> getOrders(String userId) async =>
      orders.where((order) => order.userId == userId).toList();

  @override
  Future<OrderModel> saveOrder(OrderModel order) async {
    orders.add(order);
    return order;
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    final index = orders.indexWhere((item) => item.id == order.id);
    orders[index] = order;
    return order;
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    orders.removeWhere((order) => order.id == orderId);
  }

  @override
  Future<void> deleteAllOrders(String userId) async {
    orders.removeWhere((order) => order.userId == userId);
  }
}

class _UnauthenticatedAuthRepository implements AuthRepository {
  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async =>
      throw UnimplementedError();

  @override
  Future<UserModel> updateProfile(UserModel user) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async => throw UnimplementedError();

  @override
  bool get isCloudAuth => true;
}

class _AuthenticatedAuthRepository extends _UnauthenticatedAuthRepository {
  final _user = UserModel(
    id: 'user-1',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2026, 11, 1),
  );

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(_user);

  @override
  Future<UserModel?> getCurrentUser() async => _user;
}
