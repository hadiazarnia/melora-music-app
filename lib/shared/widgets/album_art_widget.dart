import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Widget to display album art with fallback
class AlbumArtWidget extends StatelessWidget {
  final int songId;
  final double size;
  final double borderRadius;
  final ArtworkType type;

  const AlbumArtWidget({
    super.key,
    required this.songId,
    this.size = 48,
    this.borderRadius = MeloraDimens.radiusSm,
    this.type = ArtworkType.AUDIO,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: songId,
        type: type,
        artworkHeight: size,
        artworkWidth: size,
        artworkBorder: BorderRadius.circular(borderRadius),
        artworkFit: BoxFit.cover,
        quality: 100,
        format: ArtworkFormat.JPEG,
        keepOldArtwork: true,
        nullArtworkWidget: _DefaultArtwork(size: size),
        errorBuilder: (context, exception, stackTrace) {
          return _DefaultArtwork(size: size);
        },
      ),
    );
  }
}

class _DefaultArtwork extends StatelessWidget {
  final double size;

  const _DefaultArtwork({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MeloraColors.primary.withAlpha(77),
            MeloraColors.secondary.withAlpha(51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Iconsax.music,
        size: size * 0.4,
        color: Colors.white.withAlpha(153),
      ),
    );
  }
}

/// Large album art for player screen
class LargeAlbumArt extends StatelessWidget {
  final int songId;
  final double size;

  const LargeAlbumArt({super.key, required this.songId, this.size = 300});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MeloraColors.primary.withAlpha(64),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkHeight: size,
          artworkWidth: size,
          artworkFit: BoxFit.cover,
          quality: 100,
          format: ArtworkFormat.JPEG,
          keepOldArtwork: true,
          nullArtworkWidget: _LargeDefaultArtwork(size: size),
          errorBuilder: (context, exception, stackTrace) {
            return _LargeDefaultArtwork(size: size);
          },
        ),
      ),
    );
  }
}

class _LargeDefaultArtwork extends StatelessWidget {
  final double size;

  const _LargeDefaultArtwork({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MeloraColors.primary.withAlpha(77),
            MeloraColors.secondary.withAlpha(77),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Music icon
          Icon(
            Iconsax.music,
            size: size * 0.25,
            color: Colors.white.withAlpha(77),
          ),
          // Decorative circles
          Positioned(
            top: size * 0.1,
            right: size * 0.1,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.15,
            left: size * 0.15,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
