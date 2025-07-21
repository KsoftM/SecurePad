import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/encryption_service.dart';
import '../../core/cloud_key_service.dart';
import '../../core/secure_storage_service.dart';
import 'passphrase_dialog.dart';
import '../../data/templates/template_model.dart';
import '../../data/templates/templates_repository.dart';
import 'template_editor_screen.dart';
import '../bloc/auth_bloc.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userId = '';
    if (authState is Authenticated) {
      userId = authState.user.uid;
    }
    final templatesRepo = TemplatesRepository(
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
                'This passphrase will unlock your templates on any device. Do not forget it!',
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
        title: const Text('Templates'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TemplateModel>>(
        stream: templatesRepo.getTemplates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return const Center(
                child: Text('No templates yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) => FutureBuilder<EncryptionService>(
              future: getEncryptionService(),
              builder: (context, encSnapshot) {
                if (!encSnapshot.hasData)
                  return const ListTile(title: Text('[Loading...]'));
                final encService = encSnapshot.data!;
                return FutureBuilder<String>(
                  future: encService.decrypt(EncryptedPayload(
                    ciphertext: templates[index].encryptedData,
                    nonce: templates[index].nonce,
                    mac: templates[index].mac,
                  )),
                  builder: (context, decSnapshot) {
                    final name = decSnapshot.data ?? '[Encrypted]';
                    if (_search.isNotEmpty &&
                        !name.toLowerCase().contains(_search.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: const Icon(Icons.view_list),
                      title: Text(templates[index].name),
                      subtitle: Text(templates[index].created.toString()),
                      onTap: () async {
                        String decryptedContent;
                        try {
                          decryptedContent =
                              await encService.decrypt(EncryptedPayload(
                            ciphertext: templates[index].encryptedData,
                            nonce: templates[index].nonce,
                            mac: templates[index].mac,
                          ));
                        } catch (e) {
                          decryptedContent = '[Decryption failed]';
                        }
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TemplateEditorScreen(
                              initialName: templates[index].name,
                              initialContent: decryptedContent,
                              onSave: (newName, newContent) async {
                                final encrypted =
                                    await encService.encrypt(newContent);
                                final updated = TemplateModel(
                                  id: templates[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
                                  mac: encrypted.mac,
                                  created: templates[index].created,
                                  updated: DateTime.now(),
                                  name: newName,
                                );
                                await templatesRepo.updateTemplate(updated);
                              },
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await templatesRepo
                              .deleteTemplate(templates[index].id);
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
                  builder: (context) => TemplateEditorScreen(
                    onSave: (name, content) async {
                      final encrypted = await encService.encrypt(content);
                      final template = TemplateModel(
                        id: '',
                        encryptedData: encrypted.ciphertext,
                        nonce: encrypted.nonce,
                        mac: encrypted.mac,
                        created: DateTime.now(),
                        updated: DateTime.now(),
                        name: name,
                      );
                      await templatesRepo.addTemplate(template);
                    },
                  ),
                ),
              );
            },
            tooltip: 'Add Template',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
