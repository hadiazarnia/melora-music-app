// lib/core/services/music_scanner_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../shared/models/song_model.dart';
import '../../shared/models/folder_model.dart';
import 'audio_metadata_service.dart';

class MusicScannerService {
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();
  final AudioPlayer _durationPlayer = AudioPlayer();

  // ✅ Guards برای جلوگیری از درخواست‌های همزمان
  bool _isScanning = false;
  bool _isRequestingPermission = false;
  bool? _permissionGranted;

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    // اگه قبلاً permission گرفتیم، برگردون
    if (_permissionGranted != null) {
      return _permissionGranted!;
    }

    // اگه در حال درخواست هستیم، صبر نکن
    if (_isRequestingPermission) {
      return false;
    }

    _isRequestingPermission = true;

    try {
      _permissionGranted = await _audioQuery.permissionsRequest();
      return _permissionGranted!;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<bool> checkPermission() async {
    if (Platform.isIOS) return true;

    try {
      _permissionGranted = await _audioQuery.permissionsStatus();
      return _permissionGranted!;
    } catch (e) {
      return _permissionGranted ?? false;
    }
  }

  Future<List<SongModel>> getAllSongs() async {
    // ✅ جلوگیری از اسکن همزمان
    if (_isScanning) {
      debugPrint('Already scanning, skipping...');
      return [];
    }

    _isScanning = true;
    final List<SongModel> allSongs = [];

    try {
      // Initialize metadata service
      await AudioMetadataService.init();

      // 1. Android: Use on_audio_query
      if (Platform.isAndroid) {
        try {
          // Check permission first without requesting
          final hasPermission = await checkPermission();
          if (!hasPermission) {
            debugPrint('No permission, skipping media library scan');
          } else {
            final songs = await _audioQuery.querySongs(
              sortType: oaq.SongSortType.DATE_ADDED,
              orderType: oaq.OrderType.DESC_OR_GREATER,
              uriType: oaq.UriType.EXTERNAL,
              ignoreCase: true,
            );

            allSongs.addAll(
              songs
                  .where((s) => s.duration != null && s.duration! > 10000)
                  .where((s) => !_isSystemAudio(s.data))
                  .map(_convertSong),
            );
          }
        } catch (e) {
          debugPrint('on_audio_query error: $e');
        }
      }

      // 2. Scan imported_audio directory (iOS & Android)
      try {
        final importedSongs = await _scanImportedDirectory();
        debugPrint('Found ${importedSongs.length} imported songs');

        final existingPaths = allSongs.map((s) => s.path).toSet();
        for (final song in importedSongs) {
          if (!existingPaths.contains(song.path)) {
            allSongs.add(song);
          }
        }
      } catch (e) {
        debugPrint('Import scan error: $e');
      }

      // 3. iOS: Also scan Documents directory
      if (Platform.isIOS) {
        try {
          final docSongs = await _scanDocumentsDirectory();
          debugPrint('Found ${docSongs.length} document songs');

          final existingPaths = allSongs.map((s) => s.path).toSet();
          for (final song in docSongs) {
            if (!existingPaths.contains(song.path)) {
              allSongs.add(song);
            }
          }
        } catch (e) {
          debugPrint('Documents scan error: $e');
        }
      }

      debugPrint('Total songs found: ${allSongs.length}');
    } finally {
      _isScanning = false;
    }

    return allSongs;
  }

  /// Scan the imported_audio directory with full metadata extraction
  Future<List<SongModel>> _scanImportedDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final importDir = Directory(p.join(appDir.path, 'imported_audio'));

    if (!await importDir.exists()) {
      debugPrint('Import directory does not exist: ${importDir.path}');
      return [];
    }

    final songs = <SongModel>[];
    int idCounter = 900000;

    try {
      await for (final entity in importDir.list(recursive: false)) {
        if (entity is File && _isAudioFile(entity.path)) {
          try {
            final song = await _createSongFromFile(entity, idCounter++);
            songs.add(song);
            debugPrint('Found imported: ${song.title} - ${song.artist}');
          } catch (e) {
            debugPrint('Error reading file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing import directory: $e');
    }

    return songs;
  }

  /// Scan iOS Documents directory
  Future<List<SongModel>> _scanDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final songs = <SongModel>[];
    int idCounter = 800000;

    try {
      await for (final entity in appDir.list(recursive: false)) {
        if (entity is File && _isAudioFile(entity.path)) {
          if (entity.path.contains('imported_audio')) continue;

          try {
            final song = await _createSongFromFile(
              entity,
              idCounter++,
              album: 'Local Files',
            );
            songs.add(song);
          } catch (e) {
            debugPrint('Error reading doc file: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing documents: $e');
    }

    return songs;
  }

  /// Create SongModel from file with full metadata extraction
  Future<SongModel> _createSongFromFile(
    File file,
    int id, {
    String? album,
  }) async {
    final stat = await file.stat();

    // Get metadata using audiotags
    final metadata = await AudioMetadataService.getMetadata(file.path);

    // Get duration using just_audio if not available from metadata
    Duration duration = metadata.duration;
    if (duration == Duration.zero) {
      try {
        final dur = await _durationPlayer.setFilePath(file.path);
        duration = dur ?? Duration.zero;
        await _durationPlayer.stop();
      } catch (e) {
        debugPrint('Could not get duration for ${file.path}: $e');
      }
    }

    return SongModel(
      id: id,
      title: metadata.title,
      artist: metadata.artist,
      album: album ?? metadata.album,
      duration: duration,
      uri: file.path,
      path: file.path,
      size: stat.size,
      folder: p.dirname(file.path),
      albumArt: metadata.artworkPath,
      isOnline: false,
    );
  }

  Future<List<SongModel>> getSongsFromFolder(String folderPath) async {
    final allSongs = await getAllSongs();
    return allSongs.where((s) => s.folder == folderPath).toList();
  }

  Future<List<FolderModel>> getFolders() async {
    final allSongs = await getAllSongs();
    final folderMap = <String, int>{};

    for (final song in allSongs) {
      if (song.folder != null && song.folder!.isNotEmpty) {
        folderMap[song.folder!] = (folderMap[song.folder!] ?? 0) + 1;
      }
    }

    return folderMap.entries
        .map(
          (e) => FolderModel(
            name: p.basename(e.key),
            path: e.key,
            songCount: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<SongModel>> searchSongs(
    String query,
    List<SongModel> songs,
  ) async {
    if (query.isEmpty) return songs;
    final q = query.toLowerCase();
    return songs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q),
        )
        .toList();
  }

  bool _isAudioFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.wma',
      '.opus',
      '.aiff',
    ].contains(ext);
  }

  bool _isSystemAudio(String path) {
    final lower = path.toLowerCase();
    return lower.contains('whatsapp') ||
        lower.contains('telegram') ||
        lower.contains('notification') ||
        lower.contains('ringtone') ||
        lower.contains('alarm');
  }

  SongModel _convertSong(oaq.SongModel song) {
    final filePath = song.data;
    final contentUri = song.uri;
    final folder = p.dirname(filePath);

    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      duration: Duration(milliseconds: song.duration ?? 0),
      uri: contentUri ?? filePath,
      path: filePath,
      size: song.size,
      folder: folder,
      isOnline: false,
    );
  }

  void dispose() {
    _durationPlayer.dispose();
  }
}
