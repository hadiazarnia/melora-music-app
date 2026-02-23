// lib/shared/widgets/song_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../models/song_model.dart';
import '../providers/app_providers.dart';
import 'album_art_widget.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final int index;
  final bool showIndex;
  final bool showSize;
  final bool showDuration;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsTap;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.showIndex = false,
    this.showSize = false,
    this.showDuration = true,
    this.onTap,
    this.onOptionsTap,
  });

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = currentSong?.id == song.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onOptionsTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MeloraDimens.pagePadding,
            vertical: MeloraDimens.sm,
          ),
          decoration: isPlaying
              ? BoxDecoration(
                  color: MeloraColors.primary.withAlpha(20),
                  border: const Border(
                    left: BorderSide(color: MeloraColors.primary, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              // Index or Album Art
              if (showIndex)
                SizedBox(
                  width: 36,
                  child: Center(
                    child: isPlaying
                        ? const _PlayingIndicator()
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.textTertiary,
                            ),
                          ),
                  ),
                )
              else
                Stack(
                  children: [
                    AlbumArtWidget(
                      songId: song.id,
                      size: MeloraDimens.coverSm,
                      borderRadius: MeloraDimens.radiusSm,
                      artworkPath: song.albumArt,
                    ),
                    if (isPlaying)
                      Container(
                        width: MeloraDimens.coverSm,
                        height: MeloraDimens.coverSm,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MeloraDimens.radiusSm,
                          ),
                          color: Colors.black.withAlpha(153),
                        ),
                        child: const Center(child: _PlayingIndicator()),
                      ),
                  ],
                ),
              const SizedBox(width: MeloraDimens.md),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: isPlaying
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isPlaying
                            ? MeloraColors.primary
                            : context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (song.isFavorite) ...[
                          const Icon(
                            Icons.favorite,
                            size: 12,
                            color: MeloraColors.secondary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            _buildSubtitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More button
              IconButton(
                onPressed: onOptionsTap,
                icon: Icon(Iconsax.more, size: 20, color: context.textTertiary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[song.displayArtist];
    if (showDuration && song.duration != Duration.zero) {
      parts.add(_formatDuration(song.duration));
    }
    if (showSize && song.size != null) {
      parts.add(_formatFileSize(song.size!));
    }
    return parts.join(' • ');
  }
}

class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = (((_controller.value + delay) % 1.0) * 2 - 1).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 8 + (value * 8),
              decoration: BoxDecoration(
                color: MeloraColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
