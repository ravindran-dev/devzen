class UserProfile {
  final int id;
  final int userId;
  final String fullName;
  final String? headline;
  final String? bio;
  final String? technicalSummary;
  final String? careerOverview;
  final String? portfolioSummary;
  final String? avatarUrl;
  final double zenScore;
  final String zenRank;
  final Map<String, dynamic> zenBreakdown;
  final String zenTrend;
  final bool profileVisibility;
  final List<Skill> skills;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Achievement> achievements;
  final List<Certification> certifications;
  final List<Project> projects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.headline,
    this.bio,
    this.technicalSummary,
    this.careerOverview,
    this.portfolioSummary,
    this.avatarUrl,
    this.zenScore = 0.0,
    this.zenRank = 'Beginner',
    this.zenBreakdown = const {},
    this.zenTrend = 'stable',
    this.profileVisibility = true,
    this.skills = const [],
    this.educations = const [],
    this.experiences = const [],
    this.achievements = const [],
    this.certifications = const [],
    this.projects = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['fullName'] ?? '',
      headline: json['headline'],
      bio: json['bio'],
      technicalSummary: json['technical_summary'],
      careerOverview: json['career_overview'],
      portfolioSummary: json['portfolio_summary'],
      avatarUrl: json['avatar_url'],
      zenScore: (json['zen_score'] ?? 0.0).toDouble(),
      zenRank: json['zen_rank'] ?? 'Beginner',
      zenBreakdown: Map<String, dynamic>.from(json['zen_breakdown'] ?? {}),
      zenTrend: json['zen_trend'] ?? 'stable',
      profileVisibility: json['profile_visibility'] ?? true,
      skills: (json['skills'] as List? ?? []).map((s) => Skill.fromJson(s)).toList(),
      educations: (json['educations'] as List? ?? []).map((e) => Education.fromJson(e)).toList(),
      experiences: (json['experiences'] as List? ?? []).map((e) => Experience.fromJson(e)).toList(),
      achievements: (json['achievements'] as List? ?? []).map((a) => Achievement.fromJson(a)).toList(),
      certifications: (json['certifications'] as List? ?? []).map((c) => Certification.fromJson(c)).toList(),
      projects: (json['projects'] as List? ?? []).map((p) => Project.fromJson(p)).toList(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  // Convenience getters
  String get topLanguage {
    final langSkills = skills.where((s) => s.category == 'Languages').toList();
    return langSkills.isNotEmpty ? langSkills.first.name : 'N/A';
  }

  List<Skill> skillsByCategory(String category) {
    return skills.where((s) => s.category == category).toList();
  }
}

// ─── Supporting Models ────────────────────────────────────────────────────────

class Skill {
  final int id;
  final String name;
  final String? category;
  final String proficiencyLevel;
  final String source;
  final bool isVisible;

  Skill({
    required this.id,
    required this.name,
    this.category,
    this.proficiencyLevel = 'Intermediate',
    this.source = 'Manual',
    this.isVisible = true,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        category: json['category'],
        proficiencyLevel: json['proficiency_level'] ?? 'Intermediate',
        source: json['source'] ?? 'Manual',
        isVisible: json['is_visible'] ?? true,
      );
}

class Education {
  final int id;
  final String institution;
  final String degree;
  final String? department;
  final String? cgpa;
  final String? duration;
  final List<String> coursework;
  final List<String> academicProjects;

  Education({
    required this.id,
    required this.institution,
    required this.degree,
    this.department,
    this.cgpa,
    this.duration,
    this.coursework = const [],
    this.academicProjects = const [],
  });

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        id: json['id'] ?? 0,
        institution: json['institution'] ?? '',
        degree: json['degree'] ?? '',
        department: json['department'],
        cgpa: json['cgpa'],
        duration: json['duration'],
        coursework: List<String>.from(json['coursework'] ?? []),
        academicProjects: List<String>.from(json['academic_projects'] ?? []),
      );
}

class Experience {
  final int id;
  final String company;
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final List<String> keyAchievements;

  Experience({
    required this.id,
    required this.company,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.keyAchievements = const [],
  });

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        id: json['id'] ?? 0,
        company: json['company'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        startDate: json['start_date'],
        endDate: json['end_date'],
        keyAchievements: List<String>.from(json['key_achievements'] ?? []),
      );

  String get durationText {
    final start = startDate ?? '';
    final end = endDate ?? 'Present';
    return '$start — $end';
  }
}

class Achievement {
  final int id;
  final String title;
  final String? description;
  final String? date;
  final String source;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.source = 'Manual',
    this.points = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'],
        date: json['date'],
        source: json['source'] ?? 'Manual',
        points: json['points'] ?? 0,
      );
}

class Certification {
  final int id;
  final String title;
  final String issuer;
  final String? issueDate;
  final String? credentialId;
  final String? link;

  Certification({
    required this.id,
    required this.title,
    required this.issuer,
    this.issueDate,
    this.credentialId,
    this.link,
  });

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        issuer: json['issuer'] ?? '',
        issueDate: json['issue_date'],
        credentialId: json['credential_id'],
        link: json['link'],
      );
}

class Project {
  final int id;
  final String title;
  final String? objective;
  final String? description;
  final List<String> technologies;
  final String role;
  final String? repositoryLink;
  final String? readmeSummary;
  final double progress;
  final int commitsCount;
  final int starsCount;
  final int forksCount;
  final List<String> contributors;
  final String? aiSummary;
  final DateTime? lastActivity;
  final bool isVisible;

  Project({
    required this.id,
    required this.title,
    this.objective,
    this.description,
    this.technologies = const [],
    this.role = 'Contributor',
    this.repositoryLink,
    this.readmeSummary,
    this.progress = 1.0,
    this.commitsCount = 0,
    this.starsCount = 0,
    this.forksCount = 0,
    this.contributors = const [],
    this.aiSummary,
    this.lastActivity,
    this.isVisible = true,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        objective: json['objective'],
        description: json['description'],
        technologies: List<String>.from(json['technologies'] ?? []),
        role: json['role'] ?? 'Contributor',
        repositoryLink: json['repository_link'],
        readmeSummary: json['readme_summary'],
        progress: (json['progress'] ?? 1.0).toDouble(),
        commitsCount: json['commits_count'] ?? 0,
        starsCount: json['stars_count'] ?? 0,
        forksCount: json['forks_count'] ?? 0,
        contributors: List<String>.from(json['contributors'] ?? []),
        aiSummary: json['ai_summary'],
        lastActivity: json['last_activity'] != null ? DateTime.tryParse(json['last_activity']) : null,
        isVisible: json['is_visible'] ?? true,
      );

  String get shortDescription => description ?? objective ?? 'No description available';
}
