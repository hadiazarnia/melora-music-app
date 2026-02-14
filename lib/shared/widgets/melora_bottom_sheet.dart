import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';

/// Melora Design System - Bottom Sheet with glassmorphism
class MeloraBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool useGlass = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _GlassBottomSheet(
        useGlass: useGlass,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  static Future<String?> showSongMenu({
    required BuildContext context,
    required String songTitle,
    required String artist,
    bool isFavorite = false,
  }) {
    return show<String>(
      context: context,
      child: _SongMenuContent(
        songTitle: songTitle,
        artist: artist,
        isFavorite: isFavorite,
      ),
    );
  }
}

class _GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final bool useGlass;
  final double? maxHeight;

  const _GlassBottomSheet({
    required this.child,
    this.useGlass = true,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? context.screenHeight * 0.85,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MeloraDimens.bottomSheetRadius),
        ),
        child: BackdropFilter(
          filter: useGlass
              ? ImageFilter.blur(sigmaX: 30, sigmaY: 30)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              color: useGlass
                  ? (isDark
                        ? MeloraColors.darkSurface.withOpacity(0.85)
                        : MeloraColors.lightSurface.withOpacity(0.9))
                  : (isDark
                        ? MeloraColors.darkSurface
                        : MeloraColors.lightSurface),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MeloraDimens.bottomSheetRadius),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? MeloraColors.darkBorder
                        : MeloraColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongMenuContent extends StatelessWidget {
  final String songTitle;
  final String artist;
  final bool isFavorite;

  const _SongMenuContent({
    required this.songTitle,
    required this.artist,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MeloraDimens.pagePadding,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MeloraDimens.radiusSm),
                    gradient: LinearGradient(
                      colors: [
                        MeloraColors.primary.withOpacity(0.3),
                        MeloraColors.secondary.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: MeloraColors.primary,
                  ),
                ),
                const SizedBox(width: MeloraDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Divider(),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Song Info',
            onTap: () => Navigator.pop(context, 'info'),
          ),
          _MenuItem(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
            title: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            iconColor: isFavorite ? MeloraColors.secondary : null,
            onTap: () => Navigator.pop(context, 'favorite'),
          ),
          _MenuItem(
            icon: Icons.playlist_play_rounded,
            title: 'Play after current song',
            onTap: () => Navigator.pop(context, 'play_next'),
          ),
          _MenuItem(
            icon: Icons.queue_music_rounded,
            title: 'Add to playing queue',
            onTap: () => Navigator.pop(context, 'add_queue'),
          ),
          _MenuItem(
            icon: Icons.playlist_add_rounded,
            title: 'Add to playlist',
            onTap: () => Navigator.pop(context, 'add_playlist'),
          ),
          _MenuItem(
            icon: Icons.play_circle_outline_rounded,
            title: 'Preview',
            onTap: () => Navigator.pop(context, 'preview'),
          ),
          _MenuItem(
            icon: Icons.share_outlined,
            title: 'Share',
            onTap: () => Navigator.pop(context, 'share'),
          ),
          _MenuItem(
            icon: Icons.delete_outline_rounded,
            title: 'Delete permanently',
            iconColor: MeloraColors.error,
            textColor: MeloraColors.error,
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? context.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textColor ?? context.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MeloraDimens.pagePadding,
        vertical: 0,
      ),
      dense: true,
    );
  }
}
