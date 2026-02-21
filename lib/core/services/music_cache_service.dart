import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/song_model.dart';
import '../../shared/models/folder_model.dart';

/// Service to cache music data and avoid re-scanning
class MusicCacheService {
  static const String _boxName = 'melora_music_cache';
  static const String _songsKey = 'cached_songs';
  static const String _foldersKey = 'cached_folders';
  static const String _lastScanKey = 'last_scan_time';
  static const String _songCountKey = 'song_count';

  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  bool get hasCachedData {
    return _box.containsKey(_songsKey) &&
        _box.get(_songsKey) != null &&
        (jsonDecode(_box.get(_songsKey)) as List).isNotEmpty;
  }

  DateTime? get lastScanTime {
    final timestamp = _box.get(_lastScanKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  int get cachedSongCount => _box.get(_songCountKey, defaultValue: 0);

  Future<void> cacheSongs(List<SongModel> songs) async {
    final jsonList = songs.map((s) => _songToJson(s)).toList();
    await _box.put(_songsKey, jsonEncode(jsonList));
    await _box.put(_songCountKey, songs.length);
    await _box.put(_lastScanKey, DateTime.now().millisecondsSinceEpoch);
  }

  List<SongModel> getCachedSongs() {
    final data = _box.get(_songsKey);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => _songFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheFolders(List<FolderModel> folders) async {
    final jsonList = folders
        .map((f) => {'name': f.name, 'path': f.path, 'songCount': f.songCount})
        .toList();
    await _box.put(_foldersKey, jsonEncode(jsonList));
  }

  List<FolderModel> getCachedFolders() {
    final data = _box.get(_foldersKey);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList
          .map(
            (json) => FolderModel(
              name: json['name'],
              path: json['path'],
              songCount: json['songCount'],
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearCache() async {
    await _box.delete(_songsKey);
    await _box.delete(_foldersKey);
    await _box.delete(_lastScanKey);
    await _box.delete(_songCountKey);
  }

  Future<void> markNeedsRescan() async {
    await _box.delete(_lastScanKey);
  }

  Map<String, dynamic> _songToJson(SongModel song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'duration': song.duration.inMilliseconds,
      'uri': song.uri,
      'path': song.path,
      'size': song.size,
      'folder': song.folder,
      'albumArt': song.albumArt,
      'isOnline': song.isOnline,
    };
  }

  SongModel _songFromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'],
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      duration: Duration(milliseconds: json['duration'] ?? 0),
      uri: json['uri'] ?? '',
      path: json['path'],
      size: json['size'],
      folder: json['folder'],
      albumArt: json['albumArt'],
      isOnline: json['isOnline'] ?? false,
    );
  }
}
