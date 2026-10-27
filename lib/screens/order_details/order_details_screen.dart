import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/format_utils.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../services/tracking/unified_tracking_manager.dart';
import '../../services/notifications/notification_service.dart';
import 'widgets/tracking_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final UnifiedTrackingManager _trackingManager = UnifiedTrackingManager();
  bool _isRefreshing = false;
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _refreshTracking() async {
    setState(() => _isRefreshing = true);
    try {
      final result = await _trackingManager.refreshTracking(
        courierName: _currentOrder.courierName,
        trackingNumber: _currentOrder.trackingNumber,
        currentStatus: _currentOrder.status,
        orderId: _currentOrder.id,
      );

      if (mounted) {
        if (result.hasError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    result.isConfigured ? Icons.error_outline : Icons.info_outline,
                    color: result.isConfigured
                        ? const Color(0xFFF87171)
                        : AppTheme.electricLime,
                  ),
                  const SizedBox(width: 8),
                  Text(result.isConfigured ? 'Tracking Error' : 'Carrier Integration Status'),
                ],
              ),
              content: Text(
                result.errorMessage!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
                if (_currentOrder.trackingUrl != null &&
                    _currentOrder.trackingUrl!.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _launchUrl(context, _currentOrder.trackingUrl);
                    },
                    child: const Text('Open Tracking Webpage'),
                  ),
              ],
            ),
          );
        } else if (result.isLive) {
          final ordersProvider = context.read<OrdersProvider>();
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final updated = _currentOrder.copyWith(
            status: result.normalizedStatus,
            expectedDeliveryAt: result.estimatedDeliveryAt ?? _currentOrder.expectedDeliveryAt,
            lastSyncedAt: result.lastCheckedAt,
            trackingEvents: [
              ...result.events,
              ..._currentOrder.trackingEvents.where((e) => !result.events.any((re) => re.id == e.id)),
            ],
          );
          await ordersProvider.updateOrder(updated);
          if (mounted) {
            setState(() => _currentOrder = updated);
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Shipment tracking details refreshed.')),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this URL.')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
            'Delete "${_currentOrder.productName}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF87171)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<OrdersProvider>().deleteOrder(_currentOrder.id);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformColor = AppTheme.platformColor(_currentOrder.platformName);
    final platformIcon = AppTheme.platformIcon(_currentOrder.platformName);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.electricLime),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Tracking',
            onPressed: _isRefreshing ? null : _refreshTracking,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push(
              '/add-order',
              extra: {'order': _currentOrder},
            ),
          ),
          if (!_currentOrder.isDemo)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _delete(context),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product card ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      _ProductImage(
                          imageUrl: _currentOrder.productImageUrl,
                          platformIcon: platformIcon,
                          platformColor: platformColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(platformIcon,
                                    size: 14, color: platformColor),
                                const SizedBox(width: 5),
                                Text(_currentOrder.platformName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: platformColor,
                                    )),
                                if (_currentOrder.isDemo) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.electricLime
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Demo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.electricLime
                                            .withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(_currentOrder.productName,
                                style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(status: _currentOrder.status),
                                if (_currentOrder.category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.category_outlined,
                                            size: 12,
                                            color: AppTheme.electricLime),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentOrder.category!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.cloudWhite,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Info grid ─────────────────────────────────────────
                _InfoGrid(order: _currentOrder),
                const SizedBox(height: 16),

                // ── Delivery Reminder Card ────────────────────────────
                _DeliveryReminderCard(
                  order: _currentOrder,
                  onToggleReminder: (enabled) async {
                    final ordersProvider = context.read<OrdersProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final updated = _currentOrder.copyWith(
                      reminderEnabled: enabled,
                    );
                    await ordersProvider.updateOrder(updated);
                    if (mounted) {
                      setState(() => _currentOrder = updated);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(enabled
                              ? 'Delivery reminder scheduled.'
                              : 'Delivery reminder disabled.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── Action buttons ────────────────────────────────────
                _ActionButtons(
                  order: _currentOrder,
                  launchUrl: _launchUrl,
                  onRefresh: _refreshTracking,
                  isRefreshing: _isRefreshing,
                ),
                const SizedBox(height: 24),

                // ── Tracking timeline ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tracking Timeline',
                        style: theme.textTheme.headlineSmall),
                    if (_currentOrder.lastSyncedAt != null)
                      Text(
                        'Synced: ${AppDateUtils.formatTime(_currentOrder.lastSyncedAt)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TrackingTimeline(
                  events: _currentOrder.trackingEvents,
                  currentStatus: _currentOrder.status,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final IconData platformIcon;
  final Color platformColor;

  const _ProductImage({
    required this.imageUrl,
    required this.platformIcon,
    required this.platformColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (context, url) => _fallback(),
          errorWidget: (context, url, error) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: platformColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: platformColor.withValues(alpha: 0.3)),
        ),
        child: Icon(platformIcon, size: 30, color: platformColor),
      );
}

class _InfoGrid extends StatelessWidget {
  final OrderModel order;
  const _InfoGrid({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          _row(context, 'Platform Order ID', order.platformOrderId,
              Icons.receipt_long_outlined),
          if (order.category != null)
            _row(context, 'Category', order.category!, Icons.category_outlined),
          if (order.trackingNumber != null)
            _row(context, 'Tracking Number', order.trackingNumber!,
                Icons.qr_code_outlined),
          if (order.courierName != null)
            _row(context, 'Courier', order.courierName!,
                Icons.local_shipping_outlined),
          _row(
              context,
              'Price',
              CurrencyUtils.format(order.price, order.currency) +
                  (order.quantity > 1 ? ' × ${order.quantity}' : ''),
              Icons.payments_outlined),
          _row(context, 'Ordered On',
              AppDateUtils.formatShort(order.orderedAt), Icons.calendar_today_outlined),
          if (order.expectedDeliveryAt != null)
            _row(
                context,
                'Expected Delivery',
                '${AppDateUtils.formatShort(order.expectedDeliveryAt)} (${AppDateUtils.relativeLabel(order.expectedDeliveryAt)})',
                Icons.event_outlined),
          if (order.deliveredAt != null)
            _row(context, 'Delivered On',
                AppDateUtils.formatShort(order.deliveredAt), Icons.done_all),
          if (order.trackingSource != null)
            _row(context, 'Tracking Source', order.trackingSource!,
                Icons.source_outlined),
          if (order.lastSyncedAt != null)
            _row(context, 'Last Updated',
                AppDateUtils.formatDateTime(order.lastSyncedAt),
                Icons.sync_outlined),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    )),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.cloudWhite,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final OrderModel order;
  final Future<void> Function(BuildContext, String?) launchUrl;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _ActionButtons({
    required this.order,
    required this.launchUrl,
    required this.onRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Refresh tracking button
        OutlinedButton.icon(
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 16),
          label: Text(isRefreshing ? 'Checking...' : 'Refresh Status'),
        ),
        // Track on Map
        FilledButton.icon(
          onPressed: () => context.push('/map/${order.id}'),
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Track on Map'),
        ),
        // Courier tracking URL
        if (order.trackingUrl != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(context, order.trackingUrl),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Courier Tracking'),
          ),
        // Original order
        if (order.orderUrl != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(context, order.orderUrl),
            icon: const Icon(Icons.shopping_bag_outlined, size: 16),
            label: Text('View on ${order.platformName}'),
          ),
      ],
    );
  }
}

class _DeliveryReminderCard extends StatelessWidget {
  final OrderModel order;
  final ValueChanged<bool> onToggleReminder;

  const _DeliveryReminderCard({
    required this.order,
    required this.onToggleReminder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTerminal = order.isDelivered || order.isCancelled;
    final scheduledDate = NotificationService.calculateScheduledTime(order);
    final isDueSoon = NotificationService.isReminderDueSoon(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.reminderEnabled && !isTerminal
              ? AppTheme.electricLime.withValues(alpha: 0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                order.reminderEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 20,
                color: order.reminderEnabled && !isTerminal
                    ? AppTheme.electricLime
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Delivery Alert & Reminder',
                    style: theme.textTheme.titleMedium),
              ),
              Switch(
                value: order.reminderEnabled && !isTerminal,
                activeThumbColor: AppTheme.electricLime,
                onChanged: order.expectedDeliveryAt == null || isTerminal
                    ? null
                    : onToggleReminder,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isTerminal)
            Text(
              order.isDelivered
                  ? 'This order has been delivered. Reminders are completed.'
                  : 'This order was cancelled. Reminders are inactive.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            )
          else if (order.expectedDeliveryAt == null)
            const Text(
              'No expected delivery date specified. Edit this order to set a delivery date and enable reminders.',
              style: TextStyle(fontSize: 12, color: AppTheme.warningAmber),
            )
          else if (order.reminderEnabled) ...[
            Text(
              scheduledDate != null
                  ? 'Scheduled for: ${AppDateUtils.formatDateTime(scheduledDate)}'
                  : 'Reminder preference: ${order.reminderPreference == 'day_before' ? '1 day before (9 AM)' : 'Morning of delivery (9 AM)'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.cloudWhite,
              ),
            ),
            if (isDueSoon)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.electricLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Delivery alert is upcoming within the next 24 hours!',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.electricLime,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ] else
            const Text(
              'Turn on delivery reminders to receive a notification before or on the morning of scheduled delivery.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }
}
