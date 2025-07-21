import 'package:flutter/material.dart';

class TemplateEditorScreen extends StatefulWidget {
  final String? initialName;
  final String? initialContent;
  final void Function(String name, String content) onSave;
  const TemplateEditorScreen(
      {super.key, this.initialName, this.initialContent, required this.onSave});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_nameController.text, _contentController.text);
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Template Name'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Template Content'),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
