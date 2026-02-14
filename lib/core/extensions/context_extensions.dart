import 'package:flutter/material.dart';

/// Context extensions for easy access to theme, colors, and media query
extension BuildContextX on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Colors shorthand
  Color get primaryColor => colorScheme.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get bgColor => theme.scaffoldBackgroundColor;
  Color get borderColor => colorScheme.outline;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary =>
      isDark ? const Color(0xFF9898B0) : const Color(0xFF6B6B82);
  Color get textTertiary =>
      isDark ? const Color(0xFF6B6B82) : const Color(0xFF9898B0);
  Color get cardColor =>
      isDark ? const Color(0xFF16162A) : const Color(0xFFFFFFFF);

  // MediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  EdgeInsets get padding => mediaQuery.padding;
  double get bottomPadding => mediaQuery.padding.bottom;
  double get topPadding => mediaQuery.padding.top;
}
