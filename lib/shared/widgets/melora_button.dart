import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum MeloraButtonVariant { primary, secondary, outlined, ghost, gradient }

enum MeloraButtonSize { small, medium, large }

/// Melora Design System - Button Component
class MeloraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final MeloraButtonVariant variant;
  final MeloraButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? borderRadius;
  final Widget? prefix;
  final Widget? suffix;

  const MeloraButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = MeloraButtonVariant.primary,
    this.size = MeloraButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.borderRadius,
    this.prefix,
    this.suffix,
  });

  double get _height {
    switch (size) {
      case MeloraButtonSize.small:
        return MeloraDimens.buttonHeightSm;
      case MeloraButtonSize.medium:
        return MeloraDimens.buttonHeight;
      case MeloraButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (size) {
      case MeloraButtonSize.small:
        return 13;
      case MeloraButtonSize.medium:
        return 15;
      case MeloraButtonSize.large:
        return 17;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? MeloraDimens.radiusMd;

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(isDark),
            ),
          ),
          const SizedBox(width: MeloraDimens.sm),
        ],
        if (prefix != null && !isLoading) ...[
          prefix!,
          const SizedBox(width: MeloraDimens.sm),
        ],
        if (icon != null && !isLoading) ...[
          Icon(icon, size: _fontSize + 4, color: _foregroundColor(isDark)),
          const SizedBox(width: MeloraDimens.sm),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: _foregroundColor(isDark),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: MeloraDimens.sm),
          suffix!,
        ],
      ],
    );

    if (variant == MeloraButtonVariant.gradient) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: MeloraColors.primaryGradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: MeloraColors.primary.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onPressed?.call();
                    },
              borderRadius: BorderRadius.circular(radius),
              child: Center(child: buttonChild),
            ),
          ),
        ),
      );
    }

    switch (variant) {
      case MeloraButtonVariant.primary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: _height,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              elevation: 0,
            ),
            child: buttonChild,
          ),
        );

      case MeloraButtonVariant.secondary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: _height,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: MeloraColors.primary.withAlpha(38),
              foregroundColor: MeloraColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              elevation: 0,
            ),
            child: buttonChild,
          ),
        );

      case MeloraButtonVariant.outlined:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: _height,
          child: OutlinedButton(
            onPressed: isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case MeloraButtonVariant.ghost:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: _height,
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  },
            child: buttonChild,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _foregroundColor(bool isDark) {
    switch (variant) {
      case MeloraButtonVariant.primary:
      case MeloraButtonVariant.gradient:
        return Colors.white;
      case MeloraButtonVariant.secondary:
        return MeloraColors.primary;
      case MeloraButtonVariant.outlined:
        return isDark
            ? MeloraColors.darkTextPrimary
            : MeloraColors.lightTextPrimary;
      case MeloraButtonVariant.ghost:
        return MeloraColors.primary;
    }
  }
}
