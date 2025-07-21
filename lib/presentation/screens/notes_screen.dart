import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:math';

import '../../core/encryption_service.dart';
import '../../data/notes/note_model.dart';
import '../../data/notes/notes_repository.dart';
import 'note_editor_screen.dart';
import '../../core/cloud_key_service.dart';
import 'passphrase_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userId = '';
    if (authState is Authenticated) {
      userId = authState.user.uid;
    }
    final notesRepo =
        NotesRepository(firestore: FirebaseFirestore.instance, userId: userId);
    final cloudKeyService = CloudKeyService(FirebaseFirestore.instance);
    Future<EncryptionService> getEncryptionService() async {
      final keyDoc = await cloudKeyService.getEncryptedKey(userId);
      String? passphrase;
      String? salt;
      List<int> encryptionKeyBytes;
      if (keyDoc == null) {
        // First time: prompt for passphrase and generate key
        passphrase = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const PassphraseDialog(
            title: 'Set a passphrase',
            subtitle:
                'This passphrase will unlock your notes on any device. Do not forget it!',
            confirm: true,
          ),
        );
        if (passphrase == null) throw Exception('Passphrase required');
        salt = base64Encode(
            List<int>.generate(16, (_) => Random.secure().nextInt(256)));
        final derivedKey = await cloudKeyService.deriveKey(passphrase, salt);
        final random = Random.secure();
        encryptionKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));
        final encryptedKey =
            await cloudKeyService.encryptKey(encryptionKeyBytes, derivedKey);
        await cloudKeyService.storeEncryptedKey(userId, encryptedKey, salt);
      } else {
        // Existing user: prompt for passphrase and decrypt key
        passphrase = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const PassphraseDialog(
            title: 'Enter your passphrase',
          ),
        );
        if (passphrase == null) throw Exception('Passphrase required');
        salt = keyDoc['salt'] ?? '';
        final encryptedKey = keyDoc['encryptedKey'] ?? '';
        final derivedKey = await cloudKeyService.deriveKey(passphrase, salt);
        encryptionKeyBytes =
            await cloudKeyService.decryptKey(encryptedKey, derivedKey);
      }
      return EncryptionService(SecretKey(encryptionKeyBytes));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        ),
      ),
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
                    mac: notes[index].mac,
                  )),
                  builder: (context, decSnapshot) {
                    final preview = decSnapshot.data != null
                        ? decSnapshot.data!.split('\n').first.substring(
                            0,
                            decSnapshot.data!.split('\n').first.length > 200
                                ? 200
                                : decSnapshot.data!.split('\n').first.length)
                        : '[Encrypted]';
                    if (_search.isNotEmpty &&
                        !preview
                            .toLowerCase()
                            .contains(_search.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: const Icon(Icons.note),
                      title: Text(preview),
                      subtitle: Text(notes[index].created.toDate().toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditorScreen(
                              initialText: decSnapshot.data,
                              onSave: (text) async {
                                final encrypted =
                                    await encService.encrypt(text);
                                final updated = NoteModel(
                                  id: notes[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
                                  mac: encrypted.mac,
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
                        mac: encrypted.mac,
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
