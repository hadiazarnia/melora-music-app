import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage favorite songs using Hive local storage
class FavoritesService {
  static const String _boxName = 'melora_favorites';
  late Box<int> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<int>(_boxName);
    _initialized = true;
  }

  bool isFavorite(int songId) {
    return _box.containsKey(songId);
  }

  Future<void> addFavorite(int songId) async {
    if (!isFavorite(songId)) {
      await _box.put(songId, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> removeFavorite(int songId) async {
    await _box.delete(songId);
  }

  Future<void> toggleFavorite(int songId) async {
    if (isFavorite(songId)) {
      await removeFavorite(songId);
    } else {
      await addFavorite(songId);
    }
  }

  List<int> getAllFavoriteIds() {
    return _box.keys.cast<int>().toList();
  }

  int get favoriteCount => _box.length;

  Future<void> clearAll() async {
    await _box.clear();
  }
}
