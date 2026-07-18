// ============================================================
// core/theme/app_colors.dart
// Centralized color palette for JobSphere Admin
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A);    // Deep Slate (Professional Admin)
  static const Color secondary = Color(0xFF3B82F6);  // Soft Blue
  static const Color accent = Color(0xFF6366F1);     // Indigo
  static const Color success = Color(0xFF10B981);    // Emerald Green

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // ── Status Colors ─────────────────────────────────────────────
  static const Color statusPending = Color(0xFFF59E0B);   // Amber
  static const Color statusShortlisted = Color(0xFF3B82F6); // Blue
  static const Color statusAccepted = Color(0xFF10B981);  // Green
  static const Color statusRejected = Color(0xFFEF4444);  // Red

  // ── Misc ─────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color urgentBadge = Color(0xFFEF4444);
  static const Color heartSaved = Color(0xFFEF4444);
  static const Color heartUnsaved = Color(0xFF94A3B8);

  // ── Skill chip colors ────────────────────────────────────────
  static const List<Color> skillChipColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];
}
