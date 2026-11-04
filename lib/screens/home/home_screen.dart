import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/order_card.dart';
import '../../core/widgets/skeletons.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrdersProvider>();
    if (orders.loadState == OrdersLoadState.idle ||
        orders.loadState == OrdersLoadState.error) {
      await orders.loadOrders(auth.effectiveUserId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrdersProvider>();
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.electricLime,
        backgroundColor: AppTheme.surface,
        onRefresh: _loadOrders,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.midnightNavy,
              expandedHeight: isWide ? 100 : 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(auth.user?.name),
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Here\'s your order summary.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            // Avatar
                            GestureDetector(
                              onTap: () => context.go('/profile'),
                              child: _Avatar(name: auth.user?.name ?? ''),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (q) {
                      orders.setSearchQuery(q);
                      if (q.isNotEmpty) context.go('/orders');
                    },
                  ),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  Text('Overview', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  // Summary cards
                  if (orders.loadState == OrdersLoadState.error)
                    ErrorState(
                      message:
                          orders.error ??
                          'Could not load your orders from Firestore.',
                      onRetry: _loadOrders,
                    )
                  else if (orders.isLoading)
                    _buildSkeletonSummary(isWide)
                  else
                    _buildSummaryCards(context, orders, isWide),

                  // Quick Action Buttons
                  if (MediaQuery.sizeOf(context).width < 380)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/add-order'),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Order'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/analytics'),
                          icon: const Icon(Icons.insights, size: 18),
                          label: const Text('Analytics'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/add-order'),
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add Order'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/analytics'),
                            icon: const Icon(Icons.insights, size: 18),
                            label: const Text('Analytics'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Recent Orders',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/orders'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status filter chips
                  _StatusFilterRow(orders: orders),
                  const SizedBox(height: 14),

                  // Order list
                  if (orders.isLoading)
                    ...List.generate(3, (_) => const OrderCardSkeleton())
                  else if (orders.loadState == OrdersLoadState.error)
                    const SizedBox.shrink()
                  else if (orders.filteredOrders.isEmpty)
                    EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No orders yet',
                      subtitle:
                          'Tap the + button below to add your first order.',
                      actionLabel: 'Add Order',
                      onAction: () => context.push('/add-order'),
                    )
                  else
                    ...orders.filteredOrders
                        .take(8)
                        .map(
                          (o) => OrderCard(
                            order: o,
                            onTap: () => context.push('/order/${o.id}'),
                          ),
                        ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-order'),
        tooltip: 'Add Order',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSkeletonSummary(bool isWide) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: List.generate(4, (_) => const StatCardSkeleton()),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    OrdersProvider orders,
    bool isWide,
  ) {
    final cards = [
      _StatData(
        Icons.inventory_2_outlined,
        '${orders.totalCount}',
        'Total Orders',
        AppTheme.electricLime,
        () {
          orders.clearFilters();
          context.go('/orders');
        },
      ),
      _StatData(
        Icons.local_shipping_outlined,
        '${orders.activeCount}',
        'In Transit / Active',
        AppTheme.statusInTransit,
        () {
          orders.clearFilters();
          orders.setStatusFilter('in_transit');
          context.go('/orders');
        },
      ),
      _StatData(
        Icons.done_all,
        '${orders.deliveredCount}',
        'Delivered',
        AppTheme.statusDelivered,
        () {
          orders.clearFilters();
          orders.setStatusFilter('delivered');
          context.go('/orders');
        },
      ),
      _StatData(
        Icons.schedule_outlined,
        '${orders.delayedCount}',
        'Delayed',
        AppTheme.statusDelayed,
        () {
          orders.clearFilters();
          orders.setStatusFilter('delayed');
          context.go('/orders');
        },
      ),
    ];
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: cards.map((d) => _SummaryCard(data: d)).toList(),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    if (name != null && name.isNotEmpty) {
      return '$salutation, ${name.split(' ').first}! 👋';
    }
    return '$salutation! 👋';
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join()
        : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.electricLime.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.electricLime.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppTheme.electricLime,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by product, order ID, or tracking number…',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final OrdersProvider orders;
  const _StatusFilterRow({required this.orders});

  static const _filters = [
    ('all', 'All'),
    ('in_transit', 'In Transit'),
    ('out_for_delivery', 'Out for Delivery'),
    ('ordered', 'Ordered'),
    ('delivered', 'Delivered'),
    ('delayed', 'Delayed'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((f) {
          final selected = orders.statusFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: selected,
              onSelected: (_) => orders.setStatusFilter(f.$1),
              showCheckmark: false,
              side: BorderSide(
                color: selected
                    ? AppTheme.electricLime.withValues(alpha: 0.4)
                    : AppTheme.cardBorder,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatData(this.icon, this.value, this.label, this.color, this.onTap);
}

class _SummaryCard extends StatelessWidget {
  final _StatData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, size: 18, color: data.color),
            ),
            const Spacer(),
            Text(
              data.value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: data.color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(data.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
