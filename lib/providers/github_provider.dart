import 'package:flutter/material.dart';
import '../models/github_repo.dart';
import '../services/github_service.dart';
import '../services/api_service.dart';

class GitHubProvider extends ChangeNotifier {
  final GitHubService _githubService = GitHubService();
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isSyncing = false;
  List<GitHubRepo> _repos = [];
  Map<String, dynamic> _profileData = {};
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, int> _languagesAggregate = {};
  List<int> _contributions = [];
  String _currentUsername = '';
  DateTime? _lastSynced;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  List<GitHubRepo> get repos => _repos;
  Map<String, dynamic> get profileData => _profileData;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  Map<String, int> get languagesAggregate => _languagesAggregate;
  List<int> get contributions => _contributions;
  String get currentUsername => _currentUsername;
  DateTime? get lastSynced => _lastSynced;


  // Computed stats
  int get totalStars => _repos.fold(0, (sum, r) => sum + r.starsCount);
  int get totalForks => _repos.fold(0, (sum, r) => sum + r.forksCount);
  int get publicRepos => _profileData['repos'] ?? _repos.length;
  int get followers => _profileData['followers'] ?? 0;
  int get following => _profileData['following'] ?? 0;
  String get avatarUrl => _profileData['avatar_url'] ?? '';
  String get githubBio => _profileData['bio'] ?? '';
  String get location => _profileData['location'] ?? '';

  /// Load GitHub data directly from GitHub Public API (real data)
  Future<void> loadGitHubData(String username) async {
    if (username.isEmpty) return;
    _isLoading = true;
    _currentUsername = username;
    notifyListeners();

    try {
      // Fetch profile stats and repos in parallel
      final profileFuture = _githubService.fetchProfileStats(username);
      final reposFuture = _githubService.fetchRepositories(username);
      final activityFuture = _githubService.fetchRecentActivity(username);

      final results = await Future.wait([profileFuture, reposFuture, activityFuture]);

      _profileData = Map<String, dynamic>.from(results[0] as Map);
      _repos = List<GitHubRepo>.from(results[1] as Iterable);
      _recentActivity = (results[2] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Build contribution counts from events
      _contributions = _githubService.buildContributionCounts(_recentActivity);

      // Fetch language aggregate for top repos
      _languagesAggregate = await _githubService.fetchLanguagesAggregate(username, _repos);

      _lastSynced = DateTime.now();
    } catch (e, stackTrace) {
      debugPrint('Error loading GitHub data in provider: $e');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Trigger backend GitHub sync (stores data in DB for AI context)
  Future<void> syncWithBackend() async {
    _isSyncing = true;
    notifyListeners();
    try {
      await _api.post('/github/sync');
    } catch (_) {}
    _isSyncing = false;
    notifyListeners();
  }

  /// Pull-to-refresh: reload from GitHub and re-sync with backend
  Future<void> pullToRefresh(String username) async {
    await loadGitHubData(username);
    await syncWithBackend();
  }

  List<Map<String, dynamic>> get parsedTimeline {
    final timeline = <Map<String, dynamic>>[];
    for (final event in _recentActivity.take(15)) {
      final type = event['type'] as String? ?? '';
      final repoName = (event['repo'] as Map?)?['name']?.toString().split('/').last ?? '';
      final createdAt = event['created_at'] as String? ?? '';
      final payload = event['payload'] as Map<String, dynamic>? ?? {};

      String title = '';
      String? description;
      String icon = 'code';

      switch (type) {
        case 'PushEvent':
          final commits = payload['commits'] as List? ?? [];
          final count = commits.length;
          title = 'Pushed $count commit${count != 1 ? 's' : ''} to $repoName';
          description = commits.isNotEmpty ? (commits.first as Map)['message']?.toString() : null;
          icon = 'commit';
          break;
        case 'CreateEvent':
          final refType = payload['ref_type'] ?? 'repository';
          title = 'Created $refType in $repoName';
          icon = 'create';
          break;
        case 'PullRequestEvent':
          final action = payload['action'] ?? '';
          final pr = payload['pull_request'] as Map? ?? {};
          title = '${_capitalize(action)} pull request in $repoName';
          description = pr['title']?.toString();
          icon = 'pr';
          break;
        case 'ReleaseEvent':
          final release = payload['release'] as Map? ?? {};
          title = 'Released ${release['tag_name'] ?? ''} in $repoName';
          icon = 'release';
          break;
        case 'WatchEvent':
          title = 'Starred $repoName';
          icon = 'star';
          break;
        case 'ForkEvent':
          title = 'Forked $repoName';
          icon = 'fork';
          break;
        default:
          continue;
      }

      timeline.add({
        'title': title,
        'description': description,
        'repo': repoName,
        'icon': icon,
        'time': _formatTime(createdAt),
        'raw_time': createdAt,
      });
    }
    return timeline;
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
