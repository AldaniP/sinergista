import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/tasks/module_model.dart';
import '../../features/tasks/dashboard_task_model.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch Modules
  Future<List<Module>> getModules() async {
    try {
      final response = await _client
          .from('modules')
          .select()
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) {
        return Module(
          title: json['title'] ?? 'No Title',
          description: json['description'] ?? '',
          progress: 0.0, // TODO: Calculate progress from tasks
          completedCount: 0, // TODO: Count completed tasks
          taskCount: 0, // TODO: Count total tasks
          memberCount: 1, // Default to 1 for now
          dueDate: _formatDate(json['due_date']),
          tagColor: _getCategoryColor(json['category']),
          tagName: json['category'] ?? 'Personal',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching modules: $e');
      return [];
    }
  }

  // Fetch Tasks
  Future<List<DashboardTask>> getTasks() async {
    try {
      final response = await _client
          .from('tasks')
          .select('*, modules(title)')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => DashboardTask.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }

  // Add Task
  Future<void> addTask({
    required String title,
    required String priority,
    String? moduleName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // If moduleName is provided, we need to find its ID.
      // For simplicity, we'll skip linking module for now or assume moduleName is actually ID if we change UI.
      // But based on UI, it's a name. We should probably look it up or just store it as text if we didn't normalize.
      // The schema has module_id.
      // Let's try to find module ID by name if provided.
      String? moduleId;
      if (moduleName != null) {
        final moduleResponse = await _client
            .from('modules')
            .select('id')
            .eq('title', moduleName)
            .maybeSingle();
        moduleId = moduleResponse?['id'];
      }

      await _client.from('tasks').insert({
        'user_id': userId,
        'title': title,
        'priority': priority,
        'module_id': moduleId,
        'is_completed': false,
      });
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  // Update Task (Toggle Completion)
  Future<void> updateTask(String id, bool isCompleted) async {
    try {
      await _client
          .from('tasks')
          .update({'is_completed': isCompleted})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Helper to format date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      // Simple formatting, can be improved with intl
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
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Helper for category colors
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Pekerjaan':
        return const Color(0xFFEF5350); // Red
      case 'Kuliah':
        return const Color(0xFF42A5F5); // Blue
      case 'Personal':
        return const Color(0xFF66BB6A); // Green
      default:
        return Colors.grey;
    }
  }
}
