class FocusSession {
  final String? id;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final int durationSeconds; // Added field
  final String category;

  final int pauseCount;
  final int totalPauseDurationSeconds;
  final String sessionType; // 'Pomodoro', 'Stopwatch', 'Countdown'
  final int focusCount;
  final int shortBreakCount;
  final int longBreakCount;

  FocusSession({
    this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    this.durationSeconds = 0, // Default 0
    this.category = 'Fokus',
    this.pauseCount = 0,
    this.totalPauseDurationSeconds = 0,
    this.sessionType = 'Pomodoro',
    this.focusCount = 0,
    this.shortBreakCount = 0,
    this.longBreakCount = 0,
  });

  double get averagePauseDurationSeconds =>
      pauseCount == 0 ? 0 : totalPauseDurationSeconds / pauseCount;

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    final startTime = map['start_time'] != null
        ? DateTime.parse(map['start_time']).toLocal()
        : DateTime.now();
    final durationSeconds = map['duration_seconds'] ?? 0;

    return FocusSession(
      id: map['id']?.toString(),
      title: map['label'] ?? '', // Map label to title
      date: startTime,
      durationMinutes:
          (durationSeconds / 60).ceil(), // Keep for backward compat
      durationSeconds: durationSeconds, // Store precise seconds
      category: map['category'] ?? 'Fokus',
      pauseCount: map['pause_count'] ?? 0,
      totalPauseDurationSeconds: map['total_pause_duration_seconds'] ?? 0,
      sessionType: map['session_type'] ?? 'Pomodoro',
      focusCount: map['focus_count'] ?? 0,
      shortBreakCount: map['short_break_count'] ?? 0,
      longBreakCount: map['long_break_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final startTime = date;
    // Use durationSeconds if available, otherwise fallback to minutes * 60
    final durationSecs =
        durationSeconds > 0 ? durationSeconds : durationMinutes * 60;
    final endTime = startTime.add(Duration(seconds: durationSecs));

    return {
      'label': title, // Map title to label
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(), // Required by DB
      'duration_seconds': durationSecs, // Required by DB
      'category': category,
      'pause_count': pauseCount,
      'total_pause_duration_seconds': totalPauseDurationSeconds,
      'session_type': sessionType,
      'focus_count': focusCount,
      'short_break_count': shortBreakCount,
      'long_break_count': longBreakCount,
    };
  }
}
