import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'services/task_service.dart';

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
  String _priority = 'Sedang';

  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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

  Future<void> _toggleComplete(String id, bool value) async {
    await _taskService.updateCompletion(
      taskId: id,
      isCompleted: value,
    );
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebutuhan Tugas'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _taskCard(task);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddTaskDialog,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task['is_completed'] ?? false,
            activeColor: AppColors.primary,
            onChanged: (value) => _toggleComplete(task['id'], value ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  task['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: task['is_completed'] == true
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task['file_link'] != null && task['file_link'] != '')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText(
                      task['file_link'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _priorityColor(task['priority'] ?? 'Sedang')
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task['priority'] ?? 'Sedang',
                        style: TextStyle(
                          fontSize: 12,
                          color: _priorityColor(task['priority'] ?? 'Sedang'),
                        ),
                      ),
                    ),
                    if (task['due_date'] != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTime.parse(task['due_date'])
                            .toLocal()
                            .toString()
                            .substring(0, 10),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
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
            'Belum ada kebutuhan tugas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Kebutuhan Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Judul
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Tugas',
                ),
              ),

              const SizedBox(height: 12),

              // Link File
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

              // Priority
              DropdownButtonFormField<String>(
                initialValue: _priority,
                items: const [
                  DropdownMenuItem(value: 'Tinggi', child: Text('Tinggi')),
                  DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
                  DropdownMenuItem(value: 'Rendah', child: Text('Rendah')),
                ],
                onChanged: (v) => _priority = v!,
                decoration: const InputDecoration(labelText: 'Prioritas'),
              ),

              const SizedBox(height: 12),

              // DEADLINE
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.calendar),
                label: Text(
                  dueDate == null
                      ? 'Pilih Deadline'
                      : 'Deadline: ${dueDate!.toLocal().toString().substring(0, 10)}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _addTask(dueDate),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask(DateTime? dueDate) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('tasks').insert({
      'title': _titleController.text,
      'priority': _priority,
      'user_id': user.id,
      'due_date': dueDate?.toIso8601String(),
    });

    _titleController.clear();
    _linkController.clear();
    _priority = 'Sedang';

    Navigator.pop(context);
    _fetchTasks();
  }
}
