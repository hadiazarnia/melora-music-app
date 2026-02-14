import 'package:equatable/equatable.dart';

class FolderModel extends Equatable {
  final String name;
  final String path;
  final int songCount;

  const FolderModel({
    required this.name,
    required this.path,
    required this.songCount,
  });

  @override
  List<Object?> get props => [path];
}

class AlbumModel extends Equatable {
  final int id;
  final String name;
  final String artist;
  final int songCount;

  const AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.songCount,
  });

  @override
  List<Object?> get props => [id];
}
