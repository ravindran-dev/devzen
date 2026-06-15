import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/progress_ring.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/github_provider.dart';
import '../providers/zen_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);
    final zen = Provider.of<ZenProvider>(context, listen: false);

    await Future.wait([
      if (!profile.hasProfile) profile.loadProfile(),
      if (zen.total == 0) zen.loadZenScore(),
    ]);

    if (auth.githubUsername.isNotEmpty && github.repos.isEmpty) {
      github.loadGitHubData(auth.githubUsername);
    }
  }

  Future<void> _onRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);
    final zen = Provider.of<ZenProvider>(context, listen: false);

    await Future.wait([
      profile.loadProfile(),
      zen.recalculate(),
    ]);

    if (auth.githubUsername.isNotEmpty) {
      await github.pullToRefresh(auth.githubUsername);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.blueAccent,
          backgroundColor: AppColors.surfaceLight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroHeader(),
                const SizedBox(height: 20),
                _buildZenScoreCard(),
                const SizedBox(height: 20),
                _buildGitHubStatsGrid(),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Activity'),
                const SizedBox(height: 12),
                _buildActivityTimeline(),
                const SizedBox(height: 24),
                _buildSectionHeader('Skills Overview'),
                const SizedBox(height: 12),
                _buildSkillsOverview(),
                const SizedBox(height: 24),
                _buildSectionHeader('Top Projects'),
                const SizedBox(height: 12),
                _buildTopProjects(),
                const SizedBox(height: 24),
                _buildAIInsightCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero Header ──────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    final auth = Provider.of<AuthProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);
    final github = Provider.of<GitHubProvider>(context);

    final avatarUrl = profile.avatarUrl.isNotEmpty
        ? profile.avatarUrl
        : (github.avatarUrl.isNotEmpty ? github.avatarUrl : null);
    final name = profile.fullName.isNotEmpty ? profile.fullName : auth.fullName;
    final username = auth.githubUsername.isNotEmpty ? '@${auth.githubUsername}' : auth.email;
    final headline = profile.headline.isNotEmpty ? profile.headline : 'Developer';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.blueAccent, AppColors.purpleAccent],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceLight,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Name + title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // DevZen logo small brand mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('lib/logo.png', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Zen Score Card ───────────────────────────────────────────────────────

  Widget _buildZenScoreCard() {
    final zen = Provider.of<ZenProvider>(context);
    final score = zen.total;
    final rank = zen.rank;
    final trend = zen.trend;
    final breakdown = zen.breakdown;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.blueAccent.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zen Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.blueAccent, AppColors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rank,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _trendText(trend),
                        style: TextStyle(
                          fontSize: 12,
                          color: _trendColor(trend),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ProgressRing(
                value: score / 100,
                size: 80,
                strokeWidth: 6,
                activeColor: _scoreColor(score),
                centerWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Zen',
                      style: TextStyle(fontSize: 8, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Score breakdown bars
          ...breakdown.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildScoreBar(
                  item['label'] as String,
                  (item['score'] as double),
                  (item['max'] as int).toDouble(),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, double max) {
    final ratio = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('${score.toStringAsFixed(1)}/${max.toInt()}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio > 0.7
                  ? AppColors.greenAccent
                  : ratio > 0.4
                      ? AppColors.blueAccent
                      : AppColors.orangeAccent,
            ),
          ),
        ),
      ],
    );
  }

  // ─── GitHub Stats Grid ────────────────────────────────────────────────────

  Widget _buildGitHubStatsGrid() {
    final github = Provider.of<GitHubProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);

    final stats = [
      {'label': 'Repos', 'value': github.publicRepos.toString(), 'icon': Icons.folder_outlined, 'color': AppColors.blueAccent},
      {'label': 'Stars', 'value': github.totalStars.toString(), 'icon': Icons.star_outline, 'color': AppColors.orangeAccent},
      {'label': 'Followers', 'value': github.followers.toString(), 'icon': Icons.people_outline, 'color': AppColors.purpleAccent},
      {'label': 'Skills', 'value': profile.skills.length.toString(), 'icon': Icons.code_rounded, 'color': AppColors.greenAccent},
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final aspectRatio = constraints.maxWidth < 340 ? 1.1 : 1.45;
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: stats.map((s) => _buildStatCard(
          s['label'] as String,
          s['value'] as String,
          s['icon'] as IconData,
          s['color'] as Color,
        )).toList(),
      );
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 16),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Activity Timeline ────────────────────────────────────────────────────

  Widget _buildActivityTimeline() {
    final github = Provider.of<GitHubProvider>(context);
    final timeline = github.parsedTimeline;

    if (github.isLoading) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.blueAccent, strokeWidth: 2),
              SizedBox(height: 12),
              Text('Loading GitHub activity...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (timeline.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset('lib/logo.png', width: 40, height: 40, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text('No GitHub activity yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Connect your GitHub to see your developer timeline',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: timeline.length.clamp(0, 5),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final item = timeline[i];
          final color = _eventColor(item['icon'] as String);
          final icon = _eventIcon(item['icon'] as String);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if ((item['description'] as String?) != null &&
                        (item['description'] as String).isNotEmpty)
                      Text(item['description'] as String,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item['time'] as String,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Skills Overview ──────────────────────────────────────────────────────

  Widget _buildSkillsOverview() {
    final profile = Provider.of<ProfileProvider>(context);
    final skills = profile.skills.take(12).toList();

    if (skills.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Text(
          'Upload your resume to populate skills automatically',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) {
          final color = _skillColor(skill.source);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (skill.source == 'GitHub')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.code, size: 10, color: color),
                  ),
                Text(
                  skill.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Top Projects ─────────────────────────────────────────────────────────

  Widget _buildTopProjects() {
    final profile = Provider.of<ProfileProvider>(context);
    final projects = profile.projects.take(3).toList();

    if (projects.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset('lib/logo.png', width: 40, height: 40, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text('Projects auto-generated from GitHub',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Connect GitHub to automatically import all repositories',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      children: projects.map((project) {
        final techs = project.technologies.take(3).join(' · ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.starsCount > 0) ...[
                      Icon(Icons.star_rounded, size: 13, color: AppColors.orangeAccent.withOpacity(0.8)),
                      const SizedBox(width: 2),
                      Text('${project.starsCount}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ]
                  ],
                ),
                if (project.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    project.shortDescription,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (techs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    techs,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.blueAccent,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── AI Insight Card ──────────────────────────────────────────────────────

  Widget _buildAIInsightCard() {
    final profile = Provider.of<ProfileProvider>(context);

    // Generate contextual insight
    String insight = 'Your DevZen AI is ready to help. Ask it to explain your projects, generate a LinkedIn bio, or identify skill gaps.';
    if (profile.githubSkills.isNotEmpty && profile.resumeSkills.isEmpty) {
      final skill = profile.githubSkills.first.name;
      insight = 'GitHub detected $skill in your repositories. Ask DevZen AI to add it to your profile summary!';
    } else if (profile.projects.isNotEmpty) {
      insight = 'You have ${profile.projects.length} projects. Ask DevZen AI to generate a portfolio bio or explain your top project.';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.purpleAccent.withOpacity(0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleAccent.withOpacity(0.3),
                  blurRadius: 12,
                )
              ],
            ),
            child: ClipOval(
              child: Image.asset('lib/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DevZen AI Insight',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
    );
  }

  String _trendText(String trend) {
    switch (trend) {
      case 'up': return '↑ Improving';
      case 'down': return '↓ Declining';
      default: return '→ Stable';
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'up': return AppColors.greenAccent;
      case 'down': return Colors.redAccent;
      default: return AppColors.textMuted;
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.greenAccent;
    if (score >= 60) return AppColors.blueAccent;
    if (score >= 40) return AppColors.orangeAccent;
    return AppColors.textMuted;
  }

  Color _skillColor(String source) {
    switch (source) {
      case 'GitHub': return AppColors.greenAccent;
      case 'Resume': return AppColors.blueAccent;
      default: return AppColors.purpleAccent;
    }
  }

  Color _eventColor(String icon) {
    switch (icon) {
      case 'commit': return AppColors.greenAccent;
      case 'pr': return AppColors.purpleAccent;
      case 'release': return AppColors.orangeAccent;
      case 'star': return AppColors.orangeAccent;
      case 'create': return AppColors.blueAccent;
      default: return AppColors.textSecondary;
    }
  }

  IconData _eventIcon(String icon) {
    switch (icon) {
      case 'commit': return Icons.commit;
      case 'pr': return Icons.merge_type;
      case 'release': return Icons.new_releases_outlined;
      case 'star': return Icons.star_outline;
      case 'create': return Icons.add_circle_outline;
      case 'fork': return Icons.call_split;
      default: return Icons.circle_outlined;
    }
  }
}
