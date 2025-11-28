import 'package:flutter/material.dart';

class JournalModel {
  final String id;
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final DateTime createdAt;

  JournalModel({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.createdAt,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      mood: json['mood'],
      // Konversi List dynamic ke List<String>
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  // Helper untuk mendapatkan warna berdasarkan mood
  Color get moodColor {
    switch (mood) {
      case '😊': // Senang
      case '😁':
      case '🤩':
        return Colors.green;
      case '😐': // Netral
      case '🤔':
        return Colors.orange;
      case '😢': // Sedih
      case '😩':
      case '😠':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Helper untuk format tanggal (contoh: "16 Nov 2025")
  String get formattedDate {
    final months = [
      '',
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
    return '${createdAt.day} ${months[createdAt.month]} ${createdAt.year}';
  }
}
