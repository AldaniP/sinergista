import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'focus_session_model.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;
  bool _isPomodoro = true;
  // Pomodoro State
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _pomodoroCycle = 0;
  String _currentPhase =
      'Fokus'; // 'Fokus', 'Istirahat Pendek', 'Istirahat Panjang'

  // Timer Biasa State
  String _timerType = 'Stopwatch'; // 'Stopwatch', 'Countdown'
  int _stopwatchSeconds = 0;

  // Pause Tracking
  int _pauseCount = 0;
  int _totalPauseDuration = 0;
  DateTime? _pauseStartTime;

  // Settings
  int _focusDuration = 25;
  int _shortBreak = 5;
  int _longBreak = 15;

  // Session Aggregation State
  int _completedFocusSessions = 0;
  int _completedShortBreaks = 0;
  int _completedLongBreaks = 0;
  DateTime? _lastAutoSaveTime;
  String? _currentSessionId;
  bool _showAllSessions = false; // State for pagination

  // Chart State
  DateTime _chartDate = DateTime.now();

  final TextEditingController _sessionTitleController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  List<FocusSession> _recentSessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    final sessions = await _supabaseService.getRecentFocusSessions();
    if (mounted) {
      setState(() {
        _recentSessions = sessions;
        _isLoadingSessions = false;
      });
    }
  }

  Future<void> _deleteSession(FocusSession session) async {
    if (session.id == null) return;

    debugPrint('Deleting session: ${session.id}, Current: $_currentSessionId');
    // Optimistic update
    setState(() {
      _recentSessions.removeWhere((s) => s.id == session.id);
      // Prevent auto-save from re-creating the session if it's the current one
      if (session.id == _currentSessionId) {
        debugPrint('Deleting CURRENT session. Resetting state.');
        _timer?.cancel();
        _timer = null;
        _autoSaveTimer?.cancel();
        _resetTimerState();
      }
    });

    try {
      await _supabaseService.deleteFocusSession(session.id!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesi berhasil dihapus')));
    } catch (e) {
      // Revert if failed
      _loadRecentSessions();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus sesi: $e')));
    }
  }

  @override
  void deactivate() {
    // Called when the widget is removed from the tree (e.g., tab switch)
    _saveCurrentSession();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save if app is paused or detached
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentSession();
    }
  }

  void _saveCurrentSession() {
    debugPrint(
      'Check Save: Running=$_isRunning, Stopwatch=$_stopwatchSeconds, ID=$_currentSessionId',
    );
    // Save if running or has progress
    if (_isRunning ||
        _completedFocusSessions > 0 ||
        _completedShortBreaks > 0 ||
        _completedLongBreaks > 0 ||
        _completedLongBreaks > 0 ||
        (_currentPhase == 'Fokus' && _remainingSeconds < _focusDuration * 60) ||
        (_stopwatchSeconds > 0)) {
      debugPrint('Saving current session...');
      _completeSession(isStop: true);
      _lastAutoSaveTime = DateTime.now();
    }
  }

  void _periodicAutoSave() {
    // Only save if it's been at least 30 seconds since last save
    if (_lastAutoSaveTime == null ||
        DateTime.now().difference(_lastAutoSaveTime!).inSeconds >= 30) {
      _saveCurrentSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Auto-save if running or has progress
    _saveCurrentSession();
    _timer?.cancel();
    _sessionTitleController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;

    if (_sessionTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi kegiatan yang akan dilakukan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Resume from pause
    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now()
          .difference(_pauseStartTime!)
          .inSeconds;
      _totalPauseDuration += pauseDuration;
      _pauseStartTime = null;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });

    // Start auto-save timer (saves every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _periodicAutoSave();
    });
  }

  void _resetSessionCounts() {
    _completedFocusSessions = 0;
    _completedShortBreaks = 0;
    _completedLongBreaks = 0;
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _pauseCount++;
      _pauseStartTime = DateTime.now();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    // Save the session if there's any progress or completed sessions
    if (_isRunning || // Save if it was running (even if 0s)
        _completedFocusSessions > 0 ||
        _completedShortBreaks > 0 ||
        _completedLongBreaks > 0 ||
        (_currentPhase == 'Fokus' && _remainingSeconds < _focusDuration * 60) ||
        (_stopwatchSeconds > 0)) {
      _completeSession(isStop: true);
    }

    _resetTimerState();
  }

  void _resetTimerState() {
    debugPrint('Resetting Timer State');
    setState(() {
      _isRunning = false;
      _remainingSeconds = _focusDuration * 60;
      _stopwatchSeconds = 0;
      _currentPhase = 'Fokus';
      _pomodoroCycle = 0;
      _pauseCount = 0;
      _totalPauseDuration = 0;
      _pauseStartTime = null;
      _resetSessionCounts();
      _lastAutoSaveTime = null;
      _currentSessionId = null;
    });
  }

  void _handleTimerComplete() {
    _timer?.cancel();
    _timer = null;

    // If not Pomodoro, just stop
    if (!_isPomodoro) {
      if (_timerType == 'Countdown') {
        _isRunning = false;
        _completeSession();
      }
      return;
    }

    // Pomodoro Logic
    if (_currentPhase == 'Fokus') {
      // Focus finished -> Start Break
      _completedFocusSessions++;
      _pomodoroCycle++;

      if (_pomodoroCycle % 4 == 0) {
        _currentPhase = 'Istirahat Panjang';
        _remainingSeconds = _longBreak * 60;
      } else {
        _currentPhase = 'Istirahat Pendek';
        _remainingSeconds = _shortBreak * 60;
      }
    } else {
      // Break finished -> Start Focus
      if (_currentPhase == 'Istirahat Pendek') {
        _completedShortBreaks++;
      } else {
        _completedLongBreaks++;
      }
      _currentPhase = 'Fokus';
      _remainingSeconds = _focusDuration * 60;
    }

    // Play sound or notify (optional)
    // For now just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fase $_currentPhase dimulai!'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-start next phase
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleTimerComplete();
        }
      });
    });

    setState(() {});
  }

  void _tick() {
    setState(() {
      if (_isPomodoro || _timerType == 'Countdown') {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleTimerComplete();
        }
      } else {
        // Stopwatch
        _stopwatchSeconds++;
      }
    });
  }

  void _completeSession({bool isStop = false}) {
    // Calculate total duration based on completed sessions + current progress if stopped
    int totalMinutes = 0;
    int totalSeconds = 0;

    if (_isPomodoro) {
      totalMinutes += _completedFocusSessions * _focusDuration;
      // Add current progress if stopped during focus
      if (isStop && _currentPhase == 'Fokus') {
        int elapsedSeconds = (_focusDuration * 60 - _remainingSeconds);
        totalSeconds = totalMinutes * 60 + elapsedSeconds;
        totalMinutes += (elapsedSeconds / 60).ceil();
      } else {
        totalSeconds = totalMinutes * 60;
      }
    } else {
      // Timer Biasa
      if (_timerType == 'Countdown') {
        totalMinutes = _focusDuration;
        totalSeconds = totalMinutes * 60;
      } else {
        // Stopwatch
        totalSeconds = _stopwatchSeconds;
        totalMinutes = (totalSeconds / 60).ceil();
      }

      // Ensure at least 1 minute if it was running (even if < 1 min)
      if (totalMinutes == 0 && isStop) {
        totalMinutes = 1;
        if (totalSeconds == 0)
          totalSeconds = 60; // Ensure seconds match min duration
      }
    }

    final newSession = FocusSession(
      id: _currentSessionId,
      title: _sessionTitleController.text.isEmpty
          ? 'Sesi Fokus'
          : _sessionTitleController.text,
      date: DateTime.now(),
      durationMinutes: totalMinutes,
      durationSeconds: totalSeconds, // Pass precise seconds
      pauseCount: _pauseCount,
      totalPauseDurationSeconds: _totalPauseDuration,
      sessionType: _isPomodoro ? 'Pomodoro' : _timerType,
      focusCount:
          _completedFocusSessions +
          (isStop &&
                  _currentPhase == 'Fokus' &&
                  _remainingSeconds < _focusDuration * 60
              ? 1
              : 0),
      shortBreakCount: _completedShortBreaks,
      longBreakCount: _completedLongBreaks,
    );

    // Save to Supabase
    _supabaseService.saveFocusSession(newSession).then((savedSession) {
      if (mounted) {
        setState(() {
          // Replace the optimistic session with the saved one (which has ID)
          final index = _recentSessions.indexOf(newSession);
          if (index != -1) {
            debugPrint('Save success. Updating list. ID: ${savedSession.id}');
            // Update current session ID for future updates
            _currentSessionId = savedSession.id;
            _recentSessions[index] = savedSession;
          } else {
            debugPrint(
              'Save success BUT session removed from list. Deleting from DB. ID: ${savedSession.id}',
            );
            // Session was removed from list (deleted) while save was in progress.
            // Ensure it is deleted from DB too.
            if (savedSession.id != null) {
              _supabaseService.deleteFocusSession(savedSession.id!);
            }
          }
        });
      }
    });

    setState(() {
      // Optimistic update
      if (_currentSessionId != null) {
        // Update existing session in list
        final index = _recentSessions.indexWhere(
          (s) => s.id == _currentSessionId,
        );
        if (index != -1) {
          _recentSessions[index] = newSession;
        } else {
          _recentSessions.insert(0, newSession);
        }
      } else {
        // New session
        _recentSessions.insert(0, newSession);
      }

      if (isStop) {
        _sessionTitleController.clear();
      }
    });

    if (!isStop) {
      // Only show dialog if it's a countdown finish (not pomodoro phase change)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selesai!'),
          content: Text(
            'Sesi ${_isPomodoro ? "fokus" : _timerType.toLowerCase()} telah selesai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String get _timerString {
    if (!_isPomodoro && _timerType == 'Stopwatch') {
      final minutes = (_stopwatchSeconds / 60).floor().toString().padLeft(
        2,
        '0',
      );
      final seconds = (_stopwatchSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (!_isPomodoro && _timerType == 'Stopwatch') {
      return 0.0; // Stopwatch doesn't have progress
    }

    int totalMinutes;
    if (_isPomodoro) {
      if (_currentPhase == 'Fokus') {
        totalMinutes = _focusDuration;
      } else if (_currentPhase == 'Istirahat Pendek') {
        totalMinutes = _shortBreak;
      } else {
        totalMinutes = _longBreak;
      }
    } else {
      // Countdown
      totalMinutes = _focusDuration;
    }

    final totalSeconds = totalMinutes * 60;
    if (totalSeconds == 0) return 0;

    final progress = 1.0 - (_remainingSeconds / totalSeconds);
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fokus & Timer'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tingkatkan produktivitas Anda',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Hari Ini', '2.5h'),
                _buildStatCard('Minggu Ini', '24h'),
                _buildStatCard('Bulan Ini', '96h'),
                _buildStatCard('Total Sesi', '48'),
              ],
            ),

            const SizedBox(height: 32),

            // Timer Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  // Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_currentSessionId != null) _stopTimer();
                              setState(() => _isPomodoro = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isPomodoro
                                    ? Theme.of(context).cardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isPomodoro
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: const Center(
                                child: Text(
                                  'Pomodoro',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_currentSessionId != null) _stopTimer();
                              setState(() => _isPomodoro = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isPomodoro
                                    ? Theme.of(context).cardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isPomodoro
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: const Center(
                                child: Text(
                                  'Timer Biasa',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Session Title Input (Moved above timer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _sessionTitleController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Apa yang sedang Anda kerjakan? (Wajib)',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) =>
                          setState(() {}), // Rebuild for validation
                    ),
                  ),

                  const SizedBox(height: 32),

                  CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 12.0,
                    percent: _progress,
                    center: Text(
                      _timerString,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: _currentPhase == 'Fokus'
                        ? AppColors.primary
                        : Colors.green, // Green for break
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animateFromLastPercent: true,
                    footer: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _isPomodoro
                            ? _currentPhase
                            : (_timerType == 'Stopwatch'
                                  ? 'Stopwatch'
                                  : 'Countdown'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Timer Biasa Toggle (Stopwatch / Countdown)
                  if (!_isPomodoro) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (_currentSessionId != null) _stopTimer();
                              setState(() => _timerType = 'Stopwatch');
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _timerType == 'Stopwatch'
                                  ? Colors.grey.shade100
                                  : null,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Stopwatch',
                              style: TextStyle(
                                color: _timerType == 'Stopwatch'
                                    ? Colors.black
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (_currentSessionId != null) _stopTimer();
                              setState(() => _timerType = 'Countdown');
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _timerType == 'Countdown'
                                  ? Colors.grey.shade100
                                  : null,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Countdown',
                              style: TextStyle(
                                color: _timerType == 'Countdown'
                                    ? Colors.black
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (_isPomodoro) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Istirahat: $_shortBreak menit',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Start Button
                  // Control Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isRunning ? LucideIcons.pause : LucideIcons.play,
                          ),
                          label: Text(
                            _isRunning
                                ? 'Jeda Sesi'
                                : (_stopwatchSeconds > 0 ||
                                      (_currentPhase == 'Fokus' &&
                                          _remainingSeconds <
                                              _focusDuration * 60))
                                ? 'Lanjutkan'
                                : 'Mulai Sesi Fokus',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_isRunning ||
                          _remainingSeconds < _focusDuration * 60) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _stopTimer,
                            icon: const Icon(LucideIcons.square),
                            label: const Text('Berhenti'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Settings (only for Pomodoro and Countdown)
                  if (_isPomodoro) ...[
                    // Pomodoro Settings
                    _buildSettingRow('Durasi Fokus', _focusDuration, (val) {
                      setState(() {
                        _focusDuration = val;
                        if (!_isRunning) _remainingSeconds = val * 60;
                      });
                    }),
                    const SizedBox(height: 16),
                    _buildSettingRow('Istirahat Pendek', _shortBreak, (val) {
                      setState(() => _shortBreak = val);
                    }),
                    const SizedBox(height: 16),
                    _buildSettingRow('Istirahat Panjang', _longBreak, (val) {
                      setState(() => _longBreak = val);
                    }),
                  ] else if (_timerType == 'Countdown') ...[
                    // Countdown Settings
                    _buildSettingRow('Durasi', _focusDuration, (val) {
                      setState(() {
                        _focusDuration = val;
                        if (!_isRunning) _remainingSeconds = val * 60;
                      });
                    }),
                  ],
                  // No settings for Stopwatch
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Sessions
            const Row(
              children: [
                Icon(LucideIcons.trendingUp, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sesi Terakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingSessions)
              const Center(child: CircularProgressIndicator())
            else if (_recentSessions.isEmpty)
              const Center(
                child: Text(
                  'Belum ada sesi fokus.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              ...(_showAllSessions ? _recentSessions : _recentSessions.take(4))
                  .map((session) => _buildSessionItem(session)),
              if (!_showAllSessions && _recentSessions.length > 4)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAllSessions = true),
                    child: const Text('Lihat Lebih Banyak'),
                  ),
                ),
            ],

            const SizedBox(height: 32),

            // Weekly Activity Placeholder
            // Weekly Activity Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Aktivitas Minggu Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_chartDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  // Week Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft),
                        onPressed: () => setState(() {
                          _chartDate = _chartDate.subtract(
                            const Duration(days: 7),
                          );
                        }),
                      ),
                      Text(
                        'Minggu ke-${_getWeekOfMonth(_chartDate)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight),
                        onPressed: () => setState(() {
                          _chartDate = _chartDate.add(const Duration(days: 7));
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bar Chart
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.grey.shade800,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()}h',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                const dayNames = [
                                  'Sen',
                                  'Sel',
                                  'Rab',
                                  'Kam',
                                  'Jum',
                                  'Sab',
                                  'Min',
                                ];
                                final index = value.toInt();

                                if (index >= 0 && index < dayNames.length) {
                                  // Calculate the date for this day
                                  final weekStart = _chartDate.subtract(
                                    Duration(days: _chartDate.weekday - 1),
                                  );
                                  final currentDate = weekStart.add(
                                    Duration(days: index),
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          dayNames[index],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentDate.day.toString(),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (index) {
                          // Simulate data based on date to make it look dynamic
                          final daySeed = _chartDate.day + index;
                          final value =
                              (daySeed % 8) +
                              2.0; // Random value between 2 and 9

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: value,
                                color:
                                    index == DateTime.now().weekday - 1 &&
                                        _isSameWeek(_chartDate, DateTime.now())
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 10,
                                  color: Colors.grey.shade50,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.minus,
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  if (value > 1) onChanged(value - 1);
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(10),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 35,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => onChanged(value + 1),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(10),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(FocusSession session) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(session.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipe: ${session.sessionType}'),
                Text(
                  session.durationSeconds > 0
                      ? 'Durasi: ${session.durationSeconds ~/ 60} menit ${session.durationSeconds % 60} detik'
                      : 'Durasi: ${session.durationMinutes} menit',
                ),
                const Divider(),
                if (session.sessionType == 'Pomodoro') ...[
                  Text('Fokus: ${session.focusCount} kali'),
                  Text('Istirahat Pendek: ${session.shortBreakCount} kali'),
                  Text('Istirahat Panjang: ${session.longBreakCount} kali'),
                  const SizedBox(height: 8),
                ],
                Text('Jeda: ${session.pauseCount} kali'),
                Text(
                  'Rata-rata Jeda: ${session.averagePauseDurationSeconds.toStringAsFixed(1)} detik',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              if (session.id != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSession(session);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clock,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        session.sessionType,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${session.durationMinutes} min',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (session.id != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _deleteSession(session),
              ),
          ],
        ),
      ),
    );
  }

  int _getWeekOfMonth(DateTime date) {
    // Get the first day of the month
    final firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Calculate the day difference
    final daysDifference = date.difference(firstDayOfMonth).inDays;

    // Week number (starting from 1)
    return (daysDifference / 7).floor() + 1;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1 = _getWeekOfMonth(date1);
    final week2 = _getWeekOfMonth(date2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        week1 == week2;
  }
}
