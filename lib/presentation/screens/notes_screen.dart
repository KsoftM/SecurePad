import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../data/notes/note_model.dart';
import '../../data/notes/notes_repository.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.uid ?? '';
    final notesRepo =
        NotesRepository(firestore: FirebaseFirestore.instance, userId: userId);
    final storage = SecureStorageService();

    Future<EncryptionService> getEncryptionService() async {
      // Try to get the key from secure storage, or generate and store if not present
      final keyString = await storage.read('key_$userId');
      SecretKey key;
      if (keyString == null) {
        key = SecretKey(List<int>.generate(
            32, (i) => i)); // In production, use secure random
        await storage.write(
            'key_$userId', base64Encode(await key.extractBytes()));
      } else {
        key = SecretKey(base64Decode(keyString));
      }
      return EncryptionService(key);
    }

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
            itemBuilder: (context, index) => FutureBuilder<EncryptionService>(
              future: getEncryptionService(),
              builder: (context, encSnapshot) {
                if (!encSnapshot.hasData)
                  return const ListTile(title: Text('[Loading...]'));
                final encService = encSnapshot.data!;
                return FutureBuilder<String>(
                  future: encService.decrypt(EncryptedPayload(
                    ciphertext: notes[index].encryptedData,
                    nonce: notes[index].nonce,
                  )),
                  builder: (context, decSnapshot) {
                    final preview = decSnapshot.data ?? '[Encrypted]';
                    return ListTile(
                      leading: const Icon(Icons.note),
                      title: Text(preview),
                      subtitle: Text(notes[index].created.toDate().toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditorScreen(
                              initialText: preview,
                              onSave: (text) async {
                                final encrypted =
                                    await encService.encrypt(text);
                                final updated = NoteModel(
                                  id: notes[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
                                  created: notes[index].created,
                                  updated: Timestamp.now(),
                                  tags: notes[index].tags,
                                );
                                await notesRepo.updateNote(updated);
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
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<EncryptionService>(
        future: getEncryptionService(),
        builder: (context, encSnapshot) {
          if (!encSnapshot.hasData) return const SizedBox.shrink();
          final encService = encSnapshot.data!;
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    onSave: (text) async {
                      final encrypted = await encService.encrypt(text);
                      final note = NoteModel(
                        id: '',
                        encryptedData: encrypted.ciphertext,
                        nonce: encrypted.nonce,
                        created: Timestamp.now(),
                        updated: Timestamp.now(),
                        tags: [],
                      );
                      await notesRepo.addNote(note);
                    },
                  ),
                ),
              );
            },
            tooltip: 'Add Note',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
