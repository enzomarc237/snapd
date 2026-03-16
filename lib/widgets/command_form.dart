import 'package:flutter/material.dart';

import '../models/command.dart';

/// Form widget for creating or editing a [Command].
///
/// Validates that [name] and [script] are non-empty before calling [onSave].
class CommandForm extends StatefulWidget {
  final Command? initial;
  final void Function(
    String name,
    String description,
    String script,
    List<String> tags,
  ) onSave;
  final VoidCallback onCancel;

  const CommandForm({
    super.key,
    this.initial,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<CommandForm> createState() => _CommandFormState();
}

class _CommandFormState extends State<CommandForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _scriptCtrl;
  late final TextEditingController _tagsCtrl;

  @override
  void initState() {
    super.initState();
    final cmd = widget.initial;
    _nameCtrl = TextEditingController(text: cmd?.name ?? '');
    _descCtrl = TextEditingController(text: cmd?.description ?? '');
    _scriptCtrl = TextEditingController(text: cmd?.script ?? '');
    _tagsCtrl = TextEditingController(
      text: cmd?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _scriptCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList();
      widget.onSave(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim(),
        _scriptCtrl.text.trim(),
        tags,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? 'Edit Command' : 'New Command',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'e.g. Run tests',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Short description of what this command does',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _scriptCtrl,
            decoration: const InputDecoration(
              labelText: 'Script *',
              hintText: 'e.g. npm test',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
            maxLines: 4,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Script is required.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'e.g. node, npm, test  (comma-separated)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Save changes' : 'Add command'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
