import 'package:equatable/equatable.dart';

class SongModel extends Equatable {
  final int id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String uri;
  final String? path;
  final int? size;
  final String? folder;
  final String? albumArt;
  final bool isOnline;
  final bool isFavorite;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.path,
    this.size,
    this.folder,
    this.albumArt,
    this.isOnline = false,
    this.isFavorite = false,
  });

  String get displayTitle =>
      title.isNotEmpty && title != '<unknown>' ? title : 'Unknown Title';
  String get displayArtist =>
      artist.isNotEmpty && artist != '<unknown>' ? artist : 'Unknown Artist';
  String get displayAlbum =>
      album.isNotEmpty && album != '<unknown>' ? album : 'Unknown Album';

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? uri,
    String? path,
    int? size,
    String? folder,
    String? albumArt,
    bool? isOnline,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      path: path ?? this.path,
      size: size ?? this.size,
      folder: folder ?? this.folder,
      albumArt: albumArt ?? this.albumArt,
      isOnline: isOnline ?? this.isOnline,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [id, uri];
}
