import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/add_order/add_order_screen.dart';
import '../../screens/order_details/order_details_screen.dart';
import '../../screens/map/tracking_map_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/export/backup_export_screen.dart';
import 'app_shell.dart';

/// Global navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth-loading',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authProvider.state == AuthState.unknown) {
        return location == '/auth-loading' ? null : '/auth-loading';
      }

      if (!authProvider.canAccessApp && !isAuthRoute) return '/login';
      if (authProvider.canAccessApp &&
          (isAuthRoute || location == '/auth-loading')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/auth-loading'),
      GoRoute(
        path: '/auth-loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell with bottom nav / rail
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen routes (above shell)
      GoRoute(
        path: '/add-order',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddOrderScreen(existingOrder: extra?['order']);
        },
      ),
      GoRoute(
        path: '/order/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final ordersProvider = Provider.of<OrdersProvider>(
            context,
            listen: false,
          );
          final order = ordersProvider.getOrderById(id);
          if (order == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order not found')),
              body: const Center(child: Text('This order no longer exists.')),
            );
          }
          return OrderDetailsScreen(order: order);
        },
      ),
      GoRoute(
        path: '/map/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final ordersProvider = Provider.of<OrdersProvider>(
            context,
            listen: false,
          );
          final order = ordersProvider.getOrderById(id);
          if (order == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order not found')),
              body: const Center(child: Text('This order no longer exists.')),
            );
          }
          return TrackingMapScreen(order: order);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/backup-export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupExportScreen(),
      ),
    ],
  );
}
