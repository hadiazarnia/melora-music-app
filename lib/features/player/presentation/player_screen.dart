import 'dart:ui';
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
import '../../../shared/widgets/album_art_widget.dart';
import '../../../shared/widgets/audio_wave_animation.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  bool _isDraggingSeek = false;
  double _seekValue = 0;
  double _dragStartY = 0;
  double _currentDragY = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _closePlayer() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final positionData = ref.watch(positionDataProvider).valueOrNull;
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffleOn = ref.watch(shuffleEnabledProvider).valueOrNull ?? false;
    final audioLevel = ref.watch(audioLevelProvider).valueOrNull ?? 0.0;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: MeloraColors.darkBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Iconsax.music,
                size: 64,
                color: MeloraColors.darkTextTertiary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No song selected',
                style: TextStyle(color: MeloraColors.darkTextSecondary),
              ),
              const SizedBox(height: 24),
              TextButton(onPressed: _closePlayer, child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final position = positionData?.position ?? Duration.zero;
    final duration = positionData?.duration ?? Duration.zero;
    final progress = positionData?.progress ?? 0.0;

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _currentDragY = 0;
      },
      onVerticalDragUpdate: (details) {
        _currentDragY = details.globalPosition.dy - _dragStartY;
      },
      onVerticalDragEnd: (details) {
        // Swipe down to close
        if (_currentDragY > 100 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 500)) {
          _closePlayer();
        }
      },
      child: Scaffold(
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
                        MeloraColors.primary.withAlpha(102),
                        MeloraColors.darkBg,
                        MeloraColors.secondary.withAlpha(51),
                        MeloraColors.darkBg,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.black.withAlpha(77)),
            ),

            // ─── Content ──────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ─── Top Bar ────────────────────────────
                  _TopBar(
                    album: currentSong.displayAlbum,
                    onClose: _closePlayer,
                    onOptions: () =>
                        _showPlayerOptions(context, ref, currentSong),
                  ).animate().fadeIn(duration: 400.ms),

                  const Spacer(flex: 1),

                  // ─── Album Art ──────────────────────────
                  _AlbumArtSection(
                        songId: currentSong.id,
                        onSwipeLeft: () {
                          ref.read(audioHandlerProvider).skipToNext();
                          HapticFeedback.mediumImpact();
                        },
                        onSwipeRight: () {
                          ref.read(audioHandlerProvider).skipToPrevious();
                          HapticFeedback.mediumImpact();
                        },
                        onSwipeUp: () => _showQueueSheet(context, ref),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 500.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOut,
                      ),

                  const Spacer(flex: 1),

                  // ─── Song Info ──────────────────────────
                  _SongInfoSection(
                    song: currentSong,
                    onFavoriteToggle: () async {
                      await ref.read(toggleFavoriteProvider)(currentSong.id);
                      HapticFeedback.lightImpact();
                    },
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: MeloraDimens.xxl),

                  // ─── Seek Bar ───────────────────────────
                  _SeekBarSection(
                    position: position,
                    duration: duration,
                    progress: _isDraggingSeek ? _seekValue : progress,
                    onSeekStart: (value) {
                      setState(() {
                        _isDraggingSeek = true;
                        _seekValue = value;
                      });
                    },
                    onSeekUpdate: (value) {
                      setState(() => _seekValue = value);
                      HapticFeedback.selectionClick();
                    },
                    onSeekEnd: (value) {
                      final handler = ref.read(audioHandlerProvider);
                      handler.seek(
                        Duration(
                          milliseconds: (value * duration.inMilliseconds)
                              .round(),
                        ),
                      );
                      setState(() => _isDraggingSeek = false);
                    },
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: MeloraDimens.lg),

                  // ─── Controls ───────────────────────────
                  _ControlsSection(
                    isPlaying: isPlaying,
                    shuffleOn: shuffleOn,
                    loopMode: loopMode,
                    onPlayPause: () {
                      final handler = ref.read(audioHandlerProvider);
                      isPlaying ? handler.pause() : handler.play();
                      HapticFeedback.mediumImpact();
                    },
                    onNext: () {
                      ref.read(audioHandlerProvider).skipToNext();
                      HapticFeedback.mediumImpact();
                    },
                    onPrevious: () {
                      ref.read(audioHandlerProvider).skipToPrevious();
                      HapticFeedback.mediumImpact();
                    },
                    onShuffle: () {
                      ref.read(audioHandlerProvider).toggleShuffle();
                      HapticFeedback.lightImpact();
                    },
                    onLoop: () {
                      ref.read(audioHandlerProvider).cycleLoopMode();
                      HapticFeedback.lightImpact();
                    },
                    onStop: () {
                      ref.read(audioHandlerProvider).stop();
                      HapticFeedback.heavyImpact();
                      _closePlayer();
                    },
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: MeloraDimens.xxl),

                  // ─── Bottom Actions ─────────────────────
                  _BottomActionsSection(
                    onQueue: () => _showQueueSheet(context, ref),
                    onEqualizer: () =>
                        Navigator.pushNamed(context, '/equalizer'),
                    onSleepTimer: () => _showSleepTimerSheet(context, ref),
                    onSpeed: () => _showSpeedSheet(context, ref),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: MeloraDimens.md),

                  // ─── Audio Wave ─────────────────────────
                  AudioWaveAnimation(
                    isPlaying: isPlaying,
                    audioLevel: audioLevel,
                    color: MeloraColors.primary.withAlpha(77),
                    height: 35,
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: MeloraDimens.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TOP BAR
// ═══════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String album;
  final VoidCallback onClose;
  final VoidCallback onOptions;

  const _TopBar({
    required this.album,
    required this.onClose,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MeloraDimens.sm,
        vertical: MeloraDimens.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
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
                    color: Colors.white.withAlpha(153),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  album,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withAlpha(102),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOptions,
            icon: const Icon(Iconsax.more, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ALBUM ART SECTION
// ═══════════════════════════════════════════════════════════

class _AlbumArtSection extends StatelessWidget {
  final int songId;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeUp;

  const _AlbumArtSection({
    required this.songId,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          onSwipeLeft();
        } else if (details.primaryVelocity! > 300) {
          onSwipeRight();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -300) {
          onSwipeUp();
        }
      },
      child: Hero(
        tag: 'album_art_$songId',
        child: LargeAlbumArt(songId: songId, size: MeloraDimens.coverXl),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SONG INFO SECTION
// ═══════════════════════════════════════════════════════════

class _SongInfoSection extends StatelessWidget {
  final dynamic song;
  final VoidCallback onFavoriteToggle;

  const _SongInfoSection({required this.song, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.displayTitle,
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
                  song.displayArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavoriteToggle,
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
              color: song.isFavorite
                  ? MeloraColors.secondary
                  : Colors.white.withAlpha(153),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SEEK BAR SECTION
// ═══════════════════════════════════════════════════════════

class _SeekBarSection extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final double progress;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekUpdate;
  final ValueChanged<double> onSeekEnd;

  const _SeekBarSection({
    required this.position,
    required this.duration,
    required this.progress,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MeloraColors.primary,
              inactiveTrackColor: Colors.white.withAlpha(31),
              thumbColor: MeloraColors.primary,
              overlayColor: MeloraColors.primary.withAlpha(38),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChangeStart: onSeekStart,
              onChanged: onSeekUpdate,
              onChangeEnd: onSeekEnd,
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
                    color: Colors.white.withAlpha(128),
                  ),
                ),
                Text(
                  duration.formatted,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white.withAlpha(128),
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

// ═══════════════════════════════════════════════════════════
//  CONTROLS SECTION
// ═══════════════════════════════════════════════════════════

class _ControlsSection extends StatelessWidget {
  final bool isPlaying;
  final bool shuffleOn;
  final LoopMode loopMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onShuffle;
  final VoidCallback onLoop;
  final VoidCallback onStop;

  const _ControlsSection({
    required this.isPlaying,
    required this.shuffleOn,
    required this.loopMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onLoop,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          IconButton(
            onPressed: onShuffle,
            icon: Icon(
              Iconsax.shuffle,
              size: 22,
              color: shuffleOn
                  ? MeloraColors.primary
                  : Colors.white.withAlpha(128),
            ),
          ),

          // Previous
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Iconsax.previous, size: 32, color: Colors.white),
          ),

          // Play/Pause
          GestureDetector(
            onLongPress: onStop,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: MeloraColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: MeloraColors.primary.withAlpha(102),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Next
          IconButton(
            onPressed: onNext,
            icon: const Icon(Iconsax.next, size: 32, color: Colors.white),
          ),

          // Loop
          IconButton(
            onPressed: onLoop,
            icon: Icon(
              loopMode == LoopMode.one ? Iconsax.repeate_one : Iconsax.repeat,
              size: 22,
              color: loopMode != LoopMode.off
                  ? MeloraColors.primary
                  : Colors.white.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM ACTIONS
// ═══════════════════════════════════════════════════════════

class _BottomActionsSection extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onEqualizer;
  final VoidCallback onSleepTimer;
  final VoidCallback onSpeed;

  const _BottomActionsSection({
    required this.onQueue,
    required this.onEqualizer,
    required this.onSleepTimer,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Iconsax.music_playlist,
            label: 'Queue',
            onTap: onQueue,
          ),
          _ActionButton(
            icon: Iconsax.music,
            label: 'Equalizer',
            onTap: onEqualizer,
          ),
          _ActionButton(
            icon: Iconsax.timer_1,
            label: 'Timer',
            onTap: onSleepTimer,
          ),
          _ActionButton(
            icon: Iconsax.speedometer,
            label: 'Speed',
            onTap: onSpeed,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white.withAlpha(179)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: Colors.white.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEETS
// ═══════════════════════════════════════════════════════════

void _showPlayerOptions(BuildContext context, WidgetRef ref, dynamic song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: MeloraColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MeloraColors.darkTextTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          ListTile(
            leading: const Icon(Iconsax.info_circle),
            title: const Text('Song Info'),
            onTap: () {
              Navigator.pop(ctx);
              _showSongInfoDialog(context, song);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.share),
            title: const Text('Share'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Iconsax.add_circle),
            title: const Text('Add to Playlist'),
            onTap: () => Navigator.pop(ctx),
          ),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    ),
  );
}

void _showQueueSheet(BuildContext context, WidgetRef ref) {
  final handler = ref.read(audioHandlerProvider);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: MeloraColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MeloraColors.darkTextTertiary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MeloraDimens.pagePadding),
              child: Row(
                children: [
                  const Text(
                    'Playing Queue',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      handler.clearQueue();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: handler.playlistStream,
                builder: (context, snapshot) {
                  final playlist = snapshot.data ?? [];
                  final currentIndex = handler.currentIndex;

                  if (playlist.isEmpty) {
                    return const Center(
                      child: Text(
                        'Queue is empty',
                        style: TextStyle(color: MeloraColors.darkTextSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: playlist.length,
                    itemBuilder: (ctx, i) {
                      final song = playlist[i];
                      final isCurrent = i == currentIndex;

                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isCurrent
                                ? MeloraColors.primary.withAlpha(51)
                                : Colors.white.withAlpha(13),
                          ),
                          child: isCurrent
                              ? const Icon(
                                  Iconsax.music_play,
                                  size: 20,
                                  color: MeloraColors.primary,
                                )
                              : AlbumArtWidget(songId: song.id, size: 44),
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
                                : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          song.displayArtist,
                          style: const TextStyle(
                            fontSize: 12,
                            color: MeloraColors.darkTextSecondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Iconsax.close_circle,
                                  size: 20,
                                ),
                                onPressed: () => handler.removeFromQueue(i),
                              ),
                        onTap: () {
                          handler.playAtIndex(i);
                          HapticFeedback.lightImpact();
                        },
                        dense: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final sleepTimer = ref.read(sleepTimerProvider.notifier);
  final remaining = ref.read(sleepTimerProvider);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: MeloraColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MeloraColors.darkTextTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          Row(
            children: [
              const Text(
                'Sleep Timer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (remaining != null)
                TextButton(
                  onPressed: () {
                    sleepTimer.cancelTimer();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: MeloraDimens.md),
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(bottom: MeloraDimens.lg),
              child: Text(
                'Timer active: ${_formatDuration(remaining)}',
                style: const TextStyle(
                  color: MeloraColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Wrap(
            spacing: MeloraDimens.md,
            runSpacing: MeloraDimens.md,
            children: [
              _TimerChip('5 min', const Duration(minutes: 5), sleepTimer, ctx),
              _TimerChip(
                '10 min',
                const Duration(minutes: 10),
                sleepTimer,
                ctx,
              ),
              _TimerChip(
                '15 min',
                const Duration(minutes: 15),
                sleepTimer,
                ctx,
              ),
              _TimerChip(
                '30 min',
                const Duration(minutes: 30),
                sleepTimer,
                ctx,
              ),
              _TimerChip(
                '45 min',
                const Duration(minutes: 45),
                sleepTimer,
                ctx,
              ),
              _TimerChip('1 hour', const Duration(hours: 1), sleepTimer, ctx),
              _TimerChip('2 hours', const Duration(hours: 2), sleepTimer, ctx),
            ],
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    ),
  );
}

class _TimerChip extends StatelessWidget {
  final String label;
  final Duration duration;
  final SleepTimerNotifier notifier;
  final BuildContext sheetContext;

  const _TimerChip(this.label, this.duration, this.notifier, this.sheetContext);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: MeloraColors.darkSurfaceLight,
      onPressed: () {
        notifier.startTimer(duration);
        HapticFeedback.lightImpact();
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $label'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

void _showSpeedSheet(BuildContext context, WidgetRef ref) {
  final handler = ref.read(audioHandlerProvider);
  final currentSpeed = ref.read(speedProvider).valueOrNull ?? 1.0;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: MeloraColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MeloraColors.darkTextTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Playback Speed',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MeloraDimens.xl),
          Wrap(
            spacing: MeloraDimens.md,
            runSpacing: MeloraDimens.md,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
              final isSelected = (currentSpeed - speed).abs() < 0.01;
              return ChoiceChip(
                label: Text('${speed}x'),
                selected: isSelected,
                selectedColor: MeloraColors.primary,
                onSelected: (_) {
                  handler.setSpeed(speed);
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    ),
  );
}

void _showSongInfoDialog(BuildContext context, dynamic song) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MeloraColors.darkSurface,
      title: const Text('Song Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoItem('Title', song.displayTitle),
          _InfoItem('Artist', song.displayArtist),
          _InfoItem('Album', song.displayAlbum),
          _InfoItem('Duration', song.duration.formatted),
          if (song.size != null) _InfoItem('Size', song.size.fileSize),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: MeloraColors.darkTextTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
