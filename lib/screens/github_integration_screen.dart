import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/contribution_map.dart';
import '../providers/auth_provider.dart';
import '../providers/github_provider.dart';
import '../providers/profile_provider.dart';

class GitHubIntegrationScreen extends StatefulWidget {
  const GitHubIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<GitHubIntegrationScreen> createState() => _GitHubIntegrationScreenState();
}

class _GitHubIntegrationScreenState extends State<GitHubIntegrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final github = Provider.of<GitHubProvider>(context, listen: false);
    if (auth.githubUsername.isNotEmpty && github.repos.isEmpty) {
      github.loadGitHubData(auth.githubUsername);
    }
  }

  Future<void> _handleSync(GitHubProvider github, String username) async {
    await github.pullToRefresh(username);
    if (mounted) {
      await Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final github = Provider.of<GitHubProvider>(context);
    final connected = auth.githubUsername.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _handleSync(github, auth.githubUsername),
          color: AppColors.blueAccent,
          backgroundColor: AppColors.surfaceLight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'GitHub Integration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (connected && !github.isSyncing)
                      GestureDetector(
                        onTap: () => _handleSync(github, auth.githubUsername),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.sync, size: 13, color: AppColors.blueAccent),
                              SizedBox(width: 4),
                              Text('Sync', style: TextStyle(fontSize: 11, color: AppColors.blueAccent)),
                            ],
                          ),
                        ),
                      ),
                    if (github.isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                if (!connected)
                  _buildNotConnected(auth.githubUsername)
                else if (github.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.blueAccent),
                          SizedBox(height: 16),
                          Text('Fetching GitHub data...', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildProfileHeader(github, auth.githubUsername),
                  const SizedBox(height: 16),
                  _buildStatsGrid(github),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Activity (Last 30 Events)'),
                  const SizedBox(height: 12),
                  _buildContributionMap(github),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Top Languages'),
                  const SizedBox(height: 12),
                  _buildLanguagesChart(github),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Repositories (${github.repos.length})'),
                  const SizedBox(height: 12),
                  ...github.repos.take(15).map((repo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  repo.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (repo.isPrivate)
                                _badge('Private', AppColors.textMuted)
                              else
                                _badge('Public', AppColors.greenAccent.withOpacity(0.7)),
                            ],
                          ),
                          if (repo.description != null && repo.description!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              repo.description!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (repo.displayLanguage != 'N/A') ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.blueAccent,
                                  ),
                                ),
                                Text(repo.displayLanguage,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                const SizedBox(width: 12),
                              ],
                              const Icon(Icons.star_outline, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text('${repo.starsCount}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              const SizedBox(width: 10),
                              const Icon(Icons.call_split, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text('${repo.forksCount}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              const Spacer(),
                              Text(repo.timeAgo,
                                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                            ],
                          ),
                          if (repo.topics.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: repo.topics.take(4).map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.purpleAccent.withOpacity(0.25)),
                                ),
                                child: Text(t, style: const TextStyle(fontSize: 9, color: AppColors.purpleAccent)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotConnected(String username) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset('lib/logo.png', width: 64, height: 64, fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          const Text('No GitHub Account Connected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Register with a GitHub username to auto-import your repositories, activity, and developer stats.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(GitHubProvider github, String username) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: github.avatarUrl.isNotEmpty
                ? NetworkImage(github.avatarUrl)
                : null,
            child: github.avatarUrl.isEmpty
                ? Text(username.isNotEmpty ? username[0].toUpperCase() : 'G',
                    style: const TextStyle(fontSize: 20, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$username',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                if (github.githubBio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(github.githubBio,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 2),
                  ),
                if (github.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(github.location,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: AppColors.greenAccent, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(GitHubProvider github) {
    final stats = [
      {'label': 'Repositories', 'value': github.publicRepos.toString()},
      {'label': 'Total Stars', 'value': github.totalStars.toString()},
      {'label': 'Followers', 'value': github.followers.toString()},
      {'label': 'Following', 'value': github.following.toString()},
    ];
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: stats.map((s) => GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s['value']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(s['label']!,
                style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildContributionMap(GitHubProvider github) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContributionMap(
            contributions: github.contributions.isNotEmpty
                ? github.contributions
                : List.filled(140, 0),
            weeksCount: 20,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${github.recentActivity.length} public events',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesChart(GitHubProvider github) {
    final langs = github.languagesAggregate;
    if (langs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: const Text('No language data available',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center),
      );
    }
    final total = langs.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = langs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sorted.take(6).map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight.withOpacity(0.4),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blueAccent),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text, style: TextStyle(fontSize: 9, color: color)),
      );
}
