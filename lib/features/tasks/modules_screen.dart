import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import 'package:uuid/uuid.dart';
import 'module_model.dart';
import '../../core/services/supabase_service.dart';
import 'module_editor_screen.dart';

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

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final modules = await _supabaseService.getModules();
      if (mounted) {
        setState(() {
          _modules = modules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat modul: $e')));
      }
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
        case 'Terdekat (Deadline)':
          return _compareDates(a.dueDate, b.dueDate, ascending: true);
        case 'Terlama (Deadline)':
          return _compareDates(a.dueDate, b.dueDate, ascending: false);
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

  int _compareDates(String? dateA, String? dateB, {required bool ascending}) {
    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1; // Null dates go to the bottom
    if (dateB == null) return -1;

    final dtA = _parseDate(dateA);
    final dtB = _parseDate(dateB);

    return ascending ? dtA.compareTo(dtB) : dtB.compareTo(dtA);
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
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
    // Extract unique categories from modules
    final categories = ['Semua', ..._modules.map((m) => m.tagName).toSet()];

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
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
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
                ...categories.map((category) {
                  // Find a color for this category if possible
                  Color? categoryColor;
                  if (category != 'Semua') {
                    final module = _modules.firstWhere(
                      (m) => m.tagName == category,
                      orElse: () => Module(
                        id: '',
                        userId: '',
                        title: '',
                        description: '',
                        progress: 0,
                        completedCount: 0,
                        taskCount: 0,
                        memberCount: 0,
                        dueDate: '',
                        tagColor: Colors.grey,
                        tagName: '',
                      ),
                    );
                    if (module.tagName.isNotEmpty) {
                      categoryColor = module.tagColor;
                    }
                  }

                  return _buildFilterChip(
                    category,
                    _selectedFilter == category,
                    color: categoryColor,
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
                    child: _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.alertTriangle,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Terjadi Kesalahan',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _fetchModules,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            'Belum ada modul',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: _filteredModules
                        .map(
                          (module) => _buildModuleCard(context, module: module),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTemplateSelectionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showTemplateSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Template',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTemplateOption(
                icon: LucideIcons.file,
                title: 'Kosong',
                color: Colors.grey,
                onTap: () => _showCreateModuleDialog(template: 'Kosong'),
              ),
              _buildTemplateOption(
                icon: LucideIcons.graduationCap,
                title: 'Akademik',
                color: Colors.blue,
                onTap: () => _showCreateModuleDialog(template: 'Akademik'),
              ),
              _buildTemplateOption(
                icon: LucideIcons.briefcase,
                title: 'Pekerjaan',
                color: Colors.red,
                onTap: () => _showCreateModuleDialog(template: 'Pekerjaan'),
              ),
              _buildTemplateOption(
                icon: LucideIcons.store,
                title: 'Bisnis',
                color: Colors.orange,
                onTap: () => _showCreateModuleDialog(template: 'Bisnis'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(LucideIcons.chevronRight, size: 20),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        onTap();
      },
    );
  }

  void _showCreateModuleDialog({required String template}) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final dateController = TextEditingController();
    DateTime? selectedDate;

    // Pre-fill based on template
    Color selectedColor = Colors.blue;
    if (template == 'Akademik') {
      categoryController.text = 'Kuliah';
      selectedColor = const Color(0xFF42A5F5);
    } else if (template == 'Pekerjaan') {
      categoryController.text = 'Pekerjaan';
      selectedColor = const Color(0xFFEF5350);
    } else if (template == 'Bisnis') {
      categoryController.text = 'Bisnis';
      selectedColor = Colors.orange;
    }

    // Get unique existing categories
    final existingCategories = _modules
        .map((m) => {'name': m.tagName, 'color': m.tagColor})
        .toSet()
        .toList();
    // Remove duplicates based on name (since color might vary slightly or we just want unique names)
    final uniqueCategories = <String, Map<String, dynamic>>{};
    for (var cat in existingCategories) {
      uniqueCategories[cat['name'] as String] = cat;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Buat Modul Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Nama Modul',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Buat Kategori',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (uniqueCategories.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          final filteredCategories = uniqueCategories.values
                              .where((cat) {
                                final name = cat['name'] as String;
                                return name.toLowerCase().contains(
                                  categoryController.text.toLowerCase(),
                                );
                              })
                              .toList();

                          if (filteredCategories.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const Text(
                                'Pilih Kategori Ada:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: filteredCategories.map((cat) {
                                  return ActionChip(
                                    label: Text(
                                      cat['name'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: (cat['color'] as Color)
                                        .withOpacity(0.1),
                                    side: BorderSide.none,
                                    onPressed: () {
                                      setState(() {
                                        categoryController.text = cat['name'];
                                        selectedColor = cat['color'];
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Batas Waktu',
                        hintText: 'dd/mm/yyyy',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  setState(() {
                                    selectedDate = null;
                                    dateController.clear();
                                  });
                                },
                              ),
                            const Icon(LucideIcons.calendar, size: 20),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            final months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'Mei',
                              'Jun',
                              'Jul',
                              'Agu',
                              'Sep',
                              'Okt',
                              'Nov',
                              'Des',
                            ];
                            dateController.text =
                                '${picked.day} ${months[picked.month - 1]} ${picked.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Warna Kategori',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildColorOption(
                            const Color(0xFFEF5350),
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                          _buildColorOption(
                            const Color(0xFF42A5F5),
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                          _buildColorOption(
                            const Color(0xFF66BB6A),
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                          _buildColorOption(
                            Colors.orange,
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                          _buildColorOption(
                            Colors.purple,
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                          _buildColorOption(
                            Colors.teal,
                            selectedColor,
                            (c) => setState(() => selectedColor = c),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        categoryController.text.isNotEmpty) {
                      await _createModule(
                        titleController.text,
                        categoryController.text,
                        selectedColor,
                        template,
                        selectedDate,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Buat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorOption(
    Color color,
    Color selectedColor,
    Function(Color) onSelect,
  ) {
    final isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
        child: isSelected
            ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Future<void> _createModule(
    String title,
    String category,
    Color color,
    String template,
    DateTime? dueDate,
  ) async {
    try {
      List<Map<String, dynamic>>? initialContent;

      if (template == 'Akademik') {
        initialContent = [
          {
            'id': const Uuid().v4(),
            'type': 'heading1',
            'content': 'Jadwal Kuliah',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'bullet',
            'content': 'Senin: ...',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'heading1',
            'content': 'Tugas & Deadline',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'todo',
            'content': 'Tugas 1',
            'isChecked': false,
          },
        ];
      } else if (template == 'Pekerjaan') {
        initialContent = [
          {
            'id': const Uuid().v4(),
            'type': 'heading1',
            'content': 'Prioritas Hari Ini',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'todo',
            'content': 'Meeting dengan tim',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'heading1',
            'content': 'Catatan Meeting',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'text',
            'content': '',
            'isChecked': false,
          },
        ];
      } else if (template == 'Bisnis') {
        initialContent = [
          {
            'id': const Uuid().v4(),
            'type': 'heading1',
            'content': 'Overview Bisnis',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'heading2',
            'content': 'Keuangan',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'bullet',
            'content': 'Pemasukan: ...',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'heading2',
            'content': 'Marketing',
            'isChecked': false,
          },
          {
            'id': const Uuid().v4(),
            'type': 'todo',
            'content': 'Post Instagram',
            'isChecked': false,
          },
        ];
      }

      await _supabaseService.createModule(
        title: title,
        description: 'Modul $template',
        tagName: category,
        tagColor: color.value,
        dueDate: dueDate,
        content: initialContent,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Modul berhasil dibuat')));
      }
      _fetchModules(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat modul: $e')));
      }
    }
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
                : Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, {required Module module}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModuleEditorScreen(module: module),
          ),
        );
        _fetchModules();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                    color: module.tagColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 20,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  onSelected: (value) async {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;

                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Modul'),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus modul "${module.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _supabaseService.deleteModule(module.id);
                          _fetchModules();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menghapus modul: $e'),
                              ),
                            );
                          }
                        }
                      }
                    } else if (value == 'leave') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Keluar Modul'),
                          content: Text(
                            'Apakah Anda yakin ingin keluar dari modul "${module.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && currentUserId != null) {
                        try {
                          await _supabaseService.removeModuleMember(
                            module.id,
                            currentUserId,
                          );
                          _fetchModules();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Berhasil keluar dari modul'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal keluar dari modul: $e'),
                              ),
                            );
                          }
                        }
                      }
                    } else if (value == 'archive') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Arsip Modul'),
                          content: Text(
                            'Apakah Anda yakin ingin mengarsipkan modul "${module.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Arsip'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _supabaseService.archiveModule(module.id);
                          _fetchModules();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Modul berhasil diarsipkan'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengarsipkan modul: $e'),
                              ),
                            );
                          }
                        }
                      }
                    } else if (value == 'duplicate') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Duplikat Modul'),
                          content: Text(
                            'Apakah Anda yakin ingin menduplikasi modul "${module.title}" beserta isinya?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Duplikat'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _supabaseService.duplicateModule(module);
                          _fetchModules();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Modul berhasil diduplikasi'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menduplikasi modul: $e'),
                              ),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    final isOwner = module.userId == currentUserId;

                    if (isOwner) {
                      return [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(LucideIcons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplikat'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(LucideIcons.archive, size: 16),
                              SizedBox(width: 8),
                              Text('Arsip'),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      return [
                        const PopupMenuItem(
                          value: 'leave',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.logOut,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Keluar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            if (module.taskCount > 0) ...[
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
                    '${(module.progress * 100).toInt()}%',
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
                percent: module.progress,
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
                  '${module.completedCount}/${module.taskCount} tugas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.users,
                  size: 14,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${module.memberCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                if (module.dueDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    module.dueDate!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: module.tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                module.tagName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: module.tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
