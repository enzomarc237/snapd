import 'package:flutter_test/flutter_test.dart';

import 'package:snapd/models/ai_agent.dart';
import 'package:snapd/models/chat_message.dart';

void main() {
  group('AiAgent', () {
    test('serialises to and from JSON', () {
      final now = DateTime(2024, 1, 1);
      final agent = AiAgent(
        id: 'id-1',
        name: 'GPT-4o',
        type: AiAgentType.openai,
        model: 'gpt-4o',
        apiKey: 'sk-test',
        baseUrl: null,
        systemPrompt: 'Be concise.',
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );
      final json = agent.toJson();
      final restored = AiAgent.fromJson(json);

      expect(restored.id, agent.id);
      expect(restored.name, agent.name);
      expect(restored.type, agent.type);
      expect(restored.model, agent.model);
      expect(restored.apiKey, agent.apiKey);
      expect(restored.systemPrompt, agent.systemPrompt);
      expect(restored.isEnabled, agent.isEnabled);
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime(2024, 1, 1);
      final original = AiAgent(
        id: 'id-1',
        name: 'Original',
        type: AiAgentType.openai,
        model: 'gpt-4o',
        createdAt: now,
        updatedAt: now,
      );
      final copy = original.copyWith(name: 'Updated', isEnabled: false);

      expect(copy.id, original.id);
      expect(copy.name, 'Updated');
      expect(copy.isEnabled, false);
      expect(copy.type, original.type);
      expect(copy.model, original.model);
    });

    test('equality is based on id', () {
      final now = DateTime(2024, 1, 1);
      final a = AiAgent(
          id: 'same',
          name: 'A',
          type: AiAgentType.openai,
          model: 'm',
          createdAt: now,
          updatedAt: now);
      final b = AiAgent(
          id: 'same',
          name: 'B',
          type: AiAgentType.anthropic,
          model: 'n',
          createdAt: now,
          updatedAt: now);
      final c = AiAgent(
          id: 'diff',
          name: 'A',
          type: AiAgentType.openai,
          model: 'm',
          createdAt: now,
          updatedAt: now);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('effectiveBaseUrl returns custom url if set', () {
      final now = DateTime(2024, 1, 1);
      final agent = AiAgent(
        id: '1',
        name: 'x',
        type: AiAgentType.openai,
        model: 'm',
        baseUrl: 'https://my.proxy.com/v1',
        createdAt: now,
        updatedAt: now,
      );
      expect(agent.effectiveBaseUrl, 'https://my.proxy.com/v1');
    });

    test('effectiveBaseUrl falls back to provider default', () {
      final now = DateTime(2024, 1, 1);
      final agent = AiAgent(
        id: '1',
        name: 'x',
        type: AiAgentType.ollama,
        model: 'llama3',
        createdAt: now,
        updatedAt: now,
      );
      expect(agent.effectiveBaseUrl, 'http://localhost:11434/v1');
    });

    test('fromJson tolerates unknown type', () {
      final now = DateTime(2024, 1, 1).toIso8601String();
      final json = {
        'id': 'x',
        'name': 'y',
        'type': 'unknownProvider',
        'model': 'm',
        'isEnabled': true,
        'systemPrompt': '',
        'createdAt': now,
        'updatedAt': now,
      };
      final agent = AiAgent.fromJson(json);
      expect(agent.type, AiAgentType.custom);
    });

    test('AiAgentType requiresApiKey', () {
      expect(AiAgentType.ollama.requiresApiKey, isFalse);
      expect(AiAgentType.openai.requiresApiKey, isTrue);
    });

    test('AiAgentType suggestedModels is non-empty for known providers', () {
      for (final type in [
        AiAgentType.openai,
        AiAgentType.anthropic,
        AiAgentType.ollama,
        AiAgentType.gemini,
      ]) {
        expect(type.suggestedModels, isNotEmpty, reason: '${type.name} has no models');
      }
    });
  });

  group('ChatMessage', () {
    test('isError is true when errorText is set', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        errorText: 'Something went wrong',
      );
      expect(msg.isError, isTrue);
    });

    test('copyWith clears errorText when not passed', () {
      final original = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: 'text',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      final updated = original.copyWith(content: 'done', isStreaming: false);
      expect(updated.content, 'done');
      expect(updated.isStreaming, isFalse);
      expect(updated.errorText, isNull);
    });
  });
}
