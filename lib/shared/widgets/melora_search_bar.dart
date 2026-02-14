import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';

/// Melora Design System - Search Bar Component
class MeloraSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? trailing;

  const MeloraSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search music, artists...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurfaceLight
            : MeloraColors.lightSurfaceLight,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: context.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: context.textTertiary,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal_1,
            size: 20,
            color: context.textTertiary,
          ),
          suffixIcon: trailing,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MeloraDimens.lg,
            vertical: MeloraDimens.md,
          ),
        ),
      ),
    );
  }
}
