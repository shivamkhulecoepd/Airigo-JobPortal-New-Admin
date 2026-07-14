// ============================================================
// core/extensions/extensions.dart
// Helpful extensions on BuildContext, String, int, etc.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── BuildContext Extensions ──────────────────────────────────
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── String Extensions ────────────────────────────────────────
extension StringExtensions on String {
  /// Placeholder for localization — replace with real i18n later
  String get tr => this;

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(replaceAll(' ', ''));
}

// ── int / double Extensions ───────────────────────────────────
extension NumExtensions on num {
  String get asCurrency {
    if (this >= 100000) {
      return '₹${(this / 100000).toStringAsFixed(1)}L';
    } else if (this >= 1000) {
      return '₹${(this / 1000).toStringAsFixed(0)}K';
    }
    return '₹$this';
  }

  String get asLPA => '${toStringAsFixed(1)} LPA';
}

// ── DateTime Extensions ───────────────────────────────────────
extension DateTimeExtensions on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 30) return DateFormat('d MMM yyyy').format(this);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String get formattedDate => DateFormat('d MMM yyyy').format(this);
  String get formattedDateTime =>
      DateFormat('d MMM yyyy, h:mm a').format(this);
}
