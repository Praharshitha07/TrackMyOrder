import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'order_repository.dart';

/// Concrete repository that persists orders as JSON in SharedPreferences.
/// Replace this implementation with a Firestore one to move to the cloud.
class LocalOrderRepository implements OrderRepository {
  static const String _key = 'tmo_orders_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .where((o) => o.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<List<OrderModel>> _getAllOrders() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<OrderModel> orders) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  @override
  Future<OrderModel> saveOrder(OrderModel order) async {
    final all = await _getAllOrders();
    // Prevent exact duplicate platformOrderId for same user+platform
    final dup = all.any((o) =>
        o.id != order.id &&
        o.userId == order.userId &&
        o.platformName == order.platformName &&
        o.platformOrderId == order.platformOrderId);
    if (dup) {
      throw Exception(
          'An order with this Platform Order ID already exists for ${order.platformName}.');
    }
    all.add(order);
    await _saveAll(all);
    return order;
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    final all = await _getAllOrders();
    final idx = all.indexWhere((o) => o.id == order.id);
    if (idx == -1) throw Exception('Order not found: ${order.id}');
    all[idx] = order;
    await _saveAll(all);
    return order;
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    final all = await _getAllOrders();
    all.removeWhere((o) => o.id == orderId);
    await _saveAll(all);
  }

  @override
  Future<void> deleteAllOrders(String userId) async {
    final all = await _getAllOrders();
    all.removeWhere((o) => o.userId == userId);
    await _saveAll(all);
  }
}
