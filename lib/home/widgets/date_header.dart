import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  const DateHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
