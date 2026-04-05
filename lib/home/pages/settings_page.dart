import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';
import 'package:spendwise/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: const [
          _BookNameSection(),
          SizedBox(height: 28),
          _CategoriesSection(),
          SizedBox(height: 28),
          _PaymentMethodsSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section header — matches transaction form style
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon picker
// ---------------------------------------------------------------------------

const List<IconData> _iconPalette = [
  Icons.category, Icons.currency_rupee, Icons.restaurant, Icons.fastfood,
  Icons.local_cafe, Icons.local_pizza, Icons.shopping_bag, Icons.shopping_cart,
  Icons.storefront, Icons.directions_car, Icons.flight, Icons.train,
  Icons.directions_bus, Icons.two_wheeler, Icons.receipt_long, Icons.receipt,
  Icons.health_and_safety, Icons.medical_services, Icons.local_pharmacy,
  Icons.fitness_center, Icons.school, Icons.menu_book, Icons.trending_up,
  Icons.savings, Icons.account_balance, Icons.credit_card, Icons.payments,
  Icons.qr_code, Icons.swap_horiz, Icons.home, Icons.apartment,
  Icons.spa, Icons.movie, Icons.music_note, Icons.sports_esports,
  Icons.card_giftcard, Icons.celebration, Icons.child_care, Icons.pets,
  Icons.phone_android, Icons.laptop, Icons.electric_bolt, Icons.water_drop,
  Icons.wifi, Icons.subscriptions, Icons.work, Icons.attach_money,
  Icons.volunteer_activism, Icons.local_grocery_store, Icons.liquor,
  Icons.sports, Icons.beach_access, Icons.park,
];

Future<IconData?> _pickIcon(BuildContext context, IconData current) {
  return showModalBottomSheet<IconData>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.75,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text('Choose Icon',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _iconPalette.length,
                itemBuilder: (_, i) {
                  final icon = _iconPalette[i];
                  final selected = icon == current;
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary
                                .withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

InputDecoration _fieldDecoration(ThemeData theme, {required String label}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide:
        BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
  );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ---------------------------------------------------------------------------
// Book Name
// ---------------------------------------------------------------------------

class _BookNameSection extends ConsumerStatefulWidget {
  const _BookNameSection();

  @override
  ConsumerState<_BookNameSection> createState() => _BookNameSectionState();
}

class _BookNameSectionState extends ConsumerState<_BookNameSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(bookNameProvider).valueOrNull ?? 'Wallet Transactions');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(bookNameProvider.notifier).set(name);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Book name updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Edit Book Name'),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Flexible(
                flex: 3,
                child: TextFormField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: _fieldDecoration(theme, label: '').copyWith(
                    labelText: null,
                    hintText: 'Enter book name',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 1,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

class _CategoriesSection extends ConsumerStatefulWidget {
  const _CategoriesSection();

  @override
  ConsumerState<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends ConsumerState<_CategoriesSection> {
  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = ref.read(repositoryProvider).fetchCategoryUsageCounts();
  }

  void _showCategoryDialog(int? index, CategoryInfo? existing) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        existing: existing,
        onSave: (cat) {
          if (index == null) {
            ref.read(categoriesProvider.notifier).add(cat);
          } else {
            ref.read(categoriesProvider.notifier).edit(index, cat);
          }
        },
        onDelete: index == null
            ? null
            : () => ref.read(categoriesProvider.notifier).remove(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Edit Categories',
          actionLabel: '+ Add',
          onAction: () => _showCategoryDialog(null, null),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Auto-sorted by last use in transactions',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        FutureBuilder<Map<String, int>>(
          future: _countsFuture,
          builder: (context, snapshot) {
            final counts = snapshot.data ?? {};
            final sorted = List<CategoryInfo>.from(cats)
              ..sort((a, b) {
                final countDiff = (counts[b.name] ?? 0).compareTo(counts[a.name] ?? 0);
                if (countDiff != 0) return countDiff;
                return cats.indexWhere((c) => c.name == a.name)
                    .compareTo(cats.indexWhere((c) => c.name == b.name));
              });

            return LayoutBuilder(builder: (context, constraints) {
              const spacing = 12.0;
              const cols = 5;
              final tileWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
              final tileSize = tileWidth.clamp(52.0, 72.0);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: sorted.map((cat) {
                  final index = cats.indexWhere((c) => c.name == cat.name);
                  return _EditableCategoryTile(
                    cat: cat,
                    tileSize: tileSize,
                    onTap: () => _showCategoryDialog(index, cat),
                  );
                }).toList(),
              );
            });
          },
        ),
      ],
    );
  }
}

