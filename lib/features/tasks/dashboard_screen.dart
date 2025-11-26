import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../focus/focus_screen.dart';
import '../finance/budget_screen.dart';
import '../profile/profile_screen.dart';
import 'modules_screen.dart';
import 'task_list_screen.dart';
import 'dashboard_task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _supabaseService = SupabaseService();
  List<DashboardTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _supabaseService.getTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardHome(
        onTabChange: (index) => setState(() => _selectedIndex = index),
        tasks: _tasks,
        isLoading: _isLoading,
        onTaskToggle: (task) async {
          if (task.id == null) return;
          // Optimistic update
          setState(() {
            task.isCompleted = !task.isCompleted;
          });
          try {
            await _supabaseService.updateTask(task.id!, task.isCompleted);
          } catch (e) {
            // Revert on error
            setState(() {
              task.isCompleted = !task.isCompleted;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mengupdate tugas: $e')),
              );
            }
          }
        },
        onAddTask: (task) async {
          try {
            await _supabaseService.addTask(
              title: task.title,
              priority: task.priority,
              moduleName: task.moduleName,
            );
            _fetchTasks(); // Refresh list
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menyimpan tugas: $e')),
              );
            }
          }
        },
      ),
      const ModulesScreen(),
      const FocusScreen(), // Placeholder for Focus
      const BudgetScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.folder),
            label: 'Modul',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.clock),
            label: 'Fokus',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  final Function(int) onTabChange;
  final List<DashboardTask> tasks;
  final Function(DashboardTask) onTaskToggle;
  final Function(DashboardTask) onAddTask;
  final bool isLoading;

  const DashboardHome({
    super.key,
    required this.onTabChange,
    required this.tasks,
    required this.onTaskToggle,
    required this.onAddTask,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            snapshot.data?.session?.user ??
            Supabase.instance.client.auth.currentUser;
        final userName =
            user?.userMetadata?['full_name']?.split(' ').first ?? 'Pengguna';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, $userName! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hari ini, Senin, 24 November',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).cardColor,
                      child: Icon(
                        LucideIcons.bell,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: LucideIcons.checkCircle,
                        value: '12',
                        label: 'Tugas Selesai',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: LucideIcons.clock,
                        value: '24h',
                        label: 'Fokus Minggu Ini',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Shortcut Box
                const Row(
                  children: [
                    Icon(LucideIcons.zap, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Shortcut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildShortcutBox(context, 'Exam', LucideIcons.graduationCap),
                const SizedBox(height: 24),

                // Today's Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.target, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tugas Hari Ini',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${tasks.length} tugas',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showAddTaskDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (tasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Belum ada tugas hari ini'),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => _buildTaskItem(
                      context,
                      task: task,
                      onToggle: () => onTaskToggle(task),
                    ),
                  ),

                const SizedBox(height: 24),
                // Deadlines
                const Row(
                  children: [
                    Icon(LucideIcons.alertCircle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Deadline Mendatang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDeadlineItem(
                  context,
                  date: '18',
                  month: 'Nov',
                  title: 'Submission Proposal Klien',
                  subtitle: 'Project Alpha',
                ),
                _buildDeadlineItem(
                  context,
                  date: '20',
                  month: 'Nov',
                  title: 'Ujian Midterm',
                  subtitle: 'Matematika',
                ),
                _buildDeadlineItem(
                  context,
                  date: '22',
                  month: 'Nov',
                  title: 'Presentasi Q4',
                  subtitle: 'Work',
                ),

                const SizedBox(height: 24),
                // Focus CTA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai Sesi Fokus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tingkatkan produktivitas dengan Pomodoro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => onTabChange(2), // Switch to Focus tab
                        icon: const Icon(
                          LucideIcons.timer,
                          color: Color(0xFFFF5722),
                        ),
                        label: const Text(
                          'Mulai',
                          style: TextStyle(color: Color(0xFFFF5722)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Module Progress
                const Row(
                  children: [
                    Icon(LucideIcons.trendingUp, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Progress Modul',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressItem(context, 'Project Alpha', 0.65),
                _buildProgressItem(context, 'Skripsi', 0.40),
                _buildProgressItem(context, 'Side Project', 0.80),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onTabChange(1), // Switch to Modules tab
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Lihat Semua Modul',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    String selectedPriority = 'Sedang';
    String? selectedModule;
    final List<String> priorities = ['Tinggi', 'Sedang', 'Rendah'];
    final List<String> modules = [
      'Project Alpha',
      'Skripsi',
      'Side Project',
      'Lainnya',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tugas Baru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      hintText: 'Apa yang ingin dikerjakan?',
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor ??
                          Colors.grey.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prioritas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: priorities.map((priority) {
                      final isSelected = selectedPriority == priority;
                      Color chipColor;
                      Color textColor;

                      switch (priority) {
                        case 'Tinggi':
                          chipColor = isSelected
                              ? AppColors.tagRed
                              : AppColors.tagRed.withValues(alpha: 0.1);
                          textColor = AppColors.tagRedText;
                          break;
                        case 'Sedang':
                          chipColor = isSelected
                              ? Colors.orange.shade100
                              : Colors.orange.shade50;
                          textColor = Colors.orange.shade900;
                          break;
                        case 'Rendah':
                          chipColor = isSelected
                              ? Colors.green.shade100
                              : Colors.green.shade50;
                          textColor = Colors.green.shade800;
                          break;
                        default:
                          chipColor = Colors.grey.shade100;
                          textColor = Colors.black;
                      }

                      return InkWell(
                        onTap: () {
                          setState(() => selectedPriority = priority);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? textColor.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Modul (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedModule,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor ??
                          Colors.grey.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    hint: const Text('Pilih Modul'),
                    icon: const Icon(LucideIcons.chevronDown, size: 20),
                    items: modules.map((module) {
                      return DropdownMenuItem(
                        value: module,
                        child: Text(module),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedModule = value);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final color = switch (selectedPriority) {
                        'Tinggi' => AppColors.tagRed,
                        'Rendah' => Colors.green.shade100,
                        _ => Colors.grey.shade100,
                      };
                      final textColor = switch (selectedPriority) {
                        'Tinggi' => AppColors.tagRedText,
                        'Rendah' => Colors.green.shade800,
                        _ => Colors.black,
                      };

                      onAddTask(
                        DashboardTask(
                          title: titleController.text,
                          priority: selectedPriority,
                          priorityColor: color,
                          priorityTextColor: textColor,
                          moduleName: selectedModule,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Tugas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context, {
    required DashboardTask task,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Checkbox Area
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                task.isCompleted ? LucideIcons.checkSquare : LucideIcons.square,
                color: task.isCompleted
                    ? AppColors.primary
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Task Info Area
          Expanded(
            child: InkWell(
              onTap: onToggle, // Tapping text also toggles
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? Colors.grey
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.priorityColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.priorityTextColor,
                          ),
                        ),
                      ),
                      if (task.moduleName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            task.moduleName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Navigation Arrow
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TaskListScreen(moduleTitle: 'Detail Tugas'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(
    BuildContext context, {
    required String date,
    required String month,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFEF5350).withValues(alpha: 0.2)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFD32F2F),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String label,
    double percent,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(moduleTitle: label),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: percent,
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(4),
              backgroundColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.1),
              progressColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutBox(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () {
        // Handle shortcut action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label shortcut clicked'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
