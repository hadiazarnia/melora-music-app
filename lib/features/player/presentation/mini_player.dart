import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:melora_music/features/player/presentation/player_screen.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../shared/providers/app_providers.dart';

/// Mini Player shown above bottom navigation
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final positionData = ref.watch(positionDataProvider).valueOrNull;

    if (currentSong == null) return const SizedBox.shrink();

    final progress =
        positionData != null && positionData.duration.inMilliseconds > 0
        ? positionData.position.inMilliseconds /
              positionData.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PlayerScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      onHorizontalDragEnd: (details) {
        final handler = ref.read(audioHandlerProvider);
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            handler.skipToNext();
            HapticFeedback.lightImpact();
          } else if (details.primaryVelocity! > 200) {
            handler.skipToPrevious();
            HapticFeedback.lightImpact();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MeloraDimens.md,
          vertical: MeloraDimens.xs,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MeloraDimens.miniPlayerHeight,
              decoration: BoxDecoration(
                color: context.isDark
                    ? MeloraColors.darkSurface.withOpacity(0.8)
                    : MeloraColors.lightSurface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
                border: Border.all(
                  color: context.isDark
                      ? MeloraColors.glassBorder
                      : MeloraColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MeloraDimens.md,
                      ),
                      child: Row(
                        children: [
                          // Cover art
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                MeloraDimens.radiusSm,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  MeloraColors.primary.withOpacity(0.4),
                                  MeloraColors.secondary.withOpacity(0.4),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Iconsax.music,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: MeloraDimens.md),

                          // Song info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentSong.displayArtist} · ${positionData?.position.formatted ?? "0:00"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Controls
                          IconButton(
                            onPressed: () {
                              ref.read(audioHandlerProvider).skipToPrevious();
                              HapticFeedback.lightImpact();
                            },
                            icon: Icon(
                              Iconsax.previous,
                              size: 20,
                              color: context.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          GestureDetector(
                            onLongPress: () {
                              // Hold to stop
                              ref.read(audioHandlerProvider).stop();
                              HapticFeedback.heavyImpact();
                            },
                            child: IconButton(
                              onPressed: () {
                                final handler = ref.read(audioHandlerProvider);
                                isPlaying ? handler.pause() : handler.play();
                                HapticFeedback.lightImpact();
                              },
                              icon: Icon(
                                isPlaying ? Iconsax.pause : Iconsax.play,
                                size: 28,
                                color: MeloraColors.primary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(audioHandlerProvider).skipToNext();
                              HapticFeedback.lightImpact();
                            },
                            icon: Icon(
                              Iconsax.next,
                              size: 20,
                              color: context.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress bar
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(MeloraDimens.radiusLg),
                    ),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        MeloraColors.primary,
                      ),
                    ),
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
