import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum MeloraIconButtonVariant { filled, ghost, glass }

/// Melora Design System - Icon Button Component
class MeloraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final MeloraIconButtonVariant variant;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool isActive;

  const MeloraIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = MeloraIconButtonVariant.ghost,
    this.size = 44,
    this.iconSize = MeloraDimens.iconMd,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isActive
        ? MeloraColors.primary
        : color ??
              (isDark
                  ? MeloraColors.darkTextPrimary
                  : MeloraColors.lightTextPrimary);

    Widget child;

    switch (variant) {
      case MeloraIconButtonVariant.filled:
        child = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isDark
                    ? MeloraColors.darkSurfaceLight
                    : MeloraColors.lightSurfaceLight),
            borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
            border: Border.all(
              color: isDark
                  ? MeloraColors.darkBorder
                  : MeloraColors.lightBorder,
              width: 0.5,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize, color: iconColor),
            padding: EdgeInsets.zero,
          ),
        );
        break;

      case MeloraIconButtonVariant.glass:
        child = ClipRRect(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(icon, size: iconSize, color: iconColor),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        );
        break;

      case MeloraIconButtonVariant.ghost:
      default:
        child = SizedBox(
          width: size,
          height: size,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize, color: iconColor),
            padding: EdgeInsets.zero,
          ),
        );
        break;
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
