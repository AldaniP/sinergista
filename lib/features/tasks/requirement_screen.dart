import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
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
    await _taskService.updateCompletion(taskId: id, isCompleted: value);
    _fetchTasks();
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
    DateTime? dueDate;
    String priority = _priority;
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Todo list'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
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
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: const [
                    DropdownMenuItem(value: 'Tinggi', child: Text('Tinggi')),
                    DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
                    DropdownMenuItem(value: 'Rendah', child: Text('Rendah')),
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
                  await _supabase.from('tasks').insert({
                    'title': _titleController.text,
                    'file_link': _linkController.text.isNotEmpty
                        ? _linkController.text
                        : null,
                    'priority': priority,
                    'user_id': user.id,
                    'due_date': dueDate?.toIso8601String(),
                  });

                  _titleController.clear();
                  _linkController.clear();
                  _priority = 'Sedang';

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  await _fetchTasks();
                } catch (e) {
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    // Null-safe due_date
    String dueDateText = '-';
    final dueDateRaw = task['due_date'];
    if (dueDateRaw != null && dueDateRaw.toString().isNotEmpty) {
      final parsed = DateTime.tryParse(dueDateRaw.toString());
      if (parsed != null) {
        dueDateText = parsed.toLocal().toIso8601String().substring(0, 10);
      }
    }

    final hasLink =
        task['file_link'] != null && task['file_link'].toString().isNotEmpty;

    return InkWell(
      onTap: hasLink ? () => _openLink(task['file_link'].toString()) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
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
                  child: SelectableText(
                    task['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task['is_completed'] == true
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (hasLink)
                  const Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                if (task['due_date'] != null && dueDateText != '-') ...[
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDateText,
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
}
