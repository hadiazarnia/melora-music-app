import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../offline/presentation/offline_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../player/presentation/mini_player.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final currentSong = ref.watch(currentSongProvider);
    final hasSong = currentSong.valueOrNull != null;

    final screens = const [OfflineScreen(), SettingsScreen()];

    return Scaffold(
      body: Stack(
        children: [
          // Screen content
          IndexedStack(index: currentIndex, children: screens),

          // Mini Player + Bottom Nav (always at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini Player
                if (hasSong)
                  const MiniPlayer()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.3, end: 0),

                // Bottom Navigation
                _GlassBottomNav(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    HapticFeedback.lightImpact();
                    ref.read(mainTabIndexProvider.notifier).state = index;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? MeloraColors.darkBg.withAlpha(217)
                : MeloraColors.lightBg.withAlpha(217),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? MeloraColors.darkBorder.withAlpha(128)
                    : MeloraColors.lightBorder,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MeloraDimens.tabBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Iconsax.music_library_2_copy,
                    activeIcon: Iconsax.music_library_2,
                    label: 'Library',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Iconsax.setting_2,
                    activeIcon: Iconsax.setting,
                    label: 'Settings',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
                gradient: isActive ? MeloraColors.primaryGradient : null,
                color: isActive ? null : Colors.transparent,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? Colors.white : context.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? MeloraColors.primary : context.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
