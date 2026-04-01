import 'package:flutter/material.dart';

class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.isIncome,
    required this.controller,
    this.validator,
  });

  final bool isIncome;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                color: widget.isIncome
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _focusNode.hasFocus ? '' : '0.00',
                  hintStyle: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  contentPadding: EdgeInsets.zero,
                  errorStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                validator: widget.validator,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
