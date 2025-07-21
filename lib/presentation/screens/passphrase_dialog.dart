import 'package:flutter/material.dart';

class PassphraseDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool confirm;
  const PassphraseDialog(
      {super.key, required this.title, this.subtitle, this.confirm = false});

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _controller = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null) ...[
            Text(widget.subtitle!),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passphrase'),
          ),
          if (widget.confirm)
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm Passphrase'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.confirm && _controller.text != _confirmController.text) {
              setState(() => _error = 'Passphrases do not match');
              return;
            }
            if (_controller.text.isEmpty) {
              setState(() => _error = 'Passphrase required');
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
