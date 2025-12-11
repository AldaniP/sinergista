import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kanban_task_model.dart'; // Adjust path if needed

class KanbanService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<KanbanTask>> fetchTasks(String moduleId) async {
    final response = await _client
        .from('kanban_tasks')
        .select()
        .eq('module_id', moduleId)
        .order('created_at', ascending: true);

    return (response as List).map((data) => KanbanTask.fromMap(data)).toList();
  }

  Future<KanbanTask> addTask(
    String moduleId,
    String title,
    String status,
  ) async {
    final response = await _client
        .from('kanban_tasks')
        .insert({'module_id': moduleId, 'title': title, 'status': status})
        .select()
        .single();

    return KanbanTask.fromMap(response);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('kanban_tasks').delete().eq('id', id);
  }

  Future<void> updateTaskStatus(String id, String newStatus) async {
    await _client
        .from('kanban_tasks')
        .update({'status': newStatus}).eq('id', id);
  }

  Future<void> updateTaskTitle(String id, String newTitle) async {
    await _client.from('kanban_tasks').update({'title': newTitle}).eq('id', id);
  }
}
