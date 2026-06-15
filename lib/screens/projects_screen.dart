import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_input.dart';
import '../core/widgets/glass_button.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/profile_provider.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeStatus = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = Provider.of<ProfileProvider>(context);
    if (profileProvider.profile != null) {
      final backendProjects = profileProvider.profile!.projects;
      if (backendProjects.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<ProjectProvider>(context, listen: false)
                .syncWithBackendProjects(backendProjects);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'Medium';
    List<String> selectedTags = [];
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: AppColors.glassBorder),
              ),
              title: const Text(
                'Initialize Project',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassInput(
                      hintText: 'Project Name',
                      controller: nameController,
                    ),
                    const SizedBox(height: 16),
                    GlassInput(
                      hintText: 'Short Description',
                      controller: descController,
                    ),
                    const SizedBox(height: 16),
                    // Priority selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Priority:', style: TextStyle(color: AppColors.textSecondary)),
                        DropdownButton<String>(
                          value: priority,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          underline: Container(),
                          items: ['Low', 'Medium', 'High'].map((p) {
                            return DropdownMenuItem(value: p, child: Text(p));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                priority = val;
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tags Input
                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            hintText: 'Add Tag (e.g. Flutter)',
                            controller: tagsController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.blueAccent),
                          onPressed: () {
                            final tag = tagsController.text.trim();
                            if (tag.isNotEmpty) {
                              setDialogState(() {
                                selectedTags.add(tag);
                                tagsController.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedTags.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: AppColors.blueAccent.withOpacity(0.2),
                          side: BorderSide(color: AppColors.blueAccent.withOpacity(0.4)),
                          onDeleted: () {
                            setDialogState(() {
                              selectedTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                GlassButton(
                  text: 'Create',
                  width: 100,
                  height: 44,
                  onPressed: () {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    if (name.isNotEmpty) {
                      final newProject = Project(
                        id: const Uuid().v4(),
                        name: name,
                        description: desc.isEmpty ? 'No description.' : desc,
                        status: 'Active',
                        priority: priority,
                        startDate: DateTime.now(),
                        deadline: DateTime.now().add(const Duration(days: 14)),
                        progress: 0.0,
                        tags: selectedTags,
                        notes: '',
                      );
                      Provider.of<ProjectProvider>(context, listen: false).addProject(newProject);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projects = projectProvider.projects;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0), // Raise FAB above floating bottom bar
        child: FloatingActionButton(
          backgroundColor: AppColors.blueAccent,
          shape: const CircleBorder(),
          onPressed: () => _showCreateProjectDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header search and filters
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Workspace Projects',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar
                  GlassInput(
                    hintText: 'Search repository projects...',
                    prefixIcon: Icons.search,
                    controller: _searchController,
                    onChanged: (val) => projectProvider.setSearchQuery(val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['All', 'Active', 'Completed', 'Archived'].map((status) {
                        final isSelected = _activeStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            selectedColor: AppColors.blueAccent,
                            showCheckmark: false,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppColors.glassBorder,
                            ),
                            onSelected: (val) {
                              if (val) {
                                  setState(() {
                                    _activeStatus = status;
                                  });
                                  projectProvider.setStatusFilter(status);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Project card grid list
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                      child: Text('No active workspace projects found.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 160.0),
                      itemCount: projects.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _buildProjectCard(context, project);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProjectIcon(List<String> tags) {
    final lowerTags = tags.map((t) => t.toLowerCase()).toList();
    if (lowerTags.contains('flutter')) return Icons.phone_android;
    if (lowerTags.contains('react') || lowerTags.contains('vite')) return Icons.web_outlined;
    if (lowerTags.contains('node.js') || lowerTags.contains('express')) return Icons.dns_outlined;
    return Icons.terminal;
  }

  String _getProjectRole(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return 'Lead Mobile Engineer';
    if (lower.contains('openai') || lower.contains('microservice')) return 'Backend Architect';
    if (lower.contains('portfolio')) return 'Frontend Developer';
    return 'DevOps Engineer';
  }

  int _getProjectContribution(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('app')) return 85;
    if (lower.contains('openai')) return 70;
    if (lower.contains('portfolio')) return 100;
    return 90;
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active'
        ? AppColors.greenAccent
        : status == 'Completed'
            ? AppColors.blueAccent
            : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = priority == 'High'
        ? AppColors.redAccent
        : priority == 'Medium'
            ? AppColors.orangeAccent
            : AppColors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(String letter, Color bgColor) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: bgColor.withOpacity(0.6), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Logo, Title, Badges)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Logo/Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Icon(
                    _getProjectIcon(project.tags),
                    size: 20,
                    color: AppColors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildStatusBadge(project.status),
                          _buildPriorityBadge(project.priority),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Objective Section (One-line mission statement)
            Text(
              project.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Role Section (Role Badge & Contribution %)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_pin_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.purpleAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.purpleAccent.withOpacity(0.2)),
                      ),
                      child: Text(
                        _getProjectRole(project.name),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.purpleAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.donut_large, size: 14, color: AppColors.greenAccent),
                    const SizedBox(width: 6),
                    Text(
                      '${_getProjectContribution(project.name)}% Contribution',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tech Stack (chips)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: project.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Team Section & Progress
            Row(
              children: [
                // Overlapping Team avatars
                SizedBox(
                  width: 72,
                  height: 22,
                  child: Stack(
                    children: [
                      Positioned(left: 0, child: _buildMemberAvatar('A', AppColors.blueAccent)),
                      Positioned(left: 14, child: _buildMemberAvatar('S', AppColors.purpleAccent)),
                      Positioned(left: 28, child: _buildMemberAvatar('M', AppColors.orangeAccent)),
                      Positioned(
                        left: 42,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '+3',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(project.progress * 100).toInt()}% Done',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: project.progress,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blueAccent),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Footer (GitHub and View Board Buttons)
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'Repository',
                    icon: Icons.code_rounded,
                    isPrimary: false,
                    height: 38,
                    fontSize: 12,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening GitHub repository for ${project.name}...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    text: 'Identity Card',
                    icon: Icons.badge_outlined,
                    isPrimary: true,
                    height: 38,
                    fontSize: 12,
                    color: AppColors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailsScreen(project: project),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
