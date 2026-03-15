import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:snapd/models/ai_agent.dart';
import 'package:snapd/services/ai_agent_service.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir;
}

void main() {
  late Directory tempDir;
  late AiAgentService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('snapd_agent_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    svc = AiAgentService();
    await svc.load();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('AiAgentService', () {
    test('loads empty list on first run', () {
      expect(svc.agents, isEmpty);
      expect(svc.isLoaded, isTrue);
    });

    test('add creates a new agent', () async {
      await svc.add(
        name: 'Test Agent',
        type: AiAgentType.openai,
        model: 'gpt-4o',
        apiKey: 'sk-test',
      );
      expect(svc.agents.length, 1);
      expect(svc.agents.first.name, 'Test Agent');
    });

    test('enabledAgents excludes disabled agents', () async {
      final a = await svc.add(
          name: 'A', type: AiAgentType.openai, model: 'gpt-4o');
      await svc.add(name: 'B', type: AiAgentType.ollama, model: 'llama3');
      await svc.update(a.id, isEnabled: false);
      expect(svc.enabledAgents.length, 1);
      expect(svc.enabledAgents.first.name, 'B');
    });

    test('update modifies an existing agent', () async {
      final agent =
          await svc.add(name: 'Old', type: AiAgentType.openai, model: 'x');
      await svc.update(agent.id, name: 'New', model: 'gpt-4o');
      final updated = svc.agents.firstWhere((a) => a.id == agent.id);
      expect(updated.name, 'New');
      expect(updated.model, 'gpt-4o');
    });

    test('delete removes the agent', () async {
      final agent =
          await svc.add(name: 'ToDelete', type: AiAgentType.openai, model: 'x');
      await svc.delete(agent.id);
      expect(svc.agents.any((a) => a.id == agent.id), isFalse);
    });

    test('toggleEnabled flips the isEnabled flag', () async {
      final agent =
          await svc.add(name: 'Toggle', type: AiAgentType.openai, model: 'x');
      expect(agent.isEnabled, isTrue);
      await svc.toggleEnabled(agent.id);
      expect(svc.agents.first.isEnabled, isFalse);
      await svc.toggleEnabled(agent.id);
      expect(svc.agents.first.isEnabled, isTrue);
    });

    test('update throws for unknown id', () async {
      expect(() => svc.update('nonexistent', name: 'x'), throwsArgumentError);
    });

    test('persists across reload', () async {
      await svc.add(
          name: 'Persistent', type: AiAgentType.ollama, model: 'llama3');
      final svc2 = AiAgentService();
      await svc2.load();
      expect(svc2.agents.any((a) => a.name == 'Persistent'), isTrue);
    });

    test('notifies listeners on add', () async {
      var notified = false;
      svc.addListener(() => notified = true);
      await svc.add(name: 'N', type: AiAgentType.openai, model: 'm');
      expect(notified, isTrue);
    });
  });
}
