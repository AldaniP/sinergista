import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/supabase_service.dart';
import '../tasks/module_model.dart';
import '../focus/focus_session_model.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;

  List<Module> _modules = [];
  List<FocusSession> _weeklySessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final modules = await _supabaseService.getModules();

      // Fetch weekly focus sessions
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
          _weeklySessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            Text(
              'Pantau perkembangan belajar Anda',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Ringkasan'),
                Tab(text: 'Modul'),
                Tab(text: 'Pencapaian'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildModulesTab(),
                      _buildAchievementsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: RINGKASAN ---
  Widget _buildSummaryTab() {
    final completedTasks = _modules.fold(0, (sum, m) => sum + m.completedCount);
    final totalMinutes = _weeklySessions.fold(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    // Mock streak calculation (real implementation would need daily history)
    final streak = _weeklySessions.isNotEmpty ? _weeklySessions.length : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.target,
                  value: '$completedTasks',
                  label: 'Tugas Selesai',
                  color: Colors.blue,
                  bgColor: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.clock,
                  value: totalHours,
                  label: 'Jam Belajar',
                  color: Colors.purple,
                  bgColor: Colors.purple.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.bookOpen,
                  value:
                      '${_modules.length}/${_modules.length}', // Active/Total
                  label: 'Modul',
                  color: Colors.green,
                  bgColor: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.trendingUp,
                  value: '$streak',
                  label: 'Hari Streak',
                  color: Colors.orange,
                  bgColor: Colors.orange.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Target
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Mingguan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${((totalMinutes / 60) / 40 * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalHours / 40 jam',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (totalMinutes / 60 / 40).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.grey[100],
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Activity Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktivitas Mingguan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 120, // Max minutes per day assumption
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.black,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.round()}m',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Sen',
                                'Sel',
                                'Rab',
                                'Kam',
                                'Jum',
                                'Sab',
                                'Min',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
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
                        // Calculate daily total
                        final day = DateTime.now()
                            .subtract(
                              Duration(days: DateTime.now().weekday - 1),
                            )
                            .add(Duration(days: index));
                        final dailyMinutes = _weeklySessions
                            .where(
                              (s) =>
                                  s.date.day == day.day &&
                                  s.date.month == day.month,
                            )
                            .fold(0, (sum, s) => sum + s.durationMinutes);

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: dailyMinutes.toDouble(),
                              color: dailyMinutes > 0
                                  ? Colors.black
                                  : Colors.grey[200],
                              width: 12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jam belajar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // --- TAB 2: MODUL ---
  Widget _buildModulesTab() {
    if (_modules.isEmpty) {
      return const Center(child: Text('Belum ada modul'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final module = _modules[index];
        final percentage = (module.progress * 100).round();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: module.tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: module.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[100],
                  color: Colors.black, // Minimalist style
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${module.completedCount}/${module.taskCount} tugas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '2 jam lalu', // Placeholder for last active
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: PENCAPAIAN ---
  Widget _buildAchievementsTab() {
    // Logic for achievements
    final completedTasks = _modules.fold(0, (sum, m) => sum + m.completedCount);
    final totalMinutes = _weeklySessions.fold(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final streak = _weeklySessions.isNotEmpty ? _weeklySessions.length : 0;

    final achievements = [
      _Achievement(
        title: 'Streak Master',
        description: '12 hari berturut-turut', // Mock target
        isUnlocked: streak >= 12,
        progress: streak / 12,
        icon: LucideIcons.flame,
        color: Colors.orange,
      ),
      _Achievement(
        title: 'Task Warrior',
        description: 'Selesaikan 50 tugas',
        isUnlocked: completedTasks >= 50,
        progress: completedTasks / 50,
        icon: LucideIcons.medal,
        color: Colors.blue,
      ),
      _Achievement(
        title: 'Speed Learner',
        description: '40 jam belajar/minggu',
        isUnlocked: (totalMinutes / 60) >= 40,
        progress: (totalMinutes / 60) / 40,
        icon: LucideIcons.zap,
        color: Colors.purple,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = achievements[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: item.isUnlocked
                ? Border.all(color: Colors.black, width: 1.5)
                : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.isUnlocked ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.isUnlocked ? Colors.white : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: item.isUnlocked
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isUnlocked)
                    const Icon(LucideIcons.checkCircle2, color: Colors.black),
                ],
              ),
              if (!item.isUnlocked) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      '${(item.progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[100],
                    color: Colors.grey[600],
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final IconData icon;
  final Color color;

  _Achievement({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progress,
    required this.icon,
    required this.color,
  });
}
