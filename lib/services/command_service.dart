import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/command.dart';

/// Manages persistence and CRUD operations for [Command] objects.
///
/// Commands are persisted to a JSON file in the application support directory.
class CommandService extends ChangeNotifier {
  static const String _fileName = 'commands.json';
  static const _uuid = Uuid();

  List<Command> _commands = [];
  bool _isLoaded = false;

  List<Command> get commands => List.unmodifiable(_commands);
  bool get isLoaded => _isLoaded;

  /// Loads commands from disk. Must be called before using other methods.
  Future<void> load() async {
    final file = await _configFile();
    if (!await file.exists()) {
      _commands = _defaultCommands();
      await _persist();
    } else {
      try {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
        _commands = jsonList
            .cast<Map<String, dynamic>>()
            .map(Command.fromJson)
            .toList();
      } catch (e) {
        debugPrint('CommandService: failed to load commands – $e');
        _commands = _defaultCommands();
        await _persist();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Adds a new [Command] and persists to disk.
  Future<Command> add({
    required String name,
    required String script,
    String description = '',
    List<String> tags = const [],
  }) async {
    _assertLoaded();
    final cmd = Command(
      id: _uuid.v4(),
      name: name.trim(),
      description: description.trim(),
      script: script.trim(),
      tags: List<String>.from(tags),
    );
    _commands.add(cmd);
    await _persist();
    notifyListeners();
    return cmd;
  }

  /// Updates an existing [Command] identified by [id].
  Future<void> update(
    String id, {
    String? name,
    String? description,
    String? script,
    List<String>? tags,
  }) async {
    _assertLoaded();
    final index = _commands.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw ArgumentError('Command with id "$id" not found.');
    }
    final existing = _commands[index];
    _commands[index] = existing.copyWith(
      name: name?.trim() ?? existing.name,
      description: description?.trim() ?? existing.description,
      script: script?.trim() ?? existing.script,
      tags: tags ?? existing.tags,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  /// Deletes the [Command] with the given [id].
  Future<void> delete(String id) async {
    _assertLoaded();
    _commands.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  /// Returns commands matching [query] (name, description, tags).
  List<Command> search(String query) {
    if (query.isEmpty) return commands;
    final lower = query.toLowerCase();
    return _commands.where((cmd) {
      return cmd.name.toLowerCase().contains(lower) ||
          cmd.description.toLowerCase().contains(lower) ||
          cmd.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  /// Returns commands that have at least one tag in [tags].
  List<Command> filterByTags(List<String> tags) {
    if (tags.isEmpty) return commands;
    return _commands
        .where((cmd) => cmd.tags.any((t) => tags.contains(t)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<File> _configFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _persist() async {
    final file = await _configFile();
    final json = jsonEncode(_commands.map((c) => c.toJson()).toList());
    await file.writeAsString(json, flush: true);
  }

  void _assertLoaded() {
    if (!_isLoaded) {
      throw StateError('CommandService has not been loaded yet. Call load().');
    }
  }

  List<Command> _defaultCommands() => [
        Command(
          id: _uuid.v4(),
          name: 'List files',
          description: 'List all files in current directory',
          script: 'ls -la',
          tags: ['shell'],
        ),
        Command(
          id: _uuid.v4(),
          name: 'Git status',
          description: 'Show git working tree status',
          script: 'git status',
          tags: ['git'],
        ),
        Command(
          id: _uuid.v4(),
          name: 'npm install',
          description: 'Install Node.js dependencies',
          script: 'npm install',
          tags: ['node', 'npm'],
        ),
        Command(
          id: _uuid.v4(),
          name: 'pip install requirements',
          description: 'Install Python dependencies',
          script: 'pip install -r requirements.txt',
          tags: ['python', 'pip'],
        ),
        Command(
          id: _uuid.v4(),
          name: 'go build',
          description: 'Build the Go project',
          script: 'go build ./...',
          tags: ['go', 'golang'],
        ),
      ];
}
