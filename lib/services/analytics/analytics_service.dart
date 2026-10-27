import '../../models/order_model.dart';

/// Calculation result model for all analytics metrics.
class AnalyticsData {
  final double totalSpending;
  final int totalOrders;
  final double averageOrderValue;
  final int deliveredCount;
  final int activeCount;
  final int cancelledCount;
  final double currentMonthSpending;
  final Map<String, double> spendingByPlatform;
  final Map<String, int> ordersByPlatform;
  final Map<String, double> spendingByCategory;
  final Map<String, int> ordersByCategory;
  final List<MonthlySpending> monthlySpending;

  const AnalyticsData({
    required this.totalSpending,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.deliveredCount,
    required this.activeCount,
    required this.cancelledCount,
    required this.currentMonthSpending,
    required this.spendingByPlatform,
    required this.ordersByPlatform,
    required this.spendingByCategory,
    required this.ordersByCategory,
    required this.monthlySpending,
  });

  bool get isEmpty => totalOrders == 0;
}

class MonthlySpending {
  final String label; // e.g. "Oct 2026"
  final DateTime month;
  final double amount;
  final int orderCount;

  const MonthlySpending({
    required this.label,
    required this.month,
    required this.amount,
    required this.orderCount,
  });

  double get totalSpent => amount;
  String get monthLabel => label;
}

class SpendingSummary {
  final double totalSpent;
  final int includedOrderCount;
  final int cancelledOrderCount;
  final double averageOrderValue;

  const SpendingSummary({
    required this.totalSpent,
    required this.includedOrderCount,
    required this.cancelledOrderCount,
    required this.averageOrderValue,
  });
}

class PlatformBreakdown {
  final String platform;
  final int orderCount;
  final double percentage;
  final double totalSpent;

  const PlatformBreakdown({
    required this.platform,
    required this.orderCount,
    required this.percentage,
    required this.totalSpent,
  });
}

class CategoryBreakdown {
  final String category;
  final int orderCount;
  final double totalSpent;

  const CategoryBreakdown({
    required this.category,
    required this.orderCount,
    required this.totalSpent,
  });
}

/// Service computing deterministic analytics and spending metrics from saved orders.
///
/// SPENDING RULES:
/// 1. Excludes 'cancelled' orders from expenditure totals to prevent inflating purchase numbers.
/// 2. Price is calculated as: order.price * order.quantity (handles multi-unit orders).
/// 3. Rejects invalid, NaN, infinite, or negative amounts.
/// 4. Average Order Value (AOV) = totalSpending / nonCancelledEligibleOrdersCount.
class AnalyticsService {
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Comprehensive calculation for the full Analytics UI dashboard
  AnalyticsData calculate(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const AnalyticsData(
        totalSpending: 0,
        totalOrders: 0,
        averageOrderValue: 0,
        deliveredCount: 0,
        activeCount: 0,
        cancelledCount: 0,
        currentMonthSpending: 0,
        spendingByPlatform: {},
        ordersByPlatform: {},
        spendingByCategory: {},
        ordersByCategory: {},
        monthlySpending: [],
      );
    }

    final now = DateTime.now();
    double totalSpending = 0;
    int eligibleOrdersCount = 0;
    int deliveredCount = 0;
    int activeCount = 0;
    int cancelledCount = 0;
    double currentMonthSpending = 0;

    final Map<String, double> platformSpending = {};
    final Map<String, int> platformOrders = {};
    final Map<String, double> categorySpending = {};
    final Map<String, int> categoryOrders = {};
    final Map<String, MonthlySpendingAccumulator> monthMap = {};

    for (final order in orders) {
      final isCancelled = order.isCancelled || order.status.toLowerCase() == 'cancelled';
      final isDelivered = order.isDelivered || order.status.toLowerCase() == 'delivered';
      final isActive = !['delivered', 'cancelled', 'returned'].contains(order.status.toLowerCase());

      if (isCancelled) {
        cancelledCount++;
      } else if (isDelivered) {
        deliveredCount++;
      } else if (isActive) {
        activeCount++;
      }

      // Safe price calculation
      double orderTotal = order.price * order.quantity;
      if (orderTotal.isNaN || orderTotal.isInfinite || orderTotal < 0) {
        orderTotal = 0.0;
      }

      // Platform tracking
      final platform = order.platformName.trim().isEmpty ? 'Other' : order.platformName;
      platformOrders[platform] = (platformOrders[platform] ?? 0) + 1;

      // Category tracking
      final category = (order.category != null && order.category!.trim().isNotEmpty)
          ? order.category!
          : 'Uncategorized';
      categoryOrders[category] = (categoryOrders[category] ?? 0) + 1;

      // Cancelled orders are strictly excluded from monetary spending calculations
      if (!isCancelled) {
        totalSpending += orderTotal;
        eligibleOrdersCount++;

        platformSpending[platform] = (platformSpending[platform] ?? 0.0) + orderTotal;
        categorySpending[category] = (categorySpending[category] ?? 0.0) + orderTotal;

        // Check if in current calendar month
        if (order.orderedAt.year == now.year && order.orderedAt.month == now.month) {
          currentMonthSpending += orderTotal;
        }

        // Monthly bucket
        final monthKey = '${order.orderedAt.year}-${order.orderedAt.month.toString().padLeft(2, '0')}';
        if (!monthMap.containsKey(monthKey)) {
          final label = '${_monthNames[order.orderedAt.month - 1]} ${order.orderedAt.year}';
          monthMap[monthKey] = MonthlySpendingAccumulator(
            label: label,
            month: DateTime(order.orderedAt.year, order.orderedAt.month),
          );
        }
        monthMap[monthKey]!.amount += orderTotal;
        monthMap[monthKey]!.count += 1;
      }
    }

