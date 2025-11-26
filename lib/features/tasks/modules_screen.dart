import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import 'task_list_screen.dart';
import 'module_model.dart';
import '../../core/services/supabase_service.dart';
import 'module_detail_screen.dart';

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

  List<Map<String, dynamic>> get _activeCategories {
    final Map<String, Color> categories = {};
    for (var module in _modules) {
      if (!categories.containsKey(module.tagName)) {
        categories[module.tagName] = module.tagColor;
      }
    }
    return categories.entries
        .map((e) => {'name': e.key, 'color': e.value})
        .toList();
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
                const SizedBox(width: 8),
                _buildFilterChip('Semua', _selectedFilter == 'Semua'),
                ..._activeCategories.map((category) {
                  return _buildFilterChip(
                    category['name'],
                    _selectedFilter == category['name'],
                    color: category['color'],
                  );
                }),
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
                            moduleId: module.id,
                            onDelete: () => _deleteModule(module.id),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateSelection(context),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showTemplateSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.layoutTemplate,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Template Modul',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTemplateOption(
                  icon: LucideIcons.file,
                  title: 'Kosong',
                  description: 'Mulai dari awal tanpa template',
                  color: Colors.grey,
                ),
                _buildTemplateOption(
                  icon: LucideIcons.checkSquare,
                  title: 'To-Do List',
                  description: 'Daftar tugas sederhana',
                  color: Colors.blue,
                ),
                _buildTemplateOption(
                  icon: LucideIcons.graduationCap,
                  title: 'Akademik',
                  description: 'Untuk keperluan sekolah atau kuliah',
                  color: Colors.orange,
                ),
                _buildTemplateOption(
                  icon: LucideIcons.trendingUp,
                  title: 'Bisnis',
                  description: 'Manajemen usaha dan bisnis',
                  color: Colors.purple,
                ),
                _buildTemplateOption(
                  icon: LucideIcons.briefcase,
                  title: 'Kerja',
                  description: 'Proyek dan tugas pekerjaan',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (title == 'Kosong') {
          await _showColorSelectionDialog(context);
        } else {
          // TODO: Navigate to create module screen with this template
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Memilih template: $title')));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
              LucideIcons.chevronRight,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
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
    String? moduleId,
    VoidCallback? onDelete,
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
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).iconTheme.color?.withValues(alpha: 0.5),
                  ),
                  onSelected: (value) {
                    if (value == 'delete' && onDelete != null) {
                      _showDeleteConfirmation(context, title, onDelete);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Modul',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (taskCount > 0) ...[
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
            ],
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

  void _showDeleteConfirmation(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Modul?'),
        content: Text('Apakah Anda yakin ingin menghapus modul "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModule(String? id) async {
    if (id == null) return;
    try {
      await _supabaseService.deleteModule(id);
      _fetchModules(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Modul berhasil dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus modul: $e')));
      }
    }
  }

  Future<void> _showColorSelectionDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          ColorSelectionDialog(existingCategories: _activeCategories),
    );

    if (result != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModuleDetailScreen(
            categoryName: result['category'],
            categoryColor: result['color'],
          ),
        ),
      );
      _fetchModules();
    }
  }
}

class ColorSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingCategories;

  const ColorSelectionDialog({super.key, this.existingCategories = const []});

  @override
  State<ColorSelectionDialog> createState() => _ColorSelectionDialogState();
}

class _ColorSelectionDialogState extends State<ColorSelectionDialog> {
  String? _selectedCategory;
  Color? _selectedColor;
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isCreatingNew = false;

  final Map<String, Color> _categories = {
    'Pekerjaan': const Color(0xFFEF5350),
    'Kuliah': const Color(0xFF42A5F5),
    'Personal': const Color(0xFF66BB6A),
  };

  @override
  void initState() {
    super.initState();
    // Merge existing categories from parent
    for (var cat in widget.existingCategories) {
      if (!_categories.containsKey(cat['name'])) {
        _categories[cat['name']] = cat['color'];
      }
    }
  }

  final List<Color> _availableColors = [
    const Color(0xFFEF5350), // Red
    const Color(0xFF42A5F5), // Blue
    const Color(0xFF66BB6A), // Green
    const Color(0xFFAB47BC), // Purple
    const Color(0xFFFFA726), // Orange
    const Color(0xFF26C6DA), // Cyan
    const Color(0xFF8D6E63), // Brown
    const Color(0xFF78909C), // Blue Grey
  ];

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Kategori'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isCreatingNew) ...[
              ..._categories.entries.map((entry) {
                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.key),
                    ],
                  ),
                  value: entry.key,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedColor = entry.value;
                    });
                  },
                );
              }),
              ListTile(
                leading: const Icon(LucideIcons.plus),
                title: const Text('Tambah Kategori Baru'),
                onTap: () {
                  setState(() {
                    _isCreatingNew = true;
                    _selectedCategory = null;
                    _selectedColor = _availableColors.first;
                  });
                },
              ),
            ] else ...[
              TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Contoh: Hobi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pilih Warna:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isCreatingNew = false),
                child: const Text('Kembali ke Daftar'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isCreatingNew) {
              if (_newCategoryController.text.isNotEmpty &&
                  _selectedColor != null) {
                Navigator.pop(context, {
                  'category': _newCategoryController.text,
                  'color': _selectedColor,
                });
              }
            } else {
              if (_selectedCategory != null && _selectedColor != null) {
                Navigator.pop(context, {
                  'category': _selectedCategory,
                  'color': _selectedColor,
                });
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}
