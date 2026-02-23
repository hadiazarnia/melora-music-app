// lib/features/player/presentation/player_screen.dart
import 'dart:math' as math;
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

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _bgAnimController;
  late AnimationController _coverRotationController;
  late AnimationController _waveController;

  // Drag states
  double _dragOffsetY = 0;
  bool _isDraggingDown = false;

  // Seek states
  bool _isDraggingSeek = false;
  double _seekValue = 0;

  // Volume
  double _volume = 1.0;
  bool _showVolumeSlider = false;

  // Dynamic colors
  Color _dominantColor = MeloraColors.primary;
  Color _secondaryColor = MeloraColors.secondary;
  int? _lastSongId;

  // Cover 3D rotation
  double _coverRotateY = 0;
  bool _isSwipingCover = false;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _coverRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Get initial volume
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final handler = ref.read(audioHandlerProvider);
      setState(() => _volume = handler.player.volume);
    });
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _coverRotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _extractColors(int songId) async {
    if (_lastSongId == songId) return;
    _lastSongId = songId;

    try {
      // Try to get palette from album art
      // For now, use predefined colors based on songId
      final colors = _getColorsForSong(songId);
      setState(() {
        _dominantColor = colors.$1;
        _secondaryColor = colors.$2;
      });
    } catch (e) {
      // Fallback to default
    }
  }

  (Color, Color) _getColorsForSong(int songId) {
    final colorSets = [
      (const Color(0xFF6C5CE7), const Color(0xFFa29bfe)),
      (const Color(0xFFe17055), const Color(0xFFfab1a0)),
      (const Color(0xFF00b894), const Color(0xFF55efc4)),
      (const Color(0xFF0984e3), const Color(0xFF74b9ff)),
      (const Color(0xFFfdcb6e), const Color(0xFFffeaa7)),
      (const Color(0xFFe84393), const Color(0xFFfd79a8)),
      (const Color(0xFF2d3436), const Color(0xFF636e72)),
      (const Color(0xFF6c5ce7), const Color(0xFFa29bfe)),
    ];
    return colorSets[songId % colorSets.length];
  }

  void _closePlayer() {
    Navigator.of(context).pop();
  }

  void _openCoverFullScreen(int songId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FullScreenCover(songId: songId),
    );
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
      return _buildEmptyState();
    }

    // Extract colors when song changes
    _extractColors(currentSong.id);

    final position = positionData?.position ?? Duration.zero;
    final duration = positionData?.duration ?? Duration.zero;
    final progress = positionData?.progress ?? 0.0;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return GestureDetector(
      onVerticalDragStart: (_) {
        _isDraggingDown = true;
        _dragOffsetY = 0;
      },
      onVerticalDragUpdate: (details) {
        if (_isDraggingDown) {
          _dragOffsetY += details.delta.dy;

          // Swipe up = open queue
          if (_dragOffsetY < -100) {
            _isDraggingDown = false;
            _showQueueSheet(context, ref);
          }
        }
      },
      onVerticalDragEnd: (details) {
        // Swipe down = close player
        if (_dragOffsetY > 100 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 500)) {
          _closePlayer();
        }
        _isDraggingDown = false;
        _dragOffsetY = 0;
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Animated Gradient Background ─────────────
            _AnimatedBackground(
              controller: _bgAnimController,
              dominantColor: _dominantColor,
              secondaryColor: _secondaryColor,
            ),

            // ─── Blur Overlay ─────────────────────────────
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.black.withAlpha(100)),
            ),

            // ─── Main Content ─────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // ─── Top Bar ────────────────────
                            _TopBar(
                              album: currentSong.displayAlbum,
                              onClose: _closePlayer,
                              onOptions: () =>
                                  _showPlayerOptions(context, ref, currentSong),
                            ).animate().fadeIn(duration: 400.ms),

                            SizedBox(height: isSmallScreen ? 16 : 32),

                            // ─── 3D Album Art ────────────────
                            Expanded(
                              flex: isSmallScreen ? 4 : 5,
                              child: Center(
                                child: _3DAlbumArt(
                                  songId: currentSong.id,
                                  isPlaying: isPlaying,
                                  rotateY: _coverRotateY,
                                  onSwipeLeft: () {
                                    setState(() => _coverRotateY = -0.3);
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        ref
                                            .read(audioHandlerProvider)
                                            .skipToNext();
                                        setState(() => _coverRotateY = 0);
                                      },
                                    );
                                    HapticFeedback.mediumImpact();
                                  },
                                  onSwipeRight: () {
                                    setState(() => _coverRotateY = 0.3);
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        ref
                                            .read(audioHandlerProvider)
                                            .skipToPrevious();
                                        setState(() => _coverRotateY = 0);
                                      },
                                    );
                                    HapticFeedback.mediumImpact();
                                  },
                                  onTap: () =>
                                      _openCoverFullScreen(currentSong.id),
                                  maxSize: isSmallScreen ? 240 : 300,
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 16 : 24),

                            // ─── Song Info ────────────────────
                            _SongInfoSection(
                              song: currentSong,
                              onFavoriteToggle: () async {
                                await ref.read(toggleFavoriteProvider)(
                                  currentSong.id,
                                );
                                HapticFeedback.lightImpact();
                              },
                            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                            SizedBox(height: isSmallScreen ? 16 : 24),

                            // ─── Wave Seek Bar ────────────────
                            _WaveSeekBar(
                              position: position,
                              duration: duration,
                              progress: _isDraggingSeek ? _seekValue : progress,
                              audioLevel: audioLevel,
                              waveController: _waveController,
                              isPlaying: isPlaying,
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
                                    milliseconds:
                                        (value * duration.inMilliseconds)
                                            .round(),
                                  ),
                                );
                                setState(() => _isDraggingSeek = false);
                              },
                            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                            SizedBox(height: isSmallScreen ? 12 : 20),

                            // ─── Controls ─────────────────────
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
                                setState(() => _coverRotateY = -0.2);
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () => setState(() => _coverRotateY = 0),
                                );
                                ref.read(audioHandlerProvider).skipToNext();
                                HapticFeedback.mediumImpact();
                              },
                              onPrevious: () {
                                setState(() => _coverRotateY = 0.2);
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () => setState(() => _coverRotateY = 0),
                                );
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

                            SizedBox(height: isSmallScreen ? 12 : 20),

                            // ─── Volume Slider ────────────────
                            _VolumeSlider(
                              volume: _volume,
                              onChanged: (value) {
                                setState(() => _volume = value);
                                ref.read(audioHandlerProvider).setVolume(value);
                              },
                            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                            SizedBox(height: isSmallScreen ? 8 : 16),

                            // ─── Bottom Actions ───────────────
                            _BottomActionsSection(
                              onQueue: () => _showQueueSheet(context, ref),
                              onEqualizer: () =>
                                  Navigator.pushNamed(context, '/equalizer'),
                              onSleepTimer: () =>
                                  _showSleepTimerSheet(context, ref),
                              onSpeed: () => _showSpeedSheet(context, ref),
                            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                            SizedBox(height: isSmallScreen ? 8 : 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
}

// ═══════════════════════════════════════════════════════════
//  ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════════

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Color dominantColor;
  final Color secondaryColor;

  const _AnimatedBackground({
    required this.controller,
    required this.dominantColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1 + controller.value * 2,
                -1 + controller.value,
              ),
              end: Alignment(1 - controller.value * 0.5, 1),
              colors: [
                dominantColor.withAlpha(180),
                Colors.black,
                secondaryColor.withAlpha(100),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        );
      },
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
              size: 26,
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
                    color: Colors.white.withAlpha(150),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  album,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withAlpha(100),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOptions,
            icon: const Icon(Iconsax.more, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  3D ALBUM ART
// ═══════════════════════════════════════════════════════════

class _3DAlbumArt extends StatefulWidget {
  final int songId;
  final bool isPlaying;
  final double rotateY;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onTap;
  final double maxSize;

  const _3DAlbumArt({
    required this.songId,
    required this.isPlaying,
    required this.rotateY,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onTap,
    this.maxSize = 300,
  });

  @override
  State<_3DAlbumArt> createState() => _3DAlbumArtState();
}

class _3DAlbumArtState extends State<_3DAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _localRotateY = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = math.min(
      MediaQuery.of(context).size.width - 80,
      widget.maxSize,
    );

    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _localRotateY += details.delta.dx * 0.005;
          _localRotateY = _localRotateY.clamp(-0.4, 0.4);
        });
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -500) {
          widget.onSwipeLeft();
        } else if (velocity > 500) {
          widget.onSwipeRight();
        }
        setState(() => _localRotateY = 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(widget.rotateY + _localRotateY),
        transformAlignment: Alignment.center,
        child: Hero(
          tag: 'album_art_${widget.songId}',
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: MeloraColors.primary.withAlpha(80),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                  spreadRadius: -10,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Album art
                  AlbumArtWidget(
                    songId: widget.songId,
                    size: size,
                    borderRadius: 24,
                  ),
                  // Subtle gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(30),
                          Colors.transparent,
                          Colors.black.withAlpha(30),
                        ],
                      ),
                    ),
                  ),
                  // Playing indicator
                  if (widget.isPlaying)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.graphic_eq,
                          color: MeloraColors.primary,
                          size: 24,
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

