class Note {
  final String id;
  final String title;
  final String content; // Markdown text
  final String category; // e.g., 'Guides', 'Ideas', 'Specs', 'Archived'
  final bool isPinned;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.isPinned = false,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isPinned': isPinned,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      isPinned: map['isPinned'] ?? false,
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
