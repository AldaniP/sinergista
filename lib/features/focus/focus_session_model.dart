class FocusSession {
  final String title;
  final DateTime date;
  final int durationMinutes;
  final String category;

  FocusSession({
    required this.title,
    required this.date,
    required this.durationMinutes,
    this.category = 'Fokus',
    this.pauseCount = 0,
    this.totalPauseDurationSeconds = 0,
    this.sessionType = 'Pomodoro',
  });

  final int pauseCount;
  final int totalPauseDurationSeconds;
  final String sessionType; // 'Pomodoro', 'Stopwatch', 'Countdown'

  double get averagePauseDurationSeconds =>
      pauseCount == 0 ? 0 : totalPauseDurationSeconds / pauseCount;
}
