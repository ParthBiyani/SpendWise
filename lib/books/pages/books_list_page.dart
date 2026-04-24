import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/books/utils/book_icon_picker.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/utils/toast_utils.dart';
import 'package:spendwise/homepage.dart';
import 'package:spendwise/providers.dart';


class BooksListPage extends ConsumerWidget {
  const BooksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booksAsync = ref.watch(booksListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('SpendWise'),
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load books: $e')),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No books yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first book'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: books.length + 3,
            itemBuilder: (context, index) {
              // index 0 — overall summary card
              if (index == 0) {
                return _OverallSummaryCard(books: books);
              }
              // index 1 — section heading
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 5),
                  child: Text(
                    'YOUR BOOKS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }
              // last index — add new book tile
              if (index == books.length + 2) {
                return _AddNewBookTile(onTap: () => _showCreateDialog(context, ref));
              }
              final book = books[index - 2];
              return _BookCard(
                book: book,
                onTap: () => _openBook(context, ref, book),
              );
            },
          );
        },
      ),
    );
  }

  void _openBook(BuildContext context, WidgetRef ref, Book book) {
    ref.read(activeBookIdProvider.notifier).state = book.id;
    ref.read(filterStateProvider.notifier).reset();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomePage()))
        .then((_) {
      ref.read(activeBookIdProvider.notifier).state = null;
    });
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, IconData icon})>(
      context: context,
      builder: (_) => const _BookDialog(),
    );
    if (result == null || result.name.trim().isEmpty) return;
    try {
      await ref.read(booksRepositoryProvider).create(result.name.trim(), icon: result.icon);
    } catch (e) {
      if (context.mounted) showAppToast(context, 'Failed to create book: $e');
    }
  }
}


InputDecoration _bookFieldDecoration(ThemeData theme, {required String label}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
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
// Book dialog — create
// ---------------------------------------------------------------------------

class _BookDialog extends StatefulWidget {
  const _BookDialog();

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.menu_book_outlined;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await pickBookIcon(context, _selectedIcon);
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
                    'New Book',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the icon above to change it',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Name field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SizedBox(
              height: 52,
              child: TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: _bookFieldDecoration(theme, label: 'Book name'),
                onFieldSubmitted: (_) => _submit(context),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          // Create button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
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
                  onPressed: () => _submit(context),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text(
                    'Create',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          // Cancel button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.75,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, icon: _selectedIcon));
  }
}

// ---------------------------------------------------------------------------
// Add new book tile
// ---------------------------------------------------------------------------

class _AddNewBookTile extends StatelessWidget {
  const _AddNewBookTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Card widget adds 4px margin on all sides by default — match it
        margin: const EdgeInsets.all(4),
        child: const CustomPaint(
          painter: _DashedBorderPainter(
            color: appPrimaryColor,
            borderRadius: 12,
            dashWidth: 6,
            dashSpace: 4,
          ),
          child: SizedBox(
            width: double.infinity,
            // CircleAvatar default height (40) + vertical padding (16+16) = 72
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: appPrimaryColor, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add New Book',
                  style: TextStyle(
                    color: appPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}

// ---------------------------------------------------------------------------
// Book card
// ---------------------------------------------------------------------------

class _BookCard extends ConsumerWidget {
  const _BookCard({
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  IconData(book.iconCodePoint, fontFamily: book.iconFontFamily),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last edited on ${formatDate(book.updatedAt)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _BookBalanceDisplay(bookId: book.id),
            ],
          ),
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Overall summary card — aggregates totals across all books
// ---------------------------------------------------------------------------

class _OverallSummaryCard extends ConsumerStatefulWidget {
  const _OverallSummaryCard({required this.books});

  final List<Book> books;

  @override
  ConsumerState<_OverallSummaryCard> createState() => _OverallSummaryCardState();
}

class _OverallSummaryCardState extends ConsumerState<_OverallSummaryCard> {
  bool _showAmounts = false;

  void _toggle() => setState(() => _showAmounts = !_showAmounts);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalIncome = 0;
    double totalExpense = 0;
    bool loading = false;

    for (final book in widget.books) {
      final statsAsync = ref.watch(_bookStatsFamilyProvider(book.id));
      statsAsync.when(
        loading: () => loading = true,
        error: (_, _) {},
        data: (s) {
          totalIncome += s.totalIncome;
          totalExpense += s.totalExpense;
        },
      );
    }

    final net = totalIncome - totalExpense;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
            child: loading
                ? const Center(
                    heightFactor: 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Text(
                        'Overall Net Balance',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _toggle,
                        child: Text(
                          _showAmounts ? formatCurrency(net) : '₹ ● ● ● ●',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Total Money In',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _toggle,
                                    child: Text(
                                      _showAmounts ? formatCurrency(totalIncome) : '₹ ● ● ●',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: appIncomeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Total Money Out',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _toggle,
                                    child: Text(
                                      _showAmounts ? formatCurrency(totalExpense) : '₹ ● ● ●',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: appExpenseColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total books: ${widget.books.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Balance display — loaded asynchronously per card
// ---------------------------------------------------------------------------

final _bookStatsFamilyProvider = StreamProvider.family<
    ({int count, double totalIncome, double totalExpense}), int>((ref, bookId) {
  return ref.watch(booksRepositoryProvider).watchStats(bookId);
});

class _BookBalanceDisplay extends ConsumerWidget {
  const _BookBalanceDisplay({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(_bookStatsFamilyProvider(bookId));

    return statsAsync.when(
      loading: () => const SizedBox(width: 72),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        final balance = stats.totalIncome - stats.totalExpense;
        final color = balance >= 0 ? appIncomeColor : appExpenseColor;
        return Text(
          formatCurrency(balance),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        );
      },
    );
  }
}
