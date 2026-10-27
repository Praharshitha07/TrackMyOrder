import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../core/utils/format_utils.dart';
import 'status_badge.dart';

/// Premium order card used across the app.
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformColor = AppTheme.platformColor(order.platformName);
    final platformIcon = AppTheme.platformIcon(order.platformName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo banner
            if (order.isDemo)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      AppTheme.electricLime.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 11,
                        color: AppTheme.electricLime
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Demo order',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.electricLime
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: image + info + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image / platform icon
                      _ProductThumbnail(
                        imageUrl: order.productImageUrl,
                        platformIcon: platformIcon,
                        platformColor: platformColor,
                      ),
                      const SizedBox(width: 12),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Platform chip
                            Row(
                              children: [
                                Icon(platformIcon,
                                    size: 13, color: platformColor),
                                const SizedBox(width: 4),
                                Text(
                                  order.platformName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: platformColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.productName,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.platformOrderId,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: order.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Footer row
                  Row(
                    children: [
                      // Price
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyUtils.format(
                                order.price, order.currency),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.cloudWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Delivery date
                      if (order.expectedDeliveryAt != null ||
                          order.deliveredAt != null)
                        Row(
                          children: [
                            Icon(
                              order.status == 'delivered'
                                  ? Icons.done_all
                                  : Icons.schedule_outlined,
                              size: 13,
                              color: order.status == 'delivered'
                                  ? AppTheme.statusDelivered
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.status == 'delivered' &&
                                      order.deliveredAt != null
                                  ? 'Delivered ${AppDateUtils.formatShort(order.deliveredAt)}'
                                  : 'Expected ${AppDateUtils.relativeLabel(order.expectedDeliveryAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: order.status == 'delivered'
                                    ? AppTheme.statusDelivered
                                    : order.status == 'delayed'
                                        ? AppTheme.statusDelayed
                                        : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final IconData platformIcon;
  final Color platformColor;

  const _ProductThumbnail({
    required this.imageUrl,
    required this.platformIcon,
    required this.platformColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (context, url) => _iconFallback(),
          errorWidget: (context, url, error) => _iconFallback(),
        ),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: platformColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: platformColor.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(platformIcon, size: 24, color: platformColor),
    );
  }
}
