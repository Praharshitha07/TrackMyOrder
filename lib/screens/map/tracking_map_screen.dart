import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../models/order_model.dart';
import '../../models/tracking_event_model.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/simulated_tracking_data.dart';
import '../order_details/widgets/tracking_timeline.dart';

class TrackingMapScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingMapScreen({super.key, required this.order});

  List<TrackingEvent> get _genuineEventsWithCoords =>
      order.trackingEvents.where((event) {
        final latitude = event.latitude;
        final longitude = event.longitude;
        return event.source != 'demo' &&
            event.source != 'simulation' &&
            latitude != null &&
            longitude != null &&
            latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180;
      }).toList()..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mapHeight = (size.height * 0.42).clamp(240.0, 440.0);
    final events = _genuineEventsWithCoords;
    final isSimulated = order.demoTrackingEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track on Map'),
            Text(
              '${order.productName} · '
              '${isSimulated ? 'Simulated tracking' : 'Genuine tracking'}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: isSimulated
                ? const _MapView(isSimulated: true)
                : events.isNotEmpty
                ? _MapView(events: events)
                : const _MapUnavailable(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBar(order: order),
                  const SizedBox(height: 20),
                  Text(
                    'Shipment Events',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (isSimulated)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SimulationLabel(
                        text: 'SIMULATED TRACKING — FOR DEMONSTRATION ONLY',
                      ),
                    ),
                  if (order.isDemo)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SimulationLabel(text: 'DEMO DATA'),
                    ),
                  TrackingTimeline(
                    events: isSimulated
                        ? SimulatedTrackingData.eventsFor(order)
                        : order.trackingEvents
                              .where(
                                (event) =>
                                    event.source != 'demo' &&
                                    event.source != 'simulation',
                              )
                              .toList(),
                    currentStatus: isSimulated ? null : order.status,
                    isDemo: order.isDemo,
                    isSimulated: isSimulated,
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

class _MapView extends StatelessWidget {
  final List<TrackingEvent> events;
  final bool isSimulated;

  const _MapView({this.events = const [], this.isSimulated = false});

  static const _sampleRoute = [
    LatLng(19.0760, 72.8777),
    LatLng(18.9780, 73.0830),
    LatLng(18.8500, 73.3000),
    LatLng(18.6800, 73.5200),
    LatLng(18.5204, 73.8567),
  ];

  @override
  Widget build(BuildContext context) {
    final points = isSimulated
        ? _sampleRoute
        : events
              .map((event) => LatLng(event.latitude!, event.longitude!))
              .toList();
    final center = points[points.length ~/ 2];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 7,
            initialCameraFit: CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(44),
              maxZoom: isSimulated ? 9 : 15,
            ),
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
                    strokeWidth: 4,
                    color: AppTheme.terracotta,
                  ),
                ],
              ),
            if (isSimulated)
              MarkerLayer(
                markers: [
                  _marker(
                    _sampleRoute.first,
                    Icons.trip_origin,
                    AppTheme.primaryBrown,
                    'Sample origin · Mumbai',
                  ),
                  _marker(
                    _sampleRoute.last,
                    Icons.location_on,
                    AppTheme.success,
                    'Sample destination · Pune',
                  ),
                  _marker(
                    _sampleRoute[2],
                    Icons.local_shipping,
                    AppTheme.terracotta,
                    'Simulated parcel position',
                    size: 44,
                  ),
                ],
              )
            else
              MarkerLayer(
                markers: [
                  for (final event in events)
                    _marker(
                      LatLng(event.latitude!, event.longitude!),
                      Icons.location_on,
                      AppTheme.terracotta,
                      event.locationName ?? 'Tracking event location',
                    ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (isSimulated)
          const Positioned(
            top: 12,
            left: 12,
            child: _SimulationLabel(
              text: 'SIMULATED ROUTE — NOT A LIVE COURIER LOCATION',
            ),
          ),
        if (isSimulated)
          const Positioned(left: 12, bottom: 12, child: _RouteLegend()),
      ],
    );
  }

  Marker _marker(
    LatLng point,
    IconData icon,
    Color color,
    String tooltip, {
    double size = 34,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SAMPLE DELIVERY ROUTE',
            style: TextStyle(
              color: AppTheme.primaryBrown,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Mumbai, Maharashtra  →  Pune, Maharashtra',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
          ),
          SizedBox(height: 3),
          Text(
            'Sample parcel marker · not live',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SimulationLabel extends StatelessWidget {
  final String text;

  const _SimulationLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.terracotta),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryBrown,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching_outlined,
              size: 40,
              color: AppTheme.secondaryText,
            ),
            SizedBox(height: 14),
            Text(
              'Live map tracking is not available for this order yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryBrown,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'A map will appear when genuine tracking coordinates are provided.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
            ),
          ],
        ),
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
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  order.demoTrackingEnabled
                      ? 'SIMULATED TRACKING'
                      : 'GENUINE TRACKING',
                  style: const TextStyle(
                    color: AppTheme.terracotta,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                if (order.trackingNumber != null)
                  Text(
                    'Tracking: ${order.trackingNumber}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: order.status, compact: true),
              if (order.expectedDeliveryAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  AppDateUtils.formatShort(order.expectedDeliveryAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
