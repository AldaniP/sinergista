class KanbanTask {
  final String id;
  final String moduleId;
  final String title;
  final String status;
  final DateTime createdAt;

  KanbanTask({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory KanbanTask.fromMap(Map<String, dynamic> map) {
    return KanbanTask(
      id: map['id'] ?? '',
      moduleId: map['module_id'] ?? '',
      title: map['title'] ?? '',
      status: map['status'] ?? 'To Do',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'module_id': moduleId, 'title': title, 'status': status};
  }
}
