import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/duration_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/audio_wave_animation.dart';
import '../../../shared/widgets/melora_bottom_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final positionData = ref.watch(positionDataProvider).valueOrNull;
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffleOn = ref.watch(shuffleEnabledProvider).valueOrNull ?? false;
    final volume = ref.watch(volumeProvider).valueOrNull ?? 1.0;

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text('No song selected')));
    }

    final position = positionData?.position ?? Duration.zero;
    final duration = positionData?.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Animated Background ──────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + _bgController.value * 2, -1),
                    end: Alignment(1 - _bgController.value * 0.5, 1),
                    colors: [
                      MeloraColors.primary.withOpacity(0.4),
                      MeloraColors.darkBg,
                      MeloraColors.secondary.withOpacity(0.2),
                      MeloraColors.darkBg,
                    ],
                  ),
                ),
              );
            },
          ),

          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // ─── Content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ─── Top Bar ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeloraDimens.sm,
                    vertical: MeloraDimens.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Iconsax.arrow_down_1,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              currentSong.displayAlbum,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          MeloraBottomSheet.showSongMenu(
                            context: context,
                            songTitle: currentSong.displayTitle,
                            artist: currentSong.displayArtist,
                          );
                        },
                        icon: const Icon(
                          Iconsax.more,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const Spacer(flex: 1),

                // ─── Cover Art ──────────────────────────
                GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        final handler = ref.read(audioHandlerProvider);
                        if (details.primaryVelocity! < -200) {
                          handler.skipToNext();
                          HapticFeedback.mediumImpact();
                        } else if (details.primaryVelocity! > 200) {
                          handler.skipToPrevious();
                          HapticFeedback.mediumImpact();
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! < -300) {
                          // Swipe up to show queue
                          _showQueueSheet(context);
                        }
                      },
                      child: Container(
                        width: MeloraDimens.coverXl,
                        height: MeloraDimens.coverXl,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              MeloraColors.primary.withOpacity(0.3),
                              MeloraColors.secondary.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MeloraColors.primary.withOpacity(0.25),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Iconsax.music,
                                size: 80,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              // Decorative circles
                              Positioned(
                                top: 30,
                                right: 30,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOut,
                    ),

                const Spacer(flex: 1),

                // ─── Song Info ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeloraDimens.xxxl,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong.displayArtist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Favorite
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                            icon: Icon(
                              currentSong.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              color: currentSong.isFavorite
                                  ? MeloraColors.secondary
                                  : Colors.white.withOpacity(0.6),
                              size: 26,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Iconsax.info_circle,
                              color: Colors.white.withOpacity(0.6),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: MeloraDimens.xxl),

                // ─── Duration Seek Bar ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeloraDimens.xxl,
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: MeloraColors.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.12),
                          thumbColor: MeloraColors.primary,
                          overlayColor: MeloraColors.primary.withOpacity(0.15),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                        ),
                        child: Slider(
                          value: _isDragging
                              ? _dragValue
                              : progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = v;
                            });
                            HapticFeedback.selectionClick();
                          },
                          onChangeEnd: (v) {
                            final handler = ref.read(audioHandlerProvider);
                            handler.seek(
                              Duration(
                                milliseconds: (v * duration.inMilliseconds)
                                    .round(),
                              ),
                            );
                            setState(() => _isDragging = false);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              position.formatted,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              duration.formatted,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: MeloraDimens.md),

                // ─── Controls ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeloraDimens.xxl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      IconButton(
                        onPressed: () {
                          ref.read(audioHandlerProvider).toggleShuffle();
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          Iconsax.shuffle,
                          size: 22,
                          color: shuffleOn
                              ? MeloraColors.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),

                      // Skip backward
                      IconButton(
                        onPressed: () {
                          ref.read(audioHandlerProvider).skipToPrevious();
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(
                          Iconsax.previous,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      // Play/Pause
                      GestureDetector(
                        onLongPress: () {
                          ref.read(audioHandlerProvider).stop();
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: MeloraColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: MeloraColors.primary.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              final handler = ref.read(audioHandlerProvider);
                              isPlaying ? handler.pause() : handler.play();
                              HapticFeedback.mediumImpact();
                            },
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Skip forward
                      IconButton(
                        onPressed: () {
                          ref.read(audioHandlerProvider).skipToNext();
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(
                          Iconsax.next,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      // Repeat
                      IconButton(
                        onPressed: () {
                          final handler = ref.read(audioHandlerProvider);
                          final nextMode = {
                            LoopMode.off: LoopMode.all,
                            LoopMode.all: LoopMode.one,
                            LoopMode.one: LoopMode.off,
                          }[loopMode]!;
                          handler.setRepeatMode(
                            nextMode as AudioServiceRepeatMode,
                          );
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          loopMode == LoopMode.one
                              ? Iconsax.repeate_one
                              : Iconsax.repeat,
                          size: 22,
                          color: loopMode != LoopMode.off
                              ? MeloraColors.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: MeloraDimens.xxl),

                // ─── Volume Slider ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeloraDimens.xxxl,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.volume_low,
                        size: 18,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white.withOpacity(0.5),
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                            thumbColor: Colors.white,
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                          ),
                          child: Slider(
                            value: volume.clamp(0.0, 1.0),
                            onChanged: (v) {
                              ref.read(audioHandlerProvider).setVolume(v);
                              if ((v * 10).round() != ((volume * 10).round())) {
                                HapticFeedback.selectionClick();
                              }
                            },
                          ),
                        ),
                      ),
                      Icon(
                        Iconsax.volume_high,
                        size: 18,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: MeloraDimens.lg),

                // ─── Bottom Wave ────────────────────────
                AudioWaveAnimation(
                  isPlaying: isPlaying,
                  color: MeloraColors.primary.withOpacity(0.25),
                  height: 30,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: MeloraDimens.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    final handler = ref.read(audioHandlerProvider);
    MeloraBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(MeloraDimens.pagePadding),
            child: Text(
              'Playing Queue',
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          if (handler.currentPlaylist.isEmpty)
            Padding(
              padding: const EdgeInsets.all(MeloraDimens.xxxl),
              child: Text(
                'Queue is empty',
                style: TextStyle(color: context.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: handler.currentPlaylist.length,
                itemBuilder: (ctx, i) {
                  final song = handler.currentPlaylist[i];
                  final isCurrent = i == handler.currentIndex;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isCurrent
                            ? MeloraColors.primary.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                      ),
                      child: Icon(
                        isCurrent ? Iconsax.music_play : Iconsax.music,
                        size: 18,
                        color: isCurrent
                            ? MeloraColors.primary
                            : context.textTertiary,
                      ),
                    ),
                    title: Text(
                      song.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCurrent
                            ? MeloraColors.primary
                            : context.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      song.displayArtist,
                      style: context.textTheme.bodySmall,
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    );
  }
}
