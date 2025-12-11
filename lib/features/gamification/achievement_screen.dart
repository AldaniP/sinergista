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

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Module> _modules = [];
  List<FocusSession> _sessions = [];

  int xp = 0;
  int level = 1;

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  late PageController _heroPageController;
  int _currentHeroIndex = 0;

  int _totalSessionCountAllTime = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleIn = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _heroPageController = PageController(
      viewportFraction: 0.78,
      initialPage: 0,
    );

    _heroPageController.addListener(() {
      final page = _heroPageController.page ?? 0;
      final rounded = page.round();
      if (_currentHeroIndex != rounded) {
        setState(() => _currentHeroIndex = rounded);
      }
    });

    _fetchData();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final modules = await _supabaseService.getModules();

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final sessions = await _supabase_service_getFocusRangeSafe(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );

      int totalSessionCountAllTime = 0;
      try {
        totalSessionCountAllTime = await _supabaseService
            .getTotalSessionCount();
      } catch (_) {
        totalSessionCountAllTime = 0;
      }

      final int completedTasks = modules.fold<int>(
        0,
        (sum, m) => sum + (m.completedCount ?? 0),
      );
      final int totalMinutes = sessions.fold<int>(
        0,
        (sum, s) => sum + (s.durationMinutes ?? 0),
      );

      xp = (completedTasks * 5) + (totalMinutes ~/ 2);
      level = (xp ~/ 100).clamp(1, 100);

      if (mounted) {
        setState(() {
          _modules = modules;
          _sessions = sessions;
          _totalSessionCountAllTime = totalSessionCountAllTime;
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

  Future<List<FocusSession>> _supabase_service_getFocusRangeSafe(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _supabaseService.getFocusSessionsForDateRange(start, end);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _modules.fold<int>(
      0,
      (sum, m) => sum + (m.completedCount ?? 0),
    );
    final totalMinutes = _sessions.fold<int>(
      0,
      (sum, s) => sum + (s.durationMinutes ?? 0),
    );
    final streak = _sessions.isNotEmpty ? _sessions.length : 0;

    final bool hasLongSession = _sessions.any(
      (s) => (s.durationMinutes ?? 0) >= 120,
    );
    final int totalSessionsAllTime = _totalSessionCountAllTime;
    final int moduleCount = _modules.length;

    final achievements = [
      _AchievementData(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Selesaikan tugas pertama Anda',
        icon: LucideIcons.target,
        color: AppColors.tagPurpleText,
        isUnlocked: completedTasks >= 1,
        progress: (completedTasks / 1).clamp(0.0, 1.0),
        progressText: '$completedTasks/1',
        assetName: 'assets/images/target.png',
      ),
      _AchievementData(
        id: 'task_warrior',
        title: 'Task Warrior',
        description: 'Selesaikan 50 tugas',
        icon: LucideIcons.medal,
        color: AppColors.primary,
        isUnlocked: completedTasks >= 50,
        progress: (completedTasks / 50).clamp(0.0, 1.0),
        progressText: '$completedTasks/50',
        assetName: 'assets/images/star-medal.png',
      ),
      _AchievementData(
        id: 'century_club',
        title: 'Century Club',
        description: 'Selesaikan 100 tugas',
        icon: LucideIcons.award,
        color: AppColors.tagPurpleText,
        isUnlocked: completedTasks >= 100,
        progress: (completedTasks / 100).clamp(0.0, 1.0),
        progressText: '$completedTasks/100',
        assetName: 'assets/images/trophy.png',
      ),
      _AchievementData(
        id: 'streak_master',
        title: 'Streak Master',
        description: '12 sesi fokus (mingguan)',
        icon: LucideIcons.flame,
        color: Colors.deepOrange,
        isUnlocked: streak >= 12,
        progress: (streak / 12).clamp(0.0, 1.0),
        progressText: '$streak/12',
        assetName: 'assets/images/fire.png',
      ),
      _AchievementData(
        id: 'speed_learner',
        title: 'Speed Learner',
        description: '40 jam belajar/minggu',
        icon: LucideIcons.zap,
        color: Colors.amber.shade700,
        isUnlocked: (totalMinutes / 60) >= 40,
        progress: ((totalMinutes / 60) / 40).clamp(0.0, 1.0),
        progressText: '${(totalMinutes / 60).toStringAsFixed(1)}/40 jam',
        assetName: 'assets/images/rocket.png',
      ),
      _AchievementData(
        id: 'organizer_pro',
        title: 'Organizer Pro',
        description: 'Kelola 5 modul aktif',
        icon: LucideIcons.folderOpen,
        color: Colors.teal,
        isUnlocked: moduleCount >= 5,
        progress: (moduleCount / 5).clamp(0.0, 1.0),
        progressText: '$moduleCount/5',
        assetName: 'assets/images/organizer.png',
      ),

      _AchievementData(
        id: 'marathoner',
        title: 'Marathoner',
        description: 'Selesaikan sesi fokus >= 120 menit',
        icon: LucideIcons.activity,
        color: AppColors.primaryDark,
        isUnlocked: hasLongSession,
        progress: hasLongSession ? 1.0 : 0.0,
        progressText: hasLongSession ? '1/1' : '0/1',
        assetName: 'assets/images/marathoner.png',
      ),
      _AchievementData(
        id: 'session_collector',
        title: 'Session Collector',
        description: 'Kumpulkan 50 sesi fokus total',
        icon: LucideIcons.grid,
        color: Colors.green,
        isUnlocked: totalSessionsAllTime >= 50,
        progress: (totalSessionsAllTime / 50).clamp(0.0, 1.0),
        progressText: '$totalSessionsAllTime/50',
        assetName: 'assets/images/collector.png',
      ),
      _AchievementData(
        id: 'module_maestro',
        title: 'Module Maestro',
        description: 'Buat 10 modul aktif',
        icon: LucideIcons.layout,
        color: Colors.brown,
        isUnlocked: moduleCount >= 10,
        progress: (moduleCount / 10).clamp(0.0, 1.0),
        progressText: '$moduleCount/10',
        assetName: 'assets/images/maestro.png',
      ),
    ];

    final tiers = [
      _TierData(
        id: 'spark',
        title: 'Rookie Spark',
        subtitle: 'Mulai perjalananmu',
        assetName: 'assets/images/amazing.png',
        color: AppColors.tagPurpleText,
        threshold: 1,
      ),
      _TierData(
        id: 'sparkle',
        title: 'Rising Sparkle',
        subtitle: 'Lebih fokus, lebih cepat',
        assetName: 'assets/images/best_student.png',
        color: AppColors.primary,
        threshold: 6,
      ),
      _TierData(
        id: 'ace',
        title: 'Gold Ace',
        subtitle: 'Kuasai tantangan',
        assetName: 'assets/images/bravo.png',
        color: Colors.amber.shade700,
        threshold: 11,
      ),
      _TierData(
        id: 'pro',
        title: 'Platinum Pro',
        subtitle: 'Prestasi menonjol',
        assetName: 'assets/images/great_job.png',
        color: Colors.indigo,
        threshold: 21,
      ),
      _TierData(
        id: 'legend',
        title: 'Legendary Star',
        subtitle: 'Level tertinggi',
        assetName: 'assets/images/well_done.png',
        color: Colors.cyan,
        threshold: 31,
      ),
    ];

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final overallProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadowColor = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.12);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Level Akun',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _buildHeroBadgeCarousel(
                      level,
                      tiers,
                      cardShadowColor,
                      overallProgress,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ScaleTransition(
                            scale: _scaleIn,
                            child: _buildXPCard(
                              cardShadowColor,
                              overallProgress,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.74,
                      children: achievements
                          .map(
                            (achievement) => ScaleTransition(
                              scale: _scaleIn,
                              child: _buildAchievementCard(
                                context,
                                data: achievement,
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBadgeCarousel(
    int level,
    List<_TierData> tiers,
    Color shadowColor,
    double overallProgress,
  ) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _heroPageController,
        itemCount: tiers.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final t = tiers[index];
          final unlocked = level >= t.threshold;
          final isCurrent = index == _currentHeroIndex;
          final scale = isCurrent ? 1.00 : 0.92;
          final opacity = isCurrent ? 1.0 : 0.80;

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                  _heroPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: isCurrent ? 28 : 12,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: unlocked
                          ? t.color.withOpacity(0.12)
                          : Colors.transparent,
                      width: isCurrent ? 1.8 : 0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ColorFiltered(
                              colorFilter: unlocked
                                  ? const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    )
                                  : const ColorFilter.matrix(<double>[
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0, 0, 0, 1, 0,
                                    ]),
                              child: Image.asset(
                                t.assetName,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: t.color.withOpacity(0.10),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.award,
                                          color: unlocked
                                              ? t.color
                                              : Colors.grey,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18.0,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearPercentIndicator(
                                        padding: EdgeInsets.zero,
                                        lineHeight: 8,
                                        percent: (level >= t.threshold
                                            ? 1.0
                                            : (level / (t.threshold + 2)).clamp(
                                                0.0,
                                                1.0,
                                              )),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.06),
                                        progressColor: AppColors.tagPurpleText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: unlocked
                                          ? t.color.withOpacity(0.14)
                                          : Colors.grey.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      unlocked ? 'Unlocked' : 'Locked',
                                      style: TextStyle(
                                        color: unlocked ? t.color : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildXPCard(Color shadowColor, double overallProgress) {
    final int xpNeeded = level * 100;
    final double progress = xpNeeded == 0 ? 0 : (xp % xpNeeded) / xpNeeded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LevelBadge(level: level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8,
                        percent: progress,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        progressColor: AppColors.tagPurpleText,
                        barRadius: const Radius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$xp / $xpNeeded XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.award,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Overall Progress',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      Text(
                        '${(overallProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required _AchievementData data,
  }) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(data),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: data.isUnlocked
                  ? data.color.withOpacity(0.12)
                  : Colors.black12,
              blurRadius: data.isUnlocked ? 14 : 6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgeIllustrationAsset(
              assetName: data.assetName,
              size: 56,
              unlocked: data.isUnlocked,
              color: data.color,
              fallbackIcon: data.icon,
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            data.isUnlocked
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Tercapai",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: data.color,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 6,
                          percent: data.progress,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.08),
                          progressColor: AppColors.tagPurpleText,
                          barRadius: const Radius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.progressText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(_AchievementData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                    child: _BadgeIllustrationAsset(
                      assetName: data.assetName,
                      size: 36,
                      unlocked: data.isUnlocked,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(data.description),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!data.isUnlocked) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 10,
                    percent: data.progress,
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.08),
                    progressColor: AppColors.tagPurpleText,
                    barRadius: const Radius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(data.progressText),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text('Selamat! Achievement ini sudah tercapai.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _tierName(int level) {
    if (level >= 31) return 'Legendary Star';
    if (level >= 21) return 'Platinum Pro';
    if (level >= 11) return 'Gold Ace';
    if (level >= 6) return 'Rising Sparkle';
    return 'Rookie Spark';
  }

  Color _tierColor(int level) {
    if (level >= 31) return Colors.cyan;
    if (level >= 21) return Colors.indigo;
    if (level >= 11) return Colors.amber.shade700;
    if (level >= 6) return AppColors.primary;
    return AppColors.tagPurpleText;
  }
}

class _AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String progressText;
  final String assetName;

  _AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    required this.progressText,
    required this.assetName,
  });
}

class _TierData {
  final String id;
  final String title;
  final String subtitle;
  final String assetName;
  final Color color;
  final int threshold;

  _TierData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetName,
    required this.color,
    required this.threshold,
  });
}

class _BadgeIllustrationAsset extends StatelessWidget {
  final String assetName;
  final double size;
  final bool unlocked;
  final Color color;
  final IconData? fallbackIcon;

  const _BadgeIllustrationAsset({
    required this.assetName,
    this.size = 48,
    this.unlocked = false,
    this.color = AppColors.primary,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = BoxDecoration(
      shape: BoxShape.circle,
      gradient: unlocked
          ? RadialGradient(
              colors: [color.withOpacity(0.95), color.withOpacity(0.6)],
            )
          : RadialGradient(
              colors: [Colors.grey.shade200, Colors.grey.shade100],
            ),
      boxShadow: unlocked
          ? [
              BoxShadow(
                color: color.withOpacity(0.22),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
    );

    return Container(
      width: size + 12,
      height: size + 12,
      decoration: border,
      child: ClipOval(
        child: Image.asset(
          assetName,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                fallbackIcon ?? LucideIcons.award,
                color: unlocked ? Colors.white : Colors.grey,
                size: size * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final badgeColor = level >= 30
        ? Colors.purple
        : level >= 11
        ? Colors.amber
        : AppColors.tagPurpleText;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadow = BoxShadow(
      color: isDark
          ? Colors.black.withOpacity(0.6)
          : Colors.black.withOpacity(0.12),
      blurRadius: 10,
      offset: const Offset(0, 8),
    );

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [badgeColor.withOpacity(0.98), badgeColor.withOpacity(0.65)],
        ),
        shape: BoxShape.circle,
        boxShadow: [shadow],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lv',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFlame extends StatefulWidget {
  final Color color;
  final bool active;
  const _AnimatedFlame({required this.color, this.active = true});

  @override
  State<_AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<_AnimatedFlame>
    with SingleTickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _scale;
  late Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
        );
    _alpha =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
        );
    if (widget.active) _flameController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_flameController.isAnimating) {
      _flameController.repeat(reverse: true);
    } else if (!widget.active && _flameController.isAnimating) {
      _flameController.stop();
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flameController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _alpha.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(0.95),
                    widget.color.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.flame, color: Colors.white, size: 22),
              ),
            ),
          ),
        );
      },
    );
  }
}
