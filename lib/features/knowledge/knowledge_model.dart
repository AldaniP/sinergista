class KnowledgeItem {
  final String id;
  final String title;
  final String description;
  final String? url;
  final DateTime createdAt;

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.description,
    this.url,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
