import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/duration_extensions.dart';
import '../models/song_model.dart';

/// Melora Design System - Song Tile Component
class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPlaying;
  final bool showCover;
  final bool showDuration;
  final bool showSize;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.isPlaying = false,
    this.showCover = true,
    this.showDuration = true,
    this.showSize = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MeloraDimens.pagePadding,
            vertical: MeloraDimens.sm,
          ),
          child: Row(
            children: [
              // Cover Art
              if (showCover) ...[
                _CoverArt(albumArt: song.albumArt, isPlaying: isPlaying),
                const SizedBox(width: MeloraDimens.md),
              ],

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        if (showDuration) ...[
                          Text(
                            ' · ${song.duration.formatted}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: context.textTertiary,
                            ),
                          ),
                        ],
                        if (showSize && song.size != null) ...[
                          Text(
                            ' · ${song.size!.fileSize}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: context.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // More button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: onLongPress,
                  icon: Icon(
                    Iconsax.more,
                    size: 20,
                    color: context.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 30 * index),
      duration: 300.ms,
    );
  }
}

class _CoverArt extends StatelessWidget {
  final String? albumArt;
  final bool isPlaying;

  const _CoverArt({this.albumArt, this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MeloraDimens.coverSm,
      height: MeloraDimens.coverSm,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusSm),
        color: context.isDark
            ? MeloraColors.darkSurfaceLight
            : MeloraColors.lightSurfaceLight,
        border: isPlaying
            ? Border.all(color: MeloraColors.primary, width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MeloraDimens.radiusSm),
        child: albumArt != null
            ? Image.network(
                albumArt!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MeloraColors.primary.withOpacity(0.3),
            MeloraColors.secondary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Iconsax.music,
        size: 20,
        color: isPlaying ? MeloraColors.primary : context.textTertiary,
      ),
    );
  }
}
