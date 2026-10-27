import 'package:intl/intl.dart';

/// Date and currency formatting utilities.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _longDate = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _monthDay = DateFormat('d MMM');
  static final DateFormat _timeDate = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _iso = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String formatShort(DateTime? dt) =>
      dt == null ? '—' : _shortDate.format(dt);

  static String formatLong(DateTime? dt) =>
      dt == null ? '—' : _longDate.format(dt);

  static String formatMonthDay(DateTime? dt) =>
      dt == null ? '—' : _monthDay.format(dt);

  static String formatDateTime(DateTime? dt) =>
      dt == null ? '—' : _timeDate.format(dt);

  static String formatTime(DateTime? dt) =>
      dt == null ? '—' : _time.format(dt);

  static String formatIso(DateTime dt) => _iso.format(dt);

  /// Returns a human-friendly relative label: "Today", "Tomorrow", "In 3 days",
  /// "2 days ago", etc.
  static String relativeLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${-diff} days ago';
  }

  /// Returns true if date is in the past.
  static bool isPast(DateTime? dt) =>
      dt != null && dt.isBefore(DateTime.now());

  /// Returns true if date is today.
  static bool isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

class CurrencyUtils {
  CurrencyUtils._();

  static String format(double amount, String currency) {
    try {
      final formatter = NumberFormat.currency(
        locale: _localeFor(currency),
        symbol: _symbolFor(currency),
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } catch (_) {
      return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  static String _symbolFor(String currency) {
    const map = {
      'INR': '₹',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'AED': 'AED ',
      'SGD': 'S\$',
      'JPY': '¥',
    };
    return map[currency] ?? '$currency ';
  }

  static String _localeFor(String currency) {
    const map = {
      'INR': 'en_IN',
      'USD': 'en_US',
      'EUR': 'de_DE',
      'GBP': 'en_GB',
      'JPY': 'ja_JP',
    };
    return map[currency] ?? 'en_US';
  }
}
