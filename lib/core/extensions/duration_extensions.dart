/// Duration extensions for formatting music timestamps
extension DurationX on Duration {
  /// Format as mm:ss
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format as hh:mm:ss if needed
  String get fullFormatted {
    if (inHours > 0) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return formatted;
  }

  /// Format as human readable (e.g., "3 min", "1 hr 30 min")
  String get humanReadable {
    if (inHours > 0) {
      final hours = inHours;
      final minutes = inMinutes.remainder(60);
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }
    return '${inMinutes} min';
  }
}

/// int to file size string
extension FileSizeX on int {
  String get fileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
