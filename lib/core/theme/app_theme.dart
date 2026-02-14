import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import 'app_text_theme.dart';

/// Melora Design System - App Theme
class MeloraTheme {
  MeloraTheme._();

  // ═══════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: MeloraColors.darkBg,
    textTheme: MeloraTextTheme.darkTextTheme,
    colorScheme: const ColorScheme.dark(
      primary: MeloraColors.primary,
      secondary: MeloraColors.secondary,
      tertiary: MeloraColors.accent,
      surface: MeloraColors.darkSurface,
      error: MeloraColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: MeloraColors.darkTextPrimary,
      onError: Colors.white,
      outline: MeloraColors.darkBorder,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MeloraColors.darkTextPrimary,
      ),
      iconTheme: IconThemeData(color: MeloraColors.darkTextPrimary, size: 24),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: MeloraColors.primary,
      unselectedItemColor: MeloraColors.darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: MeloraColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
        side: const BorderSide(color: MeloraColors.darkBorder, width: 0.5),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MeloraColors.darkSurface,
      modalBackgroundColor: MeloraColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MeloraDimens.bottomSheetRadius),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: MeloraColors.darkBorder,
      dragHandleSize: Size(40, 4),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MeloraColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, MeloraDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MeloraColors.darkTextPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, MeloraDimens.buttonHeight),
        side: const BorderSide(color: MeloraColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MeloraColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: MeloraColors.darkTextPrimary,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MeloraColors.darkSurfaceLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MeloraDimens.lg,
        vertical: MeloraDimens.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: const BorderSide(
          color: MeloraColors.darkBorder,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: const BorderSide(color: MeloraColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: MeloraColors.darkTextTertiary,
        fontSize: 14,
      ),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: MeloraColors.primary,
      inactiveTrackColor: MeloraColors.darkBorder,
      thumbColor: MeloraColors.primary,
      overlayColor: MeloraColors.primary.withOpacity(0.15),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MeloraColors.primary;
        }
        return MeloraColors.darkTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MeloraColors.primary.withOpacity(0.3);
        }
        return MeloraColors.darkBorder;
      }),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: MeloraColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MeloraColors.darkTextPrimary,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: MeloraColors.darkBorder,
      thickness: 0.5,
      space: 0,
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: MeloraColors.primary,
      unselectedLabelColor: MeloraColors.darkTextTertiary,
      indicatorColor: MeloraColors.primary,
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
        color: MeloraColors.primary.withOpacity(0.15),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: MeloraColors.darkSurfaceLight,
      selectedColor: MeloraColors.primary.withOpacity(0.2),
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: MeloraColors.darkTextSecondary,
      ),
      side: const BorderSide(color: MeloraColors.darkBorder, width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
      ),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MeloraColors.darkSurfaceLight,
      contentTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: MeloraColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: MeloraDimens.pagePadding,
        vertical: MeloraDimens.xs,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: MeloraColors.darkTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: MeloraColors.darkTextSecondary,
      ),
      iconColor: MeloraColors.darkTextSecondary,
    ),
  );

  // ═══════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: MeloraColors.lightBg,
    textTheme: MeloraTextTheme.lightTextTheme,
    colorScheme: const ColorScheme.light(
      primary: MeloraColors.primary,
      secondary: MeloraColors.secondary,
      tertiary: MeloraColors.accent,
      surface: MeloraColors.lightSurface,
      error: MeloraColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: MeloraColors.lightTextPrimary,
      onError: Colors.white,
      outline: MeloraColors.lightBorder,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MeloraColors.lightTextPrimary,
      ),
      iconTheme: IconThemeData(color: MeloraColors.lightTextPrimary, size: 24),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: MeloraColors.primary,
      unselectedItemColor: MeloraColors.lightTextTertiary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    cardTheme: CardThemeData(
      color: MeloraColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
        side: const BorderSide(color: MeloraColors.lightBorder, width: 0.5),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MeloraColors.lightSurface,
      modalBackgroundColor: MeloraColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MeloraDimens.bottomSheetRadius),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: MeloraColors.lightBorder,
      dragHandleSize: Size(40, 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MeloraColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, MeloraDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MeloraColors.lightTextPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, MeloraDimens.buttonHeight),
        side: const BorderSide(color: MeloraColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MeloraColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MeloraColors.lightSurfaceLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MeloraDimens.lg,
        vertical: MeloraDimens.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: const BorderSide(
          color: MeloraColors.lightBorder,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        borderSide: const BorderSide(color: MeloraColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: MeloraColors.lightTextTertiary,
        fontSize: 14,
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: MeloraColors.primary,
      inactiveTrackColor: MeloraColors.lightBorder,
      thumbColor: MeloraColors.primary,
      overlayColor: MeloraColors.primary.withOpacity(0.15),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MeloraColors.primary;
        }
        return MeloraColors.lightTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MeloraColors.primary.withOpacity(0.3);
        }
        return MeloraColors.lightBorder;
      }),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: MeloraColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MeloraColors.lightTextPrimary,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: MeloraColors.lightBorder,
      thickness: 0.5,
      space: 0,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: MeloraColors.primary,
      unselectedLabelColor: MeloraColors.lightTextTertiary,
      indicatorColor: MeloraColors.primary,
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
        color: MeloraColors.primary.withOpacity(0.1),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: MeloraColors.lightSurfaceLight,
      selectedColor: MeloraColors.primary.withOpacity(0.1),
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: MeloraColors.lightTextSecondary,
      ),
      side: const BorderSide(color: MeloraColors.lightBorder, width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: MeloraColors.lightTextPrimary,
      contentTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: MeloraDimens.pagePadding,
        vertical: MeloraDimens.xs,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: MeloraColors.lightTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: MeloraColors.lightTextSecondary,
      ),
      iconColor: MeloraColors.lightTextSecondary,
    ),
  );
}
