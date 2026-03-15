import 'package:flutter_test/flutter_test.dart';

import 'package:snapd/models/command.dart';
import 'package:snapd/models/command_result.dart';
import 'package:snapd/models/project_context.dart';

void main() {
  group('Command model', () {
    test('serialises to and from JSON', () {
      final cmd = Command(
        id: 'abc-123',
        name: 'Test',
        description: 'A test command',
        script: 'echo hi',
        tags: ['shell', 'test'],
      );

      final json = cmd.toJson();
      final restored = Command.fromJson(json);

      expect(restored.id, cmd.id);
      expect(restored.name, cmd.name);
      expect(restored.description, cmd.description);
      expect(restored.script, cmd.script);
      expect(restored.tags, cmd.tags);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Command(
        id: 'abc-123',
        name: 'Original',
        description: 'desc',
        script: 'echo original',
        tags: ['a', 'b'],
      );

      final copy = original.copyWith(name: 'Updated');

      expect(copy.id, original.id);
      expect(copy.name, 'Updated');
      expect(copy.description, original.description);
      expect(copy.script, original.script);
      expect(copy.tags, original.tags);
    });

    test('equality is based on id', () {
      final a = Command(id: 'same', name: 'A', description: '', script: 'a');
      final b = Command(id: 'same', name: 'B', description: '', script: 'b');
      final c = Command(id: 'diff', name: 'A', description: '', script: 'a');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'x',
        'name': 'Minimal',
        'script': 'ls',
      };

      final cmd = Command.fromJson(json);
      expect(cmd.description, '');
      expect(cmd.tags, isEmpty);
    });
  });

  group('CommandResult', () {
    test('isSuccess returns true when exitCode is 0', () {
      final result = CommandResult(
        stdout: 'ok',
        stderr: '',
        exitCode: 0,
        duration: Duration.zero,
      );
      expect(result.isSuccess, isTrue);
    });

    test('isSuccess returns false for non-zero exit code', () {
      final result = CommandResult(
        stdout: '',
        stderr: 'error',
        exitCode: 1,
        duration: Duration.zero,
      );
      expect(result.isSuccess, isFalse);
    });
  });

  group('ProjectContext', () {
    test('relevantTags for node includes npm and javascript', () {
      final ctx = ProjectContext(projectType: ProjectType.node);
      expect(ctx.relevantTags, contains('npm'));
      expect(ctx.relevantTags, contains('javascript'));
    });

    test('relevantTags for unknown is empty', () {
      final ctx = ProjectContext(projectType: ProjectType.unknown);
      expect(ctx.relevantTags, isEmpty);
    });

    test('projectTypeName returns correct label', () {
      expect(
        ProjectContext(projectType: ProjectType.python).projectTypeName,
        'Python',
      );
      expect(
        ProjectContext(projectType: ProjectType.go).projectTypeName,
        'Go',
      );
    });
  });
}
