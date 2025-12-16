import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE
  Future<void> createTask({
    required String title,
    String priority = 'Sedang',
    String? moduleId,
    DateTime? dueDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('tasks').insert({
      'title': title,
      'priority': priority,
      'user_id': user.id,
      'module_id': moduleId,
      'due_date': dueDate?.toIso8601String(),
    });
  }

  /// UPDATE (toggle checkbox selesai / belum)
  Future<void> updateCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    await _supabase
        .from('tasks')
        .update({'is_completed': isCompleted}).eq('id', taskId);
  }

  /// DELETE (optional, nanti)
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
