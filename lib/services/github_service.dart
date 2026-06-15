import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_repo.dart';

/// GitHub Service — Direct GitHub Public API calls from Flutter.
/// Uses api.github.com endpoints without authentication (60 req/hr limit).
class GitHubService {
  static const String _base = 'https://api.github.com';
  static const Map<String, String> _headers = {
    'User-Agent': 'DevZen-App/2.0',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  final http.Client _client = http.Client();

  // ─── User Profile ─────────────────────────────────────────────────────────

  Map<String, dynamic> _mockProfile(String username) {
    return {
      'login': username,
      'id': 166739819,
      'avatar_url': 'https://avatars.githubusercontent.com/u/166739819?v=4',
      'name': 'RAVINDRAN S',
      'company': 'AIML Student',
      'blog': 'https://ravindran-dev.github.io',
      'location': 'India',
      'email': 'ravindran.s.dev@gmail.com',
      'bio': 'I’m an AIML engineering student who loves building intelligent applications and clean developer workflows.',
      'public_repos': 36,
      'followers': 12,
      'following': 15,
    };
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchUserProfile(String username) async {
    try {
      final resp = await _client
          .get(Uri.parse('$_base/users/$username'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(resp.body));
      }
    } catch (_) {}
    return {};
  }

  // ─── Profile Stats ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProfileStats(String username) async {
    var data = await fetchUserProfile(username);
    if (data.isEmpty) {
      data = _mockProfile(username);
    }
    return {
      'repos': data['public_repos'] ?? 36,
      'followers': data['followers'] ?? 142,
      'following': data['following'] ?? 98,
      'avatar_url': data['avatar_url'] ?? '',
      'name': data['name'] ?? username,
      'bio': data['bio'] ?? '',
      'location': data['location'] ?? 'India',
      'company': data['company'] ?? '',
      'blog': data['blog'] ?? '',
      'stars': 43, // Mock total stars
    };
  }

  // ─── Repositories ─────────────────────────────────────────────────────────

  Future<List<GitHubRepo>> fetchRepositories(String username) async {
    try {
      final resp = await _client
          .get(
            Uri.parse('$_base/users/$username/repos?sort=updated&per_page=30&type=owner'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((j) => GitHubRepo.fromMap(j)).toList();
      }
    } catch (_) {}

    // Fallback Mock Repositories
    return [
      GitHubRepo(
        name: 'CancerRisk-LR',
        description: 'This project implements Logistic Regression,  to perform binary classification on a real-world dataset.',
        starsCount: 5,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['cancer-detection', 'jupyter-notebook', 'logistic-regression', 'machine-learning', 'machine-learning-algorithms', 'python'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      GitHubRepo(
        name: 'CreditDecision-DT',
        description: 'This project demonstrates a machine learning approach to predict loan approvals using a Decision Tree Classifier.',
        starsCount: 5,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['jupyter-notebook', 'loan-prediction-analysis', 'machine-learning', 'machine-learning-algorithms', 'python'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      GitHubRepo(
        name: 'dotfiles',
        description: 'My Arch Linux dotfiles, a full automated setup script for quickly restoring my development environment.',
        starsCount: 4,
        forksCount: 0,
        language: 'Shell',
        topics: ['archlinux-dotfiles', 'config', 'fastfetch-conf', 'zsh-configuration'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      GitHubRepo(
        name: 'nvim',
        description: 'A Neovim configuration designed for performance and a true IDE-like development experience.',
        starsCount: 4,
        forksCount: 0,
        language: 'Lua',
        topics: ['archlinux-dotfiles', 'config', 'lazynvim', 'lua', 'mason', 'neovim', 'neovim-dotfiles', 'vimscript'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      GitHubRepo(
        name: 'HomeValue',
        description: 'This project uses machine learning algorithms to predict house prices based on various features using a dataset',
        starsCount: 3,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['house-price-prediction', 'jupyter-notebook', 'linear-regression', 'machine-learning', 'machine-learning-algorithms', 'python'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      GitHubRepo(
        name: 'AcademicPredict',
        description: 'Predicting student academic performance using a machine learning approach. This project leverages the Random Forest Classifier algorithm.',
        starsCount: 3,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['jupyter-notebook', 'machine-learning', 'machine-learning-algorithms', 'python', 'student-performance-analysis'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 11)),
      ),
      GitHubRepo(
        name: 'Leetcode',
        description: 'Collection of LeetCode questions to ace the coding interview! - Created using [LeetHub v3](https://github.com/raphaelheinz/LeetHub-3.0)',
        starsCount: 3,
        forksCount: 0,
        language: 'C++',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 13)),
      ),
      GitHubRepo(
        name: 'mining-lca-ai',
        description: 'A machine-learning based Life Cycle Assessment tool for the mining and metallurgy sector that predicts CO₂ emissions, energy use, water footprint, and circularity. It analyzes process data, estimates impacts, and suggests improvements to help industries adopt more sustainable and circular production pathways.',
        starsCount: 3,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['flask', 'machine-learning', 'rag-chatbot', 'reactjs'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      GitHubRepo(
        name: 'rootlink',
        description: 'Rootlink is a native Linux/Wayland file manager built with Qt6/QML, C++, and Rust.',
        starsCount: 2,
        forksCount: 0,
        language: 'QML',
        topics: ['archlinux', 'cmake', 'filemanager', 'filemanager-ui', 'filesystem', 'linux', 'qml-applications', 'rust', 'sway', 'wayland'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 17)),
      ),
      GitHubRepo(
        name: 'quantum',
        description: 'A modern, full-stack web-based code compiler that supports C++, Python, and Java. Write, compile, and execute code directly in your browser.',
        starsCount: 2,
        forksCount: 0,
        language: 'JavaScript',
        topics: ['javascript', 'monaco-editor', 'nodejs', 'railway', 'reactjs', 'shell-script', 'vercel-deployment'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 19)),
      ),
      GitHubRepo(
        name: 'Portfolio',
        description: 'A modern, responsive developer portfolio built with React and Tailwind CSS, showcasing AI/ML engineering expertise and full-stack development skills.',
        starsCount: 2,
        forksCount: 0,
        language: 'TypeScript',
        topics: ['github', 'portfolio-website', 'react', 'resume', 'tailwindcss'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 21)),
      ),
      GitHubRepo(
        name: 'ravindran-dev',
        description: 'I’m an AIML engineering student who loves building intelligent applications and clean developer workflows.',
        starsCount: 2,
        forksCount: 0,
        language: 'Dart',
        topics: ['config', 'github-config', 'profile-readme'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 23)),
      ),
      GitHubRepo(
        name: 'Jarvis',
        description: 'Jarvis is a terminal-based system monitoring tool for Linux',
        starsCount: 1,
        forksCount: 0,
        language: 'Rust',
        topics: ['linux', 'linux-commands', 'metrics', 'rust', 'storage', 'tui'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      GitHubRepo(
        name: 'microdet_v2',
        description: 'A lightweight, anchor-free object detection system built using MicroDet, optimized for drone imagery.',
        starsCount: 1,
        forksCount: 0,
        language: 'Python',
        topics: ['drone', 'drone-technology', 'object-detection', 'python', 'pytorch'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 27)),
      ),
      GitHubRepo(
        name: 'AirMouse3D',
        description: 'The 3D Air Mouse project enables a smartphone to act as a wireless mouse for a PC using built-in motion sensors. ',
        starsCount: 1,
        forksCount: 2,
        language: 'Rust',
        topics: ['android-sensors', 'android-studio', 'firebase-realtime-database', 'kotlin', 'multi-os', 'rust'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 29)),
      ),
      GitHubRepo(
        name: 'PostTrace',
        description: 'A full-stack web app that finds LinkedIn posts mentioning any keyword (e.g. "Adya AI" or a person\'s name) from the last six months.',
        starsCount: 1,
        forksCount: 0,
        language: 'Python',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 31)),
      ),
      GitHubRepo(
        name: 'microdet',
        description: 'Drone Automation (object detection) model ',
        starsCount: 1,
        forksCount: 0,
        language: 'Python',
        topics: ['drone-detection', 'drone-technology', 'machine-learning', 'yolov11', 'yolov8'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 33)),
      ),
      GitHubRepo(
        name: 'ravindran-dev.github.io',
        description: 'Arch Linux–inspired interactive terminal portfolio ',
        starsCount: 1,
        forksCount: 0,
        language: 'JavaScript',
        topics: ['github-config', 'portfolio-page', 'profile', 'readme-profile'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      GitHubRepo(
        name: 'GenuineGate',
        description: 'Real-time anti-scalping bot protection',
        starsCount: 1,
        forksCount: 0,
        language: 'HTML',
        topics: ['docker', 'docker-compose', 'golang', 'html5', 'redis', 'shell-script'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 37)),
      ),
      GitHubRepo(
        name: 'linux-health',
        description: 'A lightweight, fast, and dependency-free Linux system health monitoring tool written in Go.',
        starsCount: 1,
        forksCount: 0,
        language: 'Go',
        topics: ['cli', 'diagnostic-tool', 'go', 'linux'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 39)),
      ),
      GitHubRepo(
        name: 's2n-tls',
        description: 'An implementation of the TLS/SSL protocols',
        starsCount: 1,
        forksCount: 0,
        language: 'C',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 41)),
      ),
      GitHubRepo(
        name: 'devzen',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'Dart',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 43)),
      ),
      GitHubRepo(
        name: 'promptlab',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'Python',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      GitHubRepo(
        name: 'hazzlefree',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'Python',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 47)),
      ),
      GitHubRepo(
        name: 'RPS',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'JavaScript',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 49)),
      ),
      GitHubRepo(
        name: 'esa',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'TypeScript',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 51)),
      ),
      GitHubRepo(
        name: 'Machine-Guard-AI',
        description: '',
        starsCount: 0,
        forksCount: 0,
        language: 'Dart',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 53)),
      ),
      GitHubRepo(
        name: 'NoteScan',
        description: 'NoteScan is a handwritten text recognition (HTR) application that converts handwritten images into clean, editable digital text.',
        starsCount: 0,
        forksCount: 0,
        language: 'Python',
        topics: ['full-stack', 'javascript', 'machine-learning', 'ocr-recognition', 'python', 'react', 'tailwindcss'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 55)),
      ),
      GitHubRepo(
        name: 'NoteScan-ML',
        description: 'This notebook presents a complete experimental and implementation workflow for Handwritten Text Recognition (HTR) using a transformer-based OCR model',
        starsCount: 0,
        forksCount: 0,
        language: 'Jupyter Notebook',
        topics: ['deep-learning', 'jupyter-notebook', 'nlp-machine-learning', 'ocr-recognition', 'python'],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 57)),
      ),
      GitHubRepo(
        name: 'kitkat',
        description: 'A toy Git clone written in Go',
        starsCount: 0,
        forksCount: 0,
        language: 'Dart',
        topics: [],
        isPrivate: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 59)),
      ),
    ];
  }

  // ─── Recent Activity / Events ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRecentActivity(String username) async {
    try {
      final resp = await _client
          .get(
            Uri.parse('$_base/users/$username/events/public?per_page=20'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // Fallback Mock Events
    return [
      {
        'id': 'mock_evt_1',
        'type': 'PushEvent',
        'repo': {'name': '$username/CancerRisk-LR'},
        'created_at': DateTime.now().toIso8601String(),
        'payload': {
          'commits': [{'message': 'feat: implement logistic regression training loop'}]
        }
      },
      {
        'id': 'mock_evt_2',
        'type': 'PullRequestEvent',
        'repo': {'name': '$username/CreditDecision-DT'},
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'payload': {
          'action': 'merged',
          'pull_request': {'title': 'feat: add decision tree visualization'}
        }
      },
      {
        'id': 'mock_evt_3',
        'type': 'CreateEvent',
        'repo': {'name': '$username/dotfiles'},
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'payload': {
          'ref_type': 'branch',
          'ref': 'feature/wayland-hyprland'
        }
      },
      {
        'id': 'mock_evt_4',
        'type': 'WatchEvent',
        'repo': {'name': '$username/nvim'},
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'mock_evt_5',
        'type': 'ReleaseEvent',
        'repo': {'name': '$username/rootlink'},
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'payload': {
          'tag_name': 'v1.0.0',
          'release': {'name': 'Stable Release 1.0.0'}
        }
      }
    ];
  }

  // ─── Languages Aggregate ──────────────────────────────────────────────────

  Future<Map<String, int>> fetchLanguagesAggregate(String username, List<GitHubRepo> repos) async {
    final Map<String, int> aggregate = {};
    
    // Check if we are using mock repos
    bool hasMock = repos.any((r) => r.name == 'CancerRisk-LR');
    if (hasMock && repos.length <= 30) {
      // Mock language data representing ravindran-dev's actual profile
      return {
        'Jupyter Notebook': 325000,
        'Python': 325000,
        'Rust': 255000,
        'TypeScript': 230000,
        'Dart': 180000,
        'Go': 150000,
        'JavaScript': 110000,
        'C++': 95000,
        'Shell': 60000,
        'HTML': 79000,
        'CSS': 23000,
        'Lua': 45000,
        'QML': 45000,
        'C': 45000,
      };
    }

    // Only fetch languages for top 5 repos to stay within rate limits
    for (final repo in repos.take(5)) {
      try {
        final resp = await _client
            .get(
              Uri.parse('$_base/repos/$username/${repo.name}/languages'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final Map<String, dynamic> langData = json.decode(resp.body);
          langData.forEach((lang, bytes) {
            aggregate[lang] = (aggregate[lang] ?? 0) + (bytes as int);
          });
        }
      } catch (_) {}
    }
    
    if (aggregate.isEmpty && repos.isNotEmpty) {
      // Return a basic fallback if it fails
      return {'Dart': 45000, 'Python': 35000};
    }
    return aggregate;
  }

  // ─── Contribution Heatmap (simulated from events) ─────────────────────────

  List<int> buildContributionCounts(List<Map<String, dynamic>> events) {
    // Count event activity per day from the fetched events
    final Map<String, int> dayCount = {};
    for (final event in events) {
      final createdAt = event['created_at'] as String? ?? '';
      if (createdAt.length >= 10) {
        final day = createdAt.substring(0, 10);
        dayCount[day] = (dayCount[day] ?? 0) + 1;
      }
    }

    // Generate 140 days of data with real values where available
    final result = <int>[];
    final now = DateTime.now();
    for (int i = 139; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      result.add(dayCount[key] ?? 0);
    }
    return result;
  }
}
