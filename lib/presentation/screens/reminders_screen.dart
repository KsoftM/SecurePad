import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../data/reminders/reminder_model.dart';
import '../../data/reminders/reminders_repository.dart';
import 'reminder_editor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.uid ?? '';
    final remindersRepo = RemindersRepository(
        firestore: FirebaseFirestore.instance, userId: userId);
    final storage = SecureStorageService();

    Future<EncryptionService> getEncryptionService() async {
      final keyString = await storage.read('reminder_key_$userId');
      SecretKey key;
      if (keyString == null) {
        key = SecretKey(List<int>.generate(
            32, (i) => i + 3)); // Use secure random in production
        await storage.write(
            'reminder_key_$userId', base64Encode(await key.extractBytes()));
      } else {
        key = SecretKey(base64Decode(keyString));
      }
      return EncryptionService(key);
    }

    return Scaffold(
      body: StreamBuilder<List<ReminderModel>>(
        stream: remindersRepo.getReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return const Center(
                child: Text('No reminders yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) => FutureBuilder<EncryptionService>(
              future: getEncryptionService(),
              builder: (context, encSnapshot) {
                if (!encSnapshot.hasData)
                  return const ListTile(title: Text('[Loading...]'));
                final encService = encSnapshot.data!;
                return FutureBuilder<String>(
                  future: encService.decrypt(EncryptedPayload(
                    ciphertext: reminders[index].encryptedData,
                    nonce: reminders[index].nonce,
                  )),
                  builder: (context, decSnapshot) {
                    final title = decSnapshot.data ?? '[Encrypted]';
                    return ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(title),
                      subtitle: Text(reminders[index].created.toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReminderEditorScreen(
                              initialTitle: title,
                              initialContent:
                                  '[Decrypted content here]', // TODO: decrypt content field if stored separately
                              onSave: (newTitle, newContent) async {
                                final encrypted =
                                    await encService.encrypt(newTitle);
                                final updated = ReminderModel(
                                  id: reminders[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
                                  created: reminders[index].created,
                                  updated: DateTime.now(),
                                  title: newTitle,
                                );
                                await remindersRepo.updateReminder(updated);
                              },
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await remindersRepo
                              .deleteReminder(reminders[index].id);
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
                  builder: (context) => ReminderEditorScreen(
                    onSave: (title, content) async {
                      final encrypted = await encService.encrypt(title);
                      final reminder = ReminderModel(
                        id: '',
                        encryptedData: encrypted.ciphertext,
                        nonce: encrypted.nonce,
                        created: DateTime.now(),
                        updated: DateTime.now(),
                        title: title,
                      );
                      await remindersRepo.addReminder(reminder);
                    },
                  ),
                ),
              );
            },
            tooltip: 'Add Reminder',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
