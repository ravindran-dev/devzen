class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status; // 'Todo', 'In Progress', 'Review', 'Completed'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dueDate;
  final String assigneeName;
  final String assigneeAvatar; // Asset path or initial/icon name

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.assigneeName,
    required this.assigneeAvatar,
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? assigneeName,
    String? assigneeAvatar,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Todo',
      priority: map['priority'] ?? 'Medium',
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      assigneeName: map['assigneeName'] ?? 'Developer',
      assigneeAvatar: map['assigneeAvatar'] ?? 'D',
    );
  }
}
