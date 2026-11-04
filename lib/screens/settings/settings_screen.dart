import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/notifications/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App section ───────────────────────────────────────
                const _SectionHeader('App'),
                const SizedBox(height: 8),
                _card([
                  _SwitchTile(
                    icon: Icons.science_outlined,
                    title: 'Show Demo Orders',
                    subtitle:
                        'Save clearly labeled sample orders to your account.',
                    value: orders.showDemoOrders,
                    onChanged: (show) => _toggleDemoOrders(
                      context,
                      orders,
                      auth.effectiveUserId,
                      show,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Notifications ─────────────────────────────────────
                const _SectionHeader('Notifications & Delivery Reminders'),
                const SizedBox(height: 8),
                _card([
                  _SwitchTile(
                    icon: Icons.alarm,
                    title: 'Local Delivery Reminders',
                    subtitle: 'Schedule 9:00 AM delivery alerts for orders with expected delivery dates. Completely offline-first.',
                    value: NotificationService.isRemindersGloballyEnabled,
                    onChanged: (val) {
                      setState(() {
                        NotificationService.isRemindersGloballyEnabled = val;
                      });
                    },
                  ),
                  const _InfoTile(
                    icon: Icons.notifications_none,
                    title: 'Push Notifications (Cloud / FCM)',
                    subtitle: 'Requires Firebase Cloud Messaging credentials and device token registration.',
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Data & Storage ────────────────────────────────────
                const _SectionHeader('Data & Storage'),
                const SizedBox(height: 8),
                _card([
                  _ActionTile(
                    icon: Icons.download_outlined,
                    title: 'Backup & Export Data',
                    subtitle: 'Export orders to CSV spreadsheet or JSON backup file. No internet required.',
                    onTap: () => context.push('/backup-export'),
                  ),
                  const _InfoTile(
                    icon: Icons.cloud_outlined,
                    title: 'Orders',
                    subtitle: 'Orders are saved in your authenticated Firestore account.',
                  ),
                  const _InfoTile(
                    icon: Icons.science_outlined,
                    title: 'Demo Orders',
                    subtitle: 'Sample data is stored separately from your genuine orders and can be removed below.',
                  ),
                  if (orders.hasDemoOrders)
                    _ActionTile(
                      icon: Icons.delete_outline,
                      title: 'Remove demo orders',
                      subtitle: 'Delete sample records only. Your genuine orders will remain untouched.',
                      onTap: () => _removeDemoOrders(context, orders),
                    ),
                ]),
                const SizedBox(height: 20),

                // ── Future Integrations ───────────────────────────────
                const _SectionHeader('Future Features'),
                const SizedBox(height: 8),
                _card([
                  const _InfoTile(
                    icon: Icons.api_outlined,
                    title: 'Authorized Courier APIs',
                    subtitle: 'Connect directly to Delhivery, Blue Dart, and Ekart with client production credentials.',
                  ),
                  const _InfoTile(
                    icon: Icons.mail_outlined,
                    title: 'Consent-based Email Import',
                    subtitle: 'Import orders securely from Gmail with OAuth 2.0 user permission.',
                  ),
                ]),
                const SizedBox(height: 20),

                // ── About ─────────────────────────────────────────────
                const _SectionHeader('About'),
                const SizedBox(height: 8),
                _card([
                  const _InfoTile(
                    icon: Icons.info_outline,
                    title: 'Version',
                    subtitle: '1.0.0 — Track My Order',
                  ),
                  const _InfoTile(
                    icon: Icons.code_outlined,
                    title: 'Framework',
                    subtitle: 'Flutter 3 · Material 3 · Dart',
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleDemoOrders(
    BuildContext context,
    OrdersProvider orders,
    String userId,
    bool show,
  ) async {
    if (!show) {
      orders.toggleDemoOrders(false);
      return;
    }

    try {
      await orders.addDemoOrders(userId);
      orders.toggleDemoOrders(true);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add demo orders: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeDemoOrders(
    BuildContext context,
    OrdersProvider orders,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove demo orders?'),
        content: const Text(
          'Only sample orders marked as demo data will be deleted. Your genuine orders will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove demo orders'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await orders.deleteDemoOrders();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demo orders removed.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove all demo orders: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: children
            .expand(
              (w) => [w, if (w != children.last) const Divider(height: 1)],
            )
            .toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, size: 20, color: AppTheme.electricLime),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppTheme.cloudWhite),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      value: value,
      activeThumbColor: AppTheme.electricLime,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.electricLime),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.cloudWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textMuted,
          height: 1.4,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppTheme.textMuted,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppTheme.cloudWhite),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textMuted,
          height: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}
