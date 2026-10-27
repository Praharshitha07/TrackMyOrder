import 'package:shared_preferences/shared_preferences.dart';
import '../../models/order_model.dart';

/// Represents a scheduled or pending delivery reminder.
class DeliveryReminder {
  final OrderModel order;
  final DateTime scheduledTime;

  const DeliveryReminder({
    required this.order,
    required this.scheduledTime,
  });
}

/// Service managing delivery reminder preferences and local scheduling.
///
/// Reminders are evaluated offline-first based on recorded expected delivery dates.
/// Alerts are scheduled for 09:00 AM on the day of delivery or the day prior.
class NotificationService {
  static const String _notificationsEnabledKey = 'tmo_notifications_enabled';
  static const String _defaultTimingKey = 'tmo_default_reminder_timing';

  /// In-memory global switch for instant reactivity across settings & screens
  static bool isRemindersGloballyEnabled = true;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Check whether notifications / reminders are enabled globally
  Future<bool> areNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_notificationsEnabledKey) ?? isRemindersGloballyEnabled;
  }

  /// Update global notification state
  Future<void> setNotificationsEnabled(bool enabled) async {
    isRemindersGloballyEnabled = enabled;
    final prefs = await _prefs;
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Get default reminder timing ('on_day' | 'day_before')
  Future<String> getDefaultReminderTiming() async {
    final prefs = await _prefs;
    return prefs.getString(_defaultTimingKey) ?? 'on_day';
  }

  /// Set default reminder timing
  Future<void> setDefaultReminderTiming(String timing) async {
    final prefs = await _prefs;
    await prefs.setString(_defaultTimingKey, timing);
  }

  /// Determine if an order is eligible for a delivery reminder
  bool isEligibleForReminder({
    required DateTime? expectedDeliveryAt,
    required String status,
    required bool reminderEnabled,
  }) {
    if (!reminderEnabled) return false;
    if (expectedDeliveryAt == null) return false;
    if (['delivered', 'cancelled', 'returned'].contains(status)) return false;

    // Must not be in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deliveryDay = DateTime(
      expectedDeliveryAt.year,
      expectedDeliveryAt.month,
      expectedDeliveryAt.day,
    );

    return !deliveryDay.isBefore(today);
  }

  /// Calculate the scheduled reminder target DateTime
  DateTime? calculateReminderTime({
    required DateTime? expectedDeliveryAt,
    required String preference, // 'on_day' | 'day_before'
  }) {
    if (expectedDeliveryAt == null) return null;

    final targetDate = preference == 'day_before'
        ? expectedDeliveryAt.subtract(const Duration(days: 1))
        : expectedDeliveryAt;

    // Scheduled for 9:00 AM on the reminder day
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      9,
      0,
    );
  }

  // ── Static Helper Methods for Easy Widget & Test Access ────────────────────

  /// Computes the exact 9:00 AM scheduled reminder moment for a given order.
  static DateTime? calculateScheduledTime(OrderModel order) {
    if (order.expectedDeliveryAt == null) return null;

    final baseDate = order.expectedDeliveryAt!;
    final targetDate = order.reminderPreference == 'day_before'
        ? baseDate.subtract(const Duration(days: 1))
        : baseDate;

    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      9,
      0,
    );
  }

  /// Determines if an order should actively schedule a notification reminder.
  static bool shouldScheduleReminder(OrderModel order) {
    if (!isRemindersGloballyEnabled) return false;
    if (!order.reminderEnabled) return false;
    if (order.expectedDeliveryAt == null) return false;
    if (order.isDelivered || order.isCancelled || order.status.toLowerCase() == 'returned') {
      return false;
    }

    final scheduled = calculateScheduledTime(order);
    if (scheduled == null) return false;

    // Active if scheduled in future or today
    final now = DateTime.now();
    return scheduled.isAfter(now.subtract(const Duration(hours: 24)));
  }

  /// Checks if a delivery reminder is scheduled within the next 24 hours.
  static bool isReminderDueSoon(OrderModel order) {
    if (!shouldScheduleReminder(order)) return false;
    final scheduled = calculateScheduledTime(order);
    if (scheduled == null) return false;

    final now = DateTime.now();
    final difference = scheduled.difference(now);
    return difference.inHours >= 0 && difference.inHours <= 24;
  }

  /// Returns all upcoming pending reminders from a collection of orders.
  static List<DeliveryReminder> getPendingReminders(List<OrderModel> orders) {
    final List<DeliveryReminder> reminders = [];
    for (final order in orders) {
      if (shouldScheduleReminder(order)) {
        final time = calculateScheduledTime(order);
        if (time != null) {
          reminders.add(DeliveryReminder(order: order, scheduledTime: time));
        }
      }
    }
    reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return reminders;
  }
}
