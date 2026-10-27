import '../models/order_model.dart';

/// Abstract repository interface for orders.
/// Swap the implementation to move from local storage → Cloud Firestore.
abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String userId);
  Future<OrderModel> saveOrder(OrderModel order);
  Future<OrderModel> updateOrder(OrderModel order);
  Future<void> deleteOrder(String orderId);
  Future<void> deleteAllOrders(String userId);
}
