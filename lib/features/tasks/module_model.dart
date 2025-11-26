import 'package:flutter/material.dart';

class Module {
  final String? id;
  final String title;
  final String description;
  final double progress;
  final int completedCount;
  final int taskCount;
  final int memberCount;
  final String dueDate;
  final Color tagColor;
  final String tagName;

  Module({
    this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.completedCount,
    required this.taskCount,
    required this.memberCount,
    required this.dueDate,
    required this.tagColor,
    required this.tagName,
  });
}
