import 'package:flutter/material.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';

class TransactionFormPage extends StatefulWidget {
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
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceIdController = TextEditingController();
  final _entryByController = TextEditingController(text: 'You');
  late FocusNode _amountFocusNode;

  bool _isIncome = true;
  DateTime _selectedDateTime = DateTime.now();

  String? _selectedCategory;
  String? _selectedPaymentMethod;

  // Category to Classification Mapping
  final Map<String, String> _categoryClassification = const {
    'Income': 'Others',
    'Dining': 'Desire',
    'Snacks': 'Desire',
    'Shopping': 'Desire',
    'Groceries': 'Necessity',
    'Travel': 'Necessity',
    'Bills': 'Necessity',
    'Health': 'Necessity',
    'Education': 'Investment',
    'Investment': 'Investment',
    'Personal Care': 'Necessity',
    'Entertainment': 'Desire',
    'Gifts': 'Desire',
    'EMIs': 'Necessity',
    'Transfers': 'Others',
    'Housing': 'Necessity',
    'Others': 'Desire',
  };

  final List<_CategoryOption> _categoryOptions = const [
    _CategoryOption('Income', Icons.currency_rupee),
    _CategoryOption('Dining', Icons.restaurant),
    _CategoryOption('Snacks', Icons.fastfood),
    _CategoryOption('Shopping', Icons.shopping_bag),
    _CategoryOption('Groceries', Icons.shopping_cart),
    _CategoryOption('Travel', Icons.directions_car),
    _CategoryOption('Bills', Icons.receipt_long),
    _CategoryOption('Health', Icons.health_and_safety),
    _CategoryOption('Education', Icons.school),
    _CategoryOption('Investment', Icons.trending_up),
    _CategoryOption('Personal Care', Icons.spa),
    _CategoryOption('Entertainment', Icons.movie),
    _CategoryOption('Gifts', Icons.card_giftcard),
    _CategoryOption('EMIs', Icons.payments),
    _CategoryOption('Transfers', Icons.swap_horiz),
    _CategoryOption('Housing', Icons.home),
    _CategoryOption('Others', Icons.category),
  ];

  final List<String> _paymentMethods = const [
    'Cash',
    'UPI',
    'Card',
    'Bank',
  ];

