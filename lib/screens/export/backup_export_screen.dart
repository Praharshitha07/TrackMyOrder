import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../services/export/export_service.dart';
import '../../services/export/file_save_helper.dart';

class BackupExportScreen extends StatefulWidget {
  const BackupExportScreen({super.key});

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  bool _isExporting = false;

  Future<void> _exportCsv() async {
    final orders = context.read<OrdersProvider>().allUserOrders;
    if (orders.isEmpty) {
      _showMessage('No orders available to export.');
      return;
    }

    setState(() => _isExporting = true);
    try {
      final csvString = ExportService.generateCsv(orders);
      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'track_my_order_backup_$dateStamp.csv';

      final success = await FileSaveHelper.saveOrDownloadFile(
        fileName: fileName,
        content: csvString,
        mimeType: 'text/csv',
      );

      if (mounted) {
        _showMessage(
          success
              ? 'CSV backup generated & copied to clipboard ($fileName)'
              : 'Failed to generate CSV export.',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportJson() async {
    final orders = context.read<OrdersProvider>().allUserOrders;
    final auth = context.read<AuthProvider>();

    if (orders.isEmpty) {
      _showMessage('No orders available to export.');
      return;
    }

    setState(() => _isExporting = true);
    try {
      final jsonString = ExportService.generateJson(
        orders,
        exportedBy: auth.user?.email,
      );
      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'track_my_order_backup_$dateStamp.json';

      final success = await FileSaveHelper.saveOrDownloadFile(
        fileName: fileName,
        content: jsonString,
        mimeType: 'application/json',
      );

      if (mounted) {
        _showMessage(
          success
              ? 'JSON backup generated & copied to clipboard ($fileName)'
              : 'Failed to generate JSON export.',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>().allUserOrders;

    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.electricLime.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.backup_outlined,
                          size: 24,
                          color: AppTheme.electricLime,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${orders.length} Orders Stored',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cloudWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Back up your order history to CSV spreadsheet or JSON data format.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CSV Export Option
                _ExportFormatCard(
                  title: 'Export as CSV (Spreadsheet)',
                  description: 'Compatible with Microsoft Excel, Google Sheets, and Numbers. Includes dates, amounts, courier details, and tracking codes.',
                  icon: Icons.table_chart_outlined,
                  buttonLabel: 'Generate CSV Backup',
                  isLoading: _isExporting,
                  onPressed: orders.isEmpty ? null : _exportCsv,
                ),
                const SizedBox(height: 16),

                // JSON Export Option
                _ExportFormatCard(
                  title: 'Export as JSON (Full Backup)',
                  description: 'Structured schema with complete timestamps, tracking event history, categories, and delivery reminder preferences.',
                  icon: Icons.data_object_outlined,
                  buttonLabel: 'Generate JSON Backup',
                  isLoading: _isExporting,
                  onPressed: orders.isEmpty ? null : _exportJson,
                ),
                const SizedBox(height: 24),

                // Privacy Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security_outlined,
                        size: 16,
                        color: AppTheme.electricLime,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Export files contain only your order records. Passwords, API tokens, and internal keys are never serialized or exported.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportFormatCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ExportFormatCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.electricLime, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.cloudWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
