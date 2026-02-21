import 'dart:async';

/// Service to manage sleep timer
class SleepTimerService {
  Timer? _timer;
  DateTime? _endTime;
  final Function()? onTimerEnd;
  final Function(Duration remaining)? onTick;

  SleepTimerService({this.onTimerEnd, this.onTick});

  bool get isActive => _timer != null && _timer!.isActive;

  Duration? get remainingTime {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void startTimer(Duration duration) {
    cancelTimer();

    _endTime = DateTime.now().add(duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime;
      if (remaining == null || remaining.inSeconds <= 0) {
        cancelTimer();
        onTimerEnd?.call();
      } else {
        onTick?.call(remaining);
      }
    });
  }

  void addTime(Duration duration) {
    if (_endTime != null) {
      _endTime = _endTime!.add(duration);
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
  }

  void dispose() {
    cancelTimer();
  }
}

// Preset durations
class SleepTimerPresets {
  static const List<Duration> presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 2),
  ];

  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  static String formatRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
