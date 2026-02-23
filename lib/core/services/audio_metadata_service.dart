// lib/core/services/audio_metadata_service.dart
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioMetadata {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Uint8List? artwork;
  final String? artworkPath;

  AudioMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.artwork,
    this.artworkPath,
  });
}

class AudioMetadataService {
  static final Map<String, AudioMetadata> _cache = {};
  static Directory? _artworkCacheDir;

  /// Initialize artwork cache directory
  static Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _artworkCacheDir = Directory(p.join(appDir.path, 'artwork_cache'));
    if (!await _artworkCacheDir!.exists()) {
      await _artworkCacheDir!.create(recursive: true);
    }
  }

  /// Get metadata from audio file
  static Future<AudioMetadata> getMetadata(String filePath) async {
    // Check cache
    if (_cache.containsKey(filePath)) {
      return _cache[filePath]!;
    }

    String title = '';
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    Duration duration = Duration.zero;
    Uint8List? artwork;
    String? artworkPath;

    try {
      final tag = await AudioTags.read(filePath);

      if (tag != null) {
        title = tag.title ?? '';
        artist = tag.trackArtist ?? 'Unknown Artist';
        album = tag.album ?? 'Unknown Album';

        // Get duration if available
        if (tag.duration != null) {
          duration = Duration(seconds: tag.duration!);
        }

        // Get artwork
        if (tag.pictures.isNotEmpty) {
          artwork = tag.pictures.first.bytes;

          // Save artwork to cache
          if (artwork != null && _artworkCacheDir != null) {
            final artworkFile = File(
              p.join(_artworkCacheDir!.path, '${filePath.hashCode.abs()}.jpg'),
            );

            if (!await artworkFile.exists()) {
              await artworkFile.writeAsBytes(artwork);
            }
            artworkPath = artworkFile.path;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading metadata for $filePath: $e');
    }

    // Fallback to filename parsing if no title
    if (title.isEmpty) {
      final parsed = _parseFilename(p.basename(filePath));
      title = parsed['title'] ?? p.basenameWithoutExtension(filePath);
      if (artist == 'Unknown Artist') {
        artist = parsed['artist'] ?? 'Unknown Artist';
      }
    }

    final metadata = AudioMetadata(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artwork: artwork,
      artworkPath: artworkPath,
    );

    // Cache it
    _cache[filePath] = metadata;

    return metadata;
  }

  /// Get cached artwork path for a file
  static Future<String?> getArtworkPath(String filePath) async {
    if (_artworkCacheDir == null) await init();

    final artworkFile = File(
      p.join(_artworkCacheDir!.path, '${filePath.hashCode.abs()}.jpg'),
    );

    if (await artworkFile.exists()) {
      return artworkFile.path;
    }

    // Try to extract if not cached
    final metadata = await getMetadata(filePath);
    return metadata.artworkPath;
  }

  /// Parse filename for artist/title
  static Map<String, String> _parseFilename(String filename) {
    String name = p.basenameWithoutExtension(filename);

    // Remove track number prefix
    name = name.replaceAll(RegExp(r'^\d+[\.\-_\s]+'), '');

    // Remove quality suffix like (320), [320kbps], etc.
    name = name.replaceAll(
      RegExp(r'\s*[\(\[]?\d+k?(bps)?[\)\]]?\s*$', caseSensitive: false),
      '',
    );

    // Try to split by " - "
    if (name.contains(' - ')) {
      final parts = name.split(' - ');
      if (parts.length >= 2) {
        return {
          'artist': parts[0].trim(),
          'title': parts.sublist(1).join(' - ').trim(),
        };
      }
    }

    return {'artist': 'Unknown Artist', 'title': name.trim()};
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }
}
