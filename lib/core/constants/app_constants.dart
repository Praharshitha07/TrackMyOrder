/// Central app-level constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Track My Order';
  static const String appTagline = 'All your orders. One place.';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String settingsKey = 'tmo_settings';
  static const String onboardingKey = 'tmo_onboarding_done';

  // Supported platforms
  static const List<String> shoppingPlatforms = [
    'Amazon',
    'Flipkart',
    'Myntra',
    'Nykaa',
    'Meesho',
    'Other',
  ];

  // Order statuses
  static const String statusOrdered = 'ordered';
  static const String statusConfirmed = 'confirmed';
  static const String statusPacked = 'packed';
  static const String statusShipped = 'shipped';
  static const String statusInTransit = 'in_transit';
  static const String statusOutForDelivery = 'out_for_delivery';
  static const String statusDelivered = 'delivered';
  static const String statusDelayed = 'delayed';
  static const String statusCancelled = 'cancelled';
  static const String statusReturned = 'returned';

  static const List<String> allStatuses = [
    statusOrdered,
    statusConfirmed,
    statusPacked,
    statusShipped,
    statusInTransit,
    statusOutForDelivery,
    statusDelivered,
    statusDelayed,
    statusCancelled,
    statusReturned,
  ];

  // Supported couriers
  static const List<String> supportedCouriers = [
    'Delhivery',
    'Blue Dart',
    'Ekart',
    'India Post',
    'DTDC',
    'Shadowfax',
    'Amazon Logistics',
    'Other',
  ];

  // Supported product categories
  static const List<String> productCategories = [
    'Electronics',
    'Fashion & Apparel',
    'Beauty & Personal Care',
    'Home & Kitchen',
    'Books & Stationery',
    'Grocery & Essentials',
    'Fitness & Sports',
    'Other',
  ];

  // Currencies
  static const List<String> currencies = [
    'INR',
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SGD',
    'JPY',
  ];
}
