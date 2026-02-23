// lib/shared/widgets/album_art_widget.dart
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// High quality album art widget with caching
class AlbumArtWidget extends StatelessWidget {
  final int songId;
  final double size;
  final double borderRadius;
  final ArtworkType type;
  final int quality;

  const AlbumArtWidget({
    super.key,
    required this.songId,
    this.size = 48,
    this.borderRadius = MeloraDimens.radiusSm,
    this.type = ArtworkType.AUDIO,
    this.quality = 100,
  });

  @override
  Widget build(BuildContext context) {
    // Use higher quality for larger sizes
    final artworkQuality = size > 200 ? 100 : (size > 100 ? 80 : 60);
    final artworkSize = size > 200 ? 800 : (size > 100 ? 400 : 200);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: songId,
        type: type,
        artworkHeight: size,
        artworkWidth: size,
        artworkBorder: BorderRadius.circular(borderRadius),
        artworkFit: BoxFit.cover,
        quality: artworkQuality,
        size: artworkSize,
        format: ArtworkFormat.JPEG,
        keepOldArtwork: true,
        artworkQuality: FilterQuality.high,
        nullArtworkWidget: _DefaultArtwork(
          size: size,
          borderRadius: borderRadius,
        ),
        errorBuilder: (context, exception, stackTrace) {
          return _DefaultArtwork(size: size, borderRadius: borderRadius);
        },
      ),
    );
  }
}

class _DefaultArtwork extends StatelessWidget {
  final double size;
  final double borderRadius;

  const _DefaultArtwork({required this.size, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MeloraColors.primary.withAlpha(100),
            MeloraColors.secondary.withAlpha(80),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.music,
          size: size * 0.4,
          color: Colors.white.withAlpha(180),
        ),
      ),
    );
  }
}

/// Large album art for player screen with high quality
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
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkHeight: size,
          artworkWidth: size,
          artworkFit: BoxFit.cover,
          quality: 100,
          size: 800, // High resolution
          format: ArtworkFormat.JPEG,
          keepOldArtwork: true,
          artworkQuality: FilterQuality.high,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MeloraColors.primary.withAlpha(120),
            MeloraColors.secondary.withAlpha(100),
            MeloraColors.primary.withAlpha(80),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern
          Positioned.fill(child: CustomPaint(painter: _CirclePatternPainter())),
          // Music icon
          Icon(
            Iconsax.music,
            size: size * 0.3,
            color: Colors.white.withAlpha(100),
          ),
        ],
      ),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.6;

    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * (i / 5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
