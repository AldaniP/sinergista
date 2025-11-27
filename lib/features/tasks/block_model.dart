import 'package:flutter/material.dart';

enum BlockType { text, heading1, heading2, bullet, todo }

class BlockModel {
  String id;
  BlockType type;
  String content;
  bool isChecked;
  final TextEditingController controller;
  final FocusNode focusNode;

  BlockModel({
    required this.id,
    required this.type,
    this.content = '',
    this.isChecked = false,
  }) : controller = TextEditingController(text: content),
       focusNode = FocusNode();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': controller.text,
      'isChecked': isChecked,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'],
      type: BlockType.values.firstWhere((e) => e.name == map['type']),
      content: map['content'] ?? '',
      isChecked: map['isChecked'] ?? false,
    );
  }
}
