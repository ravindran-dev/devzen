import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_input.dart';
import '../core/widgets/glass_button.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';

class NotesWorkspaceScreen extends StatefulWidget {
  const NotesWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<NotesWorkspaceScreen> createState() => _NotesWorkspaceScreenState();
}

class _NotesWorkspaceScreenState extends State<NotesWorkspaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showNoteDetailOrEdit(BuildContext context, Note? note) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String category = note?.category ?? 'Ideas';
    bool isPreview = note != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  // Modal header actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note == null ? 'Draft Document' : 'Document View',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Row(
                        children: [
                          if (note != null) ...[
                            IconButton(
                              icon: Icon(
                                isPreview ? Icons.edit_note : Icons.visibility,
                                color: AppColors.blueAccent,
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  isPreview = !isPreview;
                                });
                              },
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category & Pin selections
                  if (!isPreview) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Workspace Folder:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        DropdownButton<String>(
                          value: category,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          underline: Container(),
                          items: ['Ideas', 'Specs', 'Guides', 'General'].map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                category = val;
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Editable inputs vs Markdown preview
                  Expanded(
                    child: isPreview
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    titleController.text,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Folder: ${note!.category}  •  Updated ${note.updatedAt.toString().substring(0, 16)}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                  const Divider(color: Colors.white10, height: 20),
                                  MarkdownBody(
                                    data: contentController.text,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                                      h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.8),
                                      h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                                      code: const TextStyle(fontFamily: 'FiraCode', fontSize: 12, backgroundColor: Colors.black38, color: AppColors.blueAccent),
                                      codeblockDecoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GlassInput(
                                hintText: 'Document Title',
                                controller: titleController,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: TextField(
                                    controller: contentController,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '# Markdown content support...',
                                      hintStyle: TextStyle(color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  if (!isPreview) ...[
                    GlassButton(
                      text: note == null ? 'Save Document' : 'Update Changes',
                      onPressed: () {
                        final title = titleController.text.trim();
                        final content = contentController.text;
                        if (title.isNotEmpty && content.isNotEmpty) {
                          final noteProvider = Provider.of<NoteProvider>(context, listen: false);
                          if (note == null) {
                            noteProvider.addNote(
                              Note(
                                id: const Uuid().v4(),
                                title: title,
                                content: content,
                                category: category,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          } else {
                            noteProvider.updateNote(
                              note.copyWith(
                                title: title,
                                content: content,
                                category: category,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final notes = noteProvider.notes;

    // Filter pinned
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final recentNotes = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.blueAccent,
          shape: const CircleBorder(),
          onPressed: () => _showNoteDetailOrEdit(context, null),
          child: const Icon(Icons.add_comment_outlined, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header search and folders
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Notes Workspace',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search
                  GlassInput(
                    hintText: 'Search folders and documents...',
                    prefixIcon: Icons.search,
                    controller: _searchController,
                    onChanged: (val) => noteProvider.setSearchQuery(val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: noteProvider.categories.map((cat) {
                        final isSelected = noteProvider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                noteProvider.setSelectedCategory(cat);
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
            
            // Notes list
            Expanded(
              child: notes.isEmpty
                  ? const Center(
                      child: Text('No workspace notes found.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 160.0),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (pinnedNotes.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.push_pin_outlined, size: 14, color: AppColors.blueAccent),
                              SizedBox(width: 8),
                              Text('Pinned Documents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pinnedNotes.map((note) => _buildNoteCard(note)),
                          const SizedBox(height: 24),
                        ],
                        
                        if (recentNotes.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.history_toggle_off, size: 14, color: AppColors.textMuted),
                              SizedBox(width: 8),
                              Text('Recent Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recentNotes.map((note) => _buildNoteCard(note)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showNoteDetailOrEdit(context, note),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Folder icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.blueAccent, size: 18),
              ),
              const SizedBox(width: 16),
              
              // Note metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${note.category}  •  ${note.updatedAt.toString().substring(0, 10)}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: note.isPinned ? AppColors.blueAccent : AppColors.textMuted,
                  size: 18,
                ),
                onPressed: () {
                  Provider.of<NoteProvider>(context, listen: false).togglePin(note.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.redAccent, size: 18),
                onPressed: () {
                  Provider.of<NoteProvider>(context, listen: false).deleteNote(note.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
