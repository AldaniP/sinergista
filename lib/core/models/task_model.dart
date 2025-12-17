class TaskModel {
  final String id;
  final String userId;
  final String? moduleId;
  final String title;
  final String priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    this.moduleId,
    required this.title,
    required this.priority,
    required this.isCompleted,
    this.dueDate,
    required this.createdAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      userId: map['user_id'],
      moduleId: map['module_id'],
      title: map['title'],
      priority: map['priority'],
      isCompleted: map['is_completed'],
      dueDate:
          map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
