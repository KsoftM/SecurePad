import 'package:flutter/material.dart';
import '../../core/password_generator.dart';

class VaultEditorScreen extends StatefulWidget {
  final String? initialLabel;
  final String? initialSecret;
  final void Function(String label, String secret) onSave;
  const VaultEditorScreen(
      {super.key, this.initialLabel, this.initialSecret, required this.onSave});

  @override
  State<VaultEditorScreen> createState() => _VaultEditorScreenState();
}

class _VaultEditorScreenState extends State<VaultEditorScreen> {
  late TextEditingController _labelController;
  late TextEditingController _secretController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    _secretController = TextEditingController(text: widget.initialSecret ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vault Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_labelController.text, _secretController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _secretController,
                    decoration: const InputDecoration(labelText: 'Secret / Password'),
                    obscureText: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Generate Password',
                  onPressed: () {
                    final generated = PasswordGenerator.generate();
                    _secretController.text = generated;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
