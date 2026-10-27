import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../models/order_model.dart';
import '../../models/tracking_event_model.dart';
import '../order_details/widgets/tracking_timeline.dart';

class TrackingMapScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingMapScreen({super.key, required this.order});

  List<TrackingEvent> get _eventsWithCoords =>
      order.trackingEvents.where((e) => e.latitude != null && e.longitude != null).toList();

  bool get _hasMapData => _eventsWithCoords.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track on Map'),
            Text(
              order.productName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Map section ───────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: _hasMapData ? _MapView(events: _eventsWithCoords) : _MapUnavailable(order: order),
          ),

          // ── Timeline ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info bar
                  _InfoBar(order: order),
                  const SizedBox(height: 20),
                  Text('Shipment Events',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  TrackingTimeline(
                    events: order.trackingEvents,
                    currentStatus: order.status,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real OpenStreetMap view (no API key required).
class _MapView extends StatelessWidget {
  final List<TrackingEvent> events;

  const _MapView({required this.events});

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final points =
        sorted.map((e) => LatLng(e.latitude!, e.longitude!)).toList();
    final center = points.length == 1
        ? points.first
        : LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length,
          );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: points.length == 1 ? 12.0 : 6.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.trackmyorder',
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 3,
                color: AppTheme.electricLime.withValues(alpha: 0.7),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < sorted.length; i++)
              Marker(
                point: LatLng(sorted[i].latitude!, sorted[i].longitude!),
                width: 40,
                height: 40,
                child: _MapMarker(
                  event: sorted[i],
                  isLatest: i == sorted.length - 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final TrackingEvent event;
  final bool isLatest;

  const _MapMarker({required this.event, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(event.status);
    return Tooltip(
      message: '${AppTheme.statusLabel(event.status)}\n${event.locationName ?? ''}\n${AppDateUtils.formatDateTime(event.occurredAt)}',
      child: Icon(
        isLatest ? Icons.local_shipping : Icons.circle,
        color: isLatest ? AppTheme.electricLime : color.withValues(alpha: 0.7),
        size: isLatest ? 32 : 18,
      ),
    );
  }
}

/// Honest map-unavailable state when no GPS coordinates exist.
class _MapUnavailable extends StatelessWidget {
  final OrderModel order;

  const _MapUnavailable({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.electricLime.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.electricLime.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.map_outlined,
                size: 48, color: AppTheme.electricLime),
          ),
          const SizedBox(height: 20),
          const Text(
            'Map Unavailable',
            style: TextStyle(
              color: AppTheme.cloudWhite,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No verified GPS coordinates are available for this shipment.\n\nReal-time location tracking requires authorized courier API integration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.electricLime.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.electricLime.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.electricLime),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The tracking timeline below shows verified shipment events.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.electricLime.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  final OrderModel order;
  const _InfoBar({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (order.trackingNumber != null)
                  Text('Tracking: ${order.trackingNumber}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'monospace')),
              ],
            ),
          ),
          if (order.expectedDeliveryAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppDateUtils.relativeLabel(order.expectedDeliveryAt),
                  style: const TextStyle(
                    color: AppTheme.electricLime,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AppDateUtils.formatShort(order.expectedDeliveryAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
