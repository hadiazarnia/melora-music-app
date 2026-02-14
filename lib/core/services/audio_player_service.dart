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

  Future<void> loadPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _playlist.add(songs);
    _currentIndex.add(startIndex);

    _audioSource = ConcatenatingAudioSource(
      children: songs.map((song) {
        if (song.isOnline) {
          return AudioSource.uri(Uri.parse(song.uri));
        } else {
          return AudioSource.file(song.uri);
        }
      }).toList(),
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
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.all,
    };
    await _player.setLoopMode(loopMode);
  }

  /// متد کمکی برای استفاده مستقیم LoopMode از UI
  Future<void> setPlayerLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> addToQueue(SongModel song) async {
    final updatedList = List<SongModel>.from(_playlist.value)..add(song);
    _playlist.add(updatedList);

    if (_audioSource != null) {
      if (song.isOnline) {
        await _audioSource!.add(AudioSource.uri(Uri.parse(song.uri)));
      } else {
        await _audioSource!.add(AudioSource.file(song.uri));
      }
    }
  }

  Future<void> playAfterCurrent(SongModel song) async {
    final insertIndex = _currentIndex.value + 1;
    final updatedList = List<SongModel>.from(_playlist.value)
      ..insert(insertIndex, song);
    _playlist.add(updatedList);

    if (_audioSource != null) {
      if (song.isOnline) {
        await _audioSource!.insert(
          insertIndex,
          AudioSource.uri(Uri.parse(song.uri)),
        );
      } else {
        await _audioSource!.insert(insertIndex, AudioSource.file(song.uri));
      }
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
