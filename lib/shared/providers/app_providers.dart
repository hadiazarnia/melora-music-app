import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melora_music/core/services/file_import_service.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/music_scanner_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/music_cache_service.dart';
import '../../core/services/equalizer_service.dart';
import '../../core/services/sleep_timer_service.dart';
import '../models/song_model.dart';
import '../models/folder_model.dart';

// ═══════════════════════════════════════════════════════════
//  SERVICES (override in main)
// ═══════════════════════════════════════════════════════════

final audioHandlerProvider = Provider<MeloraAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  throw UnimplementedError(
    'favoritesServiceProvider must be overridden in main',
  );
});

final musicCacheServiceProvider = Provider<MusicCacheService>((ref) {
  throw UnimplementedError(
    'musicCacheServiceProvider must be overridden in main',
  );
});

final musicScannerProvider = Provider<MusicScannerService>((ref) {
  return MusicScannerService();
});

final equalizerServiceProvider = Provider<EqualizerService>((ref) {
  throw UnimplementedError(
    'equalizerServiceProvider must be overridden in main',
  );
});

// ═══════════════════════════════════════════════════════════
//  NAVIGATION
// ═══════════════════════════════════════════════════════════

final mainTabIndexProvider = StateProvider<int>((ref) => 0);
final offlineTabIndexProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════
//  REFRESH TRIGGER
// ═══════════════════════════════════════════════════════════

final musicRefreshProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════
//  PLAYER STATE
// ═══════════════════════════════════════════════════════════

final currentSongProvider = StreamProvider<SongModel?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final favService = ref.watch(favoritesServiceProvider);

  return Rx.combineLatest2<List<SongModel>, int, SongModel?>(
    handler.playlistStream,
    handler.currentIndexStream,
    (playlist, index) {
      if (playlist.isNotEmpty && index >= 0 && index < playlist.length) {
        final song = playlist[index];
        return song.copyWith(isFavorite: favService.isFavorite(song.id));
      }
      return null;
    },
  );
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.playingStream;
});

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

final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.loopModeStream;
});

final shuffleEnabledProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.shuffleModeEnabledStream;
});

final volumeProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.volumeStream;
});

final speedProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.speedStream;
});

final audioLevelProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.audioLevelStream;
});

final queueProvider = StreamProvider<List<SongModel>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playlistStream;
});

final currentIndexProvider = StreamProvider<int>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.currentIndexStream;
});

// ═══════════════════════════════════════════════════════════
//  MUSIC LIBRARY
// ═══════════════════════════════════════════════════════════

final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  ref.watch(musicRefreshProvider);

  final scanner = ref.read(musicScannerProvider);
  final cacheService = ref.read(musicCacheServiceProvider);
  final favService = ref.read(favoritesServiceProvider);

  // Try cache first
  if (cacheService.hasCachedData) {
    final cachedSongs = cacheService.getCachedSongs();
    if (cachedSongs.isNotEmpty) {
      return cachedSongs
          .map((s) => s.copyWith(isFavorite: favService.isFavorite(s.id)))
          .toList();
    }
  }

  // Need to scan
  final hasPermission = await scanner.requestPermission();
  if (!hasPermission) return [];

  final songs = await scanner.getAllSongs();

  // Cache results
  await cacheService.cacheSongs(songs);

  // Add favorite status
  return songs
      .map((s) => s.copyWith(isFavorite: favService.isFavorite(s.id)))
      .toList();
});

final foldersProvider = FutureProvider<List<FolderModel>>((ref) async {
  ref.watch(musicRefreshProvider);

  final scanner = ref.read(musicScannerProvider);
  final cacheService = ref.read(musicCacheServiceProvider);

  // Try cache
  if (cacheService.hasCachedData) {
    final cachedFolders = cacheService.getCachedFolders();
    if (cachedFolders.isNotEmpty) {
      return cachedFolders;
    }
  }

  final hasPermission = await scanner.requestPermission();
  if (!hasPermission) return [];

  final folders = await scanner.getFolders();
  await cacheService.cacheFolders(folders);

  return folders;
});

final folderSongsProvider = FutureProvider.family<List<SongModel>, String>((
  ref,
  folderPath,
) async {
  final allSongs = await ref.watch(allSongsProvider.future);
  return allSongs.where((s) => s.folder == folderPath).toList();
});

final favoriteSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  ref.watch(musicRefreshProvider);

  final favService = ref.read(favoritesServiceProvider);
  final allSongs = await ref.watch(allSongsProvider.future);
  final favIds = favService.getAllFavoriteIds();

  return allSongs
      .where((s) => favIds.contains(s.id))
      .map((s) => s.copyWith(isFavorite: true))
      .toList();
});

// ═══════════════════════════════════════════════════════════
//  ACTIONS
// ═══════════════════════════════════════════════════════════

final toggleFavoriteProvider = Provider<Future<void> Function(int)>((ref) {
  return (int songId) async {
    final favService = ref.read(favoritesServiceProvider);
    await favService.toggleFavorite(songId);
    ref.invalidate(allSongsProvider);
    ref.invalidate(favoriteSongsProvider);
    ref.invalidate(currentSongProvider);
  };
});

final refreshMusicLibraryProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final cacheService = ref.read(musicCacheServiceProvider);
    await cacheService.clearCache();
    ref.read(musicRefreshProvider.notifier).state++;
  };
});

// ═══════════════════════════════════════════════════════════
//  SLEEP TIMER
// ═══════════════════════════════════════════════════════════

final sleepTimerProvider = StateNotifierProvider<SleepTimerNotifier, Duration?>(
  (ref) {
    final handler = ref.watch(audioHandlerProvider);
    return SleepTimerNotifier(handler);
  },
);

class SleepTimerNotifier extends StateNotifier<Duration?> {
  final MeloraAudioHandler _handler;
  SleepTimerService? _service;

  SleepTimerNotifier(this._handler) : super(null);

  bool get isActive => _service?.isActive ?? false;

  void startTimer(Duration duration) {
    _service?.dispose();
    _service = SleepTimerService(
      onTimerEnd: () {
        _handler.pause();
        state = null;
      },
      onTick: (remaining) {
        state = remaining;
      },
    );
    _service!.startTimer(duration);
    state = duration;
  }

  void addTime(Duration duration) {
    _service?.addTime(duration);
    if (state != null) {
      state = state! + duration;
    }
  }

  void cancelTimer() {
    _service?.cancelTimer();
    state = null;
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}

final importedSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  ref.watch(musicRefreshProvider);

  final files = await FileImportService.getImportedFiles();
  final songs = <SongModel>[];

  for (final file in files) {
    songs.add(await FileImportService.fileToSongModel(file));
  }

  return songs;
});
