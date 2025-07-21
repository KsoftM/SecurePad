import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
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
