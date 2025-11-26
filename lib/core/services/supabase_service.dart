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
          id: json['id']?.toString() ?? '',
          title: json['title'] ?? 'No Title',
          description: json['description'] ?? '',
          progress: (json['progress'] ?? 0).toDouble(),
          completedCount: json['completed_count'] ?? 0,
          taskCount: json['task_count'] ?? 0,
          memberCount: json['member_count'] ?? 1,
          dueDate: _formatDate(json['due_date']),
          tagColor: json['tag_color'] != null
              ? Color(json['tag_color'])
              : _getCategoryColor(json['tag_name']),
          tagName: json['tag_name'] ?? 'Personal',
          content: json['content'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching modules: $e');
      return [];
    }
  }

  // Create Module
  Future<void> createModule({
    required String title,
    required String description,
    required String tagName,
    required int tagColor,
    required DateTime dueDate,
    List<dynamic>? content,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _client.from('modules').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'tag_name': tagName,
        'tag_color': tagColor,
        'due_date': dueDate.toIso8601String(),
        'progress': 0,
        'completed_count': 0,
        'task_count': 0,
        'member_count': 1,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error creating module: $e');
      rethrow;
    }
  }

  // Update Module Content
  Future<void> updateModuleContent(
    String moduleId,
    List<dynamic> content,
  ) async {
    try {
      await _client
          .from('modules')
          .update({'content': content})
          .eq('id', moduleId);
    } catch (e) {
      debugPrint('Error updating module content: $e');
      rethrow;
    }
  }

  // Delete Module
  Future<void> deleteModule(String moduleId) async {
    try {
      await _client.from('modules').delete().eq('id', moduleId);
    } catch (e) {
      debugPrint('Error deleting module: $e');
      rethrow;
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

  // Delete Module
  Future<void> deleteModule(String id) async {
    try {
      await _client.from('modules').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting module: $e');
      rethrow;
    }
  }

  // Add Module
  Future<void> addModule({
    required String title,
    required String description,
    required String category,
    required String dueDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _client.from('modules').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'due_date': dueDate,
        // 'created_at': DateTime.now().toIso8601String(), // Usually handled by DB default
      });
    } on PostgrestException catch (e) {
      debugPrint(
        'Postgrest Error adding module: ${e.message} code: ${e.code} details: ${e.details}',
      );
      throw 'Database Error: ${e.message}';
    } catch (e) {
      debugPrint('Error adding module: $e');
      rethrow;
    }
  }

  // Helper to format date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
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

  // Helper for category colors (fallback)
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
