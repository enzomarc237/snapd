import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_agent.dart';
import '../services/ai_agent_service.dart';

/// Panel for adding, editing, and toggling AI agents/assistants.
class AiAgentsScreen extends StatefulWidget {
  const AiAgentsScreen({super.key});

  @override
  State<AiAgentsScreen> createState() => _AiAgentsScreenState();
}

class _AiAgentsScreenState extends State<AiAgentsScreen> {
  AiAgent? _editing;
  bool _showForm = false;

  void _startAdd() => setState(() {
        _showForm = true;
        _editing = null;
      });

  void _startEdit(AiAgent agent) => setState(() {
        _showForm = true;
        _editing = agent;
      });

  void _cancelForm() => setState(() {
        _showForm = false;
        _editing = null;
      });

  Future<void> _save(
    String name,
    AiAgentType type,
    String model,
    String? apiKey,
    String? baseUrl,
    String systemPrompt,
  ) async {
    final svc = context.read<AiAgentService>();
    if (_editing != null) {
      await svc.update(
        _editing!.id,
        name: name,
        type: type,
        model: model,
        apiKey: apiKey,
        baseUrl: baseUrl,
        systemPrompt: systemPrompt,
      );
    } else {
      await svc.add(
        name: name,
        type: type,
        model: model,
        apiKey: apiKey,
        baseUrl: baseUrl,
        systemPrompt: systemPrompt,
      );
    }
    if (mounted) _cancelForm();
  }

  Future<void> _delete(AiAgent agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove agent?'),
        content: Text('Remove "${agent.name}" from the dock?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remove',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AiAgentService>().delete(agent.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAgentService>(
      builder: (context, svc, _) {
        return Row(
          children: [
            // Agent list
            Expanded(
              flex: _showForm ? 1 : 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    icon: Icons.smart_toy_outlined,
                    title: 'AI Agents',
                    action: FilledButton.icon(
                      onPressed: _startAdd,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  Expanded(
                    child: svc.agents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.smart_toy,
                                    size: 36,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.3)),
                                const SizedBox(height: 8),
                                Text(
                                  'No agents yet.\nTap Add to connect one.',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: svc.agents.length,
                            itemBuilder: (ctx, i) => _AgentTile(
                              agent: svc.agents[i],
                              onToggle: () =>
                                  svc.toggleEnabled(svc.agents[i].id),
                              onEdit: () => _startEdit(svc.agents[i]),
                              onDelete: () => _delete(svc.agents[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Edit form
            if (_showForm) ...[
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _AgentForm(
                    initial: _editing,
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

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  final AiAgent agent;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgentTile({
    required this.agent,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: agent.isEnabled
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(Icons.smart_toy_outlined,
              size: 16,
              color: agent.isEnabled
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant),
        ),
        title: Text(agent.name,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${agent.type.displayName} · ${agent.model}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: agent.isEnabled,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 14),
              onPressed: onEdit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon:
                  Icon(Icons.delete_outline, size: 14, color: colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentForm extends StatefulWidget {
  final AiAgent? initial;
  final Future<void> Function(
    String name,
    AiAgentType type,
    String model,
    String? apiKey,
    String? baseUrl,
    String systemPrompt,
  ) onSave;
  final VoidCallback onCancel;

  const _AgentForm({
    this.initial,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AgentForm> createState() => _AgentFormState();
}

class _AgentFormState extends State<_AgentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _systemPromptCtrl;
  late AiAgentType _type;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _type = a?.type ?? AiAgentType.openai;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _modelCtrl = TextEditingController(
        text: a?.model ?? AiAgentType.openai.suggestedModels.first);
    _apiKeyCtrl = TextEditingController(text: a?.apiKey ?? '');
    _baseUrlCtrl = TextEditingController(text: a?.baseUrl ?? '');
    _systemPromptCtrl =
        TextEditingController(text: a?.systemPrompt ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _systemPromptCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(AiAgentType? t) {
    if (t == null) return;
    setState(() => _type = t);
    // Auto-fill suggested model if field is empty.
    if (_modelCtrl.text.isEmpty && t.suggestedModels.isNotEmpty) {
      _modelCtrl.text = t.suggestedModels.first;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameCtrl.text.trim(),
        _type,
        _modelCtrl.text.trim(),
        _apiKeyCtrl.text.trim().isNotEmpty ? _apiKeyCtrl.text.trim() : null,
        _baseUrlCtrl.text.trim().isNotEmpty ? _baseUrlCtrl.text.trim() : null,
        _systemPromptCtrl.text.trim(),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isEditing ? 'Edit Agent' : 'New Agent',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autofocus: true,
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Name is required.' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AiAgentType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Provider *',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: AiAgentType.values
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(t.displayName)))
                .toList(),
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (v) => _type.suggestedModels
                .where((m) => m.contains(v.text.toLowerCase())),
            fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
              // Sync with _modelCtrl
              if (_modelCtrl.text.isNotEmpty && ctrl.text.isEmpty) {
                ctrl.text = _modelCtrl.text;
              }
              return TextFormField(
                controller: ctrl,
                focusNode: focus,
                decoration: const InputDecoration(
                  labelText: 'Model *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => _modelCtrl.text = v,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Model is required.' : null,
              );
            },
            onSelected: (m) => _modelCtrl.text = m,
          ),
          if (_type.requiresApiKey) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _apiKeyCtrl,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: _baseUrlCtrl,
            decoration: InputDecoration(
              labelText: 'Base URL',
              hintText: _type.defaultBaseUrl,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _systemPromptCtrl,
            decoration: const InputDecoration(
              labelText: 'System prompt',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: _submit,
                  child:
                      Text(isEditing ? 'Save changes' : 'Add agent')),
            ],
          ),
        ],
      ),
    );
  }
}
