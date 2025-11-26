import 'package:flutter/material.dart';

class DashboardTask {
  final String? id;
  final String title;
  final String priority;
  final Color priorityColor;
  final Color priorityTextColor;
  final String? moduleName;
  bool isCompleted;

  DashboardTask({
    this.id,
    required this.title,
    required this.priority,
    required this.priorityColor,
    required this.priorityTextColor,
    this.isCompleted = false,
    this.moduleName,
  });

  factory DashboardTask.fromMap(Map<String, dynamic> map) {
    // Helper to get colors based on priority string
    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'Tinggi':
          return const Color(0xFFFFCDD2); // Red 100
        case 'Rendah':
          return const Color(0xFFC8E6C9); // Green 100
        default:
          return const Color(0xFFF5F5F5); // Grey 100
      }
    }

    Color getPriorityTextColor(String priority) {
      switch (priority) {
        case 'Tinggi':
          return const Color(0xFFC62828); // Red 800
        case 'Rendah':
          return const Color(0xFF2E7D32); // Green 800
        default:
          return Colors.black;
      }
    }

    return DashboardTask(
      id: map['id'],
      title: map['title'] ?? '',
      priority: map['priority'] ?? 'Sedang',
      priorityColor: getPriorityColor(map['priority'] ?? 'Sedang'),
      priorityTextColor: getPriorityTextColor(map['priority'] ?? 'Sedang'),
      isCompleted: map['is_completed'] ?? false,
      moduleName: map['modules']?['title'], // Assuming join with modules table
    );
  }
}
