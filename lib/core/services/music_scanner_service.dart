import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../shared/models/song_model.dart';
import '../../shared/models/folder_model.dart';

class MusicScannerService {
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      // On iOS, try to request but don't block if denied
      try {
        return await _audioQuery.permissionsRequest();
      } catch (e) {
        return true; // Continue anyway, we'll scan imported files
      }
    }
    return await _audioQuery.permissionsRequest();
  }

  Future<bool> checkPermission() async {
    if (Platform.isIOS) return true;
    return await _audioQuery.permissionsStatus();
  }

  Future<List<SongModel>> getAllSongs() async {
    final List<SongModel> allSongs = [];

    // 1. Try on_audio_query (works on Android, limited on iOS)
    try {
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
    } catch (e) {
      debugLog('on_audio_query error: $e');
    }

    // 2. Scan imported files directory (works on both iOS and Android)
    try {
      final importedSongs = await _scanImportedFiles();

      // Avoid duplicates by checking paths
      final existingPaths = allSongs.map((s) => s.path).toSet();
      for (final song in importedSongs) {
        if (!existingPaths.contains(song.path)) {
          allSongs.add(song);
        }
      }
    } catch (e) {
      debugLog('Import scan error: $e');
    }

    // 3. On iOS, also scan Documents directory
    if (Platform.isIOS) {
      try {
        final docSongs = await _scanDocumentsDirectory();
        final existingPaths = allSongs.map((s) => s.path).toSet();
        for (final song in docSongs) {
          if (!existingPaths.contains(song.path)) {
            allSongs.add(song);
          }
        }
      } catch (e) {
        debugLog('Documents scan error: $e');
      }
    }

    return allSongs;
  }

  /// Scan the imported_audio directory
  Future<List<SongModel>> _scanImportedFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final importDir = Directory(p.join(appDir.path, 'imported_audio'));

    if (!await importDir.exists()) return [];

    final songs = <SongModel>[];
    int idCounter = 900000; // High ID to avoid conflicts

    await for (final entity in importDir.list(recursive: true)) {
      if (entity is File && _isAudioFile(entity.path)) {
        final stat = await entity.stat();
        final name = p.basenameWithoutExtension(entity.path);

        songs.add(
          SongModel(
            id: idCounter++,
            title: _cleanTitle(name),
            artist: 'Unknown Artist',
            album: 'Imported',
            duration: Duration.zero,
            uri: entity.path,
            path: entity.path,
            size: stat.size,
            folder: p.dirname(entity.path),
            isOnline: false,
          ),
        );
      }
    }

    return songs;
  }

  /// Scan iOS Documents directory for audio files
  Future<List<SongModel>> _scanDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final songs = <SongModel>[];
    int idCounter = 800000;

    await for (final entity in appDir.list(recursive: false)) {
      if (entity is File && _isAudioFile(entity.path)) {
        final stat = await entity.stat();
        final name = p.basenameWithoutExtension(entity.path);

        songs.add(
          SongModel(
            id: idCounter++,
            title: _cleanTitle(name),
            artist: 'Unknown Artist',
            album: 'Local Files',
            duration: Duration.zero,
            uri: entity.path,
            path: entity.path,
            size: stat.size,
            folder: p.dirname(entity.path),
            isOnline: false,
          ),
        );
      }
    }

    return songs;
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

  String _cleanTitle(String name) {
    // Remove common prefixes/suffixes
    return name
        .replaceAll(RegExp(r'^\d+[\.\-_\s]+'), '') // Remove leading numbers
        .replaceAll(RegExp(r'_'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

  void debugLog(String msg) {
    // ignore: avoid_print
    print('MusicScanner: $msg');
  }
}