  final Map<String, IconData> _paymentMethodIcons = const {
    'Cash': Icons.payments,
    'Card': Icons.credit_card,
    'Bank': Icons.account_balance,
    'UPI': Icons.qr_code,
  };

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      setState(() {});
    });
    final initial = widget.initialItem;
    if (initial != null) {
      _isIncome = initial.isIncome;
      _selectedDateTime = initial.dateTime;
      _selectedCategory = initial.category;
      _selectedPaymentMethod = initial.paymentMethod;
      _remarksController.text = initial.remarks;
      _amountController.text = initial.amount.toStringAsFixed(2);
      _referenceIdController.text = initial.referenceId;
      _entryByController.text = initial.entryBy;
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
    _amountFocusNode.dispose();
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
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDateTime);
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method')),
      );
      return;
    }

    try {
      final amount = double.parse(_amountController.text.trim());
      final classType = _categoryClassification[_selectedCategory!] ?? 'Desire';
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
        entryBy: _entryByController.text.trim().isEmpty ? 'You' : _entryByController.text.trim(),
      );

      final isEditing = widget.isEditing || widget.initialItem != null;
      if (isEditing) {
        await widget.repository.update(item);
      } else {
        await widget.repository.add(item);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  List<_CategoryOption> _sortedCategoryOptions(List<TransactionItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    final order = <String, int>{};
    for (var i = 0; i < _categoryOptions.length; i++) {
      order[_categoryOptions[i].label] = i;
    }

    final options = [..._categoryOptions];
    options.sort((a, b) {
      final countA = counts[a.label] ?? 0;
      final countB = counts[b.label] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      final orderA = order[a.label] ?? 0;
      final orderB = order[b.label] ?? 0;
      return orderA.compareTo(orderB);
    });

    return options;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = formatDate(_selectedDateTime);
    final timeLabel = formatTime(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Date and Time row
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickDate,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: _pickTime,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _SegmentedToggle(
                isIncome: _isIncome,
                onChanged: (value) => setState(() => _isIncome = value),
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ENTER AMOUNT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' *',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₹',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _isIncome
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _amountFocusNode.hasFocus ? '' : '0.00',
                            hintStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter amount';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionHeader(title: 'Category', isRequired: true),
              const SizedBox(height: 10),
              StreamBuilder<List<TransactionItem>>(
                stream: widget.repository.watchAll(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <TransactionItem>[];
                  final options = _sortedCategoryOptions(items);
                  final hasCategorySelection = _selectedCategory != null;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 16.0;
                      final tileWidth = (constraints.maxWidth - (spacing * 4)) / 5;
                      final tileSize = tileWidth.clamp(56.0, 72.0);
                      return SizedBox(
                        height: tileSize + 28,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const SizedBox(width: spacing),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final selected = _selectedCategory == option.label;
                            return _CategoryTile(
                              label: option.label,
                              icon: option.icon,
                              size: tileSize,
                              selected: selected,
                              hasSelection: hasCategorySelection,
                              selectedColor: theme.colorScheme.primary,
                              onTap: () => setState(() => _selectedCategory = option.label),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              _SectionHeader(title: 'Payment method', isRequired: true),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paymentMethods.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final hasPaymentSelection = _selectedPaymentMethod != null;
                    if (index == _paymentMethods.length) {
                      return _OutlinePill(
                        label: 'Add',
                        icon: Icons.add,
                        dimmed: hasPaymentSelection,
                        onTap: () {},
                      );
                    }
                    final label = _paymentMethods[index];
                    final selected = _selectedPaymentMethod == label;
                    return _FilledPill(
                      label: label,
                      icon: _paymentMethodIcons[label],
                      selected: selected,
                      hasSelection: hasPaymentSelection,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = label;
                          // Clear reference ID if Cash is selected
                          if (label == 'Cash') {
                            _referenceIdController.clear();
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _SectionHeader(title: 'Additional details'),
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
                  enabled: _selectedPaymentMethod != 'Cash',
                  decoration: InputDecoration(
                    labelText: 'Reference ID',
                    filled: true,
                    fillColor: _selectedPaymentMethod == 'Cash'
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _selectedPaymentMethod == 'Cash'
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _selectedPaymentMethod == 'Cash'
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: TextStyle(
                    color: _selectedPaymentMethod == 'Cash'
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
                    backgroundColor:
                        _isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(widget.isEditing ? 'Save Changes' : 'Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            alignment: isIncome ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: (MediaQuery.of(context).size.width - 32 - 8) / 2,
              decoration: BoxDecoration(
                color: isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error,
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
    this.actionLabel,
    this.onActionTap,
    this.isRequired = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Row(
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
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.size,
    required this.selected,
    required this.hasSelection,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double size;
  final bool selected;
  final bool hasSelection;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmedColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    final labelColor = selected
        ? theme.colorScheme.primary
        : (hasSelection ? dimmedColor : theme.textTheme.labelLarge?.color);
    final iconColor = selected
        ? Colors.white
        : (hasSelection ? dimmedColor : theme.colorScheme.primary);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Icon(
                    icon,
                    key: ValueKey<Color>(iconColor),
                    size: size * 0.38,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ) ?? const TextStyle(),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _FilledPill extends StatelessWidget {
  const _FilledPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.hasSelection,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmedColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    final textColor = selected
        ? Colors.white
        : (hasSelection ? dimmedColor : theme.colorScheme.primary);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({
    required this.label,
    this.icon,
    this.dimmed = false,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmedColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    final textColor = dimmed ? dimmedColor : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
