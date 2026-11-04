import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import '../services/demo_data.dart';

enum OrdersLoadState { idle, loading, loaded, error }

class OrdersProvider extends ChangeNotifier {
  final OrderRepository _repo;

  OrdersProvider(this._repo);

  List<OrderModel> _orders = [];
  OrdersLoadState _loadState = OrdersLoadState.idle;
  String? _error;
  bool _showDemoOrders = false;
  int _loadGeneration = 0;

  // Filter state
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _platformFilter = 'all';
  String _sortBy = 'recent'; // 'recent' | 'delivery'

  // ── Getters ──────────────────────────────────────────────────────────────
  OrdersLoadState get loadState => _loadState;
  String? get error => _error;
  bool get isLoading => _loadState == OrdersLoadState.loading;
  bool get showDemoOrders => _showDemoOrders;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get platformFilter => _platformFilter;
  String get sortBy => _sortBy;

  List<OrderModel> get allUserOrders =>
      List.unmodifiable(_orders.where((order) => !order.isDemo));
  List<OrderModel> get demoOrders =>
      List.unmodifiable(_orders.where((order) => order.isDemo));
  bool get hasDemoOrders => _orders.any((order) => order.isDemo);

  List<OrderModel> get filteredOrders {
    final base = _orders
        .where((order) => _showDemoOrders || !order.isDemo)
        .toList();
    var result = base.where(_matchesFilters).toList();
    _applySort(result);
    return result;
  }

  Iterable<OrderModel> get _realOrders =>
      _orders.where((order) => !order.isDemo);

  int get activeCount => _realOrders
      .where((o) => !['delivered', 'cancelled', 'returned'].contains(o.status))
      .length;
  int get deliveredCount =>
      _realOrders.where((o) => o.status == 'delivered').length;
  int get delayedCount =>
      _realOrders.where((o) => o.status == 'delayed').length;
  int get totalCount => _realOrders.length;

  List<OrderModel> get recentOrders {
    final list = [..._realOrders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(5).toList();
  }

  List<OrderModel> get upcomingDeliveries {
    final now = DateTime.now();
    return _realOrders
        .where(
          (o) =>
              o.expectedDeliveryAt != null &&
              o.expectedDeliveryAt!.isAfter(now) &&
              !['delivered', 'cancelled', 'returned'].contains(o.status),
        )
        .toList()
      ..sort((a, b) => a.expectedDeliveryAt!.compareTo(b.expectedDeliveryAt!));
  }

  Map<String, int> get platformCounts {
    final map = <String, int>{};
    for (final o in _realOrders) {
      map[o.platformName] = (map[o.platformName] ?? 0) + 1;
    }
    return map;
  }

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<void> loadOrders(String userId) async {
    final generation = ++_loadGeneration;
    _loadState = OrdersLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final loadedOrders = await _repo.getOrders(userId);
      if (generation != _loadGeneration) return;
      _orders = loadedOrders;
      _loadState = OrdersLoadState.loaded;
    } catch (e) {
      if (generation != _loadGeneration) return;
      _error = e.toString().replaceFirst('Exception: ', '');
      _loadState = OrdersLoadState.error;
    }
    notifyListeners();
  }

  /// Cleanly clears in-memory state on sign out so private orders are not retained
  void clearState() {
    _loadGeneration++;
    _orders = [];
    _loadState = OrdersLoadState.idle;
    _error = null;
    _showDemoOrders = false;
    _searchQuery = '';
    _statusFilter = 'all';
    _platformFilter = 'all';
    _sortBy = 'recent';
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<void> addOrder(OrderModel order) async {
    final saved = await _repo.saveOrder(order);
    _orders.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateOrder(OrderModel order) async {
    final updated = await _repo.updateOrder(order);
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx != -1) _orders[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteOrder(String orderId) async {
    await _repo.deleteOrder(orderId);
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Future<void> addDemoOrders(String userId) async {
    if (userId.trim().isEmpty) {
      throw StateError('A signed-in user is required to add demo orders.');
    }

    final existingIds = _orders
        .where((order) => order.isDemo)
        .map((order) => order.id)
        .toSet();
    try {
      for (final demo in DemoData.generateDemoOrders(userId)) {
        if (existingIds.contains(demo.id)) continue;
        final saved = await _repo.saveOrder(demo);
        _orders.insert(0, saved);
        existingIds.add(saved.id);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteDemoOrders() async {
    final demoIds = _orders
        .where((order) => order.isDemo)
        .map((order) => order.id)
        .toList();
    try {
      for (final id in demoIds) {
        await _repo.deleteOrder(id);
        _orders.removeWhere((order) => order.id == id);
      }
      _showDemoOrders = false;
    } finally {
      notifyListeners();
    }
  }

  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setPlatformFilter(String platform) {
    _platformFilter = platform;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _platformFilter = 'all';
    _sortBy = 'recent';
    notifyListeners();
  }

  void toggleDemoOrders(bool show) {
    _showDemoOrders = show;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  bool _matchesFilters(OrderModel o) {
    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final matches =
          o.productName.toLowerCase().contains(q) ||
          o.platformOrderId.toLowerCase().contains(q) ||
          (o.trackingNumber?.toLowerCase().contains(q) ?? false) ||
          o.platformName.toLowerCase().contains(q);
      if (!matches) return false;
    }
    // Status
    if (_statusFilter != 'all' && o.status != _statusFilter) return false;
    // Platform
    if (_platformFilter != 'all' &&
        o.platformName.toLowerCase() != _platformFilter.toLowerCase()) {
      return false;
    }
    return true;
  }

  void _applySort(List<OrderModel> list) {
    if (_sortBy == 'delivery') {
      list.sort((a, b) {
        if (a.expectedDeliveryAt == null && b.expectedDeliveryAt == null) {
          return 0;
        }
        if (a.expectedDeliveryAt == null) return 1;
        if (b.expectedDeliveryAt == null) return -1;
        return a.expectedDeliveryAt!.compareTo(b.expectedDeliveryAt!);
      });
    } else if (_sortBy == 'oldest') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}
