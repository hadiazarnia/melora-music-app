// lib/features/player/presentation/mini_player.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/album_art_widget.dart';
import 'player_screen.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  // Drag states
  double _verticalDragOffset = 0;
  bool _isVerticalDragging = false;

  // Seek gesture states
  bool _isHorizontalDragging = false;
  bool _isSeekMode = false; // true = seek, false = skip
  double _seekDelta = 0;
  Duration _seekPreviewPosition = Duration.zero;
  DateTime? _horizontalDragStartTime;

  // Animation
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Constants
  static const _holdDuration = Duration(milliseconds: 200);
  static const _seekSensitivity = 0.5; // seconds per pixel

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _openFullPlayer() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragStartTime = DateTime.now();
    _seekDelta = 0;
    _isHorizontalDragging = true;
    _isSeekMode = false;

    final positionData = ref.read(positionDataProvider).valueOrNull;
    _seekPreviewPosition = positionData?.position ?? Duration.zero;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isHorizontalDragging) return;

    final elapsed = DateTime.now().difference(_horizontalDragStartTime!);

    // After hold duration, switch to seek mode
    if (elapsed >= _holdDuration && !_isSeekMode) {
      setState(() => _isSeekMode = true);
      HapticFeedback.selectionClick();
    }

    if (_isSeekMode) {
      final positionData = ref.read(positionDataProvider).valueOrNull;
      if (positionData == null) return;

      _seekDelta += details.delta.dx;

      final seekSeconds = _seekDelta * _seekSensitivity;
      final newPosition =
          positionData.position +
          Duration(milliseconds: (seekSeconds * 1000).round());

      setState(() {
        _seekPreviewPosition = Duration(
          milliseconds: newPosition.inMilliseconds.clamp(
            0,
            positionData.duration.inMilliseconds,
          ),
        );
      });
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!_isHorizontalDragging) return;

    final handler = ref.read(audioHandlerProvider);
    final velocity = details.primaryVelocity ?? 0;

    if (_isSeekMode) {
      // Seek to position
      handler.seek(_seekPreviewPosition);
      HapticFeedback.lightImpact();
    } else {
      // Quick swipe = skip track
      if (velocity < -500) {
        handler.skipToNext();
        HapticFeedback.mediumImpact();
      } else if (velocity > 500) {
        handler.skipToPrevious();
        HapticFeedback.mediumImpact();
      }
    }

    setState(() {
      _isHorizontalDragging = false;
      _isSeekMode = false;
      _seekDelta = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final positionData = ref.watch(positionDataProvider).valueOrNull;

    if (currentSong == null) return const SizedBox.shrink();

    final progress = positionData?.progress ?? 0.0;
    final position = positionData?.position ?? Duration.zero;
    final duration = positionData?.duration ?? Duration.zero;

    return GestureDetector(
      onTap: _openFullPlayer,
      // Vertical drag for opening player
      onVerticalDragStart: (_) {
        setState(() {
          _isVerticalDragging = true;
          _verticalDragOffset = 0;
        });
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _verticalDragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        if (_verticalDragOffset < -50 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! < -400)) {
          _openFullPlayer();
        }
        setState(() {
          _isVerticalDragging = false;
          _verticalDragOffset = 0;
        });
      },
      // Horizontal drag for seek/skip
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(
          0,
          _isVerticalDragging ? _verticalDragOffset.clamp(-40.0, 15.0) : 0,
          0,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: MeloraDimens.md,
          vertical: MeloraDimens.xs,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: MeloraDimens.miniPlayerHeight,
              decoration: BoxDecoration(
                color: context.isDark
                    ? MeloraColors.darkSurface.withAlpha(220)
                    : MeloraColors.lightSurface.withAlpha(230),
                borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
                border: Border.all(
                  color: context.isDark
                      ? MeloraColors.glassBorder
                      : MeloraColors.lightBorder,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      // Swipe indicator
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.textTertiary.withAlpha(80),
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
                              // Album art with Hero
                              Hero(
                                tag: 'album_art_${currentSong.id}',
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      MeloraDimens.radiusSm,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: MeloraColors.primary.withAlpha(
                                          50,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      MeloraDimens.radiusSm,
                                    ),
                                    child: AlbumArtWidget(
                                      songId: currentSong.id,
                                      size: 48,
                                      borderRadius: MeloraDimens.radiusSm,
                                    ),
                                  ),
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
                                      '${currentSong.displayArtist} • ${_formatDuration(position)}',
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
                                ? Colors.white.withAlpha(15)
                                : Colors.black.withAlpha(15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              MeloraColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Seek preview overlay
                  if (_isSeekMode)
                    _SeekPreviewOverlay(
                      seekPosition: _seekPreviewPosition,
                      duration: duration,
                      seekDelta: _seekDelta,
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

String _formatDuration(Duration duration) {
  if (duration == Duration.zero) return '0:00';
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

// ═══════════════════════════════════════════════════════════
//  SEEK PREVIEW OVERLAY
// ═══════════════════════════════════════════════════════════

class _SeekPreviewOverlay extends StatelessWidget {
  final Duration seekPosition;
  final Duration duration;
  final double seekDelta;

  const _SeekPreviewOverlay({
    required this.seekPosition,
    required this.duration,
    required this.seekDelta,
  });

  @override
  Widget build(BuildContext context) {
    final isForward = seekDelta > 0;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withAlpha(150),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Direction icon
                  Icon(
                    isForward ? Iconsax.forward : Iconsax.backward,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  // Time display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: MeloraColors.primary.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(seekPosition),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Duration info
                  Text(
                    '/ ${_formatDuration(duration)}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: Colors.white.withAlpha(180),
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

// ═══════════════════════════════════════════════════════════
//  MINI PLAYER CONTROLS
// ═══════════════════════════════════════════════════════════

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MeloraColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: MeloraColors.primary.withAlpha(100),
                  blurRadius: 16,
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
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: 24,
                  color: Colors.white,
                ),
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
