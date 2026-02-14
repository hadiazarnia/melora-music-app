import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Melora Design System - Glass Container (Glassmorphism)
/// A frosted glass card with blur effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = MeloraDimens.radiusLg,
    this.blur = 20,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.onTap,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    (isDark
                        ? Colors.white.withOpacity(opacity)
                        : Colors.white.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      borderColor ??
                      (isDark
                          ? MeloraColors.glassBorder
                          : MeloraColors.lightBorder),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
