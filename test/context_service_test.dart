import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:snapd/models/project_context.dart';
import 'package:snapd/services/context_service.dart';

void main() {
  late ContextService svc;
  late Directory tempDir;

  setUp(() async {
    svc = ContextService();
    tempDir = await Directory.systemTemp.createTemp('snapd_ctx_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ContextService', () {
    test('detects Node project from package.json', () async {
      File('${tempDir.path}/package.json').writeAsStringSync('{}');
      final ctx = await svc.detect(path: tempDir.path);
      expect(ctx.projectType, ProjectType.node);
    });

    test('detects Python project from requirements.txt', () async {
      File('${tempDir.path}/requirements.txt').writeAsStringSync('flask\n');
      final ctx = await svc.detect(path: tempDir.path);
      expect(ctx.projectType, ProjectType.python);
    });

    test('detects Go project from go.mod', () async {
      File('${tempDir.path}/go.mod').writeAsStringSync('module example.com/app\n');
      final ctx = await svc.detect(path: tempDir.path);
      expect(ctx.projectType, ProjectType.go);
    });

    test('detects Rust project from Cargo.toml', () async {
      File('${tempDir.path}/Cargo.toml').writeAsStringSync('[package]\n');
      final ctx = await svc.detect(path: tempDir.path);
      expect(ctx.projectType, ProjectType.rust);
    });

    test('returns unknown for empty directory', () async {
      final ctx = await svc.detect(path: tempDir.path);
      expect(ctx.projectType, ProjectType.unknown);
    });

    test('detects project in parent directory', () async {
      // Create a subdirectory and put the marker in the parent.
      final subDir = await Directory('${tempDir.path}/src').create();
      File('${tempDir.path}/package.json').writeAsStringSync('{}');
      final ctx = await svc.detect(path: subDir.path);
      expect(ctx.projectType, ProjectType.node);
    });

    test('notifies listeners on context change', () async {
      bool notified = false;
      svc.addListener(() => notified = true);
      File('${tempDir.path}/go.mod').writeAsStringSync('module x\n');
      await svc.detect(path: tempDir.path);
      expect(notified, isTrue);
    });
  });
}
