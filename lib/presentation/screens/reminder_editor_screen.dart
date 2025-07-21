import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderEditorScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final void Function(String title, String content) onSave;
  const ReminderEditorScreen(
      {super.key,
      this.initialTitle,
      this.initialContent,
      required this.onSave});

  @override
  State<ReminderEditorScreen> createState() => _ReminderEditorScreenState();
}

class _ReminderEditorScreenState extends State<ReminderEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  DateTime? _selectedDateTime;
  String _repeat = 'None';
  final List<String> _repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_titleController.text, _contentController.text);
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
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Reminder Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Reminder Content'),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedDateTime == null
                      ? 'No date/time selected'
                      : 'Scheduled: ' + DateFormat.yMd().add_jm().format(_selectedDateTime!)),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 10),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            DropdownButton<String>(
              value: _repeat,
              items: _repeatOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _repeat = val ?? 'None'),
            ),
          ],
        ),
      ),
    );
  }
}
