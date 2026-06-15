class ZenScore {
  final double total;
  final String rank;
  final String trend; // 'up', 'down', 'stable'
  final ZenBreakdown breakdown;
  final DateTime? lastCalculated;

  ZenScore({
    required this.total,
    required this.rank,
    required this.trend,
    required this.breakdown,
    this.lastCalculated,
  });

  factory ZenScore.empty() => ZenScore(
        total: 0,
        rank: 'Beginner',
        trend: 'stable',
        breakdown: ZenBreakdown.empty(),
      );

  factory ZenScore.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['breakdown'] as Map<String, dynamic>? ?? {};
    return ZenScore(
      total: (json['total_score'] ?? 0.0).toDouble(),
      rank: json['rank'] ?? 'Beginner',
      trend: json['trend'] ?? 'stable',
      breakdown: ZenBreakdown(
        profileCompleteness: (breakdownJson['profile_completeness'] ?? 0.0).toDouble(),
        githubActivity: (breakdownJson['github_activity'] ?? 0.0).toDouble(),
        repositoryQuality: (breakdownJson['repository_quality'] ?? 0.0).toDouble(),
        skillDiversity: (breakdownJson['skill_diversity'] ?? 0.0).toDouble(),
        resumeCompleteness: (breakdownJson['resume_completeness'] ?? 0.0).toDouble(),
        achievementCount: (breakdownJson['achievement_count'] ?? 0.0).toDouble(),
        contributionFrequency: (breakdownJson['contribution_frequency'] ?? 0.0).toDouble(),
      ),
      lastCalculated: json['last_calculated'] != null
          ? DateTime.tryParse(json['last_calculated'])
          : null,
    );
  }

  String get trendIcon {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '→';
    }
  }

  String get rankEmoji {
    switch (rank) {
      case 'Master':
        return '🏆';
      case 'Expert':
        return '🌟';
      case 'Proficient':
        return '⚡';
      case 'Rising':
        return '🚀';
      default:
        return '🌱';
    }
  }
}

class ZenBreakdown {
  final double profileCompleteness;   // max 20
  final double githubActivity;         // max 25
  final double repositoryQuality;      // max 20
  final double skillDiversity;         // max 15
  final double resumeCompleteness;     // max 10
  final double achievementCount;       // max 5
  final double contributionFrequency;  // max 5

  ZenBreakdown({
    required this.profileCompleteness,
    required this.githubActivity,
    required this.repositoryQuality,
    required this.skillDiversity,
    required this.resumeCompleteness,
    required this.achievementCount,
    required this.contributionFrequency,
  });

  factory ZenBreakdown.empty() => ZenBreakdown(
        profileCompleteness: 0,
        githubActivity: 0,
        repositoryQuality: 0,
        skillDiversity: 0,
        resumeCompleteness: 0,
        achievementCount: 0,
        contributionFrequency: 0,
      );

  List<Map<String, dynamic>> get items => [
        {'label': 'Profile', 'score': profileCompleteness, 'max': 20},
        {'label': 'GitHub Activity', 'score': githubActivity, 'max': 25},
        {'label': 'Repositories', 'score': repositoryQuality, 'max': 20},
        {'label': 'Skills', 'score': skillDiversity, 'max': 15},
        {'label': 'Resume', 'score': resumeCompleteness, 'max': 10},
        {'label': 'Achievements', 'score': achievementCount, 'max': 5},
        {'label': 'Contributions', 'score': contributionFrequency, 'max': 5},
      ];
}
