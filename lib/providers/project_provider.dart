import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/user_profile.dart' as up;

class ProjectProvider extends ChangeNotifier {
  final List<Project> _projects = [];
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedPriorityFilter = 'All';

  ProjectProvider() {
    _loadSeedProjects();
  }

  void syncWithBackendProjects(List<up.Project> backendProjects) {
    if (backendProjects.isEmpty) return;

    // Check if the backend projects list is identical to the current _projects list to prevent infinite rebuild loops
    bool isIdentical = _projects.length == backendProjects.length;
    if (isIdentical) {
      for (int i = 0; i < _projects.length; i++) {
        final local = _projects[i];
        final remote = backendProjects[i];
        if (local.id != remote.id.toString() ||
            local.name != remote.title ||
            local.description != (remote.description ?? remote.objective ?? '') ||
            local.progress != remote.progress ||
            local.status != (remote.isVisible ? 'Active' : 'Archived')) {
          isIdentical = false;
          break;
        }
      }
    }

    if (isIdentical) return;

    _projects.clear();
    for (final bp in backendProjects) {
      _projects.add(Project(
        id: bp.id.toString(),
        name: bp.title,
        description: bp.description ?? bp.objective ?? 'No description available',
        status: bp.isVisible ? 'Active' : 'Archived',
        priority: bp.starsCount > 30 ? 'High' : (bp.forksCount > 5 ? 'Medium' : 'Low'),
        startDate: bp.lastActivity ?? DateTime.now().subtract(const Duration(days: 30)),
        deadline: (bp.lastActivity ?? DateTime.now()).add(const Duration(days: 30)),
        progress: bp.progress,
        tags: bp.technologies,
        notes: bp.readmeSummary ?? bp.aiSummary ?? '',
      ));
    }
    notifyListeners();
  }

  List<Project> get projects {
    return _projects.where((project) {
      final matchesSearch = project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'All' || project.status == _selectedStatusFilter;
      final matchesPriority = _selectedPriorityFilter == 'All' || project.priority == _selectedPriorityFilter;
      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  List<Project> get rawProjects => _projects;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  void setPriorityFilter(String filter) {
    _selectedPriorityFilter = filter;
    notifyListeners();
  }

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }

  void updateProject(Project updatedProject) {
    final index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      notifyListeners();
    }
  }

  void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updateProjectProgress(String id, double progress) {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(progress: progress);
      notifyListeners();
    }
  }

  void _loadSeedProjects() {
    final uuid = const Uuid();
    _projects.addAll([
      Project(
        id: uuid.v4(),
        name: 'DevZen Mobile App',
        description: 'Design and build the premium mobile workspace using Flutter & Glassmorphic interfaces.',
        status: 'Active',
        priority: 'High',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        deadline: DateTime.now().add(const Duration(days: 20)),
        progress: 0.65,
        tags: ['Flutter', 'Firebase', 'UI/UX'],
        notes: '# Notes on UI\nUse BackdropFilter with sigma 15.0\nUse Inter & Outfit google fonts.',
      ),
      Project(
        id: uuid.v4(),
        name: 'OpenAI integration microservice',
        description: 'Express.js backend wrapper for OpenAI Chat completions with semantic search embeddings.',
        status: 'Active',
        priority: 'Medium',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        deadline: DateTime.now().add(const Duration(days: 8)),
        progress: 0.30,
        tags: ['Node.js', 'Express', 'AI'],
        notes: 'Review api keys configurations.',
      ),
      Project(
        id: uuid.v4(),
        name: 'Portfolio Web site',
        description: 'Vite + React portfolio showcasing modern 3D splines and responsive flex architectures.',
        status: 'Completed',
        priority: 'Low',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        progress: 1.0,
        tags: ['Vite', 'React', 'CSS'],
        notes: 'Deploy to Vercel.',
      ),
      Project(
        id: uuid.v4(),
        name: 'Legacy PHP CLI tools',
        description: 'Scripts parsing log archives and generating weekly statistics email reports.',
        status: 'Archived',
        priority: 'Low',
        startDate: DateTime.now().subtract(const Duration(days: 100)),
        deadline: DateTime.now().subtract(const Duration(days: 80)),
        progress: 1.0,
        tags: ['PHP', 'CLI'],
        notes: 'Deprecated.',
      ),
    ]);
  }
}
