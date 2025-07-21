import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:math';
import '../../core/encryption_service.dart';
import '../../core/cloud_key_service.dart';
import '../../core/secure_storage_service.dart';
import 'passphrase_dialog.dart';
import '../../data/reminders/reminder_model.dart';
import '../../data/reminders/reminders_repository.dart';
import 'reminder_editor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userId = '';
    if (authState is Authenticated) {
      userId = authState.user.uid;
    }
    final remindersRepo = RemindersRepository(
        firestore: FirebaseFirestore.instance, userId: userId);
    final cloudKeyService = CloudKeyService(FirebaseFirestore.instance);
    final sessionStorage = SecureStorageService();
    Future<EncryptionService> getEncryptionService() async {
      final keyDoc = await cloudKeyService.getEncryptedKey(userId);
      String? passphrase;
      String? salt;
      List<int> encryptionKeyBytes;
      if (keyDoc == null) {
        passphrase = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const PassphraseDialog(
            title: 'Set a passphrase',
            subtitle:
                'This passphrase will unlock your reminders on any device. Do not forget it!',
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
        passphrase = await sessionStorage.read('passphrase_key_$userId');
        passphrase ??= await showDialog<String>(
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
      await sessionStorage.write('passphrase_key_$userId', passphrase);
      return EncryptionService(SecretKey(encryptionKeyBytes));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search reminders...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        ),
      ),
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
                return FutureBuilder<List<String>>(
                  future: () async {
                    final title = await encService.decrypt(EncryptedPayload(
                      ciphertext: reminders[index].encryptedData,
                      nonce: reminders[index].nonce,
                      mac: reminders[index].mac,
                    ));
                    String content = '';
                    if (reminders[index].encryptedContent.isNotEmpty &&
                        reminders[index].contentNonce.isNotEmpty &&
                        reminders[index].contentMac.isNotEmpty) {
                      content = await encService.decrypt(EncryptedPayload(
                        ciphertext: reminders[index].encryptedContent,
                        nonce: reminders[index].contentNonce,
                        mac: reminders[index].contentMac,
                      ));
                    }
                    return [title, content];
                  }(),
                  builder: (context, decSnapshot) {
                    final title = decSnapshot.data?[0] ?? '[Encrypted]';
                    final content = decSnapshot.data?[1] ?? '';
                    if (_search.isNotEmpty &&
                        !title.toLowerCase().contains(_search.toLowerCase()) &&
                        !content
                            .toLowerCase()
                            .contains(_search.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(title),
                      subtitle: Text(content.isNotEmpty
                          ? content
                          : reminders[index].created.toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReminderEditorScreen(
                              initialTitle: title,
                              initialContent: content,
                              initialDate: reminders[index].created,
                              initialRepeat: reminders[index].repeat,
                              onSave: (newTitle, newContent, newRepeat) async {
                                final encryptedTitle =
                                    await encService.encrypt(newTitle);
                                final encryptedContent =
                                    await encService.encrypt(newContent);
                                final updated = ReminderModel(
                                  id: reminders[index].id,
                                  encryptedData: encryptedTitle.ciphertext,
                                  nonce: encryptedTitle.nonce,
                                  mac: encryptedTitle.mac,
                                  encryptedContent: encryptedContent.ciphertext,
                                  contentNonce: encryptedContent.nonce,
                                  contentMac: encryptedContent.mac,
                                  created: reminders[index].created,
                                  updated: DateTime.now(),
                                  title: newTitle,
                                  repeat: newRepeat,
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
                    onSave: (title, content, repeat) async {
                      final encryptedTitle = await encService.encrypt(title);
                      final encryptedContent =
                          await encService.encrypt(content);
                      final reminder = ReminderModel(
                        id: '',
                        encryptedData: encryptedTitle.ciphertext,
                        nonce: encryptedTitle.nonce,
                        mac: encryptedTitle.mac,
                        encryptedContent: encryptedContent.ciphertext,
                        contentNonce: encryptedContent.nonce,
                        contentMac: encryptedContent.mac,
                        created: DateTime.now(),
                        updated: DateTime.now(),
                        title: title,
                        repeat: repeat,
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
