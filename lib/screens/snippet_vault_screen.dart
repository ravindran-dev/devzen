import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_input.dart';
import '../core/widgets/glass_button.dart';
import '../models/snippet.dart';
import '../providers/snippet_provider.dart';

class SnippetVaultScreen extends StatefulWidget {
  const SnippetVaultScreen({Key? key}) : super(key: key);

  @override
  State<SnippetVaultScreen> createState() => _SnippetVaultScreenState();
}

class _SnippetVaultScreenState extends State<SnippetVaultScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddSnippetDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final codeController = TextEditingController();
    String language = 'Dart';
    final tagController = TextEditingController();
    List<String> tags = [];

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
              title: const Text('Save Code Snippet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassInput(
                      hintText: 'Snippet Title',
                      controller: titleController,
                    ),
                    const SizedBox(height: 16),
                    GlassInput(
                      hintText: 'Brief Purpose Description',
                      controller: descController,
                    ),
                    const SizedBox(height: 16),
                    // Language Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Language:', style: TextStyle(color: AppColors.textSecondary)),
                        DropdownButton<String>(
                          value: language,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          underline: Container(),
                          items: ['C++', 'Python', 'Java', 'Dart', 'JavaScript', 'TypeScript', 'SQL', 'HTML', 'CSS'].map((lang) {
                            return DropdownMenuItem(value: lang, child: Text(lang));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                language = val;
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Code Block Editor
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: codeController,
                        maxLines: 6,
                        style: const TextStyle(fontFamily: 'FiraCode', fontSize: 12, color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '// Paste source code here...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tags Input
                    Row(
                      children: [
                        Expanded(
                          child: GlassInput(
                            hintText: 'Add Tag',
                            controller: tagController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.blueAccent),
                          onPressed: () {
                            final text = tagController.text.trim();
                            if (text.isNotEmpty) {
                              setDialogState(() {
                                tags.add(text);
                                tagController.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: AppColors.blueAccent.withOpacity(0.15),
                        onDeleted: () {
                          setDialogState(() {
                            tags.remove(t);
                          });
                        },
                      )).toList(),
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
                  text: 'Save',
                  width: 100,
                  height: 44,
                  onPressed: () {
                    final title = titleController.text.trim();
                    final code = codeController.text;
                    if (title.isNotEmpty && code.isNotEmpty) {
                      final newSnippet = Snippet(
                        id: const Uuid().v4(),
                        title: title,
                        description: descController.text.trim(),
                        language: language,
                        code: code,
                        tags: tags,
                      );
                      Provider.of<SnippetProvider>(context, listen: false).addSnippet(newSnippet);
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

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text('Snippet copied to clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snippetProvider = Provider.of<SnippetProvider>(context);
    final snippets = snippetProvider.snippets;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.purpleAccent,
          shape: const CircleBorder(),
          onPressed: () => _showAddSnippetDialog(context),
          child: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header panel
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Snippet Vault',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search
                  GlassInput(
                    hintText: 'Search vault snippets...',
                    prefixIcon: Icons.search,
                    controller: _searchController,
                    onChanged: (val) => snippetProvider.setSearchQuery(val),
                  ),
                  const SizedBox(height: 16),

                  // Language Horizontal scroll filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        'All',
                        'Python',
                        'Dart',
                        'SQL',
                        'C++',
                        'Java',
                        'JavaScript',
                        'TypeScript',
                        'HTML',
                        'CSS'
                      ].map((lang) {
                        final isSelected = snippetProvider.selectedLanguage == lang;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              lang,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            selectedColor: AppColors.purpleAccent,
                            showCheckmark: false,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppColors.glassBorder,
                            ),
                            onSelected: (val) {
                              if (val) {
                                snippetProvider.setSelectedLanguage(lang);
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

            // Snippet cards list
            Expanded(
              child: snippets.isEmpty
                  ? const Center(
                      child: Text('No matching code snippets found.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 160.0),
                      itemCount: snippets.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final snippet = snippets[index];
                        return _buildSnippetCard(snippet);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetCard(Snippet snippet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title and language badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snippet.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snippet.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Language badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    snippet.language,
                    style: const TextStyle(fontSize: 10, color: AppColors.purpleAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Code Preview Block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Text(
                  snippet.code,
                  style: const TextStyle(
                    fontFamily: 'FiraCode',
                    fontSize: 11,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Footer controls (Tags, copy, favorite)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: snippet.tags.map((t) {
                      return Text(
                        '#$t',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      );
                    }).toList(),
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        snippet.isFavorite ? Icons.star : Icons.star_border,
                        color: snippet.isFavorite ? Colors.amber : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        Provider.of<SnippetProvider>(context, listen: false).toggleFavorite(snippet.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => _copyToClipboard(context, snippet.code),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.redAccent, size: 20),
                      onPressed: () {
                        Provider.of<SnippetProvider>(context, listen: false).deleteSnippet(snippet.id);
                      },
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
