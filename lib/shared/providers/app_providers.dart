import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/music_scanner_service.dart';
import '../../core/services/favorites_service.dart';
import '../models/song_model.dart';
import '../models/folder_model.dart';

// ─── Audio Handler (override شده در main) ──────────────
final audioHandlerProvider = Provider<MeloraAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

// ─── Favorites Service (override شده در main) ──────────
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  throw UnimplementedError(
    'favoritesServiceProvider must be overridden in main',
  );
});

// ─── Music Scanner ─────────────────────────────────────
final musicScannerProvider = Provider<MusicScannerService>((ref) {
  return MusicScannerService();
});

// ─── Navigation ────────────────────────────────────────
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

// ─── Current Song ──────────────────────────────────────
final currentSongProvider = StreamProvider<SongModel?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return Rx.combineLatest2<List<SongModel>, int, SongModel?>(
    handler.playlistStream,
    handler.currentIndexStream,
    (playlist, index) {
      if (playlist.isNotEmpty && index >= 0 && index < playlist.length) {
        return playlist[index];
      }
      return null;
    },
  );
});

// ─── Is Playing ────────────────────────────────────────
final isPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.playingStream;
});

// ─── Position Data ─────────────────────────────────────
final positionDataProvider = StreamProvider<PositionData>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    handler.player.positionStream,
    handler.player.bufferedPositionStream,
    handler.player.durationStream,
    (position, buffered, duration) =>
        PositionData(position, buffered, duration ?? Duration.zero),
  );
});

// ─── Loop Mode ─────────────────────────────────────────
final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.loopModeStream;
});

// ─── Shuffle ───────────────────────────────────────────
final shuffleEnabledProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.shuffleModeEnabledStream;
});

// ─── Volume ────────────────────────────────────────────
final volumeProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.volumeStream;
});

// ─── All Songs ─────────────────────────────────────────
final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final scanner = ref.read(musicScannerProvider);
  final hasPermission = await scanner.requestPermission();
  if (!hasPermission) return [];
  return scanner.getAllSongs();
});

// ─── Folders ───────────────────────────────────────────
final foldersProvider = FutureProvider<List<FolderModel>>((ref) async {
  final scanner = ref.read(musicScannerProvider);
  final hasPermission = await scanner.requestPermission();
  if (!hasPermission) return [];
  return scanner.getFolders();
});

// ─── Albums ────────────────────────────────────────────
final albumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final scanner = ref.read(musicScannerProvider);
  final hasPermission = await scanner.requestPermission();
  if (!hasPermission) return [];
  return scanner.getAlbums();
});

// ─── Folder Songs (family) ─────────────────────────────
final folderSongsProvider = FutureProvider.family<List<SongModel>, String>((
  ref,
  folderPath,
) async {
  final scanner = ref.read(musicScannerProvider);
  return scanner.getSongsFromFolder(folderPath);
});

// ─── Favorite Songs ────────────────────────────────────
final favoriteSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final favService = ref.read(favoritesServiceProvider);
  final allSongs = await ref.read(allSongsProvider.future);
  final favIds = favService.getAllFavoriteIds();
  return allSongs.where((s) => favIds.contains(s.id)).toList();
});
