import 'package:flutter/material.dart';

/// Melora Design System - Color Palette
/// Modern, vibrant colors with glassmorphism support
class MeloraColors {
  MeloraColors._();

  // ─── Brand Colors ───────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF6);
  static const Color primaryDark = Color(0xFF5A4BD1);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF8FB5);
  static const Color secondaryDark = Color(0xFFE85A8A);
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentLight = Color(0xFF4DE0FF);
  static const Color accentDark = Color(0xFF00B8E0);

  // ─── Dark Theme ─────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceLight = Color(0xFF252540);
  static const Color darkCard = Color(0xFF16162A);
  static const Color darkCardLight = Color(0xFF1E1E36);
  static const Color darkBorder = Color(0xFF2A2A45);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF9898B0);
  static const Color darkTextTertiary = Color(0xFF6B6B82);

  // ─── Light Theme ────────────────────────────────────────
  static const Color lightBg = Color(0xFFF8F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F0F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardLight = Color(0xFFF5F5FA);
  static const Color lightBorder = Color(0xFFE8E8F0);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B82);
  static const Color lightTextTertiary = Color(0xFF9898B0);

  // ─── Semantic Colors ────────────────────────────────────
  static const Color success = Color(0xFF00C48C);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00D2FF);

  // ─── Gradient Presets ───────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF252540), Color(0xFF1A1A2E)],
  );

  // ─── Glass Colors ──────────────────────────────────────
  static Color glassWhite = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.12);
  static Color glassHighlight = Colors.white.withOpacity(0.15);

  static Color glassBlack = Colors.black.withOpacity(0.3);
  static Color glassBorderDark = Colors.black.withOpacity(0.15);
}
