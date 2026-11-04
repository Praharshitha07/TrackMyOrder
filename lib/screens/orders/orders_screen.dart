import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/order_card.dart';
import '../../core/widgets/skeletons.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../core/constants/app_constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      context.read<OrdersProvider>().setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.midnightNavy,
            title: const Text('My Orders'),
            actions: [
              // Sort
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                color: AppTheme.surface,
                onSelected: orders.setSortBy,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'recent',
                    child: _menuItem(
                      Icons.access_time_outlined,
                      'Newest first',
                      orders.sortBy == 'recent',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest',
                    child: _menuItem(
                      Icons.history_outlined,
                      'Oldest first',
                      orders.sortBy == 'oldest',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delivery',
                    child: _menuItem(
                      Icons.calendar_today_outlined,
                      'Delivery date',
                      orders.sortBy == 'delivery',
                    ),
                  ),
                ],
              ),
              // Clear filters
              if (orders.statusFilter != 'all' ||
                  orders.platformFilter != 'all' ||
                  orders.searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  tooltip: 'Clear filters',
                  onPressed: () {
                    orders.clearFilters();
                    _searchCtrl.clear();
                  },
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  children: [
                    // Search
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search product, order ID, tracking…',
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Platform filter chips
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _platformChip('all', 'All', orders),
                          ...AppConstants.shoppingPlatforms.map(
                            (p) => _platformChip(p, p, orders),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _statusChip('all', 'All', orders),
                    _statusChip('ordered', 'Ordered', orders),
                    _statusChip('in_transit', 'In Transit', orders),
                    _statusChip('out_for_delivery', 'Out for Delivery', orders),
                    _statusChip('delivered', 'Delivered', orders),
                    _statusChip('delayed', 'Delayed', orders),
                    _statusChip('cancelled', 'Cancelled', orders),
                  ],
                ),
              ),
            ),
          ),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${orders.filteredOrders.length} order${orders.filteredOrders.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Order list
          if (orders.isLoading)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const OrderCardSkeleton(),
                  childCount: 5,
                ),
              ),
            )
          else if (orders.loadState == OrdersLoadState.error)
            SliverFillRemaining(
              child: ErrorState(
                message:
                    orders.error ??
                    'Could not load your orders from Firestore.',
                onRetry: () => context.read<OrdersProvider>().loadOrders(
                  context.read<AuthProvider>().effectiveUserId,
                ),
              ),
            )
          else if (orders.filteredOrders.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off_outlined,
                title: 'No orders found',
                subtitle: orders.searchQuery.isNotEmpty
                    ? 'No results for "${orders.searchQuery}".'
                    : 'No orders match the selected filters.',
                actionLabel: 'Add Order',
                onAction: () => context.push('/add-order'),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                8,
                isWide ? 24 : 16,
                80,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final o = orders.filteredOrders[i];
                  return OrderCard(
                    order: o,
                    onTap: () => context.push('/order/${o.id}'),
                  );
                }, childCount: orders.filteredOrders.length),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-order'),
        tooltip: 'Add Order',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _platformChip(String value, String label, OrdersProvider orders) {
    final selected = orders.platformFilter.toLowerCase() == value.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => orders.setPlatformFilter(value),
        showCheckmark: false,
        side: BorderSide(
          color: selected
              ? AppTheme.electricLime.withValues(alpha: 0.4)
              : AppTheme.cardBorder,
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, OrdersProvider orders) {
    final selected = orders.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => orders.setStatusFilter(value),
        showCheckmark: false,
        side: BorderSide(
          color: selected
              ? AppTheme.electricLime.withValues(alpha: 0.4)
              : AppTheme.cardBorder,
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, bool selected) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: selected ? AppTheme.electricLime : AppTheme.textSecondary,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.electricLime : AppTheme.cloudWhite,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
