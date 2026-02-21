import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

class MeloraTheme {
  MeloraTheme._();

  // ─── Dark Theme ─────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MeloraColors.darkBg,
      primaryColor: MeloraColors.primary,

      colorScheme: const ColorScheme.dark(
        primary: MeloraColors.primary,
        secondary: MeloraColors.secondary,
        surface: MeloraColors.darkSurface,
        error: MeloraColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: MeloraColors.darkTextPrimary,
        outline: MeloraColors.darkBorder,
      ),

      fontFamily: 'Outfit',

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: MeloraColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: MeloraColors.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: MeloraColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeloraColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: MeloraColors.darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: MeloraColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: MeloraColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: MeloraColors.darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: MeloraColors.darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MeloraColors.darkTextPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: MeloraColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeloraColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: MeloraColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MeloraColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: MeloraDimens.xl,
            vertical: MeloraDimens.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: MeloraColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: MeloraColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MeloraColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MeloraDimens.bottomSheetRadius),
          ),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: MeloraColors.primary,
        inactiveTrackColor: MeloraColors.darkBorder,
        thumbColor: MeloraColors.primary,
        overlayColor: MeloraColors.primary.withAlpha(51),
        trackHeight: 4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MeloraColors.primary;
          }
          return MeloraColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MeloraColors.primary.withAlpha(77);
          }
          return MeloraColors.darkBorder;
        }),
      ),

      dividerTheme: DividerThemeData(
        color: MeloraColors.darkBorder.withAlpha(128),
        thickness: 0.5,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: MeloraDimens.pagePadding,
          vertical: MeloraDimens.xs,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: MeloraColors.darkSurfaceLight,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: MeloraColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MeloraColors.lightBg,
      primaryColor: MeloraColors.primary,

      colorScheme: const ColorScheme.light(
        primary: MeloraColors.primary,
        secondary: MeloraColors.secondary,
        surface: MeloraColors.lightSurface,
        error: MeloraColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: MeloraColors.lightTextPrimary,
        outline: MeloraColors.lightBorder,
      ),

      fontFamily: 'Outfit',

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: MeloraColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: MeloraColors.lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: MeloraColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeloraColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: MeloraColors.lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: MeloraColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: MeloraColors.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: MeloraColors.lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: MeloraColors.lightTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MeloraColors.lightTextPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: MeloraColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeloraColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: MeloraColors.lightTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MeloraColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: MeloraDimens.xl,
            vertical: MeloraDimens.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: MeloraColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
          side: BorderSide(color: MeloraColors.lightBorder.withAlpha(128)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: MeloraColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MeloraColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MeloraDimens.bottomSheetRadius),
          ),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: MeloraColors.primary,
        inactiveTrackColor: MeloraColors.lightBorder,
        thumbColor: MeloraColors.primary,
        overlayColor: MeloraColors.primary.withAlpha(51),
        trackHeight: 4,
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
            return MeloraColors.primary.withAlpha(77);
          }
          return MeloraColors.lightBorder;
        }),
      ),

      dividerTheme: DividerThemeData(
        color: MeloraColors.lightBorder.withAlpha(128),
        thickness: 0.5,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: MeloraDimens.pagePadding,
          vertical: MeloraDimens.xs,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: MeloraColors.lightSurfaceLight,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: MeloraColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
