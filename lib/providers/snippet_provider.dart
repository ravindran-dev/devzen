import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';

class SnippetProvider extends ChangeNotifier {
  final List<Snippet> _snippets = [];
  String _searchQuery = '';
  String _selectedLanguage = 'All';

  SnippetProvider() {
    _loadSeedSnippets();
  }

  List<Snippet> get snippets {
    return _snippets.where((snippet) {
      final matchesSearch = snippet.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          snippet.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          snippet.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLanguage = _selectedLanguage == 'All' || snippet.language == _selectedLanguage;
      return matchesSearch && matchesLanguage;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String get selectedLanguage => _selectedLanguage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void addSnippet(Snippet snippet) {
    _snippets.add(snippet);
    notifyListeners();
  }

  void deleteSnippet(String id) {
    _snippets.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _snippets.indexWhere((s) => s.id == id);
    if (index != -1) {
      _snippets[index] = _snippets[index].copyWith(isFavorite: !_snippets[index].isFavorite);
      notifyListeners();
    }
  }

  void _loadSeedSnippets() {
    final uuid = const Uuid();
    _snippets.addAll([
      Snippet(
        id: uuid.v4(),
        title: 'Binary Search Algorithm',
        description: 'Optimized search in sorted array with O(log n) time complexity.',
        language: 'Python',
        code: '''def binary_search(arr, low, high, x):
    if high >= low:
        mid = (high + low) // 2
        if arr[mid] == x:
            return mid
        elif arr[mid] > x:
            return binary_search(arr, low, mid - 1, x)
        else:
            return binary_search(arr, mid + 1, high, x)
    else:
        return -1''',
        tags: ['Algorithms', 'Search', 'O(log n)'],
        isFavorite: true,
      ),
      Snippet(
        id: uuid.v4(),
        title: 'Glassmorphic Card Decoration',
        description: 'Frosted container styling using BackdropFilter in Flutter.',
        language: 'Dart',
        code: '''BoxDecoration(
  color: Colors.white.withOpacity(0.08),
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
    color: Colors.white.withOpacity(0.12),
    width: 1.2,
  ),
)''',
        tags: ['Flutter', 'Design', 'Glassmorphism'],
        isFavorite: true,
      ),
      Snippet(
        id: uuid.v4(),
        title: 'Fast API CORS Middleware',
        description: 'Configure cross-origin resource sharing globally.',
        language: 'Python',
        code: '''from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)''',
        tags: ['FastAPI', 'Backend', 'Security'],
        isFavorite: false,
      ),
      Snippet(
        id: uuid.v4(),
        title: 'Recursive Common Table Expression',
        description: 'Traverse folder nodes recursively in Postgres hierarchy.',
        language: 'SQL',
        code: '''WITH RECURSIVE FolderHierarchy AS (
    SELECT id, name, parent_id, 1 as level
    FROM folders WHERE parent_id IS NULL
    UNION ALL
    SELECT f.id, f.name, f.parent_id, fh.level + 1
    FROM folders f
    JOIN FolderHierarchy fh ON f.parent_id = fh.id
)
SELECT * FROM FolderHierarchy;''',
        tags: ['Database', 'CTE', 'PostgreSQL'],
        isFavorite: false,
      ),
    ]);
  }
}
