import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/widgets/form/amount_field.dart';
import 'package:spendwise/home/widgets/form/category_selector.dart';
import 'package:spendwise/home/widgets/form/payment_method_selector.dart';
import 'package:spendwise/home/widgets/form/transaction_datetime_row.dart';
import 'package:spendwise/config/constants.dart' show cashPaymentMethod;
import 'package:spendwise/home/utils/toast_utils.dart';
import 'package:spendwise/providers.dart'
    show availablePaymentMethodsProvider, categoryClassificationProvider;

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.repository,
    this.isEditing = false,
    this.initialItem,
    this.initialIsIncome,
  });

  final TransactionsRepository repository;
  final bool isEditing;
  final TransactionItem? initialItem;
  final bool? initialIsIncome;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceIdController = TextEditingController();
  final _entryByController = TextEditingController(text: 'You');

  bool _isIncome = true;
  DateTime _selectedDateTime = DateTime.now();
  String? _selectedCategory;
  String? _selectedPaymentMethod;


  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _isIncome = initial.isIncome;
      _selectedDateTime = initial.dateTime;
      _selectedCategory = initial.category;
      _selectedPaymentMethod = initial.paymentMethod;
      _remarksController.text = initial.remarks ?? '';
      _amountController.text = initial.amount.toStringAsFixed(2);
      _referenceIdController.text = initial.referenceId ?? '';
      _entryByController.text = initial.entryBy ?? 'You';
    } else {
      _isIncome = widget.initialIsIncome ?? true;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _amountController.dispose();
    _referenceIdController.dispose();
    _entryByController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
          _selectedDateTime.second,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: theme.colorScheme.primary.withValues(alpha: 1),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.surface;
                }
                return theme.colorScheme.primary.withValues(alpha: 0.6);
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
          _selectedDateTime.second,
        );
      });
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amountText.isEmpty || amount == null || amount <= 0) {
      showAppToast(context, 'Enter a valid amount');
      return;
    }

    if (_selectedCategory == null) {
      showAppToast(context, 'Select a category');
      return;
    }
    if (_selectedPaymentMethod == null) {
      showAppToast(context, 'Select a payment method');
      return;
    }

    try {
      final classType = ref.read(categoryClassificationProvider)[_selectedCategory!] ?? 'Desire';
      final item = TransactionItem(
        id: widget.initialItem?.id,
        remarks: _remarksController.text,
        category: _selectedCategory!,
        classType: classType,
        dateTime: _selectedDateTime,
        amount: amount,
        isIncome: _isIncome,
        paymentMethod: _selectedPaymentMethod!,
        referenceId: _referenceIdController.text,
        entryBy: _entryByController.text.trim().isEmpty
            ? 'You'
            : _entryByController.text.trim(),
      );

      final isEditing = widget.isEditing || widget.initialItem != null;
      if (isEditing) {
        await widget.repository.update(item);
      } else {
        await widget.repository.add(item);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showAppToast(context,'Error saving transaction: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SafeArea(
        child: Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              TransactionDateTimeRow(
                dateTime: _selectedDateTime,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              _SegmentedToggle(
                isIncome: _isIncome,
                onChanged: (value) => setState(() => _isIncome = value),
              ),
              const SizedBox(height: 18),
              AmountField(
                isIncome: _isIncome,
                controller: _amountController,
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Category', isRequired: true),
              const SizedBox(height: 10),
              CategorySelector(
                repository: widget.repository,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Payment method', isRequired: true),
              const SizedBox(height: 10),
              PaymentMethodSelector(
                paymentMethods: ref.watch(availablePaymentMethodsProvider),
                selectedPaymentMethod: _selectedPaymentMethod,
                onPaymentMethodSelected: (method) {
                  setState(() {
                    _selectedPaymentMethod = method;
                    if (method == cashPaymentMethod) _referenceIdController.clear();
                  });
                },
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Additional details'),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: TextFormField(
                  controller: _remarksController,
                  maxLines: 1,
                  decoration: _inputDecoration(theme, label: 'Remarks'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: TextFormField(
                  controller: _referenceIdController,
                  enabled: _selectedPaymentMethod != cashPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Reference ID',
                    filled: true,
                    fillColor: _selectedPaymentMethod == cashPaymentMethod
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _selectedPaymentMethod == cashPaymentMethod
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _selectedPaymentMethod == cashPaymentMethod
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  style: TextStyle(
                    color: _selectedPaymentMethod == cashPaymentMethod
                        ? theme.colorScheme.primary.withValues(alpha: 0.4)
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncome
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                      widget.isEditing ? 'Save Changes' : 'Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers — form-specific visual components
// ---------------------------------------------------------------------------

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.isIncome,
    required this.onChanged,
  });

  final bool isIncome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment:
                isIncome ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: (MediaQuery.of(context).size.width - 32 - 8) / 2,
              decoration: BoxDecoration(
                color: isIncome
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SegmentedLabel(
                  label: 'Money Out',
                  selected: !isIncome,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentedLabel(
                  label: 'Money In',
                  selected: isIncome,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedLabel extends StatelessWidget {
  const _SegmentedLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.isRequired = false,
  });

  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}


InputDecoration _inputDecoration(ThemeData theme, {required String label}) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
