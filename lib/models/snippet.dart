class Snippet {
  final String id;
  final String title;
  final String description;
  final String language; // 'C++', 'Python', 'Java', 'Dart', 'JavaScript', 'SQL', 'HTML', 'CSS', etc.
  final String code;
  final List<String> tags;
  final bool isFavorite;

  Snippet({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.code,
    required this.tags,
    this.isFavorite = false,
  });

  Snippet copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? code,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Snippet(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      code: code ?? this.code,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'code': code,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  factory Snippet.fromMap(Map<String, dynamic> map) {
    return Snippet(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      language: map['language'] ?? 'JavaScript',
      code: map['code'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}
