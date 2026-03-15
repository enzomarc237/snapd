import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/command.dart';
import '../services/command_service.dart';
import '../widgets/command_form.dart';
import '../widgets/command_list_item.dart';

/// Screen for managing (add / edit / delete) commands.
class CommandManagementScreen extends StatefulWidget {
  const CommandManagementScreen({super.key});

  @override
  State<CommandManagementScreen> createState() =>
      _CommandManagementScreenState();
}

class _CommandManagementScreenState extends State<CommandManagementScreen> {
  Command? _selectedCommand;
  bool _showForm = false;
  Command? _editingCommand;

  void _startAdd() {
    setState(() {
      _showForm = true;
      _editingCommand = null;
      _selectedCommand = null;
    });
  }

  void _startEdit(Command cmd) {
    setState(() {
      _showForm = true;
      _editingCommand = cmd;
      _selectedCommand = cmd;
    });
  }

  void _cancelForm() {
    setState(() {
      _showForm = false;
      _editingCommand = null;
    });
  }

  Future<void> _save(
    String name,
    String description,
    String script,
    List<String> tags,
  ) async {
    final svc = context.read<CommandService>();
    if (_editingCommand != null) {
      await svc.update(
        _editingCommand!.id,
        name: name,
        description: description,
        script: script,
        tags: tags,
      );
    } else {
      await svc.add(
        name: name,
        description: description,
        script: script,
        tags: tags,
      );
    }
    if (mounted) _cancelForm();
  }

  Future<void> _delete(Command cmd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete command?'),
        content: Text('Are you sure you want to delete "${cmd.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<CommandService>().delete(cmd.id);
      setState(() {
        if (_selectedCommand?.id == cmd.id) _selectedCommand = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandService>(
      builder: (context, svc, _) {
        if (!svc.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          children: [
            // Left: command list
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Commands',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _startAdd,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: svc.commands.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.terminal,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No commands yet.\nTap Add to create one.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            itemCount: svc.commands.length,
                            itemBuilder: (ctx, i) {
                              final cmd = svc.commands[i];
                              return CommandListItem(
                                command: cmd,
                                isSelected: _selectedCommand?.id == cmd.id,
                                onTap: () =>
                                    setState(() => _selectedCommand = cmd),
                                onRun: () {}, // Not running from management screen
                                onEdit: () => _startEdit(cmd),
                                onDelete: () => _delete(cmd),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Right: form panel
            if (_showForm) ...[
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CommandForm(
                    initial: _editingCommand,
                    onSave: _save,
                    onCancel: _cancelForm,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
