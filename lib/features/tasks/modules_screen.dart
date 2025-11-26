import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import 'task_list_screen.dart';
import 'module_model.dart';
import '../../core/services/supabase_service.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  String _selectedFilter = 'Semua';
  String _sortOption = 'Terbaru'; // Default sort
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final SupabaseService _supabaseService = SupabaseService();
  List<Module> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    final modules = await _supabaseService.getModules();
    if (mounted) {
      setState(() {
        _modules = modules;
        _isLoading = false;
      });
    }
  }

  List<Module> get _filteredModules {
    final filtered = _modules.where((module) {
      final matchesFilter =
          _selectedFilter == 'Semua' || module.tagName == _selectedFilter;
      final matchesSearch =
          module.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          module.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    // Sorting Logic
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Terdekat':
          return _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate));
        case 'Terlama':
          return _parseDate(b.dueDate).compareTo(_parseDate(a.dueDate));
        case 'Progres Terbanyak':
          return b.progress.compareTo(a.progress);
        case 'Progres Terkecil':
          return a.progress.compareTo(b.progress);
        default:
          return 0;
      }
    });

    return filtered;
  }

  DateTime _parseDate(String dateStr) {
    // Format: "25 Nov 2025" or "15 Des 2025"
    try {
      final parts = dateStr.split(' ');
      if (parts.length != 3) return DateTime.now();

      final day = int.parse(parts[0]);
      final year = int.parse(parts[2]);
      final monthStr = parts[1];

      final monthMap = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'Mei': 5,
        'Jun': 6,
        'Jul': 7,
        'Agu': 8,
        'Sep': 9,
        'Okt': 10,
        'Nov': 11,
        'Des': 12,
      };

      final month = monthMap[monthStr] ?? 1;
      return DateTime(year, month, day);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Urutkan Berdasarkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Terdekat (Deadline)'),
              _buildSortOption('Terlama (Deadline)'),
              _buildSortOption('Progres Terbanyak'),
              _buildSortOption('Progres Terkecil'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _sortOption == option;
    return ListTile(
      title: Text(
        option,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari modul...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Modul & Proyek'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? LucideIcons.x : LucideIcons.search,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowUpDown, size: 20),
                  onPressed: _showSortOptions,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Semua', _selectedFilter == 'Semua'),
                _buildFilterChip(
                  'Pekerjaan',
                  _selectedFilter == 'Pekerjaan',
                  color: const Color(0xFFEF5350),
                ),
                _buildFilterChip(
                  'Kuliah',
                  _selectedFilter == 'Kuliah',
                  color: const Color(0xFF42A5F5),
                ),
                _buildFilterChip(
                  'Personal',
                  _selectedFilter == 'Personal',
                  color: const Color(0xFF66BB6A),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModules.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada modul',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: _filteredModules
                        .map(
                          (module) => _buildModuleCard(
                            context,
                            title: module.title,
                            description: module.description,
                            progress: module.progress,
                            taskCount: module.taskCount,
                            completedCount: module.completedCount,
                            memberCount: module.memberCount,
                            dueDate: module.dueDate,
                            tagColor: module.tagColor,
                            tagName: module.tagName,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (bool value) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Theme.of(context).cardTheme.color,
        selectedColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required double progress,
    required int taskCount,
    required int completedCount,
    required int memberCount,
    required String dueDate,
    required Color tagColor,
    required String tagName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(moduleTitle: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.moreVertical,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 6,
              percent: progress,
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(3),
              backgroundColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.1),
              progressColor: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '$completedCount/$taskCount tugas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.users,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '$memberCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  dueDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tagName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
