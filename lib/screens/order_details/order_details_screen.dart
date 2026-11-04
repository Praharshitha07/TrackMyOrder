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
import '../../services/simulated_tracking_data.dart';
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
  bool _isSavingDemoTracking = false;
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _editDetails() async {
    await context.push('/add-order', extra: {'order': _currentOrder});
    if (!mounted) return;
    final updated = context.read<OrdersProvider>().getOrderById(
      _currentOrder.id,
    );
    if (updated != null) {
      setState(() => _currentOrder = updated);
    }
  }

  Future<void> _setDemoTracking(bool enabled) async {
    setState(() => _isSavingDemoTracking = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = _currentOrder.copyWith(
        demoTrackingEnabled: enabled,
        updatedAt: DateTime.now(),
      );
      await context.read<OrdersProvider>().updateOrder(updated);
      if (mounted) {
        setState(() => _currentOrder = updated);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Demo tracking enabled for this order.'
                  : 'Demo tracking disabled for this order.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Could not update Demo Tracking: '
              '${error.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDemoTracking = false);
    }
  }

  Future<void> _refreshTracking() async {
    if (_currentOrder.isDemo) return;
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
                    result.isConfigured
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: result.isConfigured
                        ? AppTheme.error
                        : AppTheme.electricLime,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.isConfigured
                        ? 'Tracking Error'
                        : 'Carrier Integration Status',
                  ),
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
            expectedDeliveryAt:
                result.estimatedDeliveryAt ?? _currentOrder.expectedDeliveryAt,
            lastSyncedAt: result.lastCheckedAt,
            trackingEvents: [
              ...result.events,
              ..._currentOrder.trackingEvents.where(
                (e) => !result.events.any((re) => re.id == e.id),
              ),
            ],
          );
          await ordersProvider.updateOrder(updated);
          if (mounted) {
            setState(() => _currentOrder = updated);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Shipment tracking details refreshed.'),
              ),
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
          'Delete "${_currentOrder.productName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
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
          if (!_currentOrder.isDemo)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.electricLime,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh Tracking',
              onPressed: _isRefreshing ? null : _refreshTracking,
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
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product card ──────────────────────────────────────
                Text('Order Summary', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
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
                        platformColor: platformColor,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  platformIcon,
                                  size: 14,
                                  color: platformColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _currentOrder.platformName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: platformColor,
                                  ),
                                ),
                                if (_currentOrder.isDemo) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.electricLime.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Demo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.electricLime.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentOrder.productName,
                              style: theme.textTheme.headlineSmall,
                            ),
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.cardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.category_outlined,
                                          size: 12,
                                          color: AppTheme.electricLime,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentOrder.category!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.cloudWhite,
                                            fontWeight: FontWeight.w500,
                                          ),
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

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _editDetails,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Details'),
                  ),
                ),
                const SizedBox(height: 16),

                _DemoTrackingCard(
                  enabled: _currentOrder.demoTrackingEnabled,
                  isSaving: _isSavingDemoTracking,
                  onChanged: _setDemoTracking,
                ),
                const SizedBox(height: 16),

                // ── Delivery Reminder Card ────────────────────────────
                if (!_currentOrder.isDemo) ...[
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
                            content: Text(
                              enabled
                                  ? 'Delivery reminder scheduled.'
                                  : 'Delivery reminder disabled.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

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
                    Text(
                      'Shipment Timeline',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (_currentOrder.lastSyncedAt != null)
                      Text(
                        'Synced: ${AppDateUtils.formatTime(_currentOrder.lastSyncedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
                if (_currentOrder.demoTrackingEnabled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.terracotta.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: AppTheme.terracotta,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SIMULATED TRACKING — FOR DEMONSTRATION ONLY',
                            style: TextStyle(
                              color: AppTheme.primaryBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_currentOrder.isDemo) ...[
                  const _DemoDataLabel(),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 14),
                TrackingTimeline(
                  events: _currentOrder.demoTrackingEnabled
                      ? SimulatedTrackingData.eventsFor(_currentOrder)
                      : _currentOrder.trackingEvents
                            .where(
                              (event) =>
                                  event.source != 'demo' &&
                                  event.source != 'simulation',
                            )
                            .toList(),
                  currentStatus: _currentOrder.demoTrackingEnabled
                      ? null
                      : _currentOrder.status,
                  isDemo: _currentOrder.isDemo,
                  isSimulated: _currentOrder.demoTrackingEnabled,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/map/${_currentOrder.id}'),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Track on Map'),
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _row(
            context,
            'Shopping Platform',
            order.platformName,
            Icons.store_outlined,
          ),
          _row(
            context,
            'Platform Order ID',
            order.platformOrderId,
            Icons.receipt_long_outlined,
          ),
          if (order.category != null)
            _row(context, 'Category', order.category!, Icons.category_outlined),
          _row(
            context,
            'Price',
            CurrencyUtils.format(order.price, order.currency) +
                (order.quantity > 1 ? ' × ${order.quantity}' : ''),
            Icons.payments_outlined,
          ),
          _row(
            context,
            'Ordered On',
            AppDateUtils.formatShort(order.orderedAt),
            Icons.calendar_today_outlined,
          ),
          if (order.expectedDeliveryAt != null)
            _row(
              context,
              'Expected Delivery',
              '${AppDateUtils.formatShort(order.expectedDeliveryAt)} (${AppDateUtils.relativeLabel(order.expectedDeliveryAt)})',
              Icons.event_outlined,
            ),
          if (order.deliveredAt != null)
            _row(
              context,
              'Delivered On',
              AppDateUtils.formatShort(order.deliveredAt),
              Icons.done_all,
            ),

          const Divider(height: 24),
          Text(
            'Courier and Tracking Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (order.courierName != null)
            _row(
              context,
              'Courier Partner',
              order.courierName!,
              Icons.local_shipping_outlined,
            ),
          if (order.trackingNumber != null)
            _row(
              context,
              'Courier Tracking ID',
              order.trackingNumber!,
              Icons.qr_code_outlined,
            ),
          if (order.courierContact != null)
            _row(
              context,
              'Courier Contact',
              order.courierContact!,
              Icons.phone_outlined,
            ),
          if (order.trackingUrl != null)
            _row(
              context,
              'Tracking URL',
              order.trackingUrl!,
              Icons.link_outlined,
            ),
          if (order.pickupLocation != null)
            _row(
              context,
              'Pickup Location',
              order.pickupLocation!,
              Icons.inventory_2_outlined,
            ),
          if (order.deliveryLocation != null)
            _row(
              context,
              'Delivery Destination',
              order.deliveryLocation!,
              Icons.location_on_outlined,
            ),
          if (order.courierName == null &&
              order.trackingNumber == null &&
              order.courierContact == null &&
              order.trackingUrl == null &&
              order.pickupLocation == null &&
              order.deliveryLocation == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Courier details are optional and can be added later.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          if (order.additionalNotes != null)
            _row(
              context,
              'Additional Notes',
              order.additionalNotes!,
              Icons.notes_outlined,
            ),
          if (order.trackingSource != null)
            _row(
              context,
              'Tracking Source',
              order.trackingSource!,
              Icons.source_outlined,
            ),
          if (order.lastSyncedAt != null)
            _row(
              context,
              'Last Updated',
              AppDateUtils.formatDateTime(order.lastSyncedAt),
              Icons.sync_outlined,
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.cloudWhite),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTrackingCard extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  const _DemoTrackingCard({
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(
            Icons.science_outlined,
            color: AppTheme.terracotta,
          ),
          title: const Text(
            'Demo Tracking',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Display a simulated tracking timeline and sample delivery route for demonstration purposes.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          value: enabled,
          onChanged: isSaving ? null : onChanged,
        ),
      ),
    );
  }
}

class _DemoDataLabel extends StatelessWidget {
  const _DemoDataLabel();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.terracotta.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.terracotta),
        ),
        child: const Text(
          'DEMO DATA',
          style: TextStyle(
            color: AppTheme.primaryBrown,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        if (!order.isDemo)
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
                child: Text(
                  'Delivery Alert & Reminder',
                  style: theme.textTheme.titleMedium,
                ),
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
