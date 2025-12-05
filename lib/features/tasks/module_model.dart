import 'package:flutter/material.dart';

class Module {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double progress;
  final int completedCount;
  final int taskCount;
  final int memberCount;
  final String? dueDate;
  final Color tagColor;
  final String tagName;
  final List<dynamic>? content; // JSON content for Notion-like editor
  final bool isArchived;

  Module({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.progress,
    required this.completedCount,
    required this.taskCount,
    required this.memberCount,
    this.dueDate,
    required this.tagColor,
    required this.tagName,
    this.content,
    this.isArchived = false,
  });

  factory Module.fromMap(Map<String, dynamic> json) {
    return Module(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
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
      isArchived: json['is_archived'] ?? false,
    );
  }

  static String? _formatDate(String? dateStr) {
    if (dateStr == null) return null;
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

  static Color _getCategoryColor(String? category) {
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
