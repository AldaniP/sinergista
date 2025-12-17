import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/task_service.dart';

class RequirementScreen extends StatefulWidget {
  const RequirementScreen({super.key});

  @override
  State<RequirementScreen> createState() => _RequirementScreenState();
}

class _RequirementScreenState extends State<RequirementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TaskService _taskService = TaskService();

  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _notesController = TextEditingController();
  String _priority = 'Sedang';
  String _category = 'Tugas';

  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  String _filterCategory = 'Semua';
  String _sortBy = 'created_at';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      var query = _supabase
          .from('tasks')
          .select()
          .eq('user_id', user.id);

      if (_filterCategory != 'Semua') {
        query = query.eq('category', _filterCategory);
      }

      final response = await query.order(_sortBy, ascending: _sortBy == 'due_date');

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // AI-powered Smart Suggestions based on task patterns
  List<String> _getSmartSuggestions() {
    final Map<String, int> categoryCount = {};
    final Map<String, int> priorityCount = {};
    
    for (var task in _tasks) {
      final cat = task['category'] ?? 'Tugas';
      final pri = task['priority'] ?? 'Sedang';
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      priorityCount[pri] = (priorityCount[pri] ?? 0) + 1;
    }

    List<String> suggestions = [];
    
    // Suggest based on incomplete tasks
    final incompleteTasks = _tasks.where((t) => t['is_completed'] != true).length;
    if (incompleteTasks > 5) {
      suggestions.add('💡 Anda punya $incompleteTasks tugas belum selesai. Fokus pada prioritas tinggi!');
    }

    // Suggest based on overdue tasks
    final now = DateTime.now();
    final overdue = _tasks.where((t) {
      if (t['due_date'] == null || t['is_completed'] == true) return false;
      final dueDate = DateTime.tryParse(t['due_date'].toString());
      return dueDate != null && dueDate.isBefore(now);
    }).length;
    
    if (overdue > 0) {
      suggestions.add('⚠️ $overdue tugas melewati deadline. Perlu segera diselesaikan!');
    }

    // Suggest most productive category
    if (categoryCount.isNotEmpty) {
      final topCat = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      suggestions.add('📊 Kategori tersibuk: ${topCat.key} (${topCat.value} tugas)');
    }

    return suggestions;
  }

  // Calculate productivity score
  Map<String, dynamic> _calculateProductivityScore() {
    final total = _tasks.length;
    if (total == 0) return {'score': 0, 'message': 'Mulai tambahkan tugas!', 'emoji': '🎯'};

    final completed = _tasks.where((t) => t['is_completed'] == true).length;
    final percentage = (completed / total * 100).round();

    String message;
    String emoji;
    
    if (percentage >= 80) {
      message = 'Produktivitas Luar Biasa!';
      emoji = '🔥';
    } else if (percentage >= 60) {
      message = 'Kerja Bagus!';
      emoji = '⭐';
    } else if (percentage >= 40) {
      message = 'Terus Semangat!';
      emoji = '💪';
    } else {
      message = 'Ayo Tingkatkan!';
      emoji = '🚀';
    }

    return {'score': percentage, 'message': message, 'emoji': emoji, 'completed': completed, 'total': total};
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Tinggi':
        return Colors.redAccent;
      case 'Rendah':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Tugas':
        return Colors.blue;
      case 'Project':
        return Colors.purple;
      case 'Meeting':
        return Colors.orange;
      case 'Belajar':
        return Colors.green;
      case 'Personal':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleComplete(String id, bool value) async {
    await _taskService.updateCompletion(taskId: id, isCompleted: value);
    _fetchTasks();
    
    if (value && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Tugas selesai! Lanjutkan!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _duplicateTask(Map<String, dynamic> task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('tasks').insert({
        'title': '${task['title']} (Copy)',
        'file_link': task['file_link'],
        'priority': task['priority'],
        'category': task['category'],
        'notes': task['notes'],
        'user_id': user.id,
        'due_date': task['due_date'],
      });

      await _fetchTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Tugas berhasil diduplikasi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link tidak valid')),
        );
      }
    }
  }

  void _showAddTaskDialog() {
    _titleController.clear();
    _linkController.clear();
    _notesController.clear();

    _showTaskDialog(isEdit: false);
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    _titleController.text = task['title'] ?? '';
    _linkController.text = task['file_link'] ?? '';
    _notesController.text = task['notes'] ?? '';
    
    _showTaskDialog(isEdit: true, taskId: task['id'], existingTask: task);
  }

  void _showTaskDialog({
    required bool isEdit,
    String? taskId,
    Map<String, dynamic>? existingTask,
  }) {
    DateTime? dueDate;
    if (isEdit && existingTask?['due_date'] != null) {
      dueDate = DateTime.tryParse(existingTask!['due_date'].toString());
    }
    
    String priority = isEdit 
        ? (existingTask?['priority'] ?? 'Sedang') 
        : _priority;
    
    String category = isEdit 
        ? (existingTask?['category'] ?? 'Tugas') 
        : _category;
    
    
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Keperluan' : 'Tambah Keperluan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    prefixIcon: Icon(LucideIcons.fileText),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link File (opsional)',
                    hintText: 'https://drive.google.com/...',
                    prefixIcon: Icon(LucideIcons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Tambahkan detail atau catatan...',
                    prefixIcon: Icon(LucideIcons.stickyNote),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'Tugas', child: Text('📝 Tugas')),
                    DropdownMenuItem(value: 'Project', child: Text('🎯 Project')),
                    DropdownMenuItem(value: 'Meeting', child: Text('👥 Meeting')),
                    DropdownMenuItem(value: 'Belajar', child: Text('📚 Belajar')),
                    DropdownMenuItem(value: 'Personal', child: Text('🏠 Personal')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        category = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 'Tinggi', child: Text('🔴 Tinggi')),
                    DropdownMenuItem(value: 'Sedang', child: Text('🟡 Sedang')),
                    DropdownMenuItem(value: 'Rendah', child: Text('🟢 Rendah')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        priority = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Prioritas'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.calendar),
                  label: Text(
                    dueDate == null
                        ? 'Pilih Deadline'
                        : 'Deadline: ${dueDate!.toIso8601String().substring(0, 10)}',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setDialogState(() {
                        dueDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                
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
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Judul harus diisi')),
                  );
                  return;
                }

                final user = _supabase.auth.currentUser;
                if (user == null) return;

                try {
                  final taskData = {
                    'title': _titleController.text,
                    'file_link': _linkController.text.isNotEmpty 
                        ? _linkController.text 
                        : null,
                    'notes': _notesController.text.isNotEmpty 
                        ? _notesController.text 
                        : null,
                    'priority': priority,
                    'category': category,
        
                    'due_date': dueDate?.toIso8601String(),
                  };

                  if (isEdit && taskId != null) {
                    await _supabase
                        .from('tasks')
                        .update(taskData)
                        .eq('id', taskId);
                  } else {
                    await _supabase.from('tasks').insert({
                      ...taskData,
                      'user_id': user.id,
                    });
                  }

                  _titleController.clear();
                  _linkController.clear();
                  _notesController.clear();
                  _priority = 'Sedang';
                  _category = 'Tugas';
                  

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  await _fetchTasks();
                  
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(isEdit 
                            ? '✅ Tugas berhasil diupdate' 
                            : '✨ Tugas berhasil ditambahkan'),
                      ),
                    );
                  }
                } catch (e) {
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(String taskId, String taskTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Yakin ingin menghapus "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('tasks').delete().eq('id', taskId);
        await _fetchTasks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Tugas berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    String dueDateText = 'Tidak ada deadline';
    final dueDateRaw = task['due_date'];
    if (dueDateRaw != null && dueDateRaw.toString().isNotEmpty) {
      final parsed = DateTime.tryParse(dueDateRaw.toString());
      if (parsed != null) {
        dueDateText = parsed.toLocal().toIso8601String().substring(0, 10);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy),
                    onPressed: () {
                      Navigator.pop(context);
                      _duplicateTask(task);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(LucideIcons.tag, 'Kategori', task['category'] ?? 'Tugas'),
              _detailRow(LucideIcons.alertCircle, 'Prioritas', task['priority'] ?? 'Sedang'),
              _detailRow(LucideIcons.calendar, 'Deadline', dueDateText),
              
              if (task['notes'] != null && task['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Catatan:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task['notes']),
                ),
              ],
              if (task['file_link'] != null && task['file_link'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.externalLink),
                  label: const Text('Buka Link File'),
                  onPressed: () => _openLink(task['file_link'].toString()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _productivityCard() {
    final stats = _calculateProductivityScore();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
              Text(
                '${stats['emoji']} Produktivitas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${stats['score']}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stats['message'],
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stats['score'] / 100,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats['completed']} dari ${stats['total']} tugas selesai',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _smartSuggestionsCard() {
    final suggestions = _getSmartSuggestions();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Smart Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(s, style: const TextStyle(fontSize: 13)),
          )),
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    String dueDateText = '-';
    final dueDateRaw = task['due_date'];
    bool isOverdue = false;
    
    if (dueDateRaw != null && dueDateRaw.toString().isNotEmpty) {
      final parsed = DateTime.tryParse(dueDateRaw.toString());
      if (parsed != null) {
        dueDateText = parsed.toLocal().toIso8601String().substring(0, 10);
        isOverdue = parsed.isBefore(DateTime.now()) && task['is_completed'] != true;
      }
    }

    final hasLink = task['file_link'] != null && 
                    task['file_link'].toString().isNotEmpty;
    

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? Colors.red.shade300 : Colors.grey.shade300,
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task['is_completed'] ?? false,
                    activeColor: AppColors.primary,
                    onChanged: (value) =>
                        _toggleComplete(task['id'], value ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task['is_completed'] == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (task['notes'] != null && task['notes'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              task['notes'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(LucideIcons.moreVertical, size: 18),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(LucideIcons.eye, size: 16),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showTaskDetails(task),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showEditTaskDialog(task),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(LucideIcons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('Duplikat'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _duplicateTask(task),
                        ),
                      ),
                      if (hasLink)
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(LucideIcons.externalLink, size: 16),
                              SizedBox(width: 8),
                              Text('Buka Link'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _openLink(task['file_link'].toString()),
                          ),
                        ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _deleteTask(task['id'], task['title']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor(task['category'] ?? 'Tugas')
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task['category'] ?? 'Tugas',
                      style: TextStyle(
                        fontSize: 11,
                        color: _categoryColor(task['category'] ?? 'Tugas'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priorityColor(task['priority'] ?? 'Sedang')
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task['priority'] ?? 'Sedang',
                      style: TextStyle(
                        fontSize: 11,
                        color: _priorityColor(task['priority'] ?? 'Sedang'),
                      ),
                    ),
                  ),
                  if (task['due_date'] != null && dueDateText != '-') ...[
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dueDateText,
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : Colors.grey,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada Keperluan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk mulai',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Urutkan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Semua', 'Tugas', 'Project', 'Meeting', 'Belajar', 'Personal']
                  .map((cat) => FilterChip(
                        label: Text(cat),
                        selected: _filterCategory == cat,
                        onSelected: (selected) {
                          setState(() {
                            _filterCategory = cat;
                          });
                          Navigator.pop(context);
                          _fetchTasks();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Urutkan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...['created_at', 'due_date', 'priority'].map((sort) {
              String label = sort == 'created_at' 
                  ? 'Terbaru' 
                  : sort == 'due_date' 
                      ? 'Deadline' 
                      : 'Prioritas';
              return RadioListTile<String>(
                title: Text(label),
                value: sort,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  Navigator.pop(context);
                  _fetchTasks();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keperluan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_tasks.isNotEmpty) ...[
                  _productivityCard(),
                  _smartSuggestionsCard(),
                ],
                Expanded(
                  child: _tasks.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return _taskCard(task);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddTaskDialog,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}