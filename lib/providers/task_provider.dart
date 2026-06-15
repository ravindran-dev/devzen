import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> getTasksForProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  List<Task> getTasksForProjectAndStatus(String projectId, String status) {
    return _tasks.where((task) => task.projectId == projectId && task.status == status).toList();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void moveTask(String id, String newStatus) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // Seed tasks linked to specific projects
  void seedTasksForProjects(List<String> projectIds) {
    if (_tasks.isNotEmpty || projectIds.isEmpty) return;

    final uuid = const Uuid();
    final projId1 = projectIds[0];
    final projId2 = projectIds.length > 1 ? projectIds[1] : projId1;

    _tasks.addAll([
      Task(
        id: uuid.v4(),
        projectId: projId1,
        title: 'Design glassmorphic theme system',
        description: 'Implement dark base (#0B0F14) with translucent layers.',
        status: 'Completed',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        assigneeName: 'Alex Mercer',
        assigneeAvatar: 'A',
      ),
      Task(
        id: uuid.v4(),
        projectId: projId1,
        title: 'Write custom Paint circular rings',
        description: 'Support neon glows and double precision arcs.',
        status: 'In Progress',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        assigneeName: 'Alex Mercer',
        assigneeAvatar: 'A',
      ),
      Task(
        id: uuid.v4(),
        projectId: projId1,
        title: 'Integrate Firestore stream bindings',
        description: 'Provide live snapshot lists for tasks and snippets.',
        status: 'Todo',
        priority: 'Medium',
        dueDate: DateTime.now().add(const Duration(days: 10)),
        assigneeName: 'Sarah Jenkins',
        assigneeAvatar: 'S',
      ),
      Task(
        id: uuid.v4(),
        projectId: projId2,
        title: 'Create OpenAI credentials configuration panel',
        description: 'Support local caching of personal access keys securely.',
        status: 'Todo',
        priority: 'Low',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        assigneeName: 'Marcus Cole',
        assigneeAvatar: 'M',
      ),
      Task(
        id: uuid.v4(),
        projectId: projId2,
        title: 'Test route controllers',
        description: 'Perform boundary load tests on AI feedback routes.',
        status: 'Review',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        assigneeName: 'Alex Mercer',
        assigneeAvatar: 'A',
      ),
    ]);
    notifyListeners();
  }

  double calculateProjectProgress(String projectId) {
    final projTasks = getTasksForProject(projectId);
    if (projTasks.isEmpty) return 0.0;
    final completedCount = projTasks.where((task) => task.status == 'Completed').length;
    return completedCount / projTasks.length;
  }
}
