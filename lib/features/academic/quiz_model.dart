import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum QuestionType { multipleChoice, essay, trueFalse, fillBlank }

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.trueFalse:
        return 'Benar/Salah';
      case QuestionType.fillBlank:
        return 'Isian';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionType.multipleChoice:
        return LucideIcons.listChecks;
      case QuestionType.essay:
        return LucideIcons.fileText;
      case QuestionType.trueFalse:
        return LucideIcons.checkCircle;
      case QuestionType.fillBlank:
        return LucideIcons.edit;
    }
  }

  String get apiValue {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.essay:
        return 'essay';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillBlank:
        return 'fill_blank';
    }
  }
}

class Quiz {
  final String moduleName;
  final String topic;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final String? sourceFile;
  final List<QuestionType> questionTypes;

  Quiz({
    required this.moduleName,
    required this.topic,
    required this.questions,
    required this.createdAt,
    this.sourceFile,
    this.questionTypes = const [],
  });
}

class QuizQuestion {
  final QuestionType type;
  final String question;
  final List<String>? options;
  final dynamic correctAnswer;
  String? essayAnswer;
  dynamic userAnswer;

  QuizQuestion({
    required this.type,
    required this.question,
    this.options,
    this.correctAnswer,
    this.essayAnswer,
    this.userAnswer,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    QuestionType type;
    switch (map['type']) {
      case 'multiple_choice':
        type = QuestionType.multipleChoice;
        break;
      case 'essay':
        type = QuestionType.essay;
        break;
      case 'true_false':
        type = QuestionType.trueFalse;
        break;
      case 'fill_blank':
        type = QuestionType.fillBlank;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    return QuizQuestion(
      type: type,
      question: map['question'] ?? '',
      options:
          map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswer: map['correctAnswer'],
    );
  }
}
