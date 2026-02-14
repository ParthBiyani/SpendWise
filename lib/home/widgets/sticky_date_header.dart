import 'package:flutter/material.dart';

class StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  StickyDateHeaderDelegate({
    required this.label,
    required this.theme,
  });

  final String label;
  final ThemeData theme;

  @override
  double get minExtent => 32.0;

  @override
  double get maxExtent => 32.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(StickyDateHeaderDelegate oldDelegate) {
    return label != oldDelegate.label;
  }
}
