import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NoteProvider extends ChangeNotifier {
  final List<Note> _notes = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  NoteProvider() {
    _loadSeedNotes();
  }

  List<Note> get notes {
    return _notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || note.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get categories => ['All', 'Ideas', 'Specs', 'Guides', 'General'];
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void updateNote(Note updatedNote) {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void togglePin(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(isPinned: !_notes[index].isPinned);
      notifyListeners();
    }
  }

  void _loadSeedNotes() {
    final uuid = const Uuid();
    _notes.addAll([
      Note(
        id: uuid.v4(),
        title: 'Project Roadmap Ideas',
        content: '''# Future Milestones
Here are some features we should investigate adding:
- [ ] Implement Offline Synced caching
- [ ] Connect custom LLMs locally
- [ ] Draw custom Git visual logs''',
        category: 'Ideas',
        isPinned: true,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Note(
        id: uuid.v4(),
        title: 'Firebase Collections Schema',
        content: '''# Firestore Schema Details

## Users Collection
- `uid`: String (Primary Key)
- `email`: String
- `displayName`: String

## Snippets Collection
- `id`: String
- `userId`: String
- `title`: String
- `code`: String''',
        category: 'Specs',
        isPinned: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Note(
        id: uuid.v4(),
        title: 'Git Commit Conventions',
        content: '''# Commit Message Formats

Follow this pattern:
`<type>(<scope>): <subject>`

### Types
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation updates
- `style`: Formatting changes''',
        category: 'Guides',
        isPinned: true,
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
  }
}
