import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/orders_provider.dart';

class PlatformsScreen extends StatelessWidget {
  const PlatformsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final theme = Theme.of(context);
    final counts = orders.platformCounts;
    final total = orders.totalCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Platforms')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shopping Platforms',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a platform to filter your orders.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final platform = AppConstants.shoppingPlatforms[index];
                  final count = counts[platform] ?? 0;
                  final color = AppTheme.platformColor(platform);
                  final icon = AppTheme.platformIcon(platform);
                  final pct = total > 0 ? count / total : 0.0;

                  return _PlatformCard(
                    platform: platform,
                    count: count,
                    color: color,
                    icon: icon,
                    percentage: pct,
                    onTap: () {
                      orders.setPlatformFilter(platform);
                      context.go('/orders');
                    },
                  );
                },
                childCount: AppConstants.shoppingPlatforms.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String platform;
  final int count;
  final Color color;
  final IconData icon;
  final double percentage;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.platform,
    required this.count,
    required this.color,
    required this.icon,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: count > 0
                ? color.withValues(alpha: 0.3)
                : AppTheme.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const Spacer(),
            // Platform name
            Text(
              platform,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: count > 0 ? AppTheme.cloudWhite : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count order${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: count > 0 ? color : AppTheme.textMuted,
                fontWeight: count > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
