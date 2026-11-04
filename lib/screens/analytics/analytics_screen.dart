import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/analytics/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final orders = ordersProvider.allUserOrders;
    final data = _analyticsService.calculate(orders);
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Data',
            onPressed: () => context.push('/backup-export'),
          ),
        ],
      ),
      body: ordersProvider.loadState == OrdersLoadState.error
          ? ErrorState(
              message:
                  ordersProvider.error ??
                  'Could not load analytics from Firestore.',
              onRetry: () => ordersProvider.loadOrders(
                context.read<AuthProvider>().effectiveUserId,
              ),
            )
          : data.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.electricLime.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_outlined,
                        size: 40,
                        color: AppTheme.electricLime,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Spending Data Yet',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your orders to view automated spending insights, category breakdowns, and monthly expenditure charts.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push('/add-order'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Your First Order'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calculation explanation banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppTheme.electricLime,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Calculated from saved orders. Cancelled orders are excluded from total spending.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Metrics Overview Grid
                      GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.35,
                        children: [
                          _MetricCard(
                            label: 'Total Spending',
                            value: CurrencyUtils.format(
                              data.totalSpending,
                              'INR',
                            ),
                            icon: Icons.payments_outlined,
                            color: AppTheme.electricLime,
                          ),
                          _MetricCard(
                            label: 'Avg Order Value',
                            value: CurrencyUtils.format(
                              data.averageOrderValue,
                              'INR',
                            ),
                            icon: Icons.calculate_outlined,
                            color: AppTheme.statusInTransit,
                          ),
                          _MetricCard(
                            label: 'This Month',
                            value: CurrencyUtils.format(
                              data.currentMonthSpending,
                              'INR',
                            ),
                            icon: Icons.calendar_month_outlined,
                            color: AppTheme.statusPacked,
                          ),
                          _MetricCard(
                            label: 'Delivered Purchases',
                            value: '${data.deliveredCount} orders',
                            icon: Icons.done_all,
                            color: AppTheme.statusDelivered,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Spending by Platform
                      Text(
                        'Spending by Platform',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _PlatformSpendingCard(data: data),
                      const SizedBox(height: 28),

                      // Spending by Category
                      Text(
                        'Spending by Category',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _CategorySpendingCard(data: data),
                      const SizedBox(height: 28),

                      // Monthly Expenditure History
                      if (data.monthlySpending.isNotEmpty) ...[
                        Text(
                          'Monthly Expenditure',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _MonthlySpendingCard(months: data.monthlySpending),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformSpendingCard extends StatelessWidget {
  final AnalyticsData data;
  const _PlatformSpendingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sortedPlatforms = data.spendingByPlatform.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: sortedPlatforms.map((entry) {
          final platform = entry.key;
          final amount = entry.value;
          final orderCount = data.ordersByPlatform[platform] ?? 0;
          final pct = data.totalSpending > 0
              ? (amount / data.totalSpending)
              : 0.0;
          final color = AppTheme.platformColor(platform);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          AppTheme.platformIcon(platform),
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          platform,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($orderCount)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyUtils.format(amount, 'INR'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.cloudWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategorySpendingCard extends StatelessWidget {
  final AnalyticsData data;
  const _CategorySpendingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sortedCategories = data.spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: sortedCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final count = data.ordersByCategory[category] ?? 0;
          final pct = data.totalSpending > 0
              ? (amount / data.totalSpending)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 15,
                          color: AppTheme.electricLime,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($count)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyUtils.format(amount, 'INR'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.electricLime,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthlySpendingCard extends StatelessWidget {
  final List<MonthlySpending> months;
  const _MonthlySpendingCard({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxAmount = months
        .map((m) => m.amount)
        .fold<double>(0.0, (prev, elem) => elem > prev ? elem : prev);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: months.map((m) {
          final pct = maxAmount > 0 ? (m.amount / maxAmount) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${CurrencyUtils.format(m.amount, 'INR')} (${m.orderCount} orders)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.electricLime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.statusInTransit,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
