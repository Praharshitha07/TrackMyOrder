import 'dart:convert';

import '../../models/order_model.dart';
import '../../core/utils/format_utils.dart';

/// Service responsible for generating and parsing CSV and JSON backups.
class ExportService {
  static const String backupSchemaVersion = '1.0.0';

  /// Generate CSV representation of orders
  static String generateCsv(List<OrderModel> orders) {
    final buffer = StringBuffer();

    // CSV Header row
    buffer.writeln(
      [
        'Order ID',
        'Platform',
        'Platform Order ID',
        'Product Name',
        'Category',
        'Quantity',
        'Price',
        'Currency',
        'Total Amount',
        'Status',
        'Courier Name',
        'Tracking Number',
        'Courier Contact',
        'Pickup Location',
        'Delivery Location',
        'Additional Notes',
        'Order Date',
        'Expected Delivery Date',
        'Delivered Date',
        'Tracking URL',
        'Order URL',
        'Demo Tracking Enabled',
        'Is Demo',
        'Reminder Enabled',
        'Reminder Preference',
      ].map(_escapeCsvValue).join(','),
    );

    // Rows
    for (final order in orders) {
      final totalAmount = (order.price * order.quantity).toStringAsFixed(2);
      buffer.writeln(
        [
          order.id,
          order.platformName,
          order.platformOrderId,
          order.productName,
          order.category ?? '',
          order.quantity.toString(),
          order.price.toStringAsFixed(2),
          order.currency,
          totalAmount,
          order.status,
          order.courierName ?? '',
          order.trackingNumber ?? '',
          order.courierContact ?? '',
          order.pickupLocation ?? '',
          order.deliveryLocation ?? '',
          order.additionalNotes ?? '',
          AppDateUtils.formatIso(order.orderedAt),
          order.expectedDeliveryAt != null
              ? AppDateUtils.formatIso(order.expectedDeliveryAt!)
              : '',
          order.deliveredAt != null
              ? AppDateUtils.formatIso(order.deliveredAt!)
              : '',
          order.trackingUrl ?? '',
          order.orderUrl ?? '',
          order.demoTrackingEnabled ? 'Yes' : 'No',
          order.isDemo ? 'Yes' : 'No',
          order.reminderEnabled ? 'Yes' : 'No',
          order.reminderPreference,
        ].map(_escapeCsvValue).join(','),
      );
    }

    return buffer.toString();
  }

  /// Generate JSON backup object with schema metadata and order array
  static String generateJson(List<OrderModel> orders, {String? exportedBy}) {
    final backupMap = {
      'app': 'Track My Order',
      'schemaVersion': backupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'recordCount': orders.length,
      'orderCount': orders.length,
      'version': 1,
      'exportedBy': exportedBy,
      'orders': orders.map((o) => o.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Parse and validate a JSON backup string, returning imported orders
  static List<OrderModel> parseJsonBackup(String jsonString) =>
      parseImportJson(jsonString);

  /// Parse imported JSON backup into a list of OrderModel
  static List<OrderModel> parseImportJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid backup: root must be a JSON object.',
      );
    }

    final ordersJson = decoded['orders'];
    if (ordersJson is! List<dynamic>) {
      throw const FormatException('Invalid backup: "orders" array missing.');
    }

    final List<OrderModel> imported = [];
    for (final item in ordersJson) {
      if (item is Map<String, dynamic>) {
        imported.add(OrderModel.fromJson(item));
      }
    }

    return imported;
  }

  static String _escapeCsvValue(String value) {
    // If value contains comma, double quote, or newline, escape it
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
