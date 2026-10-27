import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/tracking_event_model.dart';

/// Vertical tracking timeline with status icons, timestamps, and locations.
class TrackingTimeline extends StatelessWidget {
  final List<TrackingEvent> events;
  final String? currentStatus;

  const TrackingTimeline({super.key, required this.events, this.currentStatus});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.timeline, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStatus != null
                        ? 'Current status: ${AppTheme.statusLabel(currentStatus!)} (Manually recorded)'
                        : 'No detailed carrier events recorded yet.',
                    style: const TextStyle(
                      color: AppTheme.cloudWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tracking events will appear here once carrier updates are received or synchronized.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show newest first
    final sorted = [...events]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final event = sorted[index];
          final isLast = index == sorted.length - 1;
          final isFirst = index == 0;
          final color = AppTheme.statusColor(event.status);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline line + dot
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      // Top line
                      if (!isFirst)
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: 2,
                            color: AppTheme.divider,
                          ),
                        )
                      else
                        const SizedBox(height: 6),

                      // Status dot
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? color.withValues(alpha: 0.15)
                              : AppTheme.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFirst ? color : AppTheme.cardBorder,
                            width: isFirst ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          AppTheme.statusIcon(event.status),
                          size: 13,
                          color: isFirst ? color : AppTheme.textMuted,
                        ),
                      ),

                      // Bottom line
                      if (!isLast)
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: 2,
                            color: AppTheme.divider,
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Event content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status + verified badge
                        Row(
                          children: [
                            Text(
                              AppTheme.statusLabel(event.status),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isFirst ? color : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (event.isVerified
                                        ? AppTheme.electricLime
                                        : AppTheme.textMuted)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.isVerified
                                    ? 'Carrier Verified'
                                    : (event.source == 'manual'
                                        ? 'Manual Entry'
                                        : 'Demo Event'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: event.isVerified
                                      ? AppTheme.electricLime
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.cloudWhite,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            // Timestamp
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time,
                                    size: 11,
                                    color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  AppDateUtils.formatDateTime(event.occurredAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            // Location
                            if (event.locationName != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place_outlined,
                                      size: 11,
                                      color: AppTheme.textMuted),
                                  const SizedBox(width: 3),
                                  Text(
                                    event.locationName!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