    final double aov = eligibleOrdersCount > 0 ? (totalSpending / eligibleOrdersCount) : 0.0;

    // Sort monthly spending chronologically
    final sortedMonths = monthMap.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    final List<MonthlySpending> monthlyList = sortedMonths
        .map((m) => MonthlySpending(
              label: m.label,
              month: m.month,
              amount: m.amount,
              orderCount: m.count,
            ))
        .toList();

    return AnalyticsData(
      totalSpending: totalSpending,
      totalOrders: orders.length,
      averageOrderValue: aov,
      deliveredCount: deliveredCount,
      activeCount: activeCount,
      cancelledCount: cancelledCount,
      currentMonthSpending: currentMonthSpending,
      spendingByPlatform: platformSpending,
      ordersByPlatform: platformOrders,
      spendingByCategory: categorySpending,
      ordersByCategory: categoryOrders,
      monthlySpending: monthlyList,
    );
  }

  // ── Static Helper Methods for Isolated Domain Checks ──────────────────────

  /// Calculates spending summary with strict exclusion of cancelled orders.
  static SpendingSummary calculateSpending(List<OrderModel> orders) {
    double total = 0.0;
    int included = 0;
    int cancelled = 0;

    for (final o in orders) {
      if (o.isCancelled || o.status.toLowerCase() == 'cancelled') {
        cancelled++;
      } else {
        final amount = o.price * o.quantity;
        if (!amount.isNaN && !amount.isInfinite && amount > 0) {
          total += amount;
        }
        included++;
      }
    }

    final aov = included > 0 ? (total / included) : 0.0;
    return SpendingSummary(
      totalSpent: total,
      includedOrderCount: included,
      cancelledOrderCount: cancelled,
      averageOrderValue: aov,
    );
  }

  /// Calculates platform breakdown with percentages and spent amounts.
  static List<PlatformBreakdown> calculatePlatformBreakdown(List<OrderModel> orders) {
    if (orders.isEmpty) return [];

    final Map<String, int> counts = {};
    final Map<String, double> spending = {};

    for (final o in orders) {
      final p = o.platformName.trim().isEmpty ? 'Other' : o.platformName;
      counts[p] = (counts[p] ?? 0) + 1;

      if (!o.isCancelled && o.status.toLowerCase() != 'cancelled') {
        final amount = o.price * o.quantity;
        if (!amount.isNaN && !amount.isInfinite && amount > 0) {
          spending[p] = (spending[p] ?? 0.0) + amount;
        }
      }
    }

    return counts.entries.map((e) {
      final percentage = (e.value / orders.length) * 100.0;
      return PlatformBreakdown(
        platform: e.key,
        orderCount: e.value,
        percentage: percentage,
        totalSpent: spending[e.key] ?? 0.0,
      );
    }).toList();
  }

  /// Calculates category breakdown with counts and total spending.
  static List<CategoryBreakdown> calculateCategoryBreakdown(List<OrderModel> orders) {
    final Map<String, int> counts = {};
    final Map<String, double> spending = {};

    for (final o in orders) {
      final cat = (o.category != null && o.category!.trim().isNotEmpty)
          ? o.category!
          : 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;

      if (!o.isCancelled && o.status.toLowerCase() != 'cancelled') {
        final amount = o.price * o.quantity;
        if (!amount.isNaN && !amount.isInfinite && amount > 0) {
          spending[cat] = (spending[cat] ?? 0.0) + amount;
        }
      }
    }

    return counts.entries.map((e) {
      return CategoryBreakdown(
        category: e.key,
        orderCount: e.value,
        totalSpent: spending[e.key] ?? 0.0,
      );
    }).toList();
  }

  /// Groups orders by calendar month and returns chronologically ordered buckets.
  static List<MonthlySpending> calculateMonthlySpending(List<OrderModel> orders) {
    final Map<String, MonthlySpendingAccumulator> monthMap = {};

    for (final o in orders) {
      final monthKey = '${o.orderedAt.year}-${o.orderedAt.month.toString().padLeft(2, '0')}';
      if (!monthMap.containsKey(monthKey)) {
        final label = '${_monthNames[o.orderedAt.month - 1]} ${o.orderedAt.year}';
        monthMap[monthKey] = MonthlySpendingAccumulator(
          label: label,
          month: DateTime(o.orderedAt.year, o.orderedAt.month),
        );
      }

      monthMap[monthKey]!.count += 1;

      if (!o.isCancelled && o.status.toLowerCase() != 'cancelled') {
        final amount = o.price * o.quantity;
        if (!amount.isNaN && !amount.isInfinite && amount > 0) {
          monthMap[monthKey]!.amount += amount;
        }
      }
    }

    final sorted = monthMap.values.toList()..sort((a, b) => a.month.compareTo(b.month));
    return sorted
        .map((m) => MonthlySpending(
              label: m.label,
              month: m.month,
              amount: m.amount,
              orderCount: m.count,
            ))
        .toList();
  }
}

class MonthlySpendingAccumulator {
  final String label;
  final DateTime month;
  double amount = 0.0;
  int count = 0;

  MonthlySpendingAccumulator({required this.label, required this.month});
}
