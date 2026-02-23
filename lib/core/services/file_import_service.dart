// lib/core/services/file_import_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../shared/models/song_model.dart';

typedef OnFileImported = void Function(String filePath);

class FileImportService {
  static const MethodChannel _channel = MethodChannel('melora/import');

  static OnFileImported? _onFileImported;
  static final List<String> _pendingFiles = [];
  static bool _initialized = false;

  static Future<void> init({OnFileImported? onFileImported}) async {
    if (_initialized) return;
    _initialized = true;
    _onFileImported = onFileImported;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'importAudioFile':
          final String? path = call.arguments as String?;
          if (path != null && path.isNotEmpty) {
            await _handleImportedFile(path);
          }
          break;

        case 'importMultipleAudioFiles':
          final List<dynamic>? paths = call.arguments as List<dynamic>?;
          if (paths != null) {
            for (final path in paths) {
              if (path is String && path.isNotEmpty) {
                await _handleImportedFile(path);
              }
            }
          }
          break;
      }
    });
  }

  static void setOnFileImported(OnFileImported callback) {
    _onFileImported = callback;

    if (_pendingFiles.isNotEmpty) {
      for (final file in _pendingFiles) {
        callback(file);
      }
      _pendingFiles.clear();
    }
  }

  static Future<void> _handleImportedFile(String sourcePath) async {
    try {
      String cleanPath = sourcePath;

      if (cleanPath.startsWith('file://')) {
        cleanPath = Uri.parse(cleanPath).path;
      }

      final sourceFile = File(cleanPath);
      if (!await sourceFile.exists()) {
        debugPrint('Melora Import: Source file not found: $cleanPath');
        return;
      }

      if (!_isAudioFile(cleanPath)) {
        debugPrint('Melora Import: Not audio: $cleanPath');
        return;
      }

      final savedPath = await _saveToImportDir(sourceFile);
      debugPrint('Melora Import: Saved to: $savedPath');

      if (_onFileImported != null) {
        _onFileImported!(savedPath);
      } else {
        _pendingFiles.add(savedPath);
      }
    } catch (e) {
      debugPrint('Melora Import Error: $e');
    }
  }

  /// Save file to app's persistent import directory
  static Future<String> _saveToImportDir(File sourceFile) async {
    final importDir = await getImportDirectory();
    final fileName = p.basename(sourceFile.path);

    String destPath = p.join(importDir.path, fileName);
    int counter = 1;

    while (await File(destPath).exists()) {
      final existing = File(destPath);
      final existingSize = await existing.length();
      final sourceSize = await sourceFile.length();

      if (existingSize == sourceSize) {
        return destPath; // Same file
      }

      final name = p.basenameWithoutExtension(fileName);
      final ext = p.extension(fileName);
      destPath = p.join(importDir.path, '${name}_$counter$ext');
      counter++;
    }

    await sourceFile.copy(destPath);
    return destPath;
  }

  static bool _isAudioFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.wma',
      '.opus',
      '.aiff',
    ].contains(ext);
  }

  static Future<Directory> getImportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final importDir = Directory(p.join(appDir.path, 'imported_audio'));
    if (!await importDir.exists()) {
      await importDir.create(recursive: true);
    }
    return importDir;
  }

  static Future<List<File>> getImportedFiles() async {
    final importDir = await getImportDirectory();
    if (!await importDir.exists()) return [];

    final files = <File>[];
    await for (final entity in importDir.list()) {
      if (entity is File && _isAudioFile(entity.path)) {
        files.add(entity);
      }
    }
    return files;
  }

  /// ✅ این متد مهمه - فایل‌های import شده رو به SongModel تبدیل میکنه
  static Future<SongModel> fileToSongModel(File file) async {
    final stat = await file.stat();
    final name = p.basenameWithoutExtension(file.path);

    final cleanName = name
        .replaceAll(RegExp(r'_'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Generate unique ID from path
    final id = file.path.hashCode.abs();

    return SongModel(
      id: id,
      title: cleanName.isNotEmpty ? cleanName : 'Unknown',
      artist: 'Unknown Artist',
      album: 'Imported',
      duration: Duration.zero,
      uri: file.path,
      path: file.path,
      size: stat.size,
      folder: p.dirname(file.path),
      isOnline: false,
    );
  }

  /// ✅ Import از FilePicker - این متد جدیده
  static Future<int> importFromPicker(List<String> filePaths) async {
    int importedCount = 0;
    final importDir = await getImportDirectory();

    for (final sourcePath in filePaths) {
      try {
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) continue;
        if (!_isAudioFile(sourcePath)) continue;

        final fileName = p.basename(sourcePath);
        String destPath = p.join(importDir.path, fileName);

        // Handle duplicates
        if (await File(destPath).exists()) {
          final existing = File(destPath);
          final existingSize = await existing.length();
          final sourceSize = await sourceFile.length();

          if (existingSize == sourceSize) {
            continue; // Same file, skip
          }

          // Different file, rename
          int counter = 1;
          final name = p.basenameWithoutExtension(fileName);
          final ext = p.extension(fileName);

          while (await File(destPath).exists()) {
            destPath = p.join(importDir.path, '${name}_$counter$ext');
            counter++;
          }
        }

        await sourceFile.copy(destPath);
        importedCount++;
        debugPrint('Melora: Imported $fileName');
      } catch (e) {
        debugPrint('Melora: Failed to import $sourcePath: $e');
      }
    }

    return importedCount;
  }

  static Future<void> deleteImportedFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> clearImportedFiles() async {
    final importDir = await getImportDirectory();
    if (await importDir.exists()) {
      await importDir.delete(recursive: true);
      await importDir.create(recursive: true);
    }
  }
}
