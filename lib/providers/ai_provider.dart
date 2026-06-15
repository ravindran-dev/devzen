import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// AIProvider — Manages personalized chat with DevZen AI backend.
/// All responses are contextually aware of the user's profile, projects,
/// skills, and GitHub data thanks to the backend AI service.
class AIProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Send a message to DevZen AI and get a personalized response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    _messages.add({'role': 'user', 'content': content});
    _isLoading = true;
    notifyListeners();

    try {
      final resp = await _api.post('/ai/chat', data: {'message': content});
      final reply = resp.data['reply'] as String? ?? "I'm here to help! Please try again.";
      _messages.add({'role': 'assistant', 'content': reply});
    } catch (_) {
      _messages.add({
        'role': 'assistant',
        'content':
            '### DevZen AI\n\nI\'m having trouble connecting to the backend right now. Make sure the backend is running at `localhost:8000`.\n\nIn the meantime, you can:\n- Check your GitHub integration\n- Review your profile sections\n- Update your resume',
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
