import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/tasks/module_model.dart';
import '../../features/tasks/dashboard_task_model.dart';
import '../../features/focus/focus_session_model.dart';
import '../models/connection_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch Single Module
  Future<Module> getModule(String id) async {
    try {
      final response = await _client
          .from('modules')
          .select()
          .eq('id', id)
          .single();

      return Module.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching module: $e');
      rethrow;
    }
  }

  // Fetch Modules
  Future<List<Module>> getModules() async {
    try {
      final userId = _client.auth.currentUser?.id;
      debugPrint('Current User ID: $userId');

      final response = await _client
          .from('modules')
          .select()
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      debugPrint('Raw Modules Response: $response');

      final data = response as List<dynamic>;
      return data.map((json) {
        try {
          return Module.fromMap(json);
        } catch (e) {
          debugPrint('Error parsing module ${json['id']}: $e');
          rethrow;
        }
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching modules: $e\nStack: $stack');
      rethrow;
    }
  }

  // Create Module
  Future<void> createModule({
    required String title,
    required String description,
    required String tagName,
    required int tagColor,
    DateTime? dueDate,
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
        'due_date': dueDate?.toIso8601String(),
        'progress': 0,
        'completed_count': 0,
        'task_count': 0,
        'member_count': 1,
        'content': content,
        'is_archived': false,
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
      int taskCount = 0;
      int completedCount = 0;

      for (var block in content) {
        if (block['type'] == 'todo') {
          taskCount++;
          if (block['isChecked'] == true) {
            completedCount++;
          }
        }
      }

      final double progress = taskCount > 0 ? completedCount / taskCount : 0.0;

      await _client
          .from('modules')
          .update({
            'content': content,
            'task_count': taskCount,
            'completed_count': completedCount,
            'progress': progress,
          })
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

  // Fetch Archived Modules
  Future<List<Module>> getArchivedModules() async {
    try {
      final response = await _client
          .from('modules')
          .select()
          .eq('is_archived', true)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) {
        return Module.fromMap(json);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching archived modules: $e');
      return [];
    }
  }

  // Archive Module
  Future<void> archiveModule(String moduleId) async {
    try {
      await _client
          .from('modules')
          .update({'is_archived': true})
          .eq('id', moduleId);
    } catch (e) {
      debugPrint('Error archiving module: $e');
      rethrow;
    }
  }

  // Restore Module
  Future<void> restoreModule(String moduleId) async {
    try {
      await _client
          .from('modules')
          .update({'is_archived': false})
          .eq('id', moduleId);
    } catch (e) {
      debugPrint('Error restoring module: $e');
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

  // Delete Task
  Future<void> deleteTask(String id) async {
    try {
      await _client.from('tasks').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Fetch All Module Todos
  Future<List<DashboardTask>> getAllModuleTodos() async {
    try {
      final modules = await getModules();
      final List<DashboardTask> moduleTodos = [];

      for (var module in modules) {
        if (module.content != null) {
          final content = module.content as List;
          for (var block in content) {
            if (block['type'] == 'todo') {
              final isChecked = block['isChecked'] ?? false;
              // Only add if not checked (optional, depending on requirement.
              // But usually dashboard shows pending tasks.
              // Let's show all and filter in UI if needed, or just follow existing pattern)

              moduleTodos.add(
                DashboardTask(
                  id: block['id'], // Block ID
                  title: block['content'] ?? '',
                  priority: 'Sedang', // Default priority for module todos
                  priorityColor: const Color(0xFFF5F5F5),
                  priorityTextColor: Colors.black,
                  isCompleted: isChecked,
                  moduleName: module.title,
                  moduleId: module.id,
                  isModuleTodo: true,
                  dueDate: module.rawDueDate,
                ),
              );
            }
          }
        }
      }
      return moduleTodos;
    } catch (e) {
      debugPrint('Error fetching module todos: $e');
      return [];
    }
  }

  // Delete Module Todo (Remove Block)
  Future<void> deleteModuleTodo(String moduleId, String blockId) async {
    try {
      debugPrint('Deleting module todo: $moduleId, block: $blockId');

      // 1. Fetch current module content directly
      final response = await _client
          .from('modules')
          .select('content')
          .eq('id', moduleId)
          .single();

      final rawContent = response['content'];
      if (rawContent == null) return;

      // 2. Create a deep mutable copy
      final List<dynamic> content = [];
      for (var item in rawContent as List) {
        if (item is Map) {
          content.add(Map<String, dynamic>.from(item));
        } else {
          content.add(item);
        }
      }

      // 3. Remove the specific block
      final initialLength = content.length;
      content.removeWhere((block) => block is Map && block['id'] == blockId);

      if (content.length != initialLength) {
        // 4. Update stats and save
        int taskCount = 0;
        int completedCount = 0;

        for (var block in content) {
          if (block is Map && block['type'] == 'todo') {
            taskCount++;
            if (block['isChecked'] == true) {
              completedCount++;
            }
          }
        }

        final double progress = taskCount > 0
            ? completedCount / taskCount
            : 0.0;

        await _client
            .from('modules')
            .update({
              'content': content,
              'task_count': taskCount,
              'completed_count': completedCount,
              'progress': progress,
            })
            .eq('id', moduleId);
      }
    } catch (e) {
      debugPrint('Error deleting module todo: $e');
      rethrow;
    }
  }

  // Toggle Module Todo
  Future<void> toggleModuleTodo(
    String moduleId,
    String blockId,
    bool isCompleted,
  ) async {
    try {
      debugPrint(
        'Toggling module todo: $moduleId, block: $blockId, to: $isCompleted',
      );

      // 1. Fetch current module content directly
      final response = await _client
          .from('modules')
          .select('content')
          .eq('id', moduleId)
          .single();

      final rawContent = response['content'];
      if (rawContent == null) {
        debugPrint('Content is null');
        return;
      }

      // 2. Create a deep mutable copy
      final List<dynamic> content = [];
      for (var item in rawContent as List) {
        if (item is Map) {
          content.add(Map<String, dynamic>.from(item));
        } else {
          content.add(item);
        }
      }

      // 3. Update the specific block
      bool contentChanged = false;
      for (var i = 0; i < content.length; i++) {
        final block = content[i];
        if (block is Map && block['id'] == blockId) {
          debugPrint('Found block: $block');
          block['isChecked'] = isCompleted; // Direct boolean assignment
          debugPrint('Updated block to: $block');
          contentChanged = true;
          break;
        }
      }

      if (contentChanged) {
        // 4. Update directly to avoid any side effects from other methods first
        // We will call updateModuleContent logic manually here to be safe

        int taskCount = 0;
        int completedCount = 0;

        for (var block in content) {
          if (block is Map && block['type'] == 'todo') {
            taskCount++;
            if (block['isChecked'] == true) {
              completedCount++;
            }
          }
        }

        final double progress = taskCount > 0
            ? completedCount / taskCount
            : 0.0;

        debugPrint(
          'Updating DB with: taskCount=$taskCount, completed=$completedCount, progress=$progress',
        );

        await _client
            .from('modules')
            .update({
              'content': content,
              'task_count': taskCount,
              'completed_count': completedCount,
              'progress': progress,
            })
            .eq('id', moduleId);

        debugPrint('Save complete');
      } else {
        debugPrint('Block not found with ID: $blockId');
      }
    } catch (e) {
      debugPrint('Error toggling module todo: $e');
      rethrow;
    }
  }

  // Duplicate Module (Deep Copy)
  Future<void> duplicateModule(Module module) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Create new module (Copy of original)
      final newModuleResponse = await _client
          .from('modules')
          .insert({
            'user_id': userId,
            'title': '${module.title} (Copy)',
            'description': module.description,
            'tag_name': module.tagName,
            'tag_color': module.tagColor.toARGB32(),
            'due_date': module.dueDate != null
                ? _parseFormattedDate(module.dueDate!)
                : null, // Convert back to ISO string
            'progress': 0,
            'completed_count': 0,
            'task_count': 0,
            'member_count': 1,
            'content': module.content, // Copy JSON content
            'is_archived': false, // Always active when duplicated
          })
          .select()
          .single();

      final newModuleId = newModuleResponse['id'];

      // 2. Fetch related tasks
      final tasksResponse = await _client
          .from('tasks')
          .select()
          .eq('module_id', module.id);

      final tasks = tasksResponse as List<dynamic>;

      // 3. Duplicate tasks if any
      if (tasks.isNotEmpty) {
        final newTasks = tasks.map((task) {
          return {
            'user_id': userId,
            'module_id': newModuleId,
            'title': task['title'],
            'priority': task['priority'],
            'is_completed': task['is_completed'],
            // 'due_date': task['due_date'], // If exists
          };
        }).toList();

        await _client.from('tasks').insert(newTasks);
      }
    } catch (e) {
      debugPrint('Error duplicating module: $e');
      rethrow;
    }
  }

  // Add Module
  Future<void> addModule({
    required String title,
    required String description,
    required String category,
    String? dueDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('modules')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'tag_name': category,
            'tag_color': _getCategoryColor(category).toARGB32(),
            'due_date': dueDate,
            'member_count': 0, // Will be updated by trigger
          })
          .select()
          .single();

      final moduleId = response['id'] as String;

      // Add owner as member
      await _client.from('module_members').insert({
        'module_id': moduleId,
        'user_id': userId,
        'role': 'owner',
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

  // Helper to parse formatted date back to ISO string
  String _parseFormattedDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length != 3) return DateTime.now().toIso8601String();

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
      return DateTime(year, month, day).toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  // Save Focus Session
  Future<FocusSession> saveFocusSession(FocusSession session) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final data = {'user_id': userId, ...session.toMap()};

      // If ID exists, include it for upsert/update
      if (session.id != null) {
        data['id'] = session.id;
      }

      final response = await _client
          .from('focus_sessions')
          .upsert(data)
          .select()
          .single();

      return FocusSession.fromMap(response);
    } catch (e) {
      debugPrint('Error saving focus session: $e');
      rethrow;
    }
  }

  // Get Recent Focus Sessions
  Future<List<FocusSession>> getRecentFocusSessions({int limit = 5}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(limit);

      final data = response as List<dynamic>;
      return data.map((json) => FocusSession.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete Focus Session
  Future<void> deleteFocusSession(String id) async {
    try {
      await _client.from('focus_sessions').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting focus session: $e');
      rethrow;
    }
  }

  // Get Focus Sessions for Date Range
  Future<List<FocusSession>> getFocusSessionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .gte('start_time', start.toIso8601String())
          .lte('start_time', end.toIso8601String())
          .order('start_time', ascending: true);

      final data = response as List<dynamic>;
      return data.map((json) => FocusSession.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching focus sessions for range: $e');
      return [];
    }
  }

  // Get Total Session Count
  Future<int> getTotalSessionCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('focus_sessions')
          .count(CountOption.exact)
          .eq('user_id', userId);

      return response;
    } catch (e) {
      debugPrint('Error fetching total session count: $e');
      return 0;
    }
  }

  // Search Users
  Future<List<ProfileModel>> searchUsers(String query) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('profiles')
          .select()
          .neq('id', userId) // Exclude self
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      final data = response as List<dynamic>;
      return data.map((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Add Module Member
  Future<void> addModuleMember({
    required String moduleId,
    required String userId,
    String role = 'editor',
  }) async {
    try {
      await _client.from('module_members').insert({
        'module_id': moduleId,
        'user_id': userId,
        'role': role,
      });
    } catch (e) {
      debugPrint('Error adding module member: $e');
      rethrow;
    }
  }

  // Get Module Members
  Future<List<Map<String, dynamic>>> getModuleMembers(String moduleId) async {
    try {
      // 1. Fetch members (user_id and role)
      final membersResponse = await _client
          .from('module_members')
          .select('user_id, role')
          .eq('module_id', moduleId);

      final membersData = membersResponse as List<dynamic>;
      if (membersData.isEmpty) return [];

      // 2. Extract User IDs
      final userIds = membersData.map((m) => m['user_id'] as String).toList();

      // 3. Fetch Profiles for these users
      final profilesResponse = await _client
          .from('profiles')
          .select()
          .inFilter('id', userIds);

      final profilesData = profilesResponse as List<dynamic>;
      final profilesMap = {
        for (var p in profilesData) p['id'] as String: ProfileModel.fromJson(p),
      };

      // 4. Combine data
      return membersData.map((m) {
        final userId = m['user_id'] as String;
        final profile = profilesMap[userId];

        // If profile not found (shouldn't happen usually), return basic info or skip
        if (profile == null) {
          return {
            'role': m['role'],
            'profile': ProfileModel(
              id: userId,
              username: 'Unknown',
              fullName: 'Unknown User',
            ),
          };
        }

        return {'role': m['role'], 'profile': profile};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching module members: $e');
      return [];
    }
  }

  // Remove Module Member
  Future<void> removeModuleMember(String moduleId, String userId) async {
    try {
      await _client
          .from('module_members')
          .delete()
          .eq('module_id', moduleId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error removing module member: $e');
      rethrow;
    }
  }

  // Get Profile
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // Add Todo to Module Content
  Future<void> addTodoToModule(String moduleId, String contentText) async {
    try {
      // 1. Fetch current module content
      final response = await _client
          .from('modules')
          .select('content')
          .eq('id', moduleId)
          .single();

      final rawContent = response['content'];
      final List<dynamic> content = [];

      if (rawContent != null) {
        for (var item in rawContent as List) {
          if (item is Map) {
            content.add(Map<String, dynamic>.from(item));
          } else {
            content.add(item);
          }
        }
      }

      // 2. Create new Todo Block
      final newBlock = {
        'id': const Uuid().v4(),
        'type': 'todo',
        'content': contentText,
        'isChecked': false,
      };

      // 3. Append to content
      content.add(newBlock);

      // 4. Recalculate stats
      int taskCount = 0;
      int completedCount = 0;

      for (var block in content) {
        if (block is Map && block['type'] == 'todo') {
          taskCount++;
          if (block['isChecked'] == true) {
            completedCount++;
          }
        }
      }

      final double progress = taskCount > 0 ? completedCount / taskCount : 0.0;

      // 5. Update Module
      await _client
          .from('modules')
          .update({
            'content': content,
            'task_count': taskCount,
            'completed_count': completedCount,
            'progress': progress,
          })
          .eq('id', moduleId);
    } catch (e) {
      debugPrint('Error adding todo to module: $e');
      rethrow;
    }
  }
}
