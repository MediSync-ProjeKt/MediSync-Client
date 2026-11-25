import 'package:flutter/material.dart';

/// Clinical Minimalism + Ambient Intelligence Color Palette
abstract class AppColors {
  // Primary clinical accents
  static const Color primary = Color(0xFF176B67); // Deep Teal
  static const Color primaryDark = Color(0xFF104F4C);
  static const Color primaryLight = Color(0xFF238E89);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF7F8F5); // Warm Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceSecondary = Color(0xFFDCEBE3); // Soft Sage
  static const Color surfaceSubtle = Color(0xFFEFF4F1);
  static const Color surfaceTinted = Color(0xFFF0F6F3);

  // Typography & Text
  static const Color textPrimary = Color(0xFF202B2A); // Deep Charcoal
  static const Color textSecondary = Color(0xFF75817E); // Muted Slate
  static const Color textTertiary = Color(0xFF9EABA7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE6EAE6); // Soft Neutral
  static const Color borderFocused = Color(0xFF176B67);
  static const Color divider = Color(0xFFEDF1ED);

  // Clinical Status & Indicators (accessible, high contrast)
  static const Color success = Color(0xFF2E7D5B); // Muted Green
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successBorder = Color(0xFFC8E6C9);

  static const Color warning = Color(0xFFB45309); // Soft Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color critical = Color(0xFFC53030); // Muted Coral Red
  static const Color criticalLight = Color(0xFFFDE8E8);
  static const Color criticalBorder = Color(0xFFF8B4B4);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Shadows
  static const BoxShadow subtleShadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 12,
    offset: Offset(0, 3),
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
