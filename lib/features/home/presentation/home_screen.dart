import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/melora_search_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/melora_icon_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MeloraDimens.pagePadding,
                MeloraDimens.lg,
                MeloraDimens.pagePadding,
                MeloraDimens.md,
              ),
              child: Row(
                children: [
                  // App name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Melora',
                          style: context.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        Text(
                          'Feel the Music',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: MeloraColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      ],
                    ),
                  ),

                  // Notification
                  MeloraIconButton(
                    icon: Iconsax.notification,
                    variant: MeloraIconButtonVariant.filled,
                    onPressed: () {},
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(width: MeloraDimens.sm),

                  // Favorites
                  MeloraIconButton(
                    icon: Iconsax.heart,
                    variant: MeloraIconButtonVariant.filled,
                    onPressed: () {},
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                  const SizedBox(width: MeloraDimens.sm),

                  // Profile avatar
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          MeloraDimens.radiusMd,
                        ),
                        gradient: MeloraColors.primaryGradient,
                      ),
                      child: const Icon(
                        Iconsax.profile_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                ],
              ),
            ),
          ),

          // ─── Search Bar ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: const MeloraSearchBar(readOnly: true)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xl)),

          // ─── Featured Slider ────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: PageView.builder(
                padEnds: false,
                controller: PageController(viewportFraction: 0.88),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0
                          ? MeloraDimens.pagePadding
                          : MeloraDimens.sm,
                      right: MeloraDimens.sm,
                    ),
                    child: _FeaturedCard(index: index),
                  );
                },
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xxl)),

          // ─── Trending ───────────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(title: 'Trending Now', onMorePressed: () {}),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MeloraDimens.pagePadding,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: MeloraDimens.md),
                    child: _MusicCard(index: index),
                  );
                },
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xxl)),

          // ─── Recently Played ────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recently Played',
              onMorePressed: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MeloraDimens.pagePadding,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: MeloraDimens.md),
                    child: _MusicCard(index: index + 6),
                  );
                },
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xxl)),

          // ─── Recommended ────────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(title: 'Recommended', onMorePressed: () {}),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MeloraDimens.pagePadding,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: MeloraDimens.md),
                    child: _MusicCard(index: index + 12),
                  );
                },
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
          ),

          // Bottom space for mini player + nav
          const SliverToBoxAdapter(child: SizedBox(height: 180)),
        ],
      ),
    );
  }
}

// ─── Featured Card (Placeholder) ────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final int index;
  const _FeaturedCard({required this.index});

  static const _gradients = [
    [Color(0xFF6C5CE7), Color(0xFFFF6B9D)],
    [Color(0xFF00D2FF), Color(0xFF6C5CE7)],
    [Color(0xFFFF6B9D), Color(0xFFFFB800)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(MeloraDimens.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      MeloraDimens.radiusFull,
                    ),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Featured Playlist',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover new music • 24 songs',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Music Card (Placeholder) ─────────────────────────────
class _MusicCard extends StatelessWidget {
  final int index;
  const _MusicCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF6C5CE7), const Color(0xFF8B7CF6)],
      [const Color(0xFFFF6B9D), const Color(0xFFFF8FB5)],
      [const Color(0xFF00D2FF), const Color(0xFF4DE0FF)],
      [const Color(0xFFFFB800), const Color(0xFFFFD166)],
      [const Color(0xFF00C48C), const Color(0xFF4DD8A8)],
      [const Color(0xFFFF4757), const Color(0xFFFF6B81)],
    ];
    final color = colors[index % colors.length];

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
              gradient: LinearGradient(
                colors: color,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Iconsax.music,
                size: 40,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: MeloraDimens.sm),
          // Title placeholder
          Text(
            'Song Title ${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Artist Name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
