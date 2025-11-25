import 'package:flutter/material.dart';

class DashboardTask {
  final String title;
  final String priority;
  final Color priorityColor;
  final Color priorityTextColor;
  final String? moduleName;
  bool isCompleted;

  DashboardTask({
    required this.title,
    required this.priority,
    required this.priorityColor,
    required this.priorityTextColor,
    this.isCompleted = false,
    this.moduleName,
  });
}
