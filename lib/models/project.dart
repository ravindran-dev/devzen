class Project {
  final String id;
  final String name;
  final String description;
  final String status; // 'Active', 'Archived', 'Completed'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime startDate;
  final DateTime deadline;
  final double progress; // 0.0 to 1.0
  final List<String> tags;
  final String notes;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.deadline,
    required this.progress,
    required this.tags,
    required this.notes,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? priority,
    DateTime? startDate,
    DateTime? deadline,
    double? progress,
    List<String>? tags,
    String? notes,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'priority': priority,
      'startDate': startDate.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'progress': progress,
      'tags': tags,
      'notes': notes,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Active',
      priority: map['priority'] ?? 'Medium',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      deadline: DateTime.parse(map['deadline'] ?? DateTime.now().toIso8601String()),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      tags: List<String>.from(map['tags'] ?? []),
      notes: map['notes'] ?? '',
    );
  }
}
