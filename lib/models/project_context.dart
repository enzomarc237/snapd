// Represents the detected project context (e.g. Node, Python, Go).
enum ProjectType { unknown, node, python, go, rust, ruby, java }

class ProjectContext {
  final ProjectType projectType;
  final String? projectPath;
  final String? activeApp;

  const ProjectContext({
    required this.projectType,
    this.projectPath,
    this.activeApp,
  });

  String get projectTypeName {
    switch (projectType) {
      case ProjectType.node:
        return 'Node.js';
      case ProjectType.python:
        return 'Python';
      case ProjectType.go:
        return 'Go';
      case ProjectType.rust:
        return 'Rust';
      case ProjectType.ruby:
        return 'Ruby';
      case ProjectType.java:
        return 'Java';
      case ProjectType.unknown:
        return 'Unknown';
    }
  }

  /// Returns tags associated with the detected project type.
  List<String> get relevantTags {
    switch (projectType) {
      case ProjectType.node:
        return ['node', 'npm', 'javascript', 'typescript'];
      case ProjectType.python:
        return ['python', 'pip', 'django', 'flask'];
      case ProjectType.go:
        return ['go', 'golang'];
      case ProjectType.rust:
        return ['rust', 'cargo'];
      case ProjectType.ruby:
        return ['ruby', 'rails', 'gem'];
      case ProjectType.java:
        return ['java', 'maven', 'gradle'];
      case ProjectType.unknown:
        return [];
    }
  }

  @override
  String toString() =>
      'ProjectContext(type: $projectTypeName, path: $projectPath, app: $activeApp)';
}
