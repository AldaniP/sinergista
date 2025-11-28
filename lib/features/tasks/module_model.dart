import 'package:flutter/material.dart';

class Module {
  final String id;
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
}
