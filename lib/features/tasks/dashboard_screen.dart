import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../focus/focus_screen.dart';
import '../finance/budget_screen.dart';
import '../profile/profile_screen.dart';
import 'modules_screen.dart';
import 'dashboard_task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../academic/exam_screen.dart';
import 'notification_screen.dart';
import '../tracking/tracking_screen.dart';
import 'module_model.dart';

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
    try {
      final tasks = await _supabaseService.getTasks();
      final moduleTodos = await _supabaseService.getAllModuleTodos();

      if (mounted) {
        setState(() {
          _tasks = [...tasks, ...moduleTodos];
          // Sort by creation or priority if needed, for now just combined
          // Maybe sort by completion status (incomplete first)
          _tasks.sort((a, b) {
            if (a.isCompleted == b.isCompleted) {
              return 0;
            }
            return a.isCompleted ? 1 : -1;
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            if (task.isModuleTodo && task.moduleId != null) {
              await _supabaseService.toggleModuleTodo(
                task.moduleId!,
                task.id!,
                task.isCompleted,
              );
            } else {
              await _supabaseService.updateTask(task.id!, task.isCompleted);
            }
          } catch (e) {
            // Revert on error
            setState(() {
              task.isCompleted = !task.isCompleted;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mengupdate tugas: $e')),
              );
            }
          }
        },
        onAddTask: (task) async {
          try {
            if (task.isModuleTodo && task.moduleId != null) {
              // Add to module content directly
              await _supabaseService.addTodoToModule(
                task.moduleId!,
                task.title,
              );
            } else {
              // Add as standalone task
              await _supabaseService.addTask(
                title: task.title,
                priority: task.priority,
                moduleName: task.moduleName,
              );
            }
            _fetchTasks(); // Refresh list
          } catch (e) {
            if (context.mounted) {
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
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            _fetchTasks();
          }
        },
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
        final now = DateTime.now();
        final months = [
          '',
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - dengan avatar, tanggal, poin, notifikasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar dan tanggal
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${now.day} ${months[now.month]}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      // Icons kanan - hanya notifikasi
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).cardColor,
                          child: Icon(
                            LucideIcons.bell,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Cards - Streak fokus dan deadline
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStatCard(
                          context,
                          icon: LucideIcons.target,
                          title: 'Sekarang',
                          value: '0 Hari 🔥',
                          subtitle: 'Fokus Hari Ini',
                          backgroundColor: AppColors.tagBlue,
                          textColor: AppColors.tagBlueText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickStatCard(
                          context,
                          icon: LucideIcons.calendar,
                          title: 'Selanjutnya',
                          value: 'Lihat →',
                          subtitle: 'Deadline Terdekat 📅',
                          backgroundColor: AppColors.tagPurple,
                          textColor: AppColors.tagPurpleText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Goal/Target Card
                  _buildGoalCard(context),
                  const SizedBox(height: 24),

                  // Feature Menu Section
                  const Row(
                    children: [
                      Icon(LucideIcons.zap, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Fitur Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Feature - scrollable horizontal
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFeatureItem(
                          context,
                          'Exam',
                          LucideIcons.graduationCap,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExamScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildFeatureItem(
                          context,
                          'Notes',
                          LucideIcons.fileText,
                          () {
                            // Navigator ke NotesScreen (placeholder)
                            Navigator.pushNamed(context, '/notes');
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildFeatureItem(
                          context,
                          'Tracking',
                          LucideIcons.trendingUp,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TrackingScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // To-Do List Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.clipboardList, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'To Do Hari Ini',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showAddTaskDialog(context),
                            icon: const Icon(LucideIcons.plusCircle, size: 20),
                            color: AppColors.primary,
                            tooltip: 'Tambah Tugas Cepat',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (tasks.isNotEmpty)
                        Text(
                          '${tasks.where((t) => !t.isCompleted).length} tersisa',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Task List
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada tugas hari ini',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...tasks
                        .take(3)
                        .map(
                          (task) => _buildToDoItem(context, task, () {
                            // Navigate to Modules tab or Task Detail
                            if (task.isModuleTodo) {
                              // For now just go to modules list, ideally go to specific module
                              onTabChange(1);
                            } else {
                              // Handle standalone task navigation if needed
                            }
                          }, () => onTaskToggle(task)),
                        ),

                  if (tasks.length > 3) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => onTabChange(1), // Navigate to Modules
                        icon: const Icon(LucideIcons.moreHorizontal, size: 18),
                        label: Text('Lihat ${tasks.length - 3} tugas lainnya'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Explore More Section
                  const Text(
                    'Jelajahi lebih luas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildExploreCard(
                    context,
                    icon: '💡',
                    title: 'Quiz Produktivitas',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildExploreCard(
                    context,
                    icon: '🙏',
                    title:
                        'Tingkatkan pengetahuanmu\ndengan mengikuti Tips Produktivitas\nkami hari ini',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tagGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tagGreenText.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.tagGreenText.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.target,
              color: AppColors.tagGreenText,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tetapkan tujuan membaca',
                  style: TextStyle(
                    color: AppColors.tagGreenText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target Tugas Harian 📚 • 1 Hari Check-in',
                  style: TextStyle(
                    color: AppColors.tagGreenText.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: AppColors.tagGreenText.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildToDoItem(
    BuildContext context,
    DashboardTask task,
    VoidCallback onTap,
    VoidCallback onToggle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: task.priorityColor,
                              borderRadius: BorderRadius.circular(4),
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
                            Icon(
                              LucideIcons.folder,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                task.moduleName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddTaskSheet(onAddTask: onAddTask),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final Function(DashboardTask) onAddTask;

  const _AddTaskSheet({required this.onAddTask});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  bool _connectToModule = false;
  String? _selectedModuleId;
  String? _selectedModuleName;
  List<Module> _modules = [];
  bool _isLoadingModules = false;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() => _isLoadingModules = true);
    try {
      final modules = await _supabaseService.getModules();
      if (mounted) {
        setState(() {
          _modules = modules;
          _isLoadingModules = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingModules = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Tugas Cepat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Apa yang ingin dikerjakan?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _connectToModule,
                onChanged: (val) {
                  setState(() {
                    _connectToModule = val ?? false;
                    if (!_connectToModule) {
                      _selectedModuleId = null;
                      _selectedModuleName = null;
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text('Sambungkan ke Modul?'),
            ],
          ),
          if (_connectToModule) ...[
            const SizedBox(height: 8),
            if (_isLoadingModules)
              const LinearProgressIndicator()
            else if (_modules.isEmpty)
              const Text(
                'Belum ada modul tersedia.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Pilih Modul'),
                    value: _selectedModuleId,
                    items: _modules.map((module) {
                      return DropdownMenuItem(
                        value: module.id,
                        child: Text(module.title),
                        onTap: () {
                          setState(() {
                            _selectedModuleName = module.title;
                          });
                        },
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedModuleId = val;
                      });
                    },
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;

                final task = DashboardTask(
                  id: '', // Will be generated
                  title: _titleController.text.trim(),
                  priority: 'Sedang',
                  priorityColor: Colors.orange.shade100,
                  priorityTextColor: Colors.orange.shade900,
                  isCompleted: false,
                  moduleId: _selectedModuleId,
                  moduleName: _selectedModuleName,
                  isModuleTodo: _connectToModule && _selectedModuleId != null,
                );

                widget.onAddTask(task);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Tugas'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
