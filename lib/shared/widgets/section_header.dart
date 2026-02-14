import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';

/// Melora Design System - Section Header with title and "More" button
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMorePressed;
  final String moreText;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.onMorePressed,
    this.moreText = 'More',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.textTheme.headlineSmall),
          if (trailing != null)
            trailing!
          else if (onMorePressed != null)
            TextButton(
              onPressed: onMorePressed,
              style: TextButton.styleFrom(
                foregroundColor: MeloraColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: MeloraDimens.sm,
                ),
              ),
              child: Text(
                moreText,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
