import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tugas_pbm_note/models/note_model.dart';
import 'package:tugas_pbm_note/services/note_repsitory.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  late final Stream<QuerySnapshot> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream = _noteRepository.getNotesStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs
              .map((doc) => Note.fromFirestore(doc))
              .toList();

          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteListItem(
                note: note,
                onEdit: () => _showEditNoteDialog(context, note),
                onDelete: () => _deleteNote(context, note.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddNoteDialog(context),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NoteDialog(
        title: 'Add New Note',
        onSave: (title, content) async {
          await _noteRepository.addNote(title, content);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => NoteDialog(
        title: 'Edit Note',
        initialTitle: note.title,
        initialContent: note.content,
        onSave: (title, content) async {
          await _noteRepository.updateNote(note.id, title, content);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, String noteId) async {
    try {
      await _noteRepository.deleteNote(noteId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete note')),
        );
      }
    }
  }
}

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(note.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.content),
            const SizedBox(height: 4),
            Text(
              'Created: ${note.createdAt.toLocal().toString().split('.')[0]}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class NoteDialog extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialContent;
  final Future<void> Function(String title, String content) onSave;

  const NoteDialog({
    super.key,
    required this.title,
    this.initialTitle,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveNote,
          child: _isSaving 
              ? const CircularProgressIndicator()
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}