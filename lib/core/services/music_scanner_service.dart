import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as p;
import '../../shared/models/song_model.dart';
import '../../shared/models/folder_model.dart';

class MusicScannerService {
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

  Future<bool> requestPermission() async {
    // On iOS, permission is handled differently
    if (Platform.isIOS) {
      return true; // iOS uses Media Library access
    }
    return await _audioQuery.permissionsRequest();
  }

  Future<bool> checkPermission() async {
    if (Platform.isIOS) return true;
    return await _audioQuery.permissionsStatus();
  }

  Future<List<SongModel>> getAllSongs() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: oaq.SongSortType.DATE_ADDED,
        orderType: oaq.OrderType.DESC_OR_GREATER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );

      return songs
          .where(
            (s) => s.duration != null && s.duration! > 10000,
          ) // Filter very short audio (>10s)
          .where((s) => !s.data.contains('WhatsApp')) // Filter WhatsApp audio
          .where((s) => !s.data.contains('Telegram')) // Filter Telegram audio
          .where(
            (s) => !s.data.contains('notification'),
          ) // Filter notification sounds
          .where((s) => !s.data.contains('ringtone')) // Filter ringtones
          .map(_convertSong)
          .toList();
    } catch (e) {
      return [];
    }
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
}
