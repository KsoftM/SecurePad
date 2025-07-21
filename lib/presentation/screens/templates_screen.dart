import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../data/templates/template_model.dart';
import '../../data/templates/templates_repository.dart';
import 'template_editor_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.uid ?? '';
    final templatesRepo = TemplatesRepository(
        firestore: FirebaseFirestore.instance, userId: userId);
    final storage = SecureStorageService();

    Future<EncryptionService> getEncryptionService() async {
      final keyString = await storage.read('template_key_$userId');
      SecretKey key;
      if (keyString == null) {
        key = SecretKey(List<int>.generate(
            32, (i) => i + 2)); // Use secure random in production
        await storage.write(
            'template_key_$userId', base64Encode(await key.extractBytes()));
      } else {
        key = SecretKey(base64Decode(keyString));
      }
      return EncryptionService(key);
    }

    return Scaffold(
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
                  )),
                  builder: (context, decSnapshot) {
                    final name = decSnapshot.data ?? '[Encrypted]';
                    return ListTile(
                      leading: const Icon(Icons.view_list),
                      title: Text(name),
                      subtitle: Text(templates[index].created.toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TemplateEditorScreen(
                              initialName: name,
                              initialContent:
                                  '[Decrypted content here]', // TODO: decrypt content field if stored separately
                              onSave: (newName, newContent) async {
                                final encrypted =
                                    await encService.encrypt(newName);
                                final updated = TemplateModel(
                                  id: templates[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
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
                      final encrypted = await encService.encrypt(name);
                      final template = TemplateModel(
                        id: '',
                        encryptedData: encrypted.ciphertext,
                        nonce: encrypted.nonce,
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
