import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/progress_ring.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  int _getProjectContribution(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return 85;
    if (lower.contains('openai') || lower.contains('phish')) return 92;
    if (lower.contains('portfolio')) return 100;
    return 90;
  }

  int _getProjectCommits(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return 142;
    if (lower.contains('openai') || lower.contains('phish')) return 128;
    if (lower.contains('portfolio')) return 45;
    return 28;
  }

  String _getProjectVersion(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return '2.1.0';
    if (lower.contains('openai') || lower.contains('phish')) return '2.1.0';
    if (lower.contains('portfolio')) return '1.0.0';
    return '0.9.1';
  }

  double _getProjectStars(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return 1.2;
    if (lower.contains('openai') || lower.contains('phish')) return 1.2;
    if (lower.contains('portfolio')) return 2.4;
    return 0.1;
  }

  IconData _getTagIcon(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('flutter') || lower.contains('react') || lower.contains('vite')) return Icons.web_outlined;
    if (lower.contains('python') || lower.contains('pytorch')) return Icons.analytics_outlined;
    if (lower.contains('node') || lower.contains('express') || lower.contains('firebase') || lower.contains('fastapi')) return Icons.cloud_queue;
    if (lower.contains('docker') || lower.contains('aws')) return Icons.dns_outlined;
    return Icons.code;
  }

  String _getProjectAbout(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishguard') || lower.contains('security')) {
      return 'The core engine utilizes a transformer-based BERT model fine-tuned on 2.4 million malicious email samples. Achievements include a 99.8% detection accuracy with less than 1ms inference latency.';
    }
    if (lower.contains('mobile') || lower.contains('app')) {
      return 'The mobile system utilizes Flutter and dynamic Glassmorphism cards with sigma-blur backdrops. Features real-time state listeners for task lanes, local caching for snippets, and secure session authentications.';
    }
    if (lower.contains('openai')) {
      return 'An enterprise backend wrapper built on Node.js and Express. It connects with OpenAI completions APIs, handles prompt token budgeting, and serves semantic search embeddings via local vectors.';
    }
    if (lower.contains('portfolio')) {
      return 'A responsive developer portfolio showcase built with React, Vite, and Tailwind. It integrates custom 3D splines, page transitions, and contact hooks linked to cloud databases.';
    }
    return 'A collection of script files running weekly cron jobs to download server log files, compute access and error patterns, and dispatch HTML email status logs to administrators.';
  }

  String _getProjectDeployCommand(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishguard') || lower.contains('security')) return r'$ phishguard --deploy production';
    if (lower.contains('mobile') || lower.contains('app')) return r'$ flutter run --release';
    if (lower.contains('openai')) return r'$ npm run start:production';
    if (lower.contains('portfolio')) return r'$ npm run build && vercel --prod';
    return r'$ php cli.php --run --verbose';
  }

  IconData _getProjectHeaderIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('phishguard') || lower.contains('security')) return Icons.shield_outlined;
    if (lower.contains('mobile') || lower.contains('app')) return Icons.phone_android_outlined;
    if (lower.contains('openai') || lower.contains('ai')) return Icons.psychology_outlined;
    if (lower.contains('portfolio') || lower.contains('web')) return Icons.web_outlined;
    return Icons.terminal_outlined;
  }

  Widget _buildCollaboratorAvatar(String label, Color color) {
    final initials = label.split(' ')[0][0];
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = Provider.of<ProfileProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    
    // Find matching project in provider to get live/updates
    final project = projectProvider.rawProjects.firstWhere(
      (p) => p.id == widget.project.id,
      orElse: () => widget.project,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Project Identity',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search filters enabled.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 40.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Header Card (Stitch design rounded-[32px])
              GlassCard(
                borderRadius: 32.0,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    // Glowing logo emblem
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blueAccent.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blueAccent.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getProjectHeaderIcon(project.name),
                        size: 40,
                        color: AppColors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Centered Wrap to prevent title/badge overflow
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          project.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Text(
                            project.status == 'Active' ? 'PRODUCTION' : project.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.blueAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Oct 2023',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        const Text(
                          '2h ago',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mission statement
              GlassCard(
                borderRadius: 32.0,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MISSION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${project.description}"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lead Developer role details (Stitch style)
              GlassCard(
                borderRadius: 32.0,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: profile.avatarUrl.isNotEmpty ? NetworkImage(profile.avatarUrl) : null,
                          child: profile.avatarUrl.isEmpty
                              ? Text(
                                  (profile.fullName.isNotEmpty ? profile.fullName : auth.fullName)[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.greenAccent,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName.isNotEmpty ? profile.fullName : auth.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.headline.isNotEmpty ? profile.headline : 'Developer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_getProjectContribution(project.name)}%',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
                        ),
                        const Text(
                          'Contribution',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic 2x2 Stats Grid (LayoutBuilder for absolute overflow safety)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  double aspectRatio = 1.35;
                  if (width < 340) {
                    aspectRatio = 1.15;
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: aspectRatio,
                    children: [
                      // Progress Ring Card
                      GlassCard(
                        borderRadius: 32.0,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ProgressRing(
                                value: project.progress,
                                size: 36,
                                strokeWidth: 3.5,
                                activeColor: AppColors.blueAccent,
                                centerWidget: Text(
                                  '${(project.progress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'PROGRESS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Commits Card
                      GlassCard(
                        borderRadius: 32.0,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.commit_rounded, color: AppColors.greenAccent, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              '${_getProjectCommits(project.name)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'COMMITS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Members Card
                      GlassCard(
                        borderRadius: 32.0,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, color: AppColors.purpleAccent, size: 24),
                            const SizedBox(height: 6),
                            const Text(
                              '4',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'MEMBERS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Version Card
                      GlassCard(
                        borderRadius: 32.0,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.integration_instructions_outlined, color: AppColors.orangeAccent, size: 24),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _getProjectVersion(project.name),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'VERSION',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Tech stack section
              const Text(
                'TECH STACK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.blueAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTagIcon(tag),
                          size: 14,
                          color: AppColors.blueAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // About Project & Terminal Block
              GlassCard(
                borderRadius: 32.0,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'About Project',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getProjectAbout(project.name),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        _getProjectDeployCommand(project.name),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Collaborators list (wrapped in scrollable Row to prevent overflow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'COLLABORATORS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Collaborator invitations sent.')),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 12, color: AppColors.blueAccent),
                        SizedBox(width: 2),
                        Text(
                          'Add',
                          style: TextStyle(fontSize: 12, color: AppColors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCollaboratorAvatar('Ravi (Lead)', AppColors.blueAccent),
                    const SizedBox(width: 16),
                    _buildCollaboratorAvatar('Arun (BE)', AppColors.purpleAccent),
                    const SizedBox(width: 16),
                    _buildCollaboratorAvatar('Priya (UI)', AppColors.orangeAccent),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined project collaborators!')),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorder, width: 1.5),
                              color: AppColors.surfaceLight.withOpacity(0.3),
                            ),
                            child: const Icon(Icons.add, color: Colors.white54, size: 20),
                          ),
                          const SizedBox(height: 6),
                          const Text('Join', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // View Codebase GitHub star button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigating to repository codebase for ${project.name}...')),
                  );
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: AppColors.blueAccent.withOpacity(0.12),
                  borderColor: AppColors.blueAccent.withOpacity(0.3),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'View Codebase',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.orangeAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_getProjectStars(project.name)}k',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Demo & Docs Buttons
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: 'Live Demo',
                      icon: Icons.play_arrow_outlined,
                      isPrimary: false,
                      height: 48,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Launching live demo deployment for ${project.name}...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassButton(
                      text: 'Docs',
                      icon: Icons.article_outlined,
                      isPrimary: false,
                      height: 48,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening docs outline for ${project.name}...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
