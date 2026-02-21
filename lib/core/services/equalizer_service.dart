import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage audio equalizer settings
class EqualizerService {
  static const String _boxName = 'melora_equalizer';
  static const MethodChannel _channel = MethodChannel('melora/equalizer');

  late Box _box;
  bool _initialized = false;
  bool _isEnabled = false;
  List<double> _bandLevels = List.filled(5, 0.0);
  String _currentPreset = 'flat';

  // Preset configurations
  static const Map<String, List<double>> presets = {
    'flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'bass_boost': [5.0, 3.5, 0.0, 0.0, 0.0],
    'bass_reducer': [-5.0, -3.5, 0.0, 0.0, 0.0],
    'treble_boost': [0.0, 0.0, 0.0, 3.5, 5.0],
    'treble_reducer': [0.0, 0.0, 0.0, -3.5, -5.0],
    'vocal': [-2.0, 0.0, 3.0, 2.0, -1.0],
    'rock': [4.0, 2.5, -1.0, 2.5, 4.0],
    'pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'jazz': [3.0, 1.0, -1.0, 1.5, 3.5],
    'classical': [4.0, 2.0, -1.0, 2.0, 4.0],
    'hip_hop': [4.5, 3.5, 0.0, 1.0, 3.0],
    'electronic': [4.0, 2.0, 0.0, 1.0, 4.0],
  };

  // Band frequencies
  static const List<String> bandFrequencies = [
    '60Hz',
    '230Hz',
    '910Hz',
    '3.6kHz',
    '14kHz',
  ];

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _loadSettings();
    _initialized = true;
  }

  void _loadSettings() {
    _isEnabled = _box.get('enabled', defaultValue: false);
    _currentPreset = _box.get('preset', defaultValue: 'flat');
    final savedLevels = _box.get('band_levels');
    if (savedLevels != null) {
      _bandLevels = List<double>.from(savedLevels);
    } else {
      _bandLevels = List.from(presets[_currentPreset] ?? presets['flat']!);
    }
  }

  bool get isEnabled => _isEnabled;
  List<double> get bandLevels => List.from(_bandLevels);
  String get currentPreset => _currentPreset;

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _box.put('enabled', enabled);
    await _applyEqualizer();
  }

  Future<void> setBandLevel(int bandIndex, double level) async {
    if (bandIndex < 0 || bandIndex >= _bandLevels.length) return;

    _bandLevels[bandIndex] = level.clamp(-12.0, 12.0);
    _currentPreset = 'custom';
    await _box.put('band_levels', _bandLevels);
    await _box.put('preset', 'custom');
    await _applyEqualizer();
  }

  Future<void> setPreset(String presetName) async {
    if (!presets.containsKey(presetName) && presetName != 'custom') return;

    _currentPreset = presetName;
    if (presetName != 'custom') {
      _bandLevels = List.from(presets[presetName]!);
    }
    await _box.put('preset', presetName);
    await _box.put('band_levels', _bandLevels);
    await _applyEqualizer();
  }

  Future<void> resetToFlat() async {
    await setPreset('flat');
  }

  Future<void> _applyEqualizer() async {
    try {
      await _channel.invokeMethod('setEqualizer', {
        'enabled': _isEnabled,
        'bandLevels': _bandLevels,
      });
    } catch (e) {
      // Platform channel not available or equalizer not supported
    }
  }

  String getPresetDisplayName(String preset) {
    switch (preset) {
      case 'flat':
        return 'Flat';
      case 'bass_boost':
        return 'Bass Boost';
      case 'bass_reducer':
        return 'Bass Reducer';
      case 'treble_boost':
        return 'Treble Boost';
      case 'treble_reducer':
        return 'Treble Reducer';
      case 'vocal':
        return 'Vocal';
      case 'rock':
        return 'Rock';
      case 'pop':
        return 'Pop';
      case 'jazz':
        return 'Jazz';
      case 'classical':
        return 'Classical';
      case 'hip_hop':
        return 'Hip Hop';
      case 'electronic':
        return 'Electronic';
      case 'custom':
        return 'Custom';
      default:
        return preset;
    }
  }
}
