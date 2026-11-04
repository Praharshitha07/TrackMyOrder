import 'package:flutter/material.dart';

/// Track My Order — centralized Material 3 design system.
///
/// Soft Beige + Terracotta palette.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF8F3EC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primaryBrown = Color(0xFF49352D);
  static const Color secondaryText = Color(0xFF8D7567);
  static const Color terracotta = Color(0xFFC97955);
  static const Color border = Color(0xFFE9DED4);
  static const Color success = Color(0xFF438568);
  static const Color warning = Color(0xFFD69A46);
  static const Color error = Color(0xFFC65C52);

  // Retain established names so existing widgets use the shared palette.
  static const Color midnightNavy = background;
  static const Color electricLime = terracotta;
  static const Color cloudWhite = primaryBrown;
  static const Color surface = card;
  static const Color surfaceVariant = background;
  static const Color surfaceLight = card;
  static const Color cardBorder = border;
  static const Color divider = border;
  static const Color warningAmber = warning;
  static const Color textPrimary = primaryBrown;
  static const Color textSecondary = secondaryText;
  static const Color textMuted = secondaryText;

  static const Color statusOrdered = Color(0xFF8D7567);
  static const Color statusConfirmed = Color(0xFF9A6C54);
  static const Color statusPacked = Color(0xFFAA7656);
  static const Color statusShipped = Color(0xFFB77D54);
  static const Color statusInTransit = Color(0xFFB16F4F);
  static const Color statusOutForDelivery = terracotta;
  static const Color statusDelivered = success;
  static const Color statusDelayed = warning;
  static const Color statusCancelled = error;
  static const Color statusReturned = Color(0xFF946653);

  // ── Typography ───────────────────────────────────────────────────────────
  static const String _fontFamily = 'Roboto';

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: cloudWhite,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cloudWhite,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cloudWhite,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: cloudWhite,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: cloudWhite,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: electricLime,
      onPrimary: primaryBrown,
      primaryContainer: const Color(0xFFF1DED3),
      onPrimaryContainer: primaryBrown,
      secondary: secondaryText,
      onSecondary: card,
      secondaryContainer: const Color(0xFFF0E6DD),
      onSecondaryContainer: primaryBrown,
      surface: card,
      onSurface: primaryBrown,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: textSecondary,
      outline: cardBorder,
      outlineVariant: divider,
      error: AppTheme.error,
      onError: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: midnightNavy,
        foregroundColor: cloudWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _buildTextTheme().titleLarge,
        centerTitle: false,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: primaryBrown.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: electricLime.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: electricLime, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: electricLime,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          );
        }),
      ),

      // Navigation rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: electricLime, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 24),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: electricLime,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        indicatorColor: Color(0x26C97955),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricLime,
          foregroundColor: primaryBrown,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricLime,
          side: const BorderSide(color: electricLime, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricLime,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricLime,
          foregroundColor: primaryBrown,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricLime, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        floatingLabelStyle: const TextStyle(color: electricLime, fontSize: 12),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: electricLime.withValues(alpha: 0.15),
        side: const BorderSide(color: cardBorder),
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: electricLime,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: cardBorder,
        showDragHandle: true,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _buildTextTheme().headlineMedium,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: cloudWhite, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricLime,
        foregroundColor: primaryBrown,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: cloudWhite,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return card;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return electricLime;
          return cardBorder;
        }),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricLime,
        linearTrackColor: cardBorder,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'ordered':
        return statusOrdered;
      case 'confirmed':
        return statusConfirmed;
      case 'packed':
        return statusPacked;
      case 'shipped':
        return statusShipped;
      case 'in_transit':
        return statusInTransit;
      case 'out_for_delivery':
        return statusOutForDelivery;
      case 'delivered':
        return statusDelivered;
      case 'delayed':
        return statusDelayed;
      case 'cancelled':
        return statusCancelled;
      case 'returned':
        return statusReturned;
      default:
        return textSecondary;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'ordered':
        return Icons.shopping_cart_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'in_transit':
        return Icons.directions_transit_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining_outlined;
      case 'delivered':
        return Icons.done_all;
      case 'delayed':
        return Icons.schedule_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'returned':
        return Icons.assignment_return_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'ordered':
        return 'Ordered';
      case 'confirmed':
        return 'Confirmed';
      case 'packed':
        return 'Packed';
      case 'shipped':
        return 'Shipped';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'delayed':
        return 'Delayed';
      case 'cancelled':
        return 'Cancelled';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }

  static Color platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'amazon':
        return const Color(0xFFA86A3D);
      case 'flipkart':
        return const Color(0xFF5C7184);
      case 'myntra':
        return const Color(0xFFB05C63);
      case 'nykaa':
        return const Color(0xFF9C5E7A);
      case 'meesho':
        return const Color(0xFF7E6683);
      default:
        return textSecondary;
    }
  }

  static IconData platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'amazon':
        return Icons.shopping_bag_outlined;
      case 'flipkart':
        return Icons.store_outlined;
      case 'myntra':
        return Icons.checkroom_outlined;
      case 'nykaa':
        return Icons.spa_outlined;
      case 'meesho':
        return Icons.sell_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }
}
