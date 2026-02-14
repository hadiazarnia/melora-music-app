import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:melora_music/features/home/presentation/home_screen.dart';
import 'package:melora_music/features/offline/presentation/offline_screen.dart';
import 'package:melora_music/features/player/presentation/mini_player.dart';
import 'package:melora_music/features/profile/presentation/profile_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/providers/app_providers.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final currentSong = ref.watch(currentSongProvider);

    const screens = [HomeScreen(), OfflineScreen(), ProfileScreen()];

    return Scaffold(
      body: Stack(
        children: [
          // Screen content
          IndexedStack(index: currentIndex, children: screens),

          // Mini Player + Bottom Nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini Player
                if (currentSong.valueOrNull != null)
                  const MiniPlayer()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.5, end: 0),

                // Bottom Navigation with glass effect
                _GlassBottomNav(
                  currentIndex: currentIndex,
                  onTap: (index) {
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
                ? MeloraColors.darkBg.withOpacity(0.85)
                : MeloraColors.lightBg.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? MeloraColors.darkBorder.withOpacity(0.5)
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Iconsax.home_2,
                    activeIcon: Iconsax.home,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Iconsax.folder_2,
                    activeIcon: Iconsax.folder,
                    label: 'Offline',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Iconsax.profile_circle,
                    activeIcon: Iconsax.profile_circle,
                    label: 'Profile',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
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
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
                color: isActive
                    ? MeloraColors.primary.withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? MeloraColors.primary : context.textTertiary,
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