class _EditableCategoryTile extends StatelessWidget {
  const _EditableCategoryTile({
    required this.cat,
    required this.tileSize,
    required this.onTap,
  });

  final CategoryInfo cat;
  final double tileSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CategoryTile(
      label: cat.name,
      icon: cat.icon,
      size: tileSize,
      selected: false,
      selectedColor: theme.colorScheme.primary,
      onTap: onTap,
    );
  }
}


class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing, required this.onSave, this.onDelete});

  final CategoryInfo? existing;
  final ValueChanged<CategoryInfo> onSave;
  final VoidCallback? onDelete;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late String _classType;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _classType = widget.existing?.classType ?? classTypes.first;
    _selectedIcon = widget.existing?.icon ?? Icons.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Header block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await _pickIcon(context, _selectedIcon);
                      if (picked != null) setState(() => _selectedIcon = picked);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_selectedIcon, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEdit ? 'Edit Category' : 'Add Category',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the icon above to change it',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: SizedBox(
              height: 52,
              child: TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration(theme, label: 'Name'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: DropdownButtonFormField<String>(
              initialValue: _classType,
              decoration: _fieldDecoration(theme, label: 'Class type'),
              items: classTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _classType = v!),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          // Delete + Save row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                if (isEdit) ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.error.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                          label: const Text('Delete',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) return;
                          widget.onSave(CategoryInfo(
                            name: name,
                            icon: _selectedIcon,
                            classType: _classType,
                          ));
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(
                          isEdit ? 'Save' : 'Add',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button (1.5x width of one action button)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: isEdit ? 0.5 * 1.5 : 1.5 / 2,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment Methods
// ---------------------------------------------------------------------------

class _PaymentMethodsSection extends ConsumerWidget {
  const _PaymentMethodsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Edit Payment Methods',
          actionLabel: '+ Add',
          onAction: () => _showMethodDialog(context, ref, null, null),
        ),
        LayoutBuilder(builder: (context, constraints) {
          const cols = 3;
          const spacing = 10.0;
          final pillWidth =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: methods.asMap().entries.map((entry) {
              final i = entry.key;
              final method = entry.value;
              return SizedBox(
                width: pillWidth,
                height: 48,
                child: _EditablePaymentPill(
                  method: method,
                  onTap: () => _showMethodDialog(context, ref, i, method),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _showMethodDialog(BuildContext context, WidgetRef ref, int? index,
      PaymentMethodInfo? existing) {
    showDialog(
      context: context,
      builder: (_) => _PaymentMethodDialog(
        existing: existing,
        onSave: (method) {
          if (index == null) {
            ref.read(paymentMethodsProvider.notifier).add(method);
          } else {
            ref.read(paymentMethodsProvider.notifier).edit(index, method);
          }
        },
        onDelete: index == null
            ? null
            : () => ref.read(paymentMethodsProvider.notifier).remove(index),
      ),
    );
  }
}

class _EditablePaymentPill extends StatelessWidget {
  const _EditablePaymentPill({
    required this.method,
    required this.onTap,
  });

  final PaymentMethodInfo method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledPill(
      label: method.name,
      icon: method.icon,
      selected: false,
      onTap: onTap,
    );
  }
}

class _PaymentMethodDialog extends StatefulWidget {
  const _PaymentMethodDialog({this.existing, required this.onSave, this.onDelete});

  final PaymentMethodInfo? existing;
  final ValueChanged<PaymentMethodInfo> onSave;
  final VoidCallback? onDelete;

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? Icons.payment;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Header block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await _pickIcon(context, _selectedIcon);
                      if (picked != null) setState(() => _selectedIcon = picked);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_selectedIcon, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEdit ? 'Edit Payment Method' : 'Add Payment Method',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the icon above to change it',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: SizedBox(
              height: 52,
              child: TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration(theme, label: 'Name'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          // Delete + Save row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                if (isEdit) ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.error.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                          label: const Text('Delete',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) return;
                          widget.onSave(PaymentMethodInfo(
                            name: name,
                            icon: _selectedIcon,
                          ));
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(
                          isEdit ? 'Save' : 'Add',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button (1.5x width of one action button)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: isEdit ? 0.5 * 1.5 : 1.5 / 2,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
