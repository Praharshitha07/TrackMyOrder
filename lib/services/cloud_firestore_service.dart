import '../models/order_model.dart';
import '../repositories/order_repository.dart';

/// Service interface to encapsulate Cloud Firestore integration.
/// This defines the exact structure and schema operations needed for
/// multi-tenant, user-isolated Firestore collections:
///
/// Path: /users/{userId}/orders/{orderId}
abstract class CloudFirestoreService {
  /// Create or update an order document under the user's specific collection
  Future<OrderModel> saveUserOrder({
    required String userId,
    required OrderModel order,
  });

  /// Fetch all orders strictly belonging to the given user
  Future<List<OrderModel>> getUserOrders(String userId);

  /// Fetch a single order by ID for the authorized user
  Future<OrderModel?> getUserOrderById({
    required String userId,
    required String orderId,
  });

  /// Delete an order document from the user's private collection
  Future<void> deleteUserOrder({
    required String userId,
    required String orderId,
  });

  /// Batch sync or migrate local orders into the user's Firestore collection
  Future<int> migrateLocalOrders({
    required String targetUserId,
    required List<OrderModel> localOrders,
  });
}

/// Firestore-backed OrderRepository implementation.
/// Implements [OrderRepository] using [CloudFirestoreService].
class FirestoreOrderRepository implements OrderRepository {
  final CloudFirestoreService _firestoreService;

  FirestoreOrderRepository(this._firestoreService);

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    return _firestoreService.getUserOrders(userId);
  }

  @override
  Future<OrderModel> saveOrder(OrderModel order) async {
    return _firestoreService.saveUserOrder(
      userId: order.userId,
      order: order,
    );
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    return _firestoreService.saveUserOrder(
      userId: order.userId,
      order: order,
    );
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    // If orderId is provided without userId in the interface signature,
    // we route through the authorized context
    throw UnimplementedError('Call deleteUserOrder with explicit userId.');
  }

  Future<void> deleteUserOrder({
    required String userId,
    required String orderId,
  }) async {
    await _firestoreService.deleteUserOrder(
      userId: userId,
      orderId: orderId,
    );
  }

  @override
  Future<void> deleteAllOrders(String userId) async {
    final orders = await _firestoreService.getUserOrders(userId);
    for (final order in orders) {
      await _firestoreService.deleteUserOrder(
        userId: userId,
        orderId: order.id,
      );
    }
  }
}
