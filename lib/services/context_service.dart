import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/project_context.dart';

/// Detects the project type of the current working directory (or a given path)
/// by checking for well-known project marker files.
class ContextService extends ChangeNotifier {
  ProjectContext _context = const ProjectContext(projectType: ProjectType.unknown);

  ProjectContext get context => _context;

  /// Detects the project type from [path] (defaults to cwd).
  Future<ProjectContext> detect({String? path}) async {
    final dir = path ?? Directory.current.path;
    final detected = await _detectFromDirectory(dir);
    if (detected != _context) {
      _context = detected;
      notifyListeners();
    }
    return detected;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<ProjectContext> _detectFromDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return ProjectContext(projectType: ProjectType.unknown, projectPath: dirPath);
    }

    // Walk up directory tree looking for project markers.
    Directory current = dir;
    for (int depth = 0; depth < 5; depth++) {
      final type = _typeFromMarkers(current);
      if (type != ProjectType.unknown) {
        return ProjectContext(projectType: type, projectPath: current.path);
      }
      final parent = current.parent;
      if (parent.path == current.path) break; // reached filesystem root
      current = parent;
    }

    return ProjectContext(projectType: ProjectType.unknown, projectPath: dirPath);
  }

  ProjectType _typeFromMarkers(Directory dir) {
    final markerMap = {
      'package.json': ProjectType.node,
      'requirements.txt': ProjectType.python,
      'setup.py': ProjectType.python,
      'pyproject.toml': ProjectType.python,
      'go.mod': ProjectType.go,
      'Cargo.toml': ProjectType.rust,
      'Gemfile': ProjectType.ruby,
      'pom.xml': ProjectType.java,
      'build.gradle': ProjectType.java,
    };
    for (final entry in markerMap.entries) {
      if (File('${dir.path}/${entry.key}').existsSync()) {
        return entry.value;
      }
    }
    return ProjectType.unknown;
  }
}
