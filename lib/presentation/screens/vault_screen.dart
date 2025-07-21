import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:local_auth/local_auth.dart';

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
            itemBuilder: (context, index) => _VaultPasswordTile(
              item: items[index],
              encServiceFuture: getEncryptionService(),
              search: _search,
              vaultRepo: vaultRepo,
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
                      final actualSecret = secret.isEmpty ? label : secret;
                      final encrypted = await encService.encrypt(actualSecret);
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

class _VaultPasswordTile extends StatefulWidget {
  final VaultModel item;
  final Future<EncryptionService> encServiceFuture;
  final String search;
  final VaultRepository vaultRepo;
  const _VaultPasswordTile(
      {required this.item,
      required this.encServiceFuture,
      required this.search,
      required this.vaultRepo});

  @override
  State<_VaultPasswordTile> createState() => _VaultPasswordTileState();
}

class _VaultPasswordTileState extends State<_VaultPasswordTile> {
  bool _obscure = true;
  String? _decrypted;
  bool _loading = false;
  bool _biometricPassed = false;

  Future<bool> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to view the password',
        options:
            const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleShow() async {
    if (_obscure) {
      if (!_biometricPassed) {
        final passed = await _authenticate();
        if (!passed) return;
        setState(() => _biometricPassed = true);
      }
      setState(() => _loading = true);
      final encService = await widget.encServiceFuture;
      try {
        final decrypted = await encService.decrypt(EncryptedPayload(
          ciphertext: widget.item.encryptedData,
          nonce: widget.item.nonce,
          mac: widget.item.mac,
        ));
        setState(() {
          _decrypted = decrypted;
          _obscure = false;
        });
      } catch (e) {
        setState(() {
          _decrypted = '[Decryption failed]';
          _obscure = false;
        });
      } finally {
        setState(() => _loading = false);
      }
    } else {
      setState(() => _obscure = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.item.label;
    if (widget.search.isNotEmpty &&
        !label.toLowerCase().contains(widget.search.toLowerCase()) &&
        !(_decrypted ?? '')
            .toLowerCase()
            .contains(widget.search.toLowerCase())) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: Text(label),
      subtitle: _loading
          ? const Text('Decrypting...')
          : _decrypted == null || _obscure
              ? const Text('••••••••')
              : Text(_decrypted!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleShow,
            tooltip: _obscure ? 'Show Password' : 'Hide Password',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await widget.vaultRepo.deleteVaultItem(widget.item.id);
            },
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
