import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/duration_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/album_art_widget.dart';
import 'player_screen.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragOffset = 0;
  bool _isDragging = false;

  void _openFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final positionData = ref.watch(positionDataProvider).valueOrNull;

    if (currentSong == null) return const SizedBox.shrink();

    final progress = positionData?.progress ?? 0.0;

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragStart: (_) {
        setState(() {
          _isDragging = true;
          _dragOffset = 0;
        });
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        // Swipe up to open full player
        if (_dragOffset < -40 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! < -300)) {
          _openFullPlayer();
        }
        setState(() {
          _isDragging = false;
          _dragOffset = 0;
        });
      },
      onHorizontalDragEnd: (details) {
        final handler = ref.read(audioHandlerProvider);
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            handler.skipToNext();
            HapticFeedback.lightImpact();
          } else if (details.primaryVelocity! > 300) {
            handler.skipToPrevious();
            HapticFeedback.lightImpact();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          0,
          _isDragging ? _dragOffset.clamp(-30.0, 10.0) : 0,
          0,
        ),
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
                    ? MeloraColors.darkSurface.withAlpha(204)
                    : MeloraColors.lightSurface.withAlpha(217),
                borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
                border: Border.all(
                  color: context.isDark
                      ? MeloraColors.glassBorder
                      : MeloraColors.lightBorder,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Swipe indicator
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.textTertiary.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MeloraDimens.md,
                      ),
                      child: Row(
                        children: [
                          // Album art
                          Hero(
                            tag: 'album_art_${currentSong.id}',
                            child: AlbumArtWidget(
                              songId: currentSong.id,
                              size: 46,
                              borderRadius: MeloraDimens.radiusSm,
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
                                  '${currentSong.displayArtist} • ${positionData?.position.formatted ?? "0:00"}',
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
                          _MiniPlayerControls(isPlaying: isPlaying),
                        ],
                      ),
                    ),
                  ),

                  // Progress bar
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(MeloraDimens.radiusLg),
                      ),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: context.isDark
                            ? Colors.white.withAlpha(13)
                            : Colors.black.withAlpha(13),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          MeloraColors.primary,
                        ),
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

class _MiniPlayerControls extends ConsumerWidget {
  final bool isPlaying;

  const _MiniPlayerControls({required this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous
        IconButton(
          onPressed: () {
            ref.read(audioHandlerProvider).skipToPrevious();
            HapticFeedback.lightImpact();
          },
          icon: Icon(Iconsax.previous, size: 20, color: context.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),

        // Play/Pause
        GestureDetector(
          onLongPress: () {
            ref.read(audioHandlerProvider).stop();
            HapticFeedback.heavyImpact();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MeloraColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: MeloraColors.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                final handler = ref.read(audioHandlerProvider);
                isPlaying ? handler.pause() : handler.play();
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
                color: Colors.white,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ),

        // Next
        IconButton(
          onPressed: () {
            ref.read(audioHandlerProvider).skipToNext();
            HapticFeedback.lightImpact();
          },
          icon: Icon(Iconsax.next, size: 20, color: context.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}
