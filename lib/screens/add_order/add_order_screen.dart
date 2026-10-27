import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';

class AddOrderScreen extends StatefulWidget {
  final OrderModel? existingOrder;

  const AddOrderScreen({super.key, this.existingOrder});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controllers
  late final TextEditingController _productNameCtrl;
  late final TextEditingController _platformOrderIdCtrl;
  late final TextEditingController _productImageUrlCtrl;
  late final TextEditingController _courierNameCtrl;
  late final TextEditingController _trackingNumberCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _trackingUrlCtrl;
  late final TextEditingController _orderUrlCtrl;

  late String _selectedPlatform;
  late String _selectedStatus;
  late String _selectedCurrency;
  late String _selectedCategory;
  late bool _reminderEnabled;
  late String _reminderPreference;
  DateTime? _orderedAt;
  DateTime? _expectedDeliveryAt;
  bool _saving = false;

  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existingOrder;
    _selectedPlatform = o?.platformName ?? AppConstants.shoppingPlatforms.first;
    _selectedStatus = o?.status ?? AppConstants.statusOrdered;
    _selectedCurrency = o?.currency ?? 'INR';
    _selectedCategory = o?.category ?? AppConstants.productCategories.first;
    _reminderEnabled = o?.reminderEnabled ?? false;
    _reminderPreference = o?.reminderPreference ?? 'on_day';
    _orderedAt = o?.orderedAt ?? DateTime.now();
    _expectedDeliveryAt = o?.expectedDeliveryAt;

