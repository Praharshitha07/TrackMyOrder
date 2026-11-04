import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'repositories/firestore_order_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'screens/shell/app_router.dart';

class TrackMyOrderApp extends StatefulWidget {
  const TrackMyOrderApp({super.key});

  @override
  State<TrackMyOrderApp> createState() => _TrackMyOrderAppState();
}

class _TrackMyOrderAppState extends State<TrackMyOrderApp> {
  late final AuthProvider _authProvider;
  late final OrdersProvider _ordersProvider;
  late final router = buildRouter(_authProvider);
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(FirebaseAuthRepository());
    _ordersProvider = OrdersProvider(FirestoreOrderRepository());
    _authProvider.addListener(_syncOrdersWithAuth);
    unawaited(_authProvider.initialize());
  }

  void _syncOrdersWithAuth() {
    if (_authProvider.isAuthenticated) {
      final userId = _authProvider.effectiveUserId;
      if (_loadedUserId != userId) {
        _loadedUserId = userId;
        unawaited(_ordersProvider.loadOrders(userId));
      }
      return;
    }

    _loadedUserId = null;
    if (_ordersProvider.loadState != OrdersLoadState.idle) {
      _ordersProvider.clearState();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_syncOrdersWithAuth);
    router.dispose();
    _authProvider.dispose();
    _ordersProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _ordersProvider),
      ],
      child: MaterialApp.router(
        title: 'Track My Order',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
