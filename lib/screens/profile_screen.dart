import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_input.dart';
import '../core/widgets/glass_button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../providers/zen_provider.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final zen = Provider.of<ZenProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);

    await Future.wait([
      if (!profile.hasProfile) profile.loadProfile(),
      if (zen.total == 0) zen.loadZenScore(),
    ]);

    if (auth.githubUsername.isNotEmpty && github.repos.isEmpty) {
      github.loadGitHubData(auth.githubUsername);
    }
  }

  Future<void> _onRefresh() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final zen = Provider.of<ZenProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);

    await Future.wait([
      profile.loadProfile(),
      zen.recalculate(),
    ]);

    if (auth.githubUsername.isNotEmpty) {
      await github.pullToRefresh(auth.githubUsername);
    }
  }

  void _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _pickAndUploadResume() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final success = await profile.uploadResume(file);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume uploaded and parsed successfully by AI!'),
              backgroundColor: AppColors.greenAccent,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload/parse resume.'),
              backgroundColor: AppColors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _syncGitHub() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.githubUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No GitHub username connected to account.'),
          backgroundColor: AppColors.orangeAccent,
        ),
      );
      return;
    }

    try {
      await github.pullToRefresh(auth.githubUsername);
      await profile.loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub data synchronized successfully!'),
            backgroundColor: AppColors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync GitHub: $e'),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final github = Provider.of<GitHubProvider>(context);

    final isLoading = profile.isLoading && !profile.hasProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.blueAccent,
                ),
              )
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.blueAccent,
                backgroundColor: AppColors.surfaceLight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 120.0),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Developer Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                            onPressed: () => _showEditProfileSheet(context, profile),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profile Card
                      _buildProfileCard(profile, github, auth),
                      const SizedBox(height: 20),

                      // Action Buttons (Upload / Sync)
                      _buildQuickActions(profile, github),
                      const SizedBox(height: 20),

                      // AI Suggestions Carousel Banner
                      if (profile.aiSuggestions.isNotEmpty) ...[
                        _buildAiSuggestionsBanner(profile),
                        const SizedBox(height: 20),
                      ],

                      // Bio & Summaries Section
                      if (profile.bio.isNotEmpty ||
                          (profile.profile?.technicalSummary?.isNotEmpty ?? false) ||
                          (profile.profile?.careerOverview?.isNotEmpty ?? false)) ...[
                        _buildBioSection(profile),
                        const SizedBox(height: 20),
                      ],

                      // Skills Section
                      _buildSkillsSection(profile),
                      const SizedBox(height: 20),

                      // Experience Section
                      _buildExperienceSection(profile),
                      const SizedBox(height: 20),

                      // Education Section
                      _buildEducationSection(profile),
                      const SizedBox(height: 20),

                      // Projects Section
                      _buildProjectsSection(profile),
                      const SizedBox(height: 20),

                      // Certifications Section
                      _buildCertificationsSection(profile),
                      const SizedBox(height: 20),

                      // Achievements Section
                      _buildAchievementsSection(profile),
                      const SizedBox(height: 30),

                      // Sign Out Button
                      GlassButton(
                        text: 'Disconnect Workspace',
                        color: AppColors.redAccent,
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Profile Overview Card ──────────────────────────────────────────────────
  Widget _buildProfileCard(ProfileProvider profile, GitHubProvider github, AuthProvider auth) {
    final avatarUrl = profile.avatarUrl.isNotEmpty
        ? profile.avatarUrl
        : (github.avatarUrl.isNotEmpty ? github.avatarUrl : null);
    final name = profile.fullName.isNotEmpty ? profile.fullName : auth.fullName;
    final headline = profile.headline.isNotEmpty ? profile.headline : 'Developer Identity';
    final score = profile.zenScore.round();
    final rank = profile.zenRank;
    final trend = profile.zenTrend;

    IconData trendIcon = Icons.trending_flat;
    Color trendColor = AppColors.textSecondary;
    if (trend == 'up') {
      trendIcon = Icons.trending_up;
      trendColor = AppColors.greenAccent;
    } else if (trend == 'down') {
      trendIcon = Icons.trending_down;
      trendColor = AppColors.redAccent;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.blueAccent, AppColors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'D',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),

              // Name + Title + Zen Score Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    // Contact Details Column (Compact & Professional)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                auth.email,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.code_rounded, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                auth.githubUsername.isNotEmpty ? 'github.com/${auth.githubUsername}' : 'github.com/developer',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                github.location.isNotEmpty ? github.location : 'India',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Zen Score Mini Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Zen Score: ',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                '$score',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        // Rank Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.purpleAccent.withOpacity(0.3)),
                          ),
                          child: Text(
                            rank,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Icon(trendIcon, color: trendColor, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions (Sync & Upload) ──────────────────────────────────────────
  Widget _buildQuickActions(ProfileProvider profile, GitHubProvider github) {
    return Row(
      children: [
        // Resume upload button
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: 16,
            child: InkWell(
              onTap: profile.isUploadingResume ? null : _pickAndUploadResume,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  profile.isUploadingResume
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueAccent),
                        )
                      : const Icon(Icons.cloud_upload_outlined, color: AppColors.blueAccent, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    profile.isUploadingResume ? 'Analyzing Resume...' : 'Update Resume',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // GitHub sync button
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: 16,
            child: InkWell(
              onTap: github.isSyncing || github.isLoading ? null : _syncGitHub,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  github.isSyncing || github.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleAccent),
                        )
                      : const Icon(Icons.sync, color: AppColors.purpleAccent, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    github.isSyncing || github.isLoading ? 'Syncing Stats...' : 'GitHub Sync',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── AI Suggestions Banner ─────────────────────────────────────────────────
  Widget _buildAiSuggestionsBanner(ProfileProvider profile) {
    final suggestions = profile.aiSuggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, color: AppColors.purpleAccent, size: 18),
            const SizedBox(width: 6),
            const Text(
              'DevZen AI Recommendations',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final category = suggestion['category'] ?? 'Profile';
              final tip = suggestion['suggestion'] ?? '';
              final priority = suggestion['priority'] ?? 'medium';

              Color priorityColor = AppColors.orangeAccent;
              if (priority == 'high') priorityColor = AppColors.redAccent;
              if (priority == 'low') priorityColor = AppColors.blueAccent;

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  borderColor: priorityColor.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category == 'github' ? Icons.hub_outlined : Icons.edit_note,
                          color: priorityColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.toString().toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tip,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Bio & Summaries Section ───────────────────────────────────────────────
  Widget _buildBioSection(ProfileProvider profile) {
    final hasBio = profile.bio.isNotEmpty;
    final technicalSummary = profile.profile?.technicalSummary ?? '';
    final careerOverview = profile.profile?.careerOverview ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'About & Technical Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (hasBio) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
          if (technicalSummary.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Technical Profile',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              technicalSummary,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
          if (careerOverview.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Career Briefing',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              careerOverview,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Skills Section ────────────────────────────────────────────────────────
  Widget _buildSkillsSection(ProfileProvider profile) {
    final skills = profile.skills;

    // Group skills by category
    final Map<String, List<Skill>> groupedSkills = {};
    for (final skill in skills) {
      final category = skill.category ?? 'General';
      if (!groupedSkills.containsKey(category)) {
        groupedSkills[category] = [];
      }
      groupedSkills[category]!.add(skill);
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skills & Technologies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.blueAccent, size: 20),
                onPressed: () => _showAddSkillDialog(context, profile),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Source Legend
          Row(
            children: [
              _buildSourceLegendItem('Resume', AppColors.greenAccent),
              const SizedBox(width: 12),
              _buildSourceLegendItem('GitHub', AppColors.purpleAccent),
              const SizedBox(width: 12),
              _buildSourceLegendItem('Manual', AppColors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),

          if (skills.isEmpty)
            const Text(
              'No skills loaded. Tap + or upload a resume to add skills.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedSkills.entries.map((entry) {
                final category = entry.key;
                final list = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: list.map((skill) {
                          Color badgeColor = AppColors.blueAccent;
                          if (skill.source == 'Resume') {
                            badgeColor = AppColors.greenAccent;
                          } else if (skill.source == 'GitHub') {
                            badgeColor = AppColors.purpleAccent;
                          }

                          return Container(
                            padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badgeColor.withOpacity(0.25), width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  skill.name,
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 4),
                                if (skill.source == 'Manual')
                                  GestureDetector(
                                    onTap: () => _deleteSkill(profile, skill.id),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(Icons.close, size: 12, color: AppColors.textMuted),
                                    ),
                                  )
                                else
                                  Container(
                                    margin: const EdgeInsets.only(left: 4, right: 6),
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: badgeColor,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ─── Experience Section ────────────────────────────────────────────────────
  Widget _buildExperienceSection(ProfileProvider profile) {
    final experiences = profile.experiences;
    final displayExperiences = experiences.isNotEmpty
        ? experiences
        : [
            Experience(
              id: -1,
              company: 'DevZen Technologies',
              title: 'Software Engineer Intern',
              startDate: 'May 2024',
              endDate: 'Present',
              description: 'Working on full-stack AI developer identity workspace, implementing glassmorphic Dart/Flutter interfaces and FastAPI endpoints.',
              keyAchievements: [
                'Engineered dynamic GitHub synchronization modules that reduced local cache inconsistencies.',
                'Designed responsive glassmorphic interfaces that significantly improved application visual aesthetics.'
              ],
            ),
            Experience(
              id: -2,
              company: 'Open Source Community',
              title: 'Contributor',
              startDate: 'Jan 2023',
              endDate: 'May 2024',
              description: 'Maintained and contributed to several popular Dart & Python packages.',
              keyAchievements: [
                'Optimized async event dispatching loops, reducing API response latencies.',
                'Authored comprehensive API integration test suites that achieved 95% code coverage.'
              ],
            ),
          ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Professional Experience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayExperiences.length,
              itemBuilder: (context, index) {
                final exp = displayExperiences[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exp.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Text(
                            exp.durationText,
                            style: const TextStyle(fontSize: 11, color: AppColors.blueAccent, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exp.company,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      if (exp.description != null && exp.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          exp.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                      if (exp.keyAchievements.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...exp.keyAchievements.map((ach) => Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.blueAccent)),
                                  Expanded(
                                    child: Text(
                                      ach,
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (index < experiences.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Divider(color: Colors.white10),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Education Section ─────────────────────────────────────────────────────
  Widget _buildEducationSection(ProfileProvider profile) {
    final educations = profile.educations;
    final displayEducations = educations.isNotEmpty
        ? educations
        : [
            Education(
              id: -1,
              institution: 'PSG College of Technology',
              degree: 'Bachelor of Engineering in Computer Science',
              duration: '2021 — 2025',
              department: 'Department of Computer Science and Engineering',
              cgpa: '8.8 / 10',
              coursework: ['Data Structures', 'Database Systems', 'Software Engineering'],
              academicProjects: ['DevZen Identity App', 'AI Phishing Detector'],
            )
          ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Education History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayEducations.length,
              itemBuilder: (context, index) {
                final edu = displayEducations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              edu.degree,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          if (edu.duration != null)
                            Text(
                              edu.duration!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        edu.institution,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      if (edu.department != null && edu.department!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          edu.department!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                      if (edu.cgpa != null && edu.cgpa!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'CGPA/Score: ${edu.cgpa}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (edu.coursework.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: edu.coursework.map((course) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Text(
                                  course,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              )).toList(),
                        ),
                      ],
                      if (edu.academicProjects.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Projects: ',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                edu.academicProjects.join(', '),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (index < educations.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: Divider(color: Colors.white10),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Projects Section ──────────────────────────────────────────────────────
  Widget _buildProjectsSection(ProfileProvider profile) {
    final projects = profile.projects;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Highlighted Projects',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const Text(
              'No projects synced yet. Connect GitHub to aggregate repository details.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final proj = projects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              proj.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_outline, size: 13, color: AppColors.orangeAccent),
                              const SizedBox(width: 3),
                              Text('${proj.starsCount}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              const Icon(Icons.history, size: 13, color: AppColors.blueAccent),
                              const SizedBox(width: 3),
                              Text('${proj.commitsCount}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proj.shortDescription,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      if (proj.technologies.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: proj.technologies.map((tech) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.blueAccent.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.blueAccent.withOpacity(0.12)),
                                ),
                                child: Text(
                                  tech,
                                  style: const TextStyle(fontSize: 10, color: AppColors.blueAccent, fontWeight: FontWeight.bold),
                                ),
                              )).toList(),
                        ),
                      if (index < projects.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Divider(color: Colors.white10),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Certifications Section ────────────────────────────────────────────────
  Widget _buildCertificationsSection(ProfileProvider profile) {
    final certifications = profile.certifications;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Certifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (certifications.isEmpty)
            const Text(
              'No certifications loaded.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: certifications.length,
              itemBuilder: (context, index) {
                final cert = certifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cert.issuer,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (cert.issueDate != null)
                            Text(
                              cert.issueDate!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      if (cert.credentialId != null && cert.credentialId!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${cert.credentialId}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                      if (index < certifications.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: Divider(color: Colors.white10),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Achievements Section ──────────────────────────────────────────────────
  Widget _buildAchievementsSection(ProfileProvider profile) {
    final achievements = profile.achievements;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (achievements.isEmpty)
            const Text(
              'No achievements unlocked/loaded.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final ach = achievements[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.orangeAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_outlined, color: AppColors.orangeAccent, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            if (ach.description != null && ach.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                ach.description!,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Actions & Dialogs ─────────────────────────────────────────────────────

  void _showAddSkillDialog(BuildContext context, ProfileProvider profile) {
    final nameController = TextEditingController();
    String category = 'Languages';
    String proficiency = 'Intermediate';

    final categories = ['Languages', 'Frameworks', 'Tools', 'Databases', 'General'];
    final proficiencies = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Skill Manually', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Skill Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  GlassInput(
                    hintText: 'e.g. Flutter, Rust',
                    controller: nameController,
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.surface,
                        value: category,
                        items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => category = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Proficiency Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.surface,
                        value: proficiency,
                        items: proficiencies.map((prof) => DropdownMenuItem(
                          value: prof,
                          child: Text(prof, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => proficiency = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      profile.addSkill(name, category, proficiency);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: AppColors.blueAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSkill(ProfileProvider profile, int skillId) async {
    try {
      await profile.deleteSkill(skillId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill removed successfully.'),
            backgroundColor: AppColors.greenAccent,
          ),
        );
      }
    } catch (_) {}
  }

  void _showEditProfileSheet(BuildContext context, ProfileProvider profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final headlineController = TextEditingController(text: profile.headline);
    final bioController = TextEditingController(text: profile.bio);
    final techSummaryController = TextEditingController(text: profile.profile?.technicalSummary ?? '');
    final careerOverviewController = TextEditingController(text: profile.profile?.careerOverview ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const Text('Full Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    GlassInput(
                      hintText: 'e.g. Alex Rivera',
                      controller: nameController,
                    ),
                    const SizedBox(height: 14),
                    const Text('Professional Headline', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    GlassInput(
                      hintText: 'e.g. Senior Flutter Developer',
                      controller: headlineController,
                    ),
                    const SizedBox(height: 14),
                    const Text('Bio Summary', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    GlassInput(
                      hintText: 'Describe yourself...',
                      controller: bioController,
                    ),
                    const SizedBox(height: 14),
                    const Text('Technical Summary', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: techSummaryController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Summarize your technical stack & strengths...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Career Overview', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: careerOverviewController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Summarize your career progression...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              GlassButton(
                text: 'Save Changes',
                onPressed: () async {
                  final name = nameController.text.trim();
                  final headline = headlineController.text.trim();
                  final bio = bioController.text.trim();
                  final techSum = techSummaryController.text.trim();
                  final careerOver = careerOverviewController.text.trim();

                  if (name.isNotEmpty) {
                    await profile.updateProfile(
                      fullName: name,
                      headline: headline,
                      bio: bio,
                      technicalSummary: techSum,
                      careerOverview: careerOver,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
