import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_agent.dart';
import '../models/chat_message.dart';
import '../services/ai_agent_service.dart';
import '../services/ai_chat_service.dart';

/// Panel for chatting with a configured AI agent.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  AiAgent? _selectedAgent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default to first enabled agent.
      final svc = context.read<AiAgentService>();
      if (svc.enabledAgents.isNotEmpty) {
        setState(() => _selectedAgent = svc.enabledAgents.first);
      }
      _inputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    if (_selectedAgent == null) {
      _showNoAgentSnackBar();
      return;
    }
    _inputCtrl.clear();
    final svc = context.read<AiChatService>();
    await svc.sendMessage(_selectedAgent!, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNoAgentSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add an AI agent in the Agents panel first.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AiAgentService, AiChatService>(
      builder: (context, agentSvc, chatSvc, _) {
        return Column(
          children: [
            _Header(
              agents: agentSvc.enabledAgents,
              selected: _selectedAgent,
              onAgentSelected: (a) => setState(() => _selectedAgent = a),
              onClearHistory: chatSvc.clearHistory,
            ),
            const Divider(height: 1),
            Expanded(
              child: chatSvc.messages.isEmpty
                  ? _EmptyState(agentName: _selectedAgent?.name)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: chatSvc.messages.length,
                      itemBuilder: (ctx, i) =>
                          _MessageBubble(message: chatSvc.messages[i]),
                    ),
            ),
            if (chatSvc.isTyping)
              const LinearProgressIndicator(minHeight: 2),
            _InputRow(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              isEnabled: !chatSvc.isTyping && _selectedAgent != null,
              onSend: _sendMessage,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final List<AiAgent> agents;
  final AiAgent? selected;
  final ValueChanged<AiAgent> onAgentSelected;
  final VoidCallback onClearHistory;

  const _Header({
    required this.agents,
    required this.selected,
    required this.onAgentSelected,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('AI Chat',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: agents.isEmpty
                ? Text(
                    'No agents configured',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<AiAgent>(
                      value: selected,
                      isDense: true,
                      items: agents
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(
                                  '${a.name} (${a.model})',
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (a) {
                        if (a != null) onAgentSelected(a);
                      },
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 16),
            tooltip: 'Clear history',
            onPressed: onClearHistory,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? agentName;
  const _EmptyState({this.agentName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            agentName != null
                ? 'Start a conversation with $agentName'
                : 'Select an agent above to start chatting',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == ChatRole.user;

    if (message.isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.errorText ?? 'Unknown error',
            style: TextStyle(
                color: colorScheme.onErrorContainer, fontSize: 12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: isUser
                  ? const Radius.circular(14)
                  : const Radius.circular(4),
              bottomRight: isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(14),
            ),
          ),
          child: message.isStreaming
              ? _TypingIndicator()
              : SelectableText(
                  message.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUser
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = (_ctrl.value + delay) % 1.0;
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2)
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(radius: 3),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEnabled;
  final VoidCallback onSend;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.isEnabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: isEnabled,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: isEnabled ? (_) => onSend() : null,
              decoration: InputDecoration(
                hintText: 'Ask anything…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded, size: 18),
            onPressed: isEnabled ? onSend : null,
            tooltip: 'Send (↵)',
          ),
        ],
      ),
    );
  }
}
