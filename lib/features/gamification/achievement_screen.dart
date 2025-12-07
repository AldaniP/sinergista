import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../tasks/module_model.dart';
import '../focus/focus_session_model.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Module> _modules = [];
  List<FocusSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final modules = await _supabaseService.getModules();

      // Fetch stats for a wider range or just all time if possible,
      // but matching TrackingScreen logic which uses weekly for now.
      // To be better, let's fetch a reasonable range, e.g., last 30 days for streak?
      // TrackingScreen fetched this week. Let's start with that to match logic.
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final sessions = await _supabaseService.getFocusSessionsForDateRange(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );

      if (mounted) {
        setState(() {
          _modules = modules;
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data achievement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- CALCULATION LOGIC ---
    final completedTasks = _modules.fold(0, (sum, m) => sum + m.completedCount);
    final totalMinutes = _sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    // Naive streak from TrackingScreen
    final streak = _sessions.isNotEmpty ? _sessions.length : 0;

    // Define Achievements
    final achievements = [
      _AchievementData(
        title: 'First Steps',
        description: 'Selesaikan tugas pertama Anda',
        icon: LucideIcons.target,
        color: Colors.orange,
        isUnlocked: completedTasks >= 1,
        progress: (completedTasks / 1).clamp(0.0, 1.0),
        progressText: '$completedTasks/1',
      ),
      _AchievementData(
        title: 'Task Warrior',
        description: 'Selesaikan 50 tugas',
        icon: LucideIcons.medal,
        color: Colors.blue,
        isUnlocked: completedTasks >= 50,
        progress: (completedTasks / 50).clamp(0.0, 1.0),
        progressText: '$completedTasks/50',
      ),
      _AchievementData(
        title: 'Century Club',
        description: 'Selesaikan 100 tugas',
        icon: LucideIcons.award,
        color: Colors.purple,
        isUnlocked: completedTasks >= 100,
        progress: (completedTasks / 100).clamp(0.0, 1.0),
        progressText: '$completedTasks/100',
      ),
      _AchievementData(
        title: 'Streak Master',
        description: '12 sesi fokus (mingguan)',
        icon: LucideIcons.flame,
        color: Colors.red,
        isUnlocked: streak >= 12,
        progress: (streak / 12).clamp(0.0, 1.0),
        progressText: '$streak/12',
      ),
      _AchievementData(
        title: 'Speed Learner',
        description: '40 jam belajar/minggu',
        icon: LucideIcons.zap,
        color: Colors.yellow.shade800,
        isUnlocked: (totalMinutes / 60) >= 40,
        progress: ((totalMinutes / 60) / 40).clamp(0.0, 1.0),
        progressText: '${(totalMinutes / 60).toStringAsFixed(1)}/40 jam',
      ),
      _AchievementData(
        title: 'Organizer Pro',
        description: 'Kelola 5 modul aktif',
        icon: LucideIcons.folderOpen,
        color: Colors.teal,
        isUnlocked: _modules.length >= 5,
        progress: (_modules.length / 5).clamp(0.0, 1.0),
        progressText: '${_modules.length}/5',
      ),
    ];

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final overallProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Achievement'),
            if (!_isLoading)
              Text(
                '$unlockedCount dari $totalCount lencana didapat',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.trophy,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progress Keseluruhan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                padding: EdgeInsets.zero,
                                lineHeight: 8,
                                percent: overallProgress,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                progressColor: Colors.white,
                                barRadius: const Radius.circular(10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(overallProgress * 100).toInt()}% selesai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Achievement Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70, // Adjusted for content
                    children: achievements
                        .map(
                          (achievement) =>
                              _buildAchievementCard(context, data: achievement),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required _AchievementData data,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.isUnlocked
                  ? data.color
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.isUnlocked ? data.icon : LucideIcons.lock,
              color: data.isUnlocked
                  ? Colors.white
                  : Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          if (!data.isUnlocked)
            Column(
              children: [
                LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 6,
                  percent: data.progress,
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.1),
                  progressColor: AppColors.primary,
                  barRadius: const Radius.circular(10),
                ),
                const SizedBox(height: 4),
                Text(
                  data.progressText,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Tercapai",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: data.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String progressText;

  _AchievementData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    required this.progressText,
  });
}
