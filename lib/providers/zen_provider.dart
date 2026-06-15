import 'package:flutter/material.dart';
import '../models/zen_score.dart';
import '../services/api_service.dart';

/// ZenProvider — Manages the dynamic Zen Score from the backend engine.
class ZenProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ZenScore _zenScore = ZenScore.empty();
  bool _isLoading = false;
  bool _isRecalculating = false;

  ZenScore get zenScore => _zenScore;
  bool get isLoading => _isLoading;
  bool get isRecalculating => _isRecalculating;

  double get total => _zenScore.total;
  String get rank => _zenScore.rank;
  String get trend => _zenScore.trend;
  ZenBreakdown get breakdown => _zenScore.breakdown;

  Future<void> loadZenScore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final resp = await _api.get('/zen/score');
      _zenScore = ZenScore.fromJson(Map<String, dynamic>.from(resp.data));
    } catch (_) {
      // Keep existing score if load fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recalculate() async {
    _isRecalculating = true;
    notifyListeners();

    try {
      final resp = await _api.post('/zen/recalculate');
      _zenScore = ZenScore.fromJson(Map<String, dynamic>.from(resp.data));
    } catch (_) {
      // Silently fail — keep existing score
    } finally {
      _isRecalculating = false;
      notifyListeners();
    }
  }
}
