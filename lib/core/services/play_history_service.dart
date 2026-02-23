// lib/core/services/play_history_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class PlayHistoryService {
  static const String _boxName = 'melora_play_history';
  static const String _historyKey = 'play_history';
  static const String _playCountKey = 'play_counts';

  late Box _box;
  bool _initialized = false;

  // In-memory cache
  List<PlayHistoryEntry> _history = [];
  Map<int, int> _playCounts = {};

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _loadData();
    _initialized = true;
  }

  void _loadData() {
    // Load history
    final historyJson = _box.get(_historyKey);
    if (historyJson != null) {
      final List<dynamic> list = jsonDecode(historyJson);
      _history = list.map((e) => PlayHistoryEntry.fromJson(e)).toList();
    }

    // Load play counts
    final countsJson = _box.get(_playCountKey);
    if (countsJson != null) {
      final Map<String, dynamic> map = jsonDecode(countsJson);
      _playCounts = map.map((k, v) => MapEntry(int.parse(k), v as int));
    }
  }

  Future<void> _saveData() async {
    await _box.put(
      _historyKey,
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
    await _box.put(
      _playCountKey,
      jsonEncode(_playCounts.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  /// Record a song play
  Future<void> recordPlay(int songId) async {
    // Update play count
    _playCounts[songId] = (_playCounts[songId] ?? 0) + 1;

    // Add to history
    _history.insert(
      0,
      PlayHistoryEntry(songId: songId, playedAt: DateTime.now()),
    );

    // Keep only last 500 entries
    if (_history.length > 500) {
      _history = _history.sublist(0, 500);
    }

    await _saveData();
  }

  /// Get play count for a song
  int getPlayCount(int songId) {
    return _playCounts[songId] ?? 0;
  }

  /// Get all play counts
  Map<int, int> getAllPlayCounts() {
    return Map.from(_playCounts);
  }

  /// Get recently played song IDs (unique, ordered by last play)
  List<int> getRecentlyPlayedIds({int limit = 50}) {
    final seen = <int>{};
    final result = <int>[];

    for (final entry in _history) {
      if (!seen.contains(entry.songId)) {
        seen.add(entry.songId);
        result.add(entry.songId);
        if (result.length >= limit) break;
      }
    }

    return result;
  }

  /// Get play history with timestamps
  List<PlayHistoryEntry> getHistory({int limit = 100}) {
    return _history.take(limit).toList();
  }

  /// Get most played song IDs
  List<int> getMostPlayedIds({int limit = 50}) {
    final sorted = _playCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _box.put(_historyKey, jsonEncode([]));
  }

  /// Clear all data
  Future<void> clearAll() async {
    _history.clear();
    _playCounts.clear();
    await _box.clear();
  }
}

class PlayHistoryEntry {
  final int songId;
  final DateTime playedAt;

  PlayHistoryEntry({required this.songId, required this.playedAt});

  factory PlayHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PlayHistoryEntry(
      songId: json['songId'],
      playedAt: DateTime.fromMillisecondsSinceEpoch(json['playedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'songId': songId, 'playedAt': playedAt.millisecondsSinceEpoch};
  }
}
