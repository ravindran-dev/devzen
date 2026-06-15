class GitHubRepo {
  final String name;
  final String? description;
  final String? language;
  final int starsCount;
  final int forksCount;
  final int openIssuesCount;
  final String htmlUrl;
  final bool isPrivate;
  final bool isFork;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final List<String> topics;
  final Map<String, int> languages;

  GitHubRepo({
    required this.name,
    this.description,
    this.language,
    this.starsCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.htmlUrl = '',
    this.isPrivate = false,
    this.isFork = false,
    this.updatedAt,
    this.createdAt,
    this.topics = const [],
    this.languages = const {},
  });

  factory GitHubRepo.fromMap(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] ?? '',
      description: json['description'],
      language: json['language'],
      starsCount: json['stargazers_count'] ?? json['stars_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      openIssuesCount: json['open_issues_count'] ?? json['open_issues'] ?? 0,
      htmlUrl: json['html_url'] ?? '',
      isPrivate: json['private'] ?? json['is_private'] ?? false,
      isFork: json['fork'] ?? json['is_fork'] ?? false,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      topics: List<String>.from(json['topics'] ?? []),
      languages: Map<String, int>.from(json['languages'] ?? {}),
    );
  }

  String get displayLanguage => language ?? (languages.isNotEmpty ? languages.keys.first : 'N/A');

  String get timeAgo {
    if (updatedAt == null) return 'N/A';
    final diff = DateTime.now().difference(updatedAt!);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
