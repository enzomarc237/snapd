import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:snapd/services/command_service.dart';

// ---------------------------------------------------------------------------
// Fake path_provider for tests
// ---------------------------------------------------------------------------

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
  late CommandService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('snapd_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    svc = CommandService();
    await svc.load();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('CommandService', () {
    test('loads default commands on first run', () {
      expect(svc.commands, isNotEmpty);
    });

    test('add creates a new command', () async {
      final before = svc.commands.length;
      await svc.add(name: 'Hello', script: 'echo hello');
      expect(svc.commands.length, before + 1);
      expect(svc.commands.last.name, 'Hello');
    });

    test('update modifies an existing command', () async {
      final cmd = await svc.add(name: 'Old', script: 'old');
      await svc.update(cmd.id, name: 'New', script: 'new');
      final updated = svc.commands.firstWhere((c) => c.id == cmd.id);
      expect(updated.name, 'New');
      expect(updated.script, 'new');
    });

    test('delete removes the command', () async {
      final cmd = await svc.add(name: 'ToDelete', script: 'del');
      await svc.delete(cmd.id);
      expect(svc.commands.any((c) => c.id == cmd.id), isFalse);
    });

    test('search filters by name', () async {
      await svc.add(name: 'Find me', script: 'echo');
      await svc.add(name: 'Ignore me', script: 'echo');
      final results = svc.search('find');
      expect(results.any((c) => c.name == 'Find me'), isTrue);
      expect(results.any((c) => c.name == 'Ignore me'), isFalse);
    });

    test('search filters by tag', () async {
      await svc.add(name: 'Tagged', script: 'echo', tags: ['mytag']);
      await svc.add(name: 'Untagged', script: 'echo');
      final results = svc.search('mytag');
      expect(results.any((c) => c.name == 'Tagged'), isTrue);
    });

    test('search returns all commands for empty query', () {
      final results = svc.search('');
      expect(results.length, svc.commands.length);
    });

    test('filterByTags returns commands with matching tag', () async {
      await svc.add(name: 'NodeCmd', script: 'npm test', tags: ['node']);
      final results = svc.filterByTags(['node']);
      expect(results.any((c) => c.name == 'NodeCmd'), isTrue);
    });

    test('update throws for unknown id', () async {
      expect(
        () => svc.update('nonexistent', name: 'x'),
        throwsArgumentError,
      );
    });

    test('persists across reload', () async {
      await svc.add(name: 'Persistent', script: 'echo persistent');
      final svc2 = CommandService();
      await svc2.load();
      expect(svc2.commands.any((c) => c.name == 'Persistent'), isTrue);
    });
  });
}
