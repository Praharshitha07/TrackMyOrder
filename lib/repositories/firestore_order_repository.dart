import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import 'order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _orders(String userId) {
    return _firestore.collection('users').doc(userId).collection('orders');
  }

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to access your cloud orders.');
    }

    return user.uid;
  }

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    if (userId != _currentUserId) {
      throw Exception('You can only access your own orders.');
    }

    final snapshot = await _orders(userId).get();

    final orders = snapshot.docs.map((doc) {
      return OrderModel.fromJson(doc.data());
    }).toList();

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  @override
  Future<OrderModel> saveOrder(OrderModel order) async {
    final userId = _currentUserId;

    if (order.userId != userId) {
      throw Exception('Order user does not match the logged-in user.');
    }

    final existing = await _orders(userId)
        .where('platformName', isEqualTo: order.platformName)
        .where('platformOrderId', isEqualTo: order.platformOrderId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'An order with this Platform Order ID already exists '
        'for ${order.platformName}.',
      );
    }

    await _orders(userId).doc(order.id).set(order.toJson());

    return order;
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    final userId = _currentUserId;

    if (order.userId != userId) {
      throw Exception('You can only update your own orders.');
    }

    final document = _orders(userId).doc(order.id);
    final existing = await document.get();

    if (!existing.exists) {
      throw Exception('Order not found: ${order.id}');
    }

    await document.set(order.toJson(), SetOptions(merge: true));

    return order;
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await _orders(_currentUserId).doc(orderId).delete();
  }

  @override
  Future<void> deleteAllOrders(String userId) async {
    if (userId != _currentUserId) {
      throw Exception('You can only delete your own orders.');
    }

    final collection = _orders(userId);
    final snapshot = await collection.get();

    // Firestore batches support up to 500 operations.
    for (var i = 0; i < snapshot.docs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < snapshot.docs.length)
          ? i + 500
          : snapshot.docs.length;

      for (final doc in snapshot.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}
