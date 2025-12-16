class Article {
  final String id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final String iconEmoji;
  final int readTimeMinutes;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    required this.iconEmoji,
    required this.readTimeMinutes,
  });
}

enum ArticleCategory {
  timeManagement,
  focusTechniques,
  studyTips,
  productivityHacks,
  workLifeBalance,
}

extension ArticleCategoryExtension on ArticleCategory {
  String get displayName {
    switch (this) {
      case ArticleCategory.timeManagement:
        return 'Time Management';
      case ArticleCategory.focusTechniques:
        return 'Focus Techniques';
      case ArticleCategory.studyTips:
        return 'Study Tips';
      case ArticleCategory.productivityHacks:
        return 'Productivity Hacks';
      case ArticleCategory.workLifeBalance:
        return 'Work-Life Balance';
    }
  }

  String get emoji {
    switch (this) {
      case ArticleCategory.timeManagement:
        return '⏰';
      case ArticleCategory.focusTechniques:
        return '🎯';
      case ArticleCategory.studyTips:
        return '📚';
      case ArticleCategory.productivityHacks:
        return '💡';
      case ArticleCategory.workLifeBalance:
        return '🧘';
    }
  }
}
