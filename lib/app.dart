import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'repositories/local_order_repository.dart';
import 'repositories/local_auth_repository.dart';
import 'screens/shell/app_router.dart';

class TrackMyOrderApp extends StatefulWidget {
  const TrackMyOrderApp({super.key});

  @override
  State<TrackMyOrderApp> createState() => _TrackMyOrderAppState();
}

class _TrackMyOrderAppState extends State<TrackMyOrderApp> {
  late final AuthProvider _authProvider;
  late final OrdersProvider _ordersProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(LocalAuthRepository());
    _ordersProvider = OrdersProvider(LocalOrderRepository());
    // Initialize auth state
    _authProvider.initialize().then((_) {
      _ordersProvider.loadOrders(_authProvider.effectiveUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _ordersProvider),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Track My Order',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