    _productNameCtrl = TextEditingController(text: o?.productName ?? '');
    _platformOrderIdCtrl = TextEditingController(text: o?.platformOrderId ?? '');
    _productImageUrlCtrl = TextEditingController(text: o?.productImageUrl ?? '');
    _courierNameCtrl = TextEditingController(text: o?.courierName ?? '');
    _trackingNumberCtrl = TextEditingController(text: o?.trackingNumber ?? '');
    _quantityCtrl = TextEditingController(text: '${o?.quantity ?? 1}');
    _priceCtrl = TextEditingController(
        text: o != null ? o.price.toStringAsFixed(2) : '');
    _trackingUrlCtrl = TextEditingController(text: o?.trackingUrl ?? '');
    _orderUrlCtrl = TextEditingController(text: o?.orderUrl ?? '');
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _platformOrderIdCtrl.dispose();
    _productImageUrlCtrl.dispose();
    _courierNameCtrl.dispose();
    _trackingNumberCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _trackingUrlCtrl.dispose();
    _orderUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      setState(() {
        _trackingNumberCtrl.text = scannedCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned tracking code: $scannedCode'),
          backgroundColor: AppTheme.electricLime.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final ordersProvider = context.read<OrdersProvider>();
      final now = DateTime.now();

      final order = OrderModel(
        id: _isEditing ? widget.existingOrder!.id : _uuid.v4(),
        userId: auth.effectiveUserId,
        platformName: _selectedPlatform,
        platformOrderId: _platformOrderIdCtrl.text.trim(),
        productName: _productNameCtrl.text.trim(),
        productImageUrl: _productImageUrlCtrl.text.trim().isEmpty
            ? null
            : _productImageUrlCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        currency: _selectedCurrency,
        category: _selectedCategory,
        courierName: _courierNameCtrl.text.trim().isEmpty
            ? null
            : _courierNameCtrl.text.trim(),
        trackingNumber: _trackingNumberCtrl.text.trim().isEmpty
            ? null
            : _trackingNumberCtrl.text.trim(),
        status: _selectedStatus,
        orderedAt: _orderedAt ?? now,
        expectedDeliveryAt: _expectedDeliveryAt,
        reminderEnabled: _reminderEnabled,
        reminderPreference: _reminderPreference,
        trackingUrl: _trackingUrlCtrl.text.trim().isEmpty
            ? null
            : _trackingUrlCtrl.text.trim(),
        orderUrl: _orderUrlCtrl.text.trim().isEmpty
            ? null
            : _orderUrlCtrl.text.trim(),
        createdAt: _isEditing ? widget.existingOrder!.createdAt : now,
        updatedAt: now,
        isDemo: false,
        trackingEvents: _isEditing
            ? widget.existingOrder!.trackingEvents
            : [],
      );

      if (_isEditing) {
        await ordersProvider.updateOrder(order);
      } else {
        await ordersProvider.addOrder(order);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Order updated.' : 'Order saved successfully.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF87171),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Order' : 'Add Order'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.electricLime),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Platform & Status ─────────────────────────────────
                  _sectionHeader('Platform & Status'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField<String>(
                          label: 'Shopping Platform',
                          value: _selectedPlatform,
                          items: AppConstants.shoppingPlatforms,
                          itemLabel: (v) => v,
                          icon: Icons.store_outlined,
                          onChanged: (v) =>
                              setState(() => _selectedPlatform = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField<String>(
                          label: 'Status',
                          value: _selectedStatus,
                          items: AppConstants.allStatuses,
                          itemLabel: AppTheme.statusLabel,
                          icon: Icons.info_outline,
                          onChanged: (v) =>
                              setState(() => _selectedStatus = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Product Details ───────────────────────────────────
                  _sectionHeader('Product Details'),
                  const SizedBox(height: 12),
                  _field(
                    controller: _productNameCtrl,
                    label: 'Product Name',
                    icon: Icons.inventory_2_outlined,
                    required: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _productImageUrlCtrl,
                    label: 'Product Image URL (optional)',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                          return 'Enter a valid URL starting with http:// or https://';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                    label: 'Product Category',
                    value: _selectedCategory,
                    items: AppConstants.productCategories,
                    itemLabel: (v) => v,
                    icon: Icons.category_outlined,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _field(
                          controller: _priceCtrl,
                          label: 'Price',
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'))
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField<String>(
                          label: 'Currency',
                          value: _selectedCurrency,
                          items: AppConstants.currencies,
                          itemLabel: (v) => v,
                          icon: Icons.currency_exchange,
                          onChanged: (v) =>
                              setState(() => _selectedCurrency = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _quantityCtrl,
                          label: 'Qty',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final n = int.tryParse(v);
                            if (n == null || n < 1) return '≥ 1';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Order Reference ───────────────────────────────────
                  _sectionHeader('Order Reference'),
                  const SizedBox(height: 12),
                  _field(
                    controller: _platformOrderIdCtrl,
                    label: 'Platform Order ID',
                    icon: Icons.receipt_long_outlined,
                    hint: 'e.g. OD12345678 or AMZ-xxx-xxx',
                    required: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _orderUrlCtrl,
                    label: 'Original Order URL (optional)',
                    icon: Icons.open_in_new_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                          return 'Enter a valid URL (http:// or https://)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Courier & Tracking ────────────────────────────────
                  _sectionHeader('Courier & Tracking'),
                  const SizedBox(height: 4),
                  Text(
                    'These fields are optional. You can add them later.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _courierNameCtrl,
                    label: 'Courier Name',
                    icon: Icons.local_shipping_outlined,
                    hint: 'e.g. Blue Dart, Delhivery, Ekart',
                  ),
                  const SizedBox(height: 8),
                  // Quick Courier selector chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: AppConstants.supportedCouriers.map((c) {
                      final isSelected = _courierNameCtrl.text.toLowerCase() == c.toLowerCase();
                      return ChoiceChip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _courierNameCtrl.text = selected ? (c == 'Other' ? '' : c) : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          controller: _trackingNumberCtrl,
                          label: 'Courier Tracking Number',
                          icon: Icons.qr_code_outlined,
                          hint: 'e.g. FMPP0072891234',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: IconButton.filledTonal(
                          onPressed: _scanBarcode,
                          icon: const Icon(Icons.qr_code_scanner, color: AppTheme.electricLime),
                          tooltip: 'Scan Tracking Barcode/QR',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _trackingUrlCtrl,
                    label: 'Courier Tracking URL (optional)',
                    icon: Icons.link_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                          return 'Enter a valid URL (http:// or https://)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Dates ─────────────────────────────────────────────
                  _sectionHeader('Dates'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Order Date',
                          icon: Icons.calendar_today_outlined,
                          value: _orderedAt,
                          onPicked: (d) => setState(() => _orderedAt = d),
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Expected Delivery',
                          icon: Icons.event_outlined,
                          value: _expectedDeliveryAt,
                          onPicked: (d) =>
                              setState(() => _expectedDeliveryAt = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Delivery Reminders ─────────────────────────────────
                  _sectionHeader('Delivery Reminders'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Delivery Alert Reminder',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text(
                            'Schedule local morning alert at 09:00 AM for this order.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          value: _reminderEnabled,
                          activeThumbColor: AppTheme.electricLime,
                          onChanged: _expectedDeliveryAt == null
                              ? null
                              : (val) => setState(() => _reminderEnabled = val),
                        ),
                        if (_expectedDeliveryAt == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '⚠️ Please select an Expected Delivery date above to enable reminders.',
                              style: TextStyle(fontSize: 12, color: AppTheme.warningAmber),
                            ),
                          ),
                        if (_reminderEnabled && _expectedDeliveryAt != null) ...[
                          const Divider(height: 20),
                          const Text('Notification Timing:',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'on_day',
                                label: Text('On delivery day'),
                                icon: Icon(Icons.alarm, size: 16),
                              ),
                              ButtonSegment(
                                value: 'day_before',
                                label: Text('1 day before'),
                                icon: Icon(Icons.notifications_active_outlined, size: 16),
                              ),
                            ],
                            selected: {_reminderPreference},
                            onSelectionChanged: (set) {
                              if (set.isNotEmpty) {
                                setState(() => _reminderPreference = set.first);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.midnightNavy),
                                )
                              : Text(_isEditing ? 'Update Order' : 'Save Order'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final IconData icon;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: AppTheme.cloudWhite, fontSize: 14),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style: const TextStyle(
                      color: AppTheme.cloudWhite, fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;
  final bool required;

  const _DateField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onPicked,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.electricLime,
                onPrimary: AppTheme.midnightNavy,
                surface: AppTheme.surface,
                onSurface: AppTheme.cloudWhite,
              ),
            ),
            child: child!,
          ),
        );
        onPicked(picked);
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label + (required ? ' *' : ''),
            prefixIcon: Icon(icon),
            suffixIcon: value != null
                ? const Icon(Icons.event, size: 18)
                : null,
          ),
          controller: TextEditingController(
            text: value == null
                ? ''
                : '${value!.day}/${value!.month}/${value!.year}',
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Required' : null
              : null,
        ),
      ),
    );
  }
}
