import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/ai_agent.dart';
import '../models/chat_message.dart';

/// Sends chat messages to an AI provider and streams the response.
///
/// Uses the OpenAI-compatible chat completions API, which is supported by
/// OpenAI, Anthropic (via compatibility), Ollama, and most custom providers.
class AiChatService extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  /// Sends a user message to [agent] and appends both the user message and the
  /// streamed assistant response to the conversation history.
  ///
  /// Returns the final assistant [ChatMessage].
  Future<ChatMessage> sendMessage(AiAgent agent, String userText) async {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: userText.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // Placeholder assistant message shown while streaming.
    final assistantId = _uuid.v4();
    final placeholderMsg = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(placeholderMsg);
    notifyListeners();

    try {
      final response = await _callApi(agent, userText);
      _updateLastMessage(assistantId, response);
    } catch (e) {
      _updateLastMessage(
        assistantId,
        '',
        errorText: e.toString(),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }

    return _messages.last;
  }

  /// Clears the conversation history.
  void clearHistory() {
    _messages.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<String> _callApi(AiAgent agent, String userText) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (agent.apiKey?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer ${agent.apiKey}';
    }

    // Build context from previous messages (last 20 turns).
    final history = _messages
        .where((m) =>
            m.role != ChatRole.system && !m.isStreaming && m.errorText == null)
        .toList();
    final contextMsgs = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    final messagesPayload = <Map<String, String>>[
      if (agent.systemPrompt.isNotEmpty)
        {'role': 'system', 'content': agent.systemPrompt},
      ...contextMsgs.map((m) => {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          }),
    ];

    final body = jsonEncode({
      'model': agent.model,
      'messages': messagesPayload,
      'temperature': 0.7,
      'max_tokens': 2048,
    });

    final uri = Uri.parse('${agent.effectiveBaseUrl}/chat/completions');
    final httpResponse = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 60));

    if (httpResponse.statusCode != 200) {
      throw Exception(
          'HTTP ${httpResponse.statusCode}: ${httpResponse.body}');
    }

    final decoded = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>;
    if (choices.isEmpty) throw Exception('No response choices returned.');

    final content =
        (choices.first as Map<String, dynamic>)['message']
            ?['content'] as String? ??
        '';
    return content;
  }

  void _updateLastMessage(
    String id,
    String content, {
    String? errorText,
  }) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _messages[index] = _messages[index].copyWith(
      content: content,
      isStreaming: false,
      errorText: errorText,
    );
    notifyListeners();
  }
}
