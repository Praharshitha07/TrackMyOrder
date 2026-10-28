import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import 'order_repository.dart';
import 'local_order_repository.dart';
import 'firestore_order_repository.dart';

class HybridOrderRepository implements OrderRepository {
  final LocalOrderRepository _local;
  final FirestoreOrderRepository _cloud;

  HybridOrderRepository(this._local, this._cloud);

  bool get _useLocal => FirebaseAuth.instance.currentUser == null;

  @override
  Future<List<OrderModel>> getOrders(String userId) {
    if (_useLocal) {
      return _local.getOrders(userId);
    }

    return _cloud.getOrders(userId);
  }

  @override
  Future<OrderModel> saveOrder(OrderModel order) {
    if (_useLocal) {
      return _local.saveOrder(order);
    }

    return _cloud.saveOrder(order);
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) {
    if (_useLocal) {
      return _local.updateOrder(order);
    }

    return _cloud.updateOrder(order);
  }

  @override
  Future<void> deleteOrder(String orderId) {
    if (_useLocal) {
      return _local.deleteOrder(orderId);
    }

    return _cloud.deleteOrder(orderId);
  }

  @override
  Future<void> deleteAllOrders(String userId) {
    if (_useLocal) {
      return _local.deleteAllOrders(userId);
    }

    return _cloud.deleteAllOrders(userId);
  }
}
