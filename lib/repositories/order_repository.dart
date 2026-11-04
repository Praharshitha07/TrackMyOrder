import '../models/order_model.dart';

/// User-owned order operations backed by Cloud Firestore.
abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String userId);
  Future<OrderModel> saveOrder(OrderModel order);
  Future<OrderModel> updateOrder(OrderModel order);
  Future<void> deleteOrder(String orderId);
  Future<void> deleteAllOrders(String userId);
}
