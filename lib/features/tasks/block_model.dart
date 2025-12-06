import 'package:flutter/material.dart';

enum BlockType { text, heading1, heading2, bullet, todo, link }

class BlockModel {
  String id;
  BlockType type;
  String content;
  bool isChecked;
  String? url; // Add URL field
  final TextEditingController controller;
  final FocusNode focusNode;

  BlockModel({
    required this.id,
    required this.type,
    this.content = '',
    this.isChecked = false,
    this.url,
  }) : controller = TextEditingController(text: content),
       focusNode = FocusNode();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': controller.text,
      'isChecked': isChecked,
      'url': url, // Save URL
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'],
      type: BlockType.values.firstWhere((e) => e.name == map['type']),
      content: map['content'] ?? '',
      isChecked: map['isChecked'] ?? false,
      url: map['url'], // Load URL
    );
  }
}
