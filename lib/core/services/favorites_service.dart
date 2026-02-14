import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage favorite songs using Hive local storage
class FavoritesService {
  static const String _boxName = 'melora_favorites';
  late Box<int> _box;

  Future<void> init() async {
    _box = await Hive.openBox<int>(_boxName);
  }

  bool isFavorite(int songId) {
    return _box.containsKey(songId);
  }

  Future<void> toggleFavorite(int songId) async {
    if (isFavorite(songId)) {
      await _box.delete(songId);
    } else {
      await _box.put(songId, songId);
    }
  }

  List<int> getAllFavoriteIds() {
    return _box.values.toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
