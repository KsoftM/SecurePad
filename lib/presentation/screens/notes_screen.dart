import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/notes/note_model.dart';
import '../../data/notes/notes_repository.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual user ID from auth provider
    const userId = 'demo-user';
    final notesRepo =
        NotesRepository(firestore: FirebaseFirestore.instance, userId: userId);
    return Scaffold(
      body: StreamBuilder<List<NoteModel>>(
        stream: notesRepo.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.note),
              title:
                  const Text('[Encrypted]'), // TODO: Decrypt and show preview
              subtitle: Text(notes[index].created.toDate().toString()),
              onTap: () {
                // TODO: Decrypt and edit note
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(
                      initialText: '[Decrypted note here]',
                      onSave: (text) {
                        // TODO: Encrypt and update note
                      },
                    ),
                  ),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await notesRepo.deleteNote(notes[index].id);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                onSave: (text) async {
                  // TODO: Encrypt and add note
                },
              ),
            ),
          );
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