// ═══════════════════════════════════════════════════════════
//  FULL SCREEN COVER
// ═══════════════════════════════════════════════════════════

class _FullScreenCover extends StatelessWidget {
  final int songId;

  const _FullScreenCover({required this.songId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AlbumArtWidget(
              songId: songId,
              size: MediaQuery.of(context).size.width - 40,
              borderRadius: 16,
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
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
                    fontSize: 24,
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
                    fontSize: 16,
                    color: Colors.white.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavoriteToggle,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                song.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border_rounded,
                key: ValueKey(song.isFavorite),
                color: song.isFavorite
                    ? MeloraColors.secondary
                    : Colors.white.withAlpha(150),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WAVE SEEK BAR
// ═══════════════════════════════════════════════════════════

class _WaveSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final double progress;
  final double audioLevel;
  final AnimationController waveController;
  final bool isPlaying;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekUpdate;
  final ValueChanged<double> onSeekEnd;

  const _WaveSeekBar({
    required this.position,
    required this.duration,
    required this.progress,
    required this.audioLevel,
    required this.waveController,
    required this.isPlaying,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  @override
  State<_WaveSeekBar> createState() => _WaveSeekBarState();
}

class _WaveSeekBarState extends State<_WaveSeekBar> {
  bool _isDragging = false;
  double _thumbScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
      child: Column(
        children: [
          // Wave progress bar
          SizedBox(
            height: 50,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDragging = true;
                  _thumbScale = 1.4;
                });
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.globalPosition);
                final value = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                widget.onSeekStart(value);
              },
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.globalPosition);
                final value = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                widget.onSeekUpdate(value);
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                  _thumbScale = 1.0;
                });
                widget.onSeekEnd(widget.progress);
              },
              onTapUp: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.globalPosition);
                final value = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                widget.onSeekEnd(value);
              },
              child: AnimatedBuilder(
                animation: widget.waveController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 50),
                    painter: _WaveSeekBarPainter(
                      progress: widget.progress,
                      audioLevel: widget.audioLevel,
                      wavePhase: widget.waveController.value,
                      isPlaying: widget.isPlaying,
                      isDragging: _isDragging,
                      thumbScale: _thumbScale,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.position.formatted,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(180),
                ),
              ),
              Text(
                widget.duration.formatted,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: Colors.white.withAlpha(120),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveSeekBarPainter extends CustomPainter {
  final double progress;
  final double audioLevel;
  final double wavePhase;
  final bool isPlaying;
  final bool isDragging;
  final double thumbScale;

  _WaveSeekBarPainter({
    required this.progress,
    required this.audioLevel,
    required this.wavePhase,
    required this.isPlaying,
    required this.isDragging,
    required this.thumbScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final progressX = size.width * progress;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), bgPaint);

    // Wave path for active portion
    if (isPlaying || isDragging) {
      final wavePath = Path();
      final waveHeight = 8 + (audioLevel * 12);

      wavePath.moveTo(0, centerY);

      for (double x = 0; x <= progressX; x += 2) {
        final normalizedX = x / size.width;
        final waveY =
            math.sin((normalizedX * 4 * math.pi) + (wavePhase * 2 * math.pi)) *
            waveHeight *
            (normalizedX < 0.9 ? normalizedX : 1 - (normalizedX - 0.9) * 10);

        wavePath.lineTo(x, centerY + waveY);
      }

      final wavePaint = Paint()
        ..shader = const LinearGradient(
          colors: [MeloraColors.primary, MeloraColors.secondary],
        ).createShader(Rect.fromLTWH(0, 0, progressX, size.height))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(wavePath, wavePaint);
    } else {
      // Static progress line when paused
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [MeloraColors.primary, MeloraColors.secondary],
        ).createShader(Rect.fromLTWH(0, 0, progressX, size.height))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(progressX, centerY),
        progressPaint,
      );
    }

    // Thumb
    final thumbRadius = 8.0 * thumbScale;
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final thumbShadowPaint = Paint()
      ..color = MeloraColors.primary.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(progressX, centerY),
      thumbRadius + 4,
      thumbShadowPaint,
    );
    canvas.drawCircle(Offset(progressX, centerY), thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveSeekBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.audioLevel != audioLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.thumbScale != thumbScale;
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
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          _ControlButton(
            icon: Iconsax.shuffle,
            isActive: shuffleOn,
            onTap: onShuffle,
            size: 24,
          ),

          // Previous
          _ControlButton(icon: Iconsax.previous, onTap: onPrevious, size: 32),

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
                    color: MeloraColors.primary.withAlpha(120),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPlayPause,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Next
          _ControlButton(icon: Iconsax.next, onTap: onNext, size: 32),

          // Loop
          _ControlButton(
            icon: loopMode == LoopMode.one
                ? Iconsax.repeate_one
                : Iconsax.repeat,
            isActive: loopMode != LoopMode.off,
            onTap: onLoop,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: size,
        color: isActive ? MeloraColors.primary : Colors.white.withAlpha(180),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  VOLUME SLIDER
// ═══════════════════════════════════════════════════════════

class _VolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
      child: Row(
        children: [
          Icon(
            volume == 0 ? Iconsax.volume_slash : Iconsax.volume_low,
            size: 20,
            color: Colors.white.withAlpha(120),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white.withAlpha(200),
                inactiveTrackColor: Colors.white.withAlpha(30),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withAlpha(20),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(value: volume, onChanged: onChanged),
            ),
          ),
          Icon(
            Iconsax.volume_high,
            size: 20,
            color: Colors.white.withAlpha(120),
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
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Iconsax.music_playlist,
            label: 'Queue',
            onTap: onQueue,
          ),
          _ActionButton(
            icon: Iconsax.sound,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
            ),
            child: Icon(icon, size: 22, color: Colors.white.withAlpha(180)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: Colors.white.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM SHEETS (Queue, Timer, Speed, Options)
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
              color: MeloraColors.darkTextTertiary.withAlpha(80),
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
      initialChildSize: 0.65,
      maxChildSize: 0.95,
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
                color: MeloraColors.darkTextTertiary.withAlpha(80),
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
                      fontSize: 20,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isCurrent
                                ? MeloraColors.primary.withAlpha(60)
                                : Colors.white.withAlpha(10),
                          ),
                          child: isCurrent
                              ? const Icon(
                                  Iconsax.music_play,
                                  size: 22,
                                  color: MeloraColors.primary,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AlbumArtWidget(
                                    songId: song.id,
                                    size: 48,
                                  ),
                                ),
                        ),
                        title: Text(
                          song.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
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
                            fontSize: 13,
                            color: MeloraColors.darkTextSecondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Iconsax.close_circle,
                                  size: 22,
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
              color: MeloraColors.darkTextTertiary.withAlpha(80),
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
                  fontSize: 20,
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
              color: MeloraColors.darkTextTertiary.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Playback Speed',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
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
