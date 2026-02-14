import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as p;
import '../../shared/models/song_model.dart';
import '../../shared/models/folder_model.dart';

class MusicScannerService {
  final oaq.OnAudioQuery _audioQuery = oaq.OnAudioQuery();

  Future<bool> requestPermission() async {
    return await _audioQuery.permissionsRequest();
  }

  Future<List<SongModel>> getAllSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: oaq.SongSortType.DATE_ADDED,
      orderType: oaq.OrderType.DESC_OR_GREATER,
      uriType: oaq.UriType.EXTERNAL,
      ignoreCase: true,
    );
    return songs.map(_convertSong).toList();
  }

  Future<List<SongModel>> getSongsFromFolder(String folderPath) async {
    final allSongs = await getAllSongs();
    return allSongs
        .where((s) => s.path != null && p.dirname(s.path!) == folderPath)
        .toList();
  }

  Future<List<FolderModel>> getFolders() async {
    final allSongs = await getAllSongs();
    final folderMap = <String, int>{};
    for (final song in allSongs) {
      if (song.path != null) {
        final folder = p.dirname(song.path!);
        folderMap[folder] = (folderMap[folder] ?? 0) + 1;
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

  Future<List<AlbumModel>> getAlbums() async {
    final albums = await _audioQuery.queryAlbums(
      sortType: oaq.AlbumSortType.ALBUM,
      orderType: oaq.OrderType.ASC_OR_SMALLER,
    );
    return albums
        .map(
          (a) => AlbumModel(
            id: a.id,
            name: a.album,
            artist: a.artist ?? 'Unknown',
            songCount: a.numOfSongs,
          ),
        )
        .toList();
  }

  Future<List<SongModel>> getSongsByAlbum(int albumId) async {
    final songs = await _audioQuery.queryAudiosFrom(
      oaq.AudiosFromType.ALBUM_ID,
      albumId,
    );
    return songs.map(_convertSong).toList();
  }

  Future<List<SongModel>> searchSongs(String query) async {
    final allSongs = await getAllSongs();
    final q = query.toLowerCase();
    return allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q),
        )
        .toList();
  }

  // ✅ FIX: ذخیره صحیح uri و path
  SongModel _convertSong(oaq.SongModel song) {
    // song.data = مسیر واقعی فایل: /storage/emulated/0/Music/song.mp3
    // song.uri  = content URI: content://media/external/audio/media/123
    final filePath = song.data;
    final contentUri = song.uri;

    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      duration: Duration(milliseconds: song.duration ?? 0),
      // ✅ uri: ترجیحاً content URI برای fallback
      uri: contentUri ?? filePath,
      // ✅ path: مسیر واقعی فایل برای پخش
      path: filePath,
      size: song.size,
      folder: p.dirname(filePath),
      isOnline: false,
    );
  }
}
