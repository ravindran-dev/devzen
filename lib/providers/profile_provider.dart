import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

/// ProfileProvider — Loads and manages the full user profile from the backend.
/// All data comes from resume parsing + GitHub sync performed at registration.
class ProfileProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserProfile? _profile;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isUploadingResume = false;
  String _resumeUploadStatus = '';

  List<Map<String, dynamic>> _aiSuggestions = [];

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isUploadingResume => _isUploadingResume;
  String get resumeUploadStatus => _resumeUploadStatus;
  List<Map<String, dynamic>> get aiSuggestions => _aiSuggestions;

  bool get hasProfile => _profile != null;

  // Convenience getters
  String get fullName => _profile?.fullName ?? '';
  String get headline => _profile?.headline ?? '';
  String get bio => _profile?.bio ?? '';
  String get avatarUrl => _profile?.avatarUrl ?? '';
  double get zenScore => _profile?.zenScore ?? 0.0;
  String get zenRank => _profile?.zenRank ?? 'Beginner';
  String get zenTrend => _profile?.zenTrend ?? 'stable';
  List<Skill> get skills => _profile?.skills ?? [];
  List<Education> get educations => _profile?.educations ?? [];
  List<Experience> get experiences => _profile?.experiences ?? [];
  List<Project> get projects => _profile?.projects ?? [];
  List<Achievement> get achievements => _profile?.achievements ?? [];
  List<Certification> get certifications => _profile?.certifications ?? [];

  List<Skill> get githubSkills =>
      skills.where((s) => s.source == 'GitHub').toList();
  List<Skill> get resumeSkills =>
      skills.where((s) => s.source == 'Resume').toList();

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final resp = await _api.get('/profile/me');
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(resp.data));
      _errorMessage = '';
      
      // Also fetch suggestions automatically
      await loadSuggestions();
    } catch (e) {
      _errorMessage = 'Failed to load profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuggestions() async {
    try {
      final resp = await _api.get('/ai/suggestions');
      _aiSuggestions = List<Map<String, dynamic>>.from(resp.data);
    } catch (_) {
      _aiSuggestions = [];
    }
  }

  Future<bool> uploadResume(File resumeFile) async {
    _isUploadingResume = true;
    _resumeUploadStatus = 'Analyzing resume with AI...';
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'resume': await MultipartFile.fromFile(
          resumeFile.path,
          filename: resumeFile.path.split(r'\').last.split('/').last,
        ),
      });
      final resp = await _api.postMultipart('/profile/resume/upload', formData);
      final result = Map<String, dynamic>.from(resp.data);
      _resumeUploadStatus = result['message'] ?? 'Resume analyzed successfully!';

      // Reload profile with new data
      await loadProfile();
      return true;
    } catch (e) {
      _resumeUploadStatus = 'Resume upload failed. Please try again.';
      return false;
    } finally {
      _isUploadingResume = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? headline,
    String? bio,
    String? technicalSummary,
    String? careerOverview,
  }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName ?? _profile?.fullName ?? '',
        'headline': headline ?? _profile?.headline,
        'bio': bio ?? _profile?.bio,
        'technical_summary': technicalSummary ?? _profile?.technicalSummary,
        'career_overview': careerOverview ?? _profile?.careerOverview,
        'profile_visibility': _profile?.profileVisibility ?? true,
      };
      final resp = await _api.put('/profile/me', data: body);
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(resp.data));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
    }
  }

  Future<void> addSkill(String name, String category, String proficiency) async {
    try {
      await _api.post('/profile/skills', data: {
        'name': name,
        'category': category,
        'proficiency_level': proficiency,
        'source': 'Manual',
        'is_visible': true,
        'order': 0,
      });
      await loadProfile();
    } catch (e) {
      _errorMessage = 'Failed to add skill';
      notifyListeners();
    }
  }

  Future<void> deleteSkill(int skillId) async {
    try {
      await _api.delete('/profile/skills/$skillId');
      await loadProfile();
    } catch (e) {
      _errorMessage = 'Failed to delete skill';
      notifyListeners();
    }
  }
}
