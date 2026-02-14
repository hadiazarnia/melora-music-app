import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../shared/models/song_model.dart';

class MeloraAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final BehaviorSubject<List<SongModel>> _playlist = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndex = BehaviorSubject.seeded(0);

  ConcatenatingAudioSource? _audioSource;
  bool _shuffleEnabled = false;

  AudioPlayer get player => _player;
  Stream<List<SongModel>> get playlistStream => _playlist.stream;
  Stream<int> get currentIndexStream => _currentIndex.stream;
  List<SongModel> get currentPlaylist => _playlist.value;
  int get currentIndex => _currentIndex.value;
  SongModel? get currentSong =>
      _playlist.value.isNotEmpty ? _playlist.value[_currentIndex.value] : null;
  bool get shuffleEnabled => _shuffleEnabled;

  MeloraAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen(_broadcastState);

    _player.currentIndexStream.listen((index) {
      if (index != null && index < _playlist.value.length) {
        _currentIndex.add(index);
        _updateMediaItem(index);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex.value,
      ),
    );
  }

  void _updateMediaItem(int index) {
    if (index < _playlist.value.length) {
      final song = _playlist.value[index];
      mediaItem.add(
        MediaItem(
          id: song.uri,
          title: song.displayTitle,
          artist: song.displayArtist,
          album: song.displayAlbum,
          duration: song.duration,
          artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
        ),
      );
    }
  }

  // ✅ FIX: متد کمکی برای ساخت AudioSource صحیح
  AudioSource _createAudioSource(SongModel song) {
    if (song.isOnline) {
      // آنلاین → URI معمولی
      return AudioSource.uri(Uri.parse(song.uri));
    }

    // آفلاین → اول مسیر واقعی فایل، بعد content URI
    if (song.path != null && song.path!.startsWith('/')) {
      // مسیر فایل واقعی مثل /storage/emulated/0/Music/song.mp3
      return AudioSource.file(song.path!);
    }

    // اگر مسیر واقعی نبود، از content:// URI استفاده کن
    if (song.uri.startsWith('content://')) {
      return AudioSource.uri(Uri.parse(song.uri));
    }

    // fallback
    return AudioSource.uri(Uri.parse(song.uri));
  }

  Future<void> loadPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _playlist.add(songs);
    _currentIndex.add(startIndex);

    // ✅ FIX: استفاده از _createAudioSource
    _audioSource = ConcatenatingAudioSource(
      children: songs.map(_createAudioSource).toList(),
    );

    await _player.setAudioSource(_audioSource!, initialIndex: startIndex);
    _updateMediaItem(startIndex);
    play();
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    if (queue != null) {
      final index = queue.indexOf(song);
      await loadPlaylist(queue, startIndex: index >= 0 ? index : 0);
    } else {
      await loadPlaylist([song]);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex.value < _playlist.value.length - 1) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex.value > 0) {
      await _player.seekToPrevious();
    }
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await _player.setShuffleModeEnabled(_shuffleEnabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    final loopMode = switch (mode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.all,
    };
    await _player.setLoopMode(loopMode);
  }

  Future<void> setPlayerLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  // ✅ FIX: استفاده از _createAudioSource
  Future<void> addToQueue(SongModel song) async {
    final updatedList = List<SongModel>.from(_playlist.value)..add(song);
    _playlist.add(updatedList);

    if (_audioSource != null) {
      await _audioSource!.add(_createAudioSource(song));
    }
  }

  // ✅ FIX: استفاده از _createAudioSource
  Future<void> playAfterCurrent(SongModel song) async {
    final insertIndex = _currentIndex.value + 1;
    final updatedList = List<SongModel>.from(_playlist.value)
      ..insert(insertIndex, song);
    _playlist.add(updatedList);

    if (_audioSource != null) {
      await _audioSource!.insert(insertIndex, _createAudioSource(song));
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _player.dispose();
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
