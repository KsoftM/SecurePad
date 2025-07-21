import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../../core/encryption_service.dart';
import '../../core/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../data/vault/vault_model.dart';
import '../../data/vault/vault_repository.dart';
import 'vault_editor_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.uid ?? '';
    final vaultRepo =
        VaultRepository(firestore: FirebaseFirestore.instance, userId: userId);
    final storage = SecureStorageService();

    Future<EncryptionService> getEncryptionService() async {
      final keyString = await storage.read('vault_key_$userId');
      SecretKey key;
      if (keyString == null) {
        final random = Random.secure();
        final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
        key = SecretKey(keyBytes);
        await storage.write(
            'vault_key_$userId', base64Encode(await key.extractBytes()));
      } else {
        key = SecretKey(base64Decode(keyString));
      }
      return EncryptionService(key);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<VaultModel>>(
        stream: vaultRepo.getVaultItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
                child: Text('No passwords yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => FutureBuilder<EncryptionService>(
              future: getEncryptionService(),
              builder: (context, encSnapshot) {
                if (!encSnapshot.hasData)
                  return const ListTile(title: Text('[Loading...]'));
                final encService = encSnapshot.data!;
                return FutureBuilder<String>(
                  future: encService.decrypt(EncryptedPayload(
                    ciphertext: items[index].encryptedData,
                    nonce: items[index].nonce,
                    mac: items[index].mac,
                  )),
                  builder: (context, decSnapshot) {
                    final label = decSnapshot.data ?? '[Encrypted]';
                    if (_search.isNotEmpty &&
                        !label.toLowerCase().contains(_search.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: const Icon(Icons.vpn_key),
                      title: Text(label),
                      subtitle: Text(items[index].created.toString()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VaultEditorScreen(
                              initialLabel: label,
                              initialSecret:
                                  '[Decrypted secret here]', // TODO: decrypt secret field if stored separately
                              onSave: (newLabel, newSecret) async {
                                final encrypted =
                                    await encService.encrypt(newLabel);
                                final updated = VaultModel(
                                  id: items[index].id,
                                  encryptedData: encrypted.ciphertext,
                                  nonce: encrypted.nonce,
                                  mac: encrypted.mac,
                                  created: items[index].created,
                                  updated: DateTime.now(),
                                  label: newLabel,
                                );
                                await vaultRepo.updateVaultItem(updated);
                              },
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await vaultRepo.deleteVaultItem(items[index].id);
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
                  builder: (context) => VaultEditorScreen(
                    onSave: (label, secret) async {
                      final encrypted = await encService.encrypt(label);
                      final item = VaultModel(
                        id: '',
                        encryptedData: encrypted.ciphertext,
                        nonce: encrypted.nonce,
                        mac: encrypted.mac,
                        created: DateTime.now(),
                        updated: DateTime.now(),
                        label: label,
                      );
                      await vaultRepo.addVaultItem(item);
                    },
                  ),
                ),
              );
            },
            tooltip: 'Add Password',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
