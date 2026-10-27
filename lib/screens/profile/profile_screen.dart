import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrdersProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // ── Avatar ────────────────────────────────────────────
                const SizedBox(height: 16),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.electricLime.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.electricLime.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: AppTheme.electricLime,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(auth.isAuthenticated ? (user?.name ?? '—') : 'Guest User',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                    auth.isAuthenticated
                        ? (user?.email ?? '—')
                        : 'Using local offline storage',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 28),

                // ── Stats row ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statPill('${orders.totalCount}', 'Orders'),
                    _statPill('${orders.activeCount}', 'Active'),
                    _statPill('${orders.deliveredCount}', 'Delivered'),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Account section ───────────────────────────────────
                _SectionCard(
                  title: 'Account',
                  children: [
                    _tile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Account Mode',
                      trailing: auth.isAuthenticated ? 'Signed In' : 'Guest Mode',
                    ),
                    _tile(
                      context,
                      icon: Icons.badge_outlined,
                      title: 'Name',
                      trailing: auth.isAuthenticated ? (user?.name ?? '—') : 'Guest',
                    ),
                    _tile(
                      context,
                      icon: Icons.email_outlined,
                      title: 'Email',
                      trailing: auth.isAuthenticated ? (user?.email ?? '—') : 'Not registered',
                    ),
                    _tile(
                      context,
                      icon: Icons.storage_outlined,
                      title: 'Storage',
                      trailing: 'Local device',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Tools & Insights ─────────────────────────────────
                _SectionCard(
                  title: 'Tools & Insights',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.insights, size: 20, color: AppTheme.electricLime),
                      title: const Text('Spending Analytics',
                          style: TextStyle(fontSize: 14, color: AppTheme.cloudWhite, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Order metrics, platform distribution, monthly spending history.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                      dense: true,
                      onTap: () => context.push('/analytics'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined, size: 20, color: AppTheme.electricLime),
                      title: const Text('Backup & Export',
                          style: TextStyle(fontSize: 14, color: AppTheme.cloudWhite, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Export orders as CSV spreadsheet or JSON backup.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                      dense: true,
                      onTap: () => context.push('/backup-export'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textSecondary),
                      title: const Text('App Settings',
                          style: TextStyle(fontSize: 14, color: AppTheme.cloudWhite)),
                      subtitle: const Text('Notification reminders, demo orders toggle, and storage info.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                      dense: true,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Integrations section ──────────────────────────────
                _SectionCard(
                  title: 'Connected Services',
                  children: [
                    _integrationTile(
                      context,
                      icon: Icons.qr_code_scanner,
                      title: 'Barcode / Label Scanner',
                      subtitle: 'Active (Camera / Code Scanning)',
                      connected: true,
                    ),
                    _integrationTile(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Courier APIs (Delhivery, Blue Dart, Ekart)',
                      subtitle: 'Architecture ready — awaiting carrier API tokens.',
                      connected: false,
                    ),
                    _integrationTile(
                      context,
                      icon: Icons.mail_outline,
                      title: 'Email Import',
                      subtitle: 'Not available — requires OAuth consent.',
                      connected: false,
                    ),
                    _integrationTile(
                      context,
                      icon: Icons.cloud_sync_outlined,
                      title: 'Guest-to-Cloud Order Migration',
                      subtitle: auth.isAuthenticated
                          ? 'Ready to migrate offline orders to your cloud account.'
                          : 'Sign in to sync local orders to your account.',
                      connected: auth.isAuthenticated,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Privacy section ───────────────────────────────────
                _SectionCard(
                  title: 'Privacy',
                  children: [
                    _tile(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Data Storage',
                      trailing: 'On-device only',
                    ),
                    _tile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Passwords',
                      trailing: 'Not sent to any server',
                    ),
                    _tile(
                      context,
                      icon: Icons.cloud_off_outlined,
                      title: 'Cloud Sync',
                      trailing: 'Not configured',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Auth Action ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: auth.isAuthenticated
                      ? OutlinedButton.icon(
                          onPressed: () => _signOut(context, auth),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF87171),
                            side: const BorderSide(color: Color(0xFFF87171)),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Sign In / Register'),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.electricLime,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      required String trailing}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(trailing,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      dense: true,
    );
  }

  Widget _integrationTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool connected}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: connected
              ? AppTheme.statusDelivered.withValues(alpha: 0.1)
              : AppTheme.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          connected ? 'Connected' : 'Not connected',
          style: TextStyle(
            fontSize: 11,
            color: connected
                ? AppTheme.statusDelivered
                : AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      dense: true,
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out? Your session and in-memory cache will be cleared.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OrdersProvider>().clearState();
      await auth.signOut();
      if (context.mounted) {
        context.read<OrdersProvider>().loadOrders(auth.effectiveUserId);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
