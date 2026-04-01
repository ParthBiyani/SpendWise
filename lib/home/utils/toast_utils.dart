import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Shows a dark pill toast anchored 100px above the bottom of the screen.
void showAppToast(BuildContext context, String message) {
  (FToast()..init(context)).showToast(
    toastDuration: const Duration(seconds: 2),
    positionedToastBuilder: (context, child, _) =>
        Positioned(left: 24, right: 24, bottom: 100, child: child),
    child: Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
