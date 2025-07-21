import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../data/templates/template_model.dart';
import '../../data/templates/templates_repository.dart';
import 'template_editor_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _search = '';

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
        final random = Random.secure();
        final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
        key = SecretKey(keyBytes);
        await storage.write(
            'template_key_$userId', base64Encode(await key.extractBytes()));
      } else {
        key = SecretKey(base64Decode(keyString));
      }
      return EncryptionService(key);
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
                      final encrypted = await encService.encrypt(name);
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
